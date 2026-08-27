import {
  KNOWN_ROLES,
  decodeReserveConfiguration,
  getBits,
  getSolidityStorageSlotAddress,
  getSolidityStorageSlotBytes,
  getSolidityStorageSlotUint,
} from '@aave-dao/toolbox';
import { getAddressBookReferences } from '@aave-dao/aave-address-book/utils';
import {
  getAddress,
  hexToString,
  keccak256,
  slice,
  stringToHex,
  toHex,
  type Address,
  type Hex,
} from 'viem';
import type { RawStorage, SlotDiff, AaveV3Snapshot } from '../snapshot-types';
import type { AaveV4Snapshot } from '../snapshot-types-v4';
import type { StorageLayout } from './storageLayoutTypes';
import { enumRegistry, storageLayoutDb, wellKnownSlots } from './storageLayoutDb';
import {
  buildV3Context,
  buildV4Context,
  resolveContractKind,
  type SnapshotContext,
} from './resolveContractKind';

export type DecodedField = {
  /** variable path, e.g. '_reserves[0x…(WETH)].configuration.ltv' */
  label: string;
  /** solidity type, e.g. 'uint16' */
  type: string;
  previousValue: string;
  newValue: string;
};

export type DecodedSlot = { fields: DecodedField[] };

/** contract address -> slot -> decoded fields; slots without an entry render raw */
export type DecodedStorage = Record<string, Record<string, DecodedSlot>>;

export type CandidateKeys = {
  addresses: Set<string>;
  uints: Set<bigint>;
  bytes32: Set<Hex>;
};

type Snapshot = AaveV3Snapshot | AaveV4Snapshot;

/** structural log type: accepts both snapshot logs (emitter) and toolbox parsed logs (address + args) */
export type CandidateLog = {
  topics?: readonly string[];
  emitter?: string;
  address?: string;
  args?: unknown;
};

/** ids used by PoolAddressesProvider._addresses, stored as bytes32 short strings */
const ADDRESSES_PROVIDER_IDS = [
  'POOL',
  'POOL_CONFIGURATOR',
  'PRICE_ORACLE',
  'ACL_MANAGER',
  'ACL_ADMIN',
  'PRICE_ORACLE_SENTINEL',
  'DATA_PROVIDER',
  'INCENTIVES_CONTROLLER',
];

const MAX_MAPPING_DEPTH = 2;
const MAX_ARRAY_WORDS = 64;

// --- candidate key gathering ---

const ADDRESS_RE = /^0x[0-9a-fA-F]{40}$/;
const BYTES32_RE = /^0x[0-9a-fA-F]{64}$/;

function addCandidateValue(candidates: CandidateKeys, value: unknown) {
  if (typeof value === 'bigint') {
    if (value >= 0n && value < 1n << 64n) candidates.uints.add(value);
  } else if (typeof value === 'number' && Number.isInteger(value) && value >= 0) {
    candidates.uints.add(BigInt(value));
  } else if (typeof value === 'string') {
    if (ADDRESS_RE.test(value)) candidates.addresses.add(value.toLowerCase());
    else if (BYTES32_RE.test(value)) {
      const asBigint = BigInt(value);
      candidates.bytes32.add(value as Hex);
      // 32-byte values with a 20-byte payload are frequently addresses (e.g. indexed topics)
      if (asBigint > 0n && asBigint < 1n << 160n) {
        candidates.addresses.add(toHex(asBigint, { size: 20 }));
      }
    }
  } else if (Array.isArray(value)) {
    for (const item of value) addCandidateValue(candidates, item);
  } else if (typeof value === 'object' && value !== null) {
    for (const item of Object.values(value)) addCandidateValue(candidates, item);
  }
}

export function buildCandidateKeys(
  after: Snapshot,
  raw: RawStorage,
  logs: CandidateLog[] | undefined
): CandidateKeys {
  const candidates: CandidateKeys = {
    addresses: new Set(),
    uints: new Set(),
    bytes32: new Set(),
  };

  // small integers: reserve ids, eMode ids, access levels, enum keys, …
  for (let i = 0n; i < 32n; i++) candidates.uints.add(i);
  for (const role of Object.keys(KNOWN_ROLES)) candidates.bytes32.add(role as Hex);
  for (const id of ADDRESSES_PROVIDER_IDS) candidates.bytes32.add(stringToHex(id, { size: 32 }));

  for (const [account, entry] of Object.entries(raw)) {
    candidates.addresses.add(account.toLowerCase());
    for (const diff of Object.values(entry.stateDiff)) {
      for (const value of [diff.previousValue, diff.newValue]) {
        const asBigint = BigInt(value);
        // heuristic: a 20-byte payload inside a changed word is likely an address
        if (asBigint > 0n && asBigint < 1n << 160n && asBigint > 1n << 120n) {
          candidates.addresses.add(toHex(asBigint, { size: 20 }));
        }
      }
    }
  }

  addCandidateValue(candidates, after as unknown);

  for (const log of logs ?? []) {
    const emitter = log.emitter ?? log.address;
    if (emitter) candidates.addresses.add(emitter.toLowerCase());
    for (const topic of log.topics?.slice(1) ?? []) addCandidateValue(candidates, topic);
    // decoded args are present when the caller passes eventDb-parsed logs
    addCandidateValue(candidates, log.args);
  }

  return candidates;
}

