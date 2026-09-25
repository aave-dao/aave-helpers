import { readFileSync } from 'fs';
import { decodeRawStorage, buildCandidateKeys } from './utils/decodeStorage';
const d = JSON.parse(readFileSync('/tmp/sb_dump_43114.json', 'utf-8'), (_k, v) =>
  typeof v === 'string' && /^\d+n$/.test(v) ? BigInt(v.slice(0, -1)) : v
);
const am = '0xe069096bDAfF9bAD15b2f1079EaF0f1685a24522';
const decoded = decodeRawStorage(d.raw, { chainId: 43114 }, d.parsedLogs);
const n = Object.keys(d.raw[am].stateDiff).length;
console.log('AM decoded', Object.keys(decoded[am] ?? {}).length, '/', n);
const c = buildCandidateKeys({ chainId: 43114 }, d.raw, d.parsedLogs);
console.log(
  'candidates: addresses',
  c.addresses.size,
  'uints',
  c.uints.size,
  'bytes32',
  c.bytes32.size
);
