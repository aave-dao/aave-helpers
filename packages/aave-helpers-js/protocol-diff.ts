import { diff, type DiffResult } from './diff';
import type { AaveV3Snapshot, RawStorage, Log } from './snapshot-types';
import { renderReservesSection } from './sections/reserves';
import { renderEmodesSection } from './sections/emodes';
import { renderPoolConfigSection } from './sections/pool-config';
import { renderRawSection } from './sections/raw';
import { renderLogsSection } from './sections/logs';

/**
 * Diff two Aave V3 protocol snapshots and produce a formatted markdown report.
 *
 * The `raw` and `logs` sections only exist in the "after" snapshot and are
 * rendered as-is (they already represent the diff / changes).
 */
export async function diffSnapshots(
  before: AaveV3Snapshot,
  after: AaveV3Snapshot
): Promise<string> {
  // Extract raw & logs from "after" - they don't participate in the structural diff
  let raw: RawStorage | undefined;
  let logs: Log[] | undefined;

  const postCopy: AaveV3Snapshot = { ...after };
  if (postCopy.raw) {
    raw = postCopy.raw;
    delete postCopy.raw;
  }
  if (postCopy.logs) {
    logs = [...postCopy.logs];
    delete postCopy.logs;
  }

  // Run the structural diff on the remaining data
  const diffResult: DiffResult<AaveV3Snapshot> = diff(before, postCopy);

  // Assemble the markdown report
  let md = '';

  md += renderReservesSection(diffResult, before, after);
  md += renderEmodesSection(diffResult, before, after);
  md += renderPoolConfigSection(diffResult, after.chainId);
  md += await renderLogsSection(logs, after.chainId);
  md += renderRawSection(raw, after.chainId);

  // Append raw JSON diff as fallback (without raw/logs which have their own sections)
  const diffWithoutUnchanged = diff(before, postCopy, true);
  md += `## Raw diff\n\n\`\`\`json\n${JSON.stringify(diffWithoutUnchanged, null, 2)}\n\`\`\`\n`;

  return md;
}