// --- layout indexing ---

type WordField = {
  label: string;
  typeId: string;
  offset: number;
  special?: 'bytes' | 'bytesData' | 'reserveConfig' | 'arrayLength';
};

type WordIndex = Map<bigint, WordField[]>;

/** how many overflow words of a long string/bytes variable get indexed */
const LONG_BYTES_WORDS = 4;

type Annotate = (address: string) => string;

function pushField(index: WordIndex, slot: bigint, field: WordField) {
  const fields = index.get(slot);
  if (fields) fields.push(field);
  else index.set(slot, [field]);
}

function formatMappingKey(
  keyTypeLabel: string,
  key: string | bigint | Hex,
  annotate: Annotate
): string {
  if (typeof key === 'bigint') return key.toString();
  if (keyTypeLabel.startsWith('address') || keyTypeLabel.startsWith('contract')) {
    return annotate(key as string);
  }
  const known = (KNOWN_ROLES as Record<string, string>)[key];
  return known ?? (key as string);
}

function expand(
  index: WordIndex,
  layout: StorageLayout,
  slot: bigint,
  label: string,
  typeId: string,
  offset: number,
  candidates: CandidateKeys,
  annotate: Annotate,
  mappingDepth: number
): void {
  const type = layout.types[typeId];
  if (!type) return;

  if (type.label.endsWith('ReserveConfigurationMap')) {
    pushField(index, slot, { label, typeId, offset: 0, special: 'reserveConfig' });
    return;
  }

  if (type.members) {
    for (const member of type.members) {
      expand(
        index,
        layout,
        slot + BigInt(member.slot),
        `${label}.${member.label}`,
        member.type,
        member.offset,
        candidates,
        annotate,
        mappingDepth
      );
    }
    return;
  }

  switch (type.encoding) {
    case 'inplace': {
      if (type.base) {
        // static array
        const itemType = layout.types[type.base];
        if (!itemType) return;
        const itemSize = Number(itemType.numberOfBytes);
        const totalBytes = Number(type.numberOfBytes);
        if (totalBytes / 32 > MAX_ARRAY_WORDS) return;
        if (itemSize >= 32) {
          const wordsPerItem = Math.ceil(itemSize / 32);
          const count = totalBytes / 32 / wordsPerItem;
          for (let i = 0; i < count; i++) {
            expand(
              index,
              layout,
              slot + BigInt(i * wordsPerItem),
              `${label}[${i}]`,
              type.base,
              0,
              candidates,
              annotate,
              mappingDepth
            );
          }
        } else {
          const perWord = Math.floor(32 / itemSize);
          const count = (totalBytes / 32) * perWord;
          for (let i = 0; i < count; i++) {
            pushField(index, slot + BigInt(Math.floor(i / perWord)), {
              label: `${label}[${i}]`,
              typeId: type.base,
              offset: (i % perWord) * itemSize,
            });
          }
        }
        return;
      }
      pushField(index, slot, { label, typeId, offset });
      return;
    }
    case 'bytes': {
      pushField(index, slot, { label, typeId, offset: 0, special: 'bytes' });
      // long strings/bytes overflow into keccak(slot) + i
      const contentBase = BigInt(keccak256(toHex(slot, { size: 32 })));
      for (let i = 0; i < LONG_BYTES_WORDS; i++) {
        pushField(index, contentBase + BigInt(i), {
          label: `${label} (data)`,
          typeId,
          offset: 0,
          special: 'bytesData',
        });
      }
      return;
    }
    case 'dynamic_array': {
      pushField(index, slot, {
        label: `${label}.length`,
        typeId,
        offset: 0,
        special: 'arrayLength',
      });
      return;
    }
    case 'mapping': {
      if (mappingDepth >= MAX_MAPPING_DEPTH || !type.key || !type.value) return;
      const keyType = layout.types[type.key];
      const keyLabel = keyType?.label ?? type.key;
      const expandForKey = (derivedSlot: Hex, key: string | bigint | Hex) => {
        expand(
          index,
          layout,
          BigInt(derivedSlot),
          `${label}[${formatMappingKey(keyLabel, key, annotate)}]`,
          type.value!,
          0,
          candidates,
          annotate,
          mappingDepth + 1
        );
      };
      if (keyLabel.startsWith('address') || keyLabel.startsWith('contract')) {
        for (const address of candidates.addresses) {
          expandForKey(getSolidityStorageSlotAddress(slot, address as Hex), address);
        }
      } else if (
        keyLabel.startsWith('uint') ||
        keyLabel.startsWith('int') ||
        keyLabel.startsWith('enum')
      ) {
        for (const key of candidates.uints) {
          expandForKey(getSolidityStorageSlotUint(slot, key), key);
        }
      } else if (keyLabel.startsWith('bytes32')) {
        for (const key of candidates.bytes32) {
          expandForKey(getSolidityStorageSlotBytes(toHex(slot, { size: 32 }), key), key);
        }
      }
      return;
    }
  }
}

