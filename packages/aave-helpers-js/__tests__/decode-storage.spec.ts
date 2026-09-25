import { readFileSync } from 'fs';
import { join } from 'path';
import { encodeAbiParameters, keccak256, toHex, type Hex } from 'viem';
import { describe, it, expect } from 'vitest';
import { decodeRawStorage, buildCandidateKeys, buildWordIndex } from '../utils/decodeStorage';
import type { StorageLayout } from '../utils/storageLayoutTypes';
import { resolveContractKind } from '../utils/resolveContractKind';
import { parseSnapshotLogs } from '../sections/logs';
import type { AaveV3Snapshot } from '../snapshot-types';

function loadReport(name: string): AaveV3Snapshot {
  return JSON.parse(readFileSync(join(__dirname, '..', '..', '..', 'reports', name), 'utf-8'));
}

// All tests are pure (no RPC): parseSnapshotLogs decodes against the bundled
// eventDb and decodeRawStorage preimages mapping slots from snapshot data.

describe('decodeRawStorage', () => {
  describe('PayloadsController (default report)', () => {
    const after = loadReport('default_after.json');
    const decoded = decodeRawStorage(after.raw, after, parseSnapshotLogs(after.logs!));
    const controller = decoded['0xdabad81af85554e9ae636395611c58f7ec1aaec5'];

    it('decodes the payload state transition, resolving the mapping key from event args', () => {
      const stateSlot =
        controller['0xeca4505ea32ae1a4ee824c5255e38a00422c023b789b59b6ce92c6731bc69891'];
      expect(stateSlot.fields).toEqual([
        {
          label: '_payloads[414].state',
          type: 'enum IPayloadsControllerCore.PayloadState',
          previousValue: '2 (Queued)',
          newValue: '3 (Executed)',
        },
      ]);
    });

    it('decodes the packed executedAt timestamp in the following struct word', () => {
      const executedAtSlot =
        controller['0xeca4505ea32ae1a4ee824c5255e38a00422c023b789b59b6ce92c6731bc69892'];
      expect(executedAtSlot.fields).toEqual([
        {
          label: '_payloads[414].executedAt',
          type: 'uint40',
          previousValue: '0',
          newValue: '1773490691',
        },
      ]);
    });
  });

  describe('megaeth report', () => {
    const after = loadReport('megaeth_after.json');
    const decoded = decodeRawStorage(after.raw, after, parseSnapshotLogs(after.logs!));

    const ezEthAToken = decoded['0x03c99cce547b1c2e74442b73e6f588a66d19597e'];
    const slot = (n: bigint) => toHex(n, { size: 32 });

    it('decodes short-string name and symbol slots', () => {
      expect(ezEthAToken[slot(0x37n)].fields[0]).toMatchObject({
        label: '_name',
        type: 'string',
        previousValue: '""',
        newValue: '"Aave MegaEth ezETH"',
      });
      expect(ezEthAToken[slot(0x38n)].fields[0]).toMatchObject({
        label: '_symbol',
        newValue: '"aMegezETH"',
      });
    });

    it('decodes the ERC-1967 implementation slot with an address-book annotation', () => {
      const impl =
        ezEthAToken['0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc'];
      expect(impl.fields[0].label).toBe('implementation (ERC-1967)');
      expect(impl.fields[0].newValue).toBe(
        '0x34CA0A24E0b7cbCEB77088AE539f57BA0650fC05 (AaveV3MegaEth.DEFAULT_A_TOKEN_IMPL)'
      );
    });

    it('emits one field per changed packed struct member', () => {
      const userState =
        ezEthAToken['0x00178004c8b5e6a4bdf613a65a4d1115faeef8496f92c9b852322c440ecd85b1'];
      expect(userState.fields.map((f) => f.label)).toEqual([
        '_userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643 (AaveV3MegaEth.DUST_BIN)].balance',
        '_userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643 (AaveV3MegaEth.DUST_BIN)].additionalData',
      ]);
      expect(userState.fields[0]).toMatchObject({ type: 'uint120', newValue: '2500000000000000' });
    });

    it('decodes long string content words, including content ending in a zero nibble', () => {
      // "Aave MegaEth Variable Debt USDT0" is exactly 32 bytes and ends in '0' (0x30):
      // a per-nibble trim would shift the whole string by 4 bits
      const usdt0VToken = decoded['0xb951225133b5eed3d88645e4bb1360136ff70d9a'];
      const nameData =
        usdt0VToken['0xbbe3212124853f8b0084a66a2d057c2966e251e132af3691db153ab65f0d1a4d'];
      expect(nameData.fields[0]).toMatchObject({
        label: '_name (data)',
        newValue: '"Aave MegaEth Variable Debt USDT0"',
      });
      // the length word itself reports the long-form summary
      expect(usdt0VToken[slot(0x3bn)].fields[0].newValue).toBe('(long string, length 32)');
    });

    it('decodes pool reserve configuration and reserve list entries', () => {
      const pool = decoded['0x7e324abc5de01d112afc03a584966ff199741c28'];
      const allFields = Object.values(pool).flatMap((s) => s.fields.map((f) => f.label));
      expect(allFields).toContain(
        '_reserves[0x601aC63637933D88285A025C685AC4e9a92a98dA (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING)].configuration.decimals'
      );
      expect(allFields).toContain(
        '_reserves[0x601aC63637933D88285A025C685AC4e9a92a98dA (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING)].liquidityIndex'
      );
      expect(allFields).toContain('_reservesList[6]');
      expect(allFields).toContain('_reservesCount');
    });

    it('leaves contracts without a known layout undecoded', () => {
      // plain ERC20 underlying: no layout kind resolvable
      expect(decoded['0x09601a65e7de7bc8a19813d263dd9e98bfdc3c57']).toBeUndefined();
    });

    it('skips slots whose bits did not change', () => {
      // slot 1 (initializing flags) is touched but written back unchanged
      expect(ezEthAToken[slot(0x1n)]).toBeUndefined();
    });
  });

  describe('buildWordIndex', () => {
    it('indexes dynamic array element slots at keccak(base) + i', () => {
      const layout: StorageLayout = {
        storage: [
          {
            astId: 1,
            contract: 'T.sol:T',
            label: '_list',
            offset: 0,
            slot: '7',
            type: 't_array(t_address)dyn_storage',
          },
        ],
        types: {
          't_array(t_address)dyn_storage': {
            encoding: 'dynamic_array',
            label: 'address[]',
            numberOfBytes: '32',
            base: 't_address',
          },
          t_address: { encoding: 'inplace', label: 'address', numberOfBytes: '20' },
        },
      };
      const index = buildWordIndex(layout, {
        addresses: new Set(),
        uints: new Set(),
        bytes32: new Set(),
      });
      const elementsBase = BigInt(keccak256(toHex(7n, { size: 32 })));
      expect(index.get(7n)![0].label).toBe('_list.length');
      expect(index.get(elementsBase)![0].label).toBe('_list[0]');
      expect(index.get(elementsBase + 5n)![0].label).toBe('_list[5]');
    });
  });

  describe('index budget', () => {
    it('caps nested mapping expansion and keeps static slots indexed', () => {
      // address => address => uint mapping: expansion is quadratic in candidates
      const layout: StorageLayout = {
        storage: [
          {
            astId: 1,
            contract: 'T.sol:T',
            label: '_totalSupply',
            offset: 0,
            slot: '0',
            type: 't_uint256',
          },
          {
            astId: 2,
            contract: 'T.sol:T',
            label: '_allowances',
            offset: 0,
            slot: '1',
            type: 't_mapping(t_address,t_mapping(t_address,t_uint256))',
          },
        ],
        types: {
          t_uint256: { encoding: 'inplace', label: 'uint256', numberOfBytes: '32' },
          t_address: { encoding: 'inplace', label: 'address', numberOfBytes: '20' },
          't_mapping(t_address,t_uint256)': {
            encoding: 'mapping',
            label: 'mapping(address => uint256)',
            numberOfBytes: '32',
            key: 't_address',
            value: 't_uint256',
          },
          't_mapping(t_address,t_mapping(t_address,t_uint256))': {
            encoding: 'mapping',
            label: 'mapping(address => mapping(address => uint256))',
            numberOfBytes: '32',
            key: 't_address',
            value: 't_mapping(t_address,t_uint256)',
          },
        },
      };
      const addresses = new Set<string>();
      for (let i = 1; i <= 400; i++) addresses.add(toHex(BigInt(i), { size: 20 }));
      const index = buildWordIndex(layout, { addresses, uints: new Set(), bytes32: new Set() });
      const totalFields = [...index.values()].reduce((sum, fields) => sum + fields.length, 0);
      // 400^2 = 160k pairs would exceed the 100k budget
      expect(totalFields).toBeLessThanOrEqual(100_000);
      // mappings expand last, so the static variable survives budget exhaustion
      expect(index.get(0n)![0].label).toBe('_totalSupply');

      // with target slots, mapping expansion stops once every target is matched:
      // a target resolved by the static pass means no keccak preimaging at all
      const lazyIndex = buildWordIndex(
        layout,
        { addresses, uints: new Set(), bytes32: new Set() },
        undefined,
        new Set([0n])
      );
      const lazyFields = [...lazyIndex.values()].reduce((sum, fields) => sum + fields.length, 0);
      expect(lazyIndex.get(0n)![0].label).toBe('_totalSupply');
      expect(lazyFields).toBe(1);
    });
  });

  describe('buildCandidateKeys', () => {
    it('collects keys from snapshot, raw accounts, and parsed event args', () => {
      const after = loadReport('default_after.json');
      const candidates = buildCandidateKeys(after, after.raw!, parseSnapshotLogs(after.logs!));
      // payload id 414 only appears in event args - the critical mapping key
      expect(candidates.uints.has(414n)).toBe(true);
      // raw diff account
      expect(candidates.addresses.has('0xdabad81af85554e9ae636395611c58f7ec1aaec5')).toBe(true);
    });
  });
});

