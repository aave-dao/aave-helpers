import { readFileSync } from 'fs';
import { buildCandidateKeys, buildWordIndex } from './utils/decodeStorage';
import { storageLayoutDb } from './utils/storageLayoutDb';
const sb = JSON.parse(readFileSync('/tmp/sb_dump_43114.json', 'utf-8'), (_k, v) =>
  typeof v === 'string' && /^\d+n$/.test(v) ? BigInt(v.slice(0, -1)) : v
);
const am = '0xe069096bDAfF9bAD15b2f1079EaF0f1685a24522';
const slots = Object.keys(sb.raw[am].stateDiff).map(BigInt);
const c = buildCandidateKeys({ chainId: 43114 }, sb.raw, sb.parsedLogs);
const layout = storageLayoutDb.AccessManagerEnumerable.layout;
const eager = buildWordIndex(layout, c);
const lazy = buildWordIndex(layout, c, undefined, new Set(slots));
for (const s of slots)
  console.log(
    s.toString(16).slice(0, 8),
    'eager:',
    eager.get(s)?.[0]?.label ?? '-',
    '| lazy:',
    lazy.get(s)?.[0]?.label ?? '-'
  );