export function buildWordIndex(
  layout: StorageLayout,
  candidates: CandidateKeys,
  annotate: Annotate = (address) => address
): WordIndex {
  const index: WordIndex = new Map();
  for (const variable of layout.storage) {
    expand(
      index,
      layout,
      BigInt(variable.slot),
      variable.label,
      variable.type,
      variable.offset,
      candidates,
      annotate,
      0
    );
  }
  return index;
}

// --- value decoding ---

function extractBits(word: bigint, offset: number, numberOfBytes: number): bigint {
  if (numberOfBytes >= 32) return word;
  return getBits(word, BigInt(offset * 8), BigInt((offset + numberOfBytes) * 8 - 1));
}

function formatValue(
  bits: bigint,
  typeLabel: string,
  numberOfBytes: number,
  annotate: (address: string) => string
): string {
  if (typeLabel.startsWith('address') || typeLabel.startsWith('contract')) {
    return annotate(toHex(bits, { size: 20 }));
  }
  if (typeLabel === 'bool') return bits === 0n ? 'false' : 'true';
  if (typeLabel.startsWith('enum ')) {
    const name = enumRegistry[typeLabel]?.[Number(bits)];
    return name ? `${bits} (${name})` : bits.toString();
  }
  if (typeLabel.startsWith('uint')) return bits.toString();
  if (typeLabel.startsWith('int')) {
    const width = BigInt(numberOfBytes * 8);
    const signed = bits >= 1n << (width - 1n) ? bits - (1n << width) : bits;
    return signed.toString();
  }
  if (typeLabel.startsWith('bytes')) return toHex(bits, { size: numberOfBytes });
  return toHex(bits, { size: numberOfBytes });
}

function formatShortStringWord(word: bigint, typeLabel: string): string {
  if (word === 0n) return '""';
  if ((word & 1n) === 1n) {
    return `(long ${typeLabel}, length ${(word - 1n) / 2n})`;
  }
  const length = Number(word & 0xffn) / 2;
  if (!Number.isInteger(length) || length > 31) return toHex(word, { size: 32 });
  if (length === 0) return '""';
  const content = slice(toHex(word, { size: 32 }), 0, length);
  return typeLabel === 'string' ? `"${hexToString(content)}"` : content;
}

/** renders one 32-byte overflow word of a long string/bytes variable */
function formatBytesDataWord(word: bigint, typeLabel: string): string {
  if (word === 0n) return '""';
  // strip trailing zero BYTES (viem's trim works per nibble, which would shift
  // content ending in a low-nibble-zero character like '0' = 0x30)
  let hex = toHex(word, { size: 32 }).slice(2);
  while (hex.endsWith('00')) hex = hex.slice(0, -2);
  const content = `0x${hex}` as Hex;
  if (typeLabel !== 'string') return content;
  try {
    return `"${hexToString(content)}"`;
  } catch {
    return content;
  }
}

function decodeReserveConfigFields(label: string, previous: bigint, next: bigint): DecodedField[] {
  const before = decodeReserveConfiguration(previous) as unknown as Record<string, unknown>;
  const after = decodeReserveConfiguration(next) as unknown as Record<string, unknown>;
  const fields: DecodedField[] = [];
  for (const key of Object.keys(after)) {
    if (String(before[key]) === String(after[key])) continue;
    fields.push({
      label: `${label}.${key}`,
      type: typeof after[key] === 'boolean' ? 'bool' : 'uint256',
      previousValue: String(before[key]),
      newValue: String(after[key]),
    });
  }
  return fields;
}

