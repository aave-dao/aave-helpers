import { isChange, hasChanges, diff } from '../diff';
import { formatValue, type FormatterContext } from '../formatters';
import type { AaveV3Emode, AaveV3Snapshot, CHAIN_ID } from '../snapshot-types';

const EMODE_KEY_ORDER: (keyof AaveV3Emode)[] = [
  'eModeCategory',
  'label',
  'ltv',
  'liquidationThreshold',
  'liquidationBonus',
  'priceSource',
  'borrowableBitmap',
  'collateralBitmap',
];

const OMIT_KEYS: (keyof AaveV3Emode)[] = ['eModeCategory'];

function sortKeys(keys: string[]): string[] {
  return [...keys].sort((a, b) => {
    const iA = EMODE_KEY_ORDER.indexOf(a as keyof AaveV3Emode);
    const iB = EMODE_KEY_ORDER.indexOf(b as keyof AaveV3Emode);
    if (iA === -1 && iB === -1) return a.localeCompare(b);
    if (iA === -1) return 1;
    if (iB === -1) return -1;
    return iA - iB;
  });
}

function renderEmodeDiffTable(
  diffObj: Record<string, any>,
  pre: AaveV3Snapshot,
  post: AaveV3Snapshot
): string {
  const chainId = post.chainId;
  let md = '| description | value before | value after |\n| --- | --- | --- |\n';

  const keys = sortKeys(
    Object.keys(diffObj).filter((k) => !OMIT_KEYS.includes(k as keyof AaveV3Emode))
  );

  for (const key of keys) {
    if (isChange(diffObj[key])) {
      const ctxPre: FormatterContext = { chainId, emode: diffObj as AaveV3Emode, snapshot: pre };
      const ctxPost: FormatterContext = { chainId, emode: diffObj as AaveV3Emode, snapshot: post };
      const fromVal = diffObj[key].from != null
        ? formatValue('emode', key, diffObj[key].from, ctxPre)
        : '-';
      const toVal = diffObj[key].to != null
        ? formatValue('emode', key, diffObj[key].to, ctxPost)
        : '-';
      md += `| ${key} | ${fromVal} | ${toVal} |\n`;
    }
  }

  return md;
}

export function renderEmodesSection(
  diffResult: Record<string, any>,
  pre: AaveV3Snapshot,
  post: AaveV3Snapshot
): string {
  if (!diffResult.eModes) return '';

  const emodesDiff = diffResult.eModes;
  let md = '';

  for (const emodeId of Object.keys(emodesDiff)) {
    const emodeDiff = emodesDiff[emodeId];
    const postEmode = post.eModes[emodeId];
    const preEmode = pre.eModes[emodeId];

    // Only render if there are actual changes
    const emodeFullDiff = diff(preEmode || {}, postEmode || {});
    if (!hasChanges(emodeFullDiff)) continue;

    const label = postEmode?.label || preEmode?.label || 'Unknown';
    const category = postEmode?.eModeCategory ?? preEmode?.eModeCategory ?? emodeId;

    md += `### EMode: ${label} (id: ${category})\n\n`;
    md += renderEmodeDiffTable(emodeFullDiff, pre, post);
    md += '\n\n';
  }

  if (!md) return '';
  return '## EMode changes\n\n' + md;
}
