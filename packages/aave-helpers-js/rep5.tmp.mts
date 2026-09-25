import { readFileSync } from 'fs';
import { getSolidityStorageSlotUint, getSolidityStorageSlotAddress } from '@aave-dao/toolbox';
const expected = BigInt(
  getSolidityStorageSlotAddress(
    BigInt(getSolidityStorageSlotUint(1n, 400n)),
    '0xd8d7AbC42c1c938BdEC94fF8da1b3cd5b7e3b107'
  )
);
const sb = JSON.parse(readFileSync('/tmp/sb_dump_43114.json', 'utf-8'));
const keys = Object.keys(sb.raw['0xe069096bDAfF9bAD15b2f1079EaF0f1685a24522'].stateDiff);
const got = BigInt(keys.find((k) => k.startsWith('0x2e83'))!);
console.log('expected', expected.toString(16));
console.log('tenderly', got.toString(16));
console.log(
  'expected - tenderly =',
  (expected - got).toString(16),
  '= 2^' + Math.log2(Number(expected - got))
);
console.log(
  'raw tenderly key string:',
  keys.find((k) => k.startsWith('0x2e83')),
  'len',
  keys[0].length
);
