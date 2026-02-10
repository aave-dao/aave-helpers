import { isChange, type DiffResult, type Change } from '../diff';
import { formatValue, type FormatterContext } from '../formatters';
import type { AaveV3Strategy, CHAIN_ID } from '../snapshot-types';

const IR_CHART_BASE = 'https://dash.onaave.com/api/static';

const IR_CHART_PARAMS: (keyof AaveV3Strategy)[] = [
  'variableRateSlope1',
  'variableRateSlope2',
  'optimalUsageRatio',
  'baseVariableBorrowRate',
  'maxVariableBorrowRate',
];

function irChartUrl(strategy: Partial<AaveV3Strategy>): string {
  const params = IR_CHART_PARAMS.map((k) => `${k}=${strategy[k] ?? '0'}`).join('&');
  return `${IR_CHART_BASE}?${params}`;
}

export function renderIrImage(strategy: Partial<AaveV3Strategy>): string {
  return `| interestRate | ![ir](${irChartUrl(strategy)}) |\n`;
}

export function renderIrDiffImages(
  from: Partial<AaveV3Strategy>,
  to: Partial<AaveV3Strategy>
): string {
  return `| interestRate | ![before](${irChartUrl(from)}) | ![after](${irChartUrl(to)}) |\n`;
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
