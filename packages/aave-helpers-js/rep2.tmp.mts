import { readFileSync } from 'fs';
import { decodeRawStorage } from './utils/decodeStorage';
import { parseSnapshotLogs } from './sections/logs';
const sb = JSON.parse(readFileSync('/tmp/sb_dump_43114.json', 'utf-8'), (_k, v) =>
  typeof v === 'string' && /^\d+n$/.test(v) ? BigInt(v.slice(0, -1)) : v
);
const fRaw = JSON.parse(readFileSync('/tmp/decode-demo/diffs/43114_125_raw.json', 'utf-8'));
const fLogs = parseSnapshotLogs(
  JSON.parse(readFileSync('/tmp/decode-demo/diffs/43114_125_logs.json', 'utf-8'))
);
const am = (r: any) =>
  Object.keys(r).find((k) => k.toLowerCase() === '0xe069096bdaff9bad15b2f1079eaf0f1685a24522')!;
for (const [name, raw, logs] of [
  ['seatbelt raw + seatbelt logs', sb.raw, sb.parsedLogs],
  ['seatbelt raw + forge logs', sb.raw, fLogs],
  ['forge raw + seatbelt logs', fRaw, sb.parsedLogs],
  ['forge raw + forge logs', fRaw, fLogs],
] as const) {
  const d = decodeRawStorage(raw, { chainId: 43114 }, logs as any);
  console.log(
    name.padEnd(30),
    Object.keys(d[am(raw)] ?? {}).length,
    '/',
    Object.keys(raw[am(raw)].stateDiff).length
  );
}
const s = Object.keys(sb.raw[am(sb.raw)].stateDiff).sort(),
  f = Object.keys(fRaw[am(fRaw)].stateDiff).sort();
console.log('same AM slot keys:', JSON.stringify(s) === JSON.stringify(f));
console.log('sb accounts', Object.keys(sb.raw).length, 'forge accounts', Object.keys(fRaw).length);
