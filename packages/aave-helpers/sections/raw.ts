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
      md += `**Balance diff**: ${entry.balanceDiff}\n\n`;
    }
    if (entry.nonceDiff) {
      md += `**Nonce diff**: ${entry.nonceDiff}\n\n`;
    }

    const slots = Object.keys(entry.stateDiff);
    if (slots.length) {
      md += '| slot | previous value | new value |\n| --- | --- | --- |\n';
      for (const slot of slots) {
        const slotDiff = entry.stateDiff[slot];
        const slotLabel = slotDiff.label ? ` (${slotDiff.label})` : '';
        md += `| ${slot}${slotLabel} | ${slotDiff.previousValue} | ${slotDiff.newValue} |\n`;
      }
      md += '\n';
    }
  }

  md += '\n';
  return md;
}