function decodeSlotAgainstFields(
  diff: SlotDiff,
  fields: WordField[],
  layout: StorageLayout,
  annotate: (address: string) => string
): DecodedField[] {
  const previous = BigInt(diff.previousValue);
  const next = BigInt(diff.newValue);
  const decoded: DecodedField[] = [];

  for (const field of fields) {
    const type = layout.types[field.typeId];
    const typeLabel = type?.label ?? field.typeId;

    if (field.special === 'reserveConfig') {
      decoded.push(...decodeReserveConfigFields(field.label, previous, next));
      continue;
    }
    if (field.special === 'bytes') {
      decoded.push({
        label: field.label,
        type: typeLabel,
        previousValue: formatShortStringWord(previous, typeLabel),
        newValue: formatShortStringWord(next, typeLabel),
      });
      continue;
    }
    if (field.special === 'bytesData') {
      decoded.push({
        label: field.label,
        type: typeLabel,
        previousValue: formatBytesDataWord(previous, typeLabel),
        newValue: formatBytesDataWord(next, typeLabel),
      });
      continue;
    }
    if (field.special === 'arrayLength') {
      decoded.push({
        label: field.label,
        type: 'uint256',
        previousValue: previous.toString(),
        newValue: next.toString(),
      });
      continue;
    }

    const numberOfBytes = Number(type?.numberOfBytes ?? 32);
    const previousBits = extractBits(previous, field.offset, numberOfBytes);
    const nextBits = extractBits(next, field.offset, numberOfBytes);
    if (previousBits === nextBits) continue; // only report fields whose bits changed
    decoded.push({
      label: field.label,
      type: typeLabel,
      previousValue: formatValue(previousBits, typeLabel, numberOfBytes, annotate),
      newValue: formatValue(nextBits, typeLabel, numberOfBytes, annotate),
    });
  }

  return decoded;
}

// --- top level ---

function buildContext(after: Snapshot): SnapshotContext {
  if ('reserves' in after) return buildV3Context(after);
  return buildV4Context(after);
}

/**
 * Best-effort decoding of raw storage diffs against known contract layouts.
 * Pure and deterministic (no RPC); anything that cannot be decoded is simply
 * absent from the result and renders as raw hex.
 */
export function decodeRawStorage(
  raw: RawStorage | undefined,
  after: Snapshot,
  logs: CandidateLog[] | undefined
): DecodedStorage {
  const decoded: DecodedStorage = {};
  if (!raw) return decoded;

  const chainId = after.chainId;
  const annotate = (address: string): string => {
    const checksummed = getAddress(address);
    try {
      const references = getAddressBookReferences(checksummed, chainId);
      if (references.length) return `${checksummed} (${references[0]})`;
    } catch {
      // annotation is cosmetic - never fail a decode over it
    }
    return checksummed;
  };

  let context: SnapshotContext;
  let candidates: CandidateKeys;
  try {
    context = buildContext(after);
    candidates = buildCandidateKeys(after, raw, logs);
  } catch {
    return decoded;
  }

  const indexCache = new Map<string, WordIndex>();

  for (const [account, entry] of Object.entries(raw)) {
    const slots: Record<string, DecodedSlot> = {};

    let index: WordIndex | undefined;
    let layout: StorageLayout | undefined;
    try {
      const kind = resolveContractKind(account as Address, chainId, context);
      const layoutEntry = kind ? storageLayoutDb[kind] : undefined;
      if (layoutEntry) {
        layout = layoutEntry.layout;
        index = indexCache.get(kind!);
        if (!index) {
          index = buildWordIndex(layout, candidates, annotate);
          indexCache.set(kind!, index);
        }
      }
    } catch {
      index = undefined;
    }

    for (const [slot, diff] of Object.entries(entry.stateDiff)) {
      try {
        // fields already decoded upstream (e.g. by foundry itself) win
        if (diff.label && diff.decoded) {
          slots[slot] = {
            fields: [
              {
                label: diff.label,
                type: diff.type ?? '-',
                previousValue: diff.decoded.previousValue,
                newValue: diff.decoded.newValue,
              },
            ],
          };
          continue;
        }

        const wellKnown = wellKnownSlots[slot as Hex];
        if (wellKnown) {
          slots[slot] = {
            fields: [
              {
                label: wellKnown.label,
                type: wellKnown.type,
                previousValue: formatValue(
                  BigInt(diff.previousValue),
                  wellKnown.type,
                  32,
                  annotate
                ),
                newValue: formatValue(BigInt(diff.newValue), wellKnown.type, 32, annotate),
              },
            ],
          };
          continue;
        }

        if (!index || !layout) continue;
        const fields = index.get(BigInt(slot));
        if (!fields) continue;
        const decodedFields = decodeSlotAgainstFields(diff, fields, layout, annotate);
        if (decodedFields.length) slots[slot] = { fields: decodedFields };
      } catch {
        // best effort: leave the slot raw
      }
    }

    if (Object.keys(slots).length) decoded[account] = slots;
  }

  return decoded;
}
