import { diff } from './diff';
import type { AaveV4Snapshot } from './snapshot-types-v4';
import type { RawStorage, Log } from './snapshot-types';
import { renderSpokeReservesSection } from './sections/spoke-reserves';
import { renderHubAssetsSection } from './sections/hub-assets';
import { renderSpokeConfigsSection } from './sections/spoke-configs';
import { renderSpokeLiquidationSection } from './sections/spoke-liquidation';
import { renderPositionManagersSection } from './sections/position-managers';
import { renderAccessManagerRolesSection } from './sections/access-manager-roles';
import { renderRawSection } from './sections/raw';
import { renderLogsSection, parseSnapshotLogs } from './sections/logs';
import { decodeRawStorage } from './utils/decodeStorage';

/**
 * Diff two Aave V4 protocol snapshots and produce a formatted markdown report.
 *
 * The `raw` and `logs` sections only exist in the "after" snapshot and are
 * rendered as-is (they already represent the diff / changes).
 */
export async function diffV4Snapshots(
  before: AaveV4Snapshot,
  after: AaveV4Snapshot
): Promise<string> {
  // Extract raw & logs from "after" — they don't participate in the structural diff
  let raw: RawStorage | undefined;
  let logs: Log[] | undefined;

  const postCopy: AaveV4Snapshot = { ...after };
  if (postCopy.raw) {
    raw = postCopy.raw;
    delete postCopy.raw;
  }
  if (postCopy.logs) {
    logs = [...postCopy.logs];
    delete postCopy.logs;
  }

  // Build the markdown report from each section
  let md = '';

  md += renderSpokeReservesSection(before, postCopy);
  md += renderHubAssetsSection(before, postCopy);
  md += renderSpokeConfigsSection(before, postCopy);
  md += renderSpokeLiquidationSection(before, postCopy);
  md += renderPositionManagersSection(before, postCopy);
  md += renderAccessManagerRolesSection(before, postCopy);
  // Parse logs once (pure); decoded args also feed mapping-key candidates for
  // storage decoding. Must run before renderLogsSection, which mutates args.
  const parsedLogs = logs ? parseSnapshotLogs(logs) : undefined;
  const decodedStorage = decodeRawStorage(raw, after, parsedLogs);
  md += await renderLogsSection(logs, after.chainId, parsedLogs);
  md += renderRawSection(raw, after.chainId, decodedStorage);

  // Append raw JSON diff as fallback
  const preCopy: Record<string, unknown> = { ...before };
  delete preCopy.raw;
  delete preCopy.logs;
  const diffWithoutUnchanged = diff(preCopy as any, postCopy as any, true);
  md += `## Raw diff\n\n\`\`\`json\n${JSON.stringify(diffWithoutUnchanged, null, 2)}\n\`\`\`\n`;

  if (!md.trim() || md.trim() === '## Raw diff\n\n```json\n{}\n```') {
    return 'No configuration changes detected.\n';
  }

  return md;
}
