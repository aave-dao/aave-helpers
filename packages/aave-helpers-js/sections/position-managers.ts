import type { Hex } from 'viem';
import { getClient } from '@aave-dao/toolbox';
import type { AaveV4Snapshot } from '../snapshot-types-v4';
import { toAddressLink, boolToMarkdown } from '../utils/markdown';

/**
 * Renders the per-spoke position-manager registration diff. Each row is a
 * (spoke, positionManager) pair whose `active` flag changed.
 */
export function renderPositionManagersSection(
  before: AaveV4Snapshot,
  after: AaveV4Snapshot
): string {
  const beforePm = before.positionManagers ?? {};
  const afterPm = after.positionManagers ?? {};
  const allSpokes = new Set<string>([...Object.keys(beforePm), ...Object.keys(afterPm)]);

  const client = getClient(after.chainId, {});
  const rows: string[] = [];

  for (const spokeAddr of allSpokes) {
    const beforeSpoke = beforePm[spokeAddr] ?? {};
    const afterSpoke = afterPm[spokeAddr] ?? {};
    const allManagers = new Set<string>([...Object.keys(beforeSpoke), ...Object.keys(afterSpoke)]);
    for (const manager of allManagers) {
      const bv = beforeSpoke[manager];
      const av = afterSpoke[manager];
      if (bv === av) continue;
      const spokeLink = toAddressLink(spokeAddr as Hex, true, client);
      const managerLink = toAddressLink(manager as Hex, true, client);
      const fromFmt = bv === undefined ? '*missing*' : boolToMarkdown(bv);
      const toFmt = av === undefined ? '*missing*' : boolToMarkdown(av);
      rows.push(`| ${spokeLink} | ${managerLink} | ${fromFmt} | ${toFmt} |`);
    }
  }

  if (rows.length === 0) return '';
  let md = '## Position Manager Changes\n\n';
  md += '| spoke | position manager | active before | active after |\n';
  md += '| --- | --- | --- | --- |\n';
  md += rows.join('\n') + '\n\n';
  return md;
}
