import { formatUnits } from 'viem';
import { isChange, type DiffResult, type Change } from '../diff';
import { formatValue, type FormatterContext } from '../formatters';
import type { AaveV3Strategy, CHAIN_ID } from '../snapshot-types';

const RAY = 10n ** 27n;
const NUM_POINTS = 21; // 0%, 5%, 10%, ..., 100%

function computeIrCurve(strategy: Partial<AaveV3Strategy>): number[] {
  const baseRate = BigInt(strategy.baseVariableBorrowRate ?? '0');
  const slope1 = BigInt(strategy.variableRateSlope1 ?? '0');
  const slope2 = BigInt(strategy.variableRateSlope2 ?? '0');
  const optimal = BigInt(strategy.optimalUsageRatio ?? '0');
  const excess = RAY - optimal;

  const rates: number[] = [];
  for (let i = 0; i < NUM_POINTS; i++) {
    const utilization = (RAY * BigInt(i)) / BigInt(NUM_POINTS - 1);
    let rate: bigint;
    if (optimal === 0n) {
      rate = baseRate;
    } else if (utilization <= optimal) {
      rate = baseRate + (slope1 * utilization) / optimal;
    } else {
      rate = baseRate + slope1 + (excess > 0n ? (slope2 * (utilization - optimal)) / excess : 0n);
    }
    rates.push(Number(formatUnits(rate, 25)));
  }
  return rates;
}

function renderMermaidChart(lines: { name: string; data: number[] }[]): string {
  const xLabels = Array.from({ length: NUM_POINTS }, (_, i) =>
    ((i * 100) / (NUM_POINTS - 1)).toString()
  );
  const parts = [
    'xychart-beta',
    'title "Interest Rate Model"',
    `x-axis "Utilization (%)" [${xLabels.join(', ')}]`,
    'y-axis "Rate (%)"',
    ...lines.map((line) => `line [${line.data.join(', ')}]`),
  ];
  return `<pre lang="mermaid">${parts.join('&#13;')}&#13;</pre>`;
}

export function renderIrChart(strategy: Partial<AaveV3Strategy>): string {
  const rates = computeIrCurve(strategy);
  const chart = renderMermaidChart([{ name: 'rate', data: rates }]);
  return `| interestRate | ${chart} |\n`;
}

export function renderIrDiffCharts(
  from: Partial<AaveV3Strategy>,
  to: Partial<AaveV3Strategy>
): string {
  const ratesFrom = computeIrCurve(from);
  const ratesTo = computeIrCurve(to);
  const chartFrom = renderMermaidChart([{ name: 'before', data: ratesFrom }]);
  const chartTo = renderMermaidChart([{ name: 'after', data: ratesTo }]);
  return `| interestRate | ${chartFrom} | ${chartTo} |\n`;
}

const STRATEGY_KEY_ORDER: (keyof AaveV3Strategy)[] = [
  'optimalUsageRatio',
  'maxVariableBorrowRate',
  'baseVariableBorrowRate',
  'variableRateSlope1',
  'variableRateSlope2',
];

const OMIT_KEYS: (keyof AaveV3Strategy)[] = ['address'];

function sortKeys(keys: string[]): string[] {
  return [...keys].sort((a, b) => {
    const iA = STRATEGY_KEY_ORDER.indexOf(a as keyof AaveV3Strategy);
    const iB = STRATEGY_KEY_ORDER.indexOf(b as keyof AaveV3Strategy);
    if (iA === -1 && iB === -1) return a.localeCompare(b);
    if (iA === -1) return 1;
    if (iB === -1) return -1;
    return iA - iB;
  });
}

export function renderStrategy(strategy: AaveV3Strategy, chainId: CHAIN_ID): string {
  const ctx: FormatterContext = { chainId, strategy };
  let md = '';
  const keys = sortKeys(
    Object.keys(strategy).filter((k) => !OMIT_KEYS.includes(k as keyof AaveV3Strategy))
  );
  for (const key of keys) {
    md += `| ${key} | ${formatValue('strategy', key, (strategy as any)[key], ctx)} |\n`;
  }
  return md;
}

export function renderStrategyDiff(
  strategyDiff: DiffResult<AaveV3Strategy>,
  chainId: CHAIN_ID
): string {
  const from: Record<string, unknown> = {};
  const to: Record<string, unknown> = {};
  for (const key of Object.keys(strategyDiff)) {
    const val = strategyDiff[key as keyof AaveV3Strategy];
    if (isChange(val)) {
      from[key] = val.from;
      to[key] = val.to;
    } else {
      from[key] = val;
      to[key] = val;
    }
  }

  const ctxFrom: FormatterContext = { chainId, strategy: from as AaveV3Strategy };
  const ctxTo: FormatterContext = { chainId, strategy: to as AaveV3Strategy };

  let md = '';
  const changedKeys = sortKeys(
    Object.keys(strategyDiff)
      .filter((k) => !OMIT_KEYS.includes(k as keyof AaveV3Strategy))
      .filter((key) => isChange(strategyDiff[key as keyof AaveV3Strategy]))
  );
  for (const key of changedKeys) {
    const change = strategyDiff[key as keyof AaveV3Strategy] as Change<unknown>;
    md += `| ${key} | ${formatValue('strategy', key, change.from, ctxFrom)} | ${formatValue('strategy', key, change.to, ctxTo)} |\n`;
  }
  return md;
}
