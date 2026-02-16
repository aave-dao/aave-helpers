import type { Hex } from 'viem';
import { getClient } from '@bgd-labs/toolbox';
import { isChange, hasChanges, diff, type DiffResult, type Change } from '../diff';
import { formatValue, type FormatterContext } from '../formatters';
import type { AaveV3Reserve, AaveV3Snapshot, CHAIN_ID } from '../snapshot-types';
import { toAddressLink } from '../utils/markdown';
import {
  renderStrategyDiff,
  renderStrategy,
  renderIrChart,
  renderIrDiffCharts,
} from './strategies';

// --- Field display order ---

const RESERVE_KEY_ORDER: (keyof AaveV3Reserve)[] = [
  'id',
  'symbol',
  'decimals',
  'isActive',
  'isFrozen',
  'isPaused',
  'supplyCap',
  'borrowCap',
  'debtCeiling',
  'isSiloed',
  'isFlashloanable',
  'oracle',
  'oracleDecimals',
  'oracleDescription',
  'oracleName',
  'oracleLatestAnswer',
  'usageAsCollateralEnabled',
  'ltv',
  'liquidationThreshold',
  'liquidationBonus',
  'liquidationProtocolFee',
  'reserveFactor',
  'aToken',
  'aTokenName',
  'aTokenSymbol',
  'variableDebtToken',
  'variableDebtTokenName',
  'variableDebtTokenSymbol',
  'borrowingEnabled',
  'isBorrowableInIsolation',
  'interestRateStrategy',
  'aTokenUnderlyingBalance',
  'virtualBalance',
];

const OMIT_IN_HEADER: (keyof AaveV3Reserve)[] = ['underlying', 'symbol'];

function sortKeys(keys: string[]): string[] {
  return [...keys].sort((a, b) => {
    const iA = RESERVE_KEY_ORDER.indexOf(a as keyof AaveV3Reserve);
    const iB = RESERVE_KEY_ORDER.indexOf(b as keyof AaveV3Reserve);
    if (iA === -1 && iB === -1) return a.localeCompare(b);
    if (iA === -1) return 1;
    if (iB === -1) return -1;
    return iA - iB;
  });
}

function reserveHeadline(reserve: AaveV3Reserve, chainId: CHAIN_ID): string {
  const client = getClient(chainId, {});
  const link = toAddressLink(reserve.underlying as Hex, true, client);
  return `#### ${reserve.symbol} (${link})\n\n`;
}

// --- Render a full reserve config table (for added/removed reserves) ---

function renderReserveTable(reserve: AaveV3Reserve, chainId: CHAIN_ID): string {
  const ctx: FormatterContext = { chainId, reserve };
  let md = reserveHeadline(reserve, chainId);
  md += '| description | value |\n| --- | --- |\n';
  const keys = sortKeys(
    Object.keys(reserve).filter((k) => !OMIT_IN_HEADER.includes(k as keyof AaveV3Reserve))
  );
  for (const key of keys) {
    const value = (reserve as any)[key];
    md += `| ${key} | ${formatValue('reserve', key, value, ctx)} |\n`;
  }
  return md;
}

// --- Render a reserve diff table (for altered reserves) ---

function renderReserveDiffTable(reserveDiff: DiffResult<AaveV3Reserve>, chainId: CHAIN_ID): string {
  // Reconstruct "before" and "after" reserves from the diff
  const from: Record<string, unknown> = {};
  const to: Record<string, unknown> = {};
  for (const key of Object.keys(reserveDiff)) {
    const val = reserveDiff[key as keyof AaveV3Reserve];
    if (isChange(val)) {
      from[key] = val.from;
      to[key] = val.to;
    } else {
      from[key] = val;
      to[key] = val;
    }
  }

  const ctxFrom: FormatterContext = { chainId, reserve: from as AaveV3Reserve };
  const ctxTo: FormatterContext = { chainId, reserve: to as AaveV3Reserve };

  let md = reserveHeadline(from as AaveV3Reserve, chainId);
  md += '| description | value before | value after |\n| --- | --- | --- |\n';

  const changedKeys = sortKeys(
    Object.keys(reserveDiff).filter((key) => isChange(reserveDiff[key as keyof AaveV3Reserve]))
  );
  for (const key of changedKeys) {
    const change = reserveDiff[key as keyof AaveV3Reserve] as Change<unknown>;
    const fromVal = formatValue('reserve', key, change.from, ctxFrom);
    const toVal = formatValue('reserve', key, change.to, ctxTo);
    md += `| ${key} | ${fromVal} | ${toVal} |\n`;
  }
  return md;
}

// --- Main reserves section renderer ---

export function renderReservesSection(
  diffResult: DiffResult<AaveV3Snapshot>,
  pre: AaveV3Snapshot,
  post: AaveV3Snapshot
): string {
  if (!diffResult.reserves) return '';

  const reservesDiff = diffResult.reserves as Record<
    string,
    DiffResult<AaveV3Reserve> | Change<AaveV3Reserve>
  >;
  const added: string[] = [];
  const removed: string[] = [];
  const altered: string[] = [];

  for (const key of Object.keys(reservesDiff)) {
    const entry = reservesDiff[key];

    // Added reserve: the whole entry is { from: null, to: {...} }
    if (isChange<AaveV3Reserve>(entry) && entry.from === null && entry.to !== null) {
      let report = renderReserveTable(entry.to, pre.chainId);
      if (post.strategies[key]) {
        report += renderStrategy(post.strategies[key], pre.chainId);
        report += renderIrChart(post.strategies[key]);
      }
      added.push(report);
      continue;
    }

    // Removed reserve: { from: {...}, to: null }
    if (isChange<AaveV3Reserve>(entry) && entry.from !== null && entry.to === null) {
      removed.push(renderReserveTable(entry.from, pre.chainId));
      continue;
    }

    // Altered reserve: nested diff object
    if (typeof entry === 'object' && !isChange(entry)) {
      const reserveDiff = entry as DiffResult<AaveV3Reserve>;
      const hasReserveChanges = hasChanges(reserveDiff as Record<string, unknown>);
      const preStrategy = pre.strategies[key];
      const postStrategy = post.strategies[key];
      const strategyChanged =
        preStrategy && postStrategy && JSON.stringify(preStrategy) !== JSON.stringify(postStrategy);

      if (!hasReserveChanges && !strategyChanged) continue;

      let report = '';
      if (hasReserveChanges) {
        report += renderReserveDiffTable(reserveDiff, pre.chainId);
      }
      if (strategyChanged) {
        const stratDiff = diff(preStrategy, postStrategy);
        report += renderStrategyDiff(stratDiff, pre.chainId);
        report += renderIrDiffCharts(preStrategy, postStrategy);
      }
      if (report) altered.push(report);
    }
  }

  if (!added.length && !removed.length && !altered.length) return '';

  let md = '## Reserve changes\n\n';

  if (added.length) {
    md += `### Reserves added\n\n`;
    md += added.join('\n\n');
    md += '\n\n';
  }

  if (altered.length) {
    md += `### Reserves altered\n\n`;
    md += altered.join('\n\n');
    md += '\n\n';
  }

  if (removed.length) {
    md += `### Reserves removed\n\n`;
    md += removed.join('\n\n');
    md += '\n\n';
  }

  return md;
}
