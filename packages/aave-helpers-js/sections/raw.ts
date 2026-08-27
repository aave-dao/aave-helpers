import type { RawStorage, CHAIN_ID } from '../snapshot-types';
import { isKnownAddress } from '../utils/address';
import type { DecodedStorage } from '../utils/decodeStorage';

function abbreviateSlot(slot: string): string {
  if (slot.length <= 14) return slot;
  return `${slot.slice(0, 8)}…${slot.slice(-4)}`;
}

export function renderRawSection(
  raw: RawStorage | undefined,
  chainId: CHAIN_ID,
  decoded?: DecodedStorage
): string {
  if (!raw) return '';

  const contracts = Object.keys(raw);
  if (!contracts.length) return '';

  let md = '## Raw storage changes\n\n';

  for (const address of contracts) {
    const entry = raw[address as keyof typeof raw];
    if (!entry) continue;

    const knownName = isKnownAddress(address as `0x${string}`, chainId);
    const label = entry.label || (knownName ? knownName.join(', ') : null);
    const heading = label ? `${address} (${label})` : address;

    md += `### ${heading}\n\n`;

    if (entry.balanceDiff) {
      md += `**Balance diff**: ${entry.balanceDiff.previousValue} → ${entry.balanceDiff.newValue}\n\n`;
    }
    if (entry.nonceDiff) {
      md += `**Nonce diff**: ${entry.nonceDiff.previousValue} → ${entry.nonceDiff.newValue}\n\n`;
    }

    const slots = Object.keys(entry.stateDiff);
    if (slots.length) {
      const decodedSlots = decoded?.[address] ?? {};
      const hasDecoded = slots.some((slot) => decodedSlots[slot]?.fields.length);

      if (hasDecoded) {
        md +=
          '| slot | variable | type | previous value | new value |\n| --- | --- | --- | --- | --- |\n';
        for (const slot of slots) {
          const slotDiff = entry.stateDiff[slot];
          const fields = decodedSlots[slot]?.fields;
          if (fields?.length) {
            for (const field of fields) {
              md += `| ${abbreviateSlot(slot)} | ${field.label} | ${field.type} | ${field.previousValue} | ${field.newValue} |\n`;
            }
          } else {
            // undecoded slots stay visible as raw hex in the same table
            md += `| ${abbreviateSlot(slot)} | - | - | ${slotDiff.previousValue} | ${slotDiff.newValue} |\n`;
          }
        }
      } else {
        md += '| slot | previous value | new value |\n| --- | --- | --- |\n';
        for (const slot of slots) {
          const slotDiff = entry.stateDiff[slot];
          const slotLabel = slotDiff.label ? ` (${slotDiff.label})` : '';
          md += `| ${slot}${slotLabel} | ${slotDiff.previousValue} | ${slotDiff.newValue} |\n`;
        }
      }
      md += '\n';
    }
  }

  md += '\n';
  return md;
}