describe('risk stewards', () => {
  // `vm.getStateDiffJson()` of executing pending payload 471 (V4 risk stewards activation)
  // on a mainnet fork taken 2026-09-25, before it was executed on chain
  const fixture = JSON.parse(
    readFileSync(join(__dirname, 'fixtures', 'mainnet-payload-471.json'), 'utf-8')
  );
  const steward = '0x6f48d9cdb8ee6e17c96b2d8aec128af426a295c1';

  it('decodes every changed slot of payload 471 with only a chainId snapshot', () => {
    const decoded = decodeRawStorage(fixture.raw, { chainId: 1 }, parseSnapshotLogs(fixture.logs));
    for (const [account, entry] of Object.entries<any>(fixture.raw)) {
      expect(Object.keys(decoded[account] ?? {}).sort()).toEqual(
        Object.keys(entry.stateDiff).sort()
      );
    }
  });

  it('decodes the V4 steward config into packed debounce fields', () => {
    const decoded = decodeRawStorage(fixture.raw, { chainId: 1 }, parseSnapshotLogs(fixture.logs));
    const fields = Object.values(decoded[steward]).flatMap((slot) => slot.fields);
    expect(fields).toContainEqual({
      label: '_config.hub.cap.addCap.isChangeRelative',
      type: 'bool',
      previousValue: 'false',
      newValue: 'true',
    });
    expect(fields).toContainEqual({
      label: '_config.oracle.priceCapStable.maxPercentChange',
      type: 'uint208',
      previousValue: '0',
      newValue: '50',
    });
    expect(fields.find((f) => f.label === '_config.hub.configurator')).toEqual({
      label: '_config.hub.configurator',
      type: 'contract IHubConfigurator',
      // zero address must not pick up the address book's 0x0 placeholder entries
      previousValue: '0x0000000000000000000000000000000000000000',
      newValue: '0x1F0753480bB03EaA00863224602267B7E0525C3d (AaveV4Ethereum.HUB_CONFIGURATOR)',
    });
  });

  it('resolves V3 stewards by deployment, not by address-book key', () => {
    const none = new Map<string, string>();
    // AaveV3Ethereum.RISK_STEWARD runs the current layout
    expect(resolveContractKind('0x13a9CC64344b02bACC5AD9Cf38B5711F1B9ec3d4', 1, none)).toBe(
      'V3RiskSteward'
    );
    // AaveV3Metis.RISK_STEWARD is still on the debtCeiling generation
    expect(resolveContractKind('0x97CB9e81d480A2AB03299760654C1DDC0C16bE07', 1088, none)).toBe(
      'V3RiskStewardDebtCeiling'
    );
    // AaveV3Avalanche.EDGE_RISK_STEWARD_CAPS is the oldest, flat-config generation
    expect(resolveContractKind('0x57218F3aB422A39115951c3Eb06881a7A719DfdD', 43114, none)).toBe(
      'V3RiskStewardFlatConfig'
    );
    // same Edge address on two chains, pinned per chain
    expect(resolveContractKind('0x655252250f4A453854040A49E8280951A76f3033', 100, none)).toBe(
      'V3RiskStewardDebtCeiling'
    );
    // AaveV3Scroll.RISK_STEWARD has no verifiable source: stays undecoded
    expect(
      resolveContractKind('0xc524A770ae73e57F0295aA48fd7605927a628B3b', 534352, none)
    ).toBeUndefined();
  });

  it('resolves V4 hubs/spokes by address-book group, excluding treasury spokes and oracles', () => {
    const none = new Map<string, string>();
    // AaveV4Base.HUBS.EQUITIES_HUB
    expect(resolveContractKind('0xa4d5947Eb727A052bae69C593FfC84247EC9864E', 8453, none)).toBe(
      'HubInstance'
    );
    // AaveV4Ethereum.SPOKES.MAIN_SPOKE
    expect(resolveContractKind('0x94e7A5dCbE816e498b89aB752661904E2F56c485', 1, none)).toBe(
      'SpokeInstance'
    );
    // AaveV4Ethereum.SPOKES.MAIN_SPOKE_ORACLE and .TREASURY_SPOKE are other contracts
    expect(
      resolveContractKind('0x99B2B6CEa9C3D2fd8F4d90f86741C44B212a6127', 1, none)
    ).toBeUndefined();
    expect(
      resolveContractKind('0xB9B0b8616f6Bf6841972a52058132BE08d723155', 1, none)
    ).toBeUndefined();
    // GovernanceV3InkWhitelabel.PERMISSIONED_PAYLOADS_CONTROLLER
    expect(resolveContractKind('0x1dE9CB9420Dd1f2cCeFFf9393E126b800D413b7A', 57073, none)).toBe(
      'PermissionedPayloadsController'
    );
  });

  it('narrows contract-typed keys so triple-nested mappings resolve within budget', () => {
    const layout: StorageLayout = {
      storage: [
        {
          astId: 1,
          contract: 'T.sol:T',
          label: '_debounces',
          offset: 0,
          slot: '5',
          type: 't_mapping(t_contract(IHub)1,t_mapping(t_contract(ISpoke)2,t_mapping(t_address,t_uint40)))',
        },
      ],
      types: {
        t_address: { encoding: 'inplace', label: 'address', numberOfBytes: '20' },
        t_uint40: { encoding: 'inplace', label: 'uint40', numberOfBytes: '5' },
        't_contract(IHub)1': { encoding: 'inplace', label: 'contract IHub', numberOfBytes: '20' },
        't_contract(ISpoke)2': {
          encoding: 'inplace',
          label: 'contract ISpoke',
          numberOfBytes: '20',
        },
        't_mapping(t_address,t_uint40)': {
          encoding: 'mapping',
          label: 'mapping(address => uint40)',
          numberOfBytes: '32',
          key: 't_address',
          value: 't_uint40',
        },
        't_mapping(t_contract(ISpoke)2,t_mapping(t_address,t_uint40))': {
          encoding: 'mapping',
          label: 'mapping(contract ISpoke => mapping(address => uint40))',
          numberOfBytes: '32',
          key: 't_contract(ISpoke)2',
          value: 't_mapping(t_address,t_uint40)',
        },
        't_mapping(t_contract(IHub)1,t_mapping(t_contract(ISpoke)2,t_mapping(t_address,t_uint40)))':
          {
            encoding: 'mapping',
            label:
              'mapping(contract IHub => mapping(contract ISpoke => mapping(address => uint40)))',
            numberOfBytes: '32',
            key: 't_contract(IHub)1',
            value: 't_mapping(t_contract(ISpoke)2,t_mapping(t_address,t_uint40))',
          },
      },
    };
    const addresses = new Set<string>();
    for (let i = 1; i <= 400; i++) addresses.add(toHex(BigInt(i), { size: 20 }));
    const [hub, spoke, asset] = [
      toHex(7n, { size: 20 }),
      toHex(9n, { size: 20 }),
      toHex(400n, { size: 20 }),
    ];
    const slotOf = (base: bigint, key: string) =>
      BigInt(
        keccak256(
          encodeAbiParameters([{ type: 'address' }, { type: 'uint256' }], [key as Hex, base])
        )
      );
    const target = slotOf(slotOf(slotOf(5n, hub), spoke), asset);
    const index = buildWordIndex(
      layout,
      {
        addresses,
        uints: new Set(),
        bytes32: new Set(),
        addressesByKind: new Map([
          ['HubInstance', new Set([hub])],
          ['SpokeInstance', new Set([spoke])],
        ]),
      },
      undefined,
      new Set([target])
    );
    // 400^3 untyped combinations would blow the 100k budget long before this key
    expect(index.get(target)?.[0].label).toBe(`_debounces[${hub}][${spoke}][${asset}]`);
  });
});
