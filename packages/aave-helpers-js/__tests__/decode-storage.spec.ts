import { readFileSync } from 'fs';
import { join } from 'path';
import { keccak256, toHex } from 'viem';
import { describe, it, expect } from 'vitest';
import { decodeRawStorage, buildCandidateKeys, buildWordIndex } from '../utils/decodeStorage';
import type { StorageLayout } from '../utils/storageLayoutTypes';
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
