import type { RawStorage, CHAIN_ID } from '../snapshot-types';
import { isKnownAddress } from '../utils/address';

export function renderRawSection(raw: RawStorage | undefined, chainId: CHAIN_ID): string {
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
      // Check if any slot has decoded info
      const hasDecoded = slots.some((s) => {
        const d = entry.stateDiff[s];
        return (
          d.label && d.decoded && (d.decoded.previousValue !== '0x' || d.decoded.newValue !== '0x')
        );
      });

      if (hasDecoded) {
        md +=
          '| label | type | decoded previous value | decoded new value |\n| --- | --- | --- | --- |\n';
        for (const slot of slots) {
          const slotDiff = entry.stateDiff[slot];
          const label = slotDiff.label || slot;
          const type = slotDiff.type || '-';
          const useDecoded =
            slotDiff.decoded &&
            (slotDiff.decoded.previousValue !== '0x' || slotDiff.decoded.newValue !== '0x');
          const prev = useDecoded ? slotDiff.decoded!.previousValue : slotDiff.previousValue;
          const next = useDecoded ? slotDiff.decoded!.newValue : slotDiff.newValue;
          md += `| ${label} | ${type} | ${prev} | ${next} |\n`;
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
