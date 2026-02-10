import { isChange } from '../diff';
import { formatValue, type FormatterContext } from '../formatters';
import type { AaveV3Strategy, CHAIN_ID } from '../snapshot-types';

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
  diffObj: Record<string, any>,
  chainId: CHAIN_ID
): string {
  const from = {} as Record<string, any>;
  const to = {} as Record<string, any>;
  for (const key of Object.keys(diffObj)) {
    if (isChange(diffObj[key])) {
      from[key] = diffObj[key].from;
      to[key] = diffObj[key].to;
    } else {
      from[key] = diffObj[key];
      to[key] = diffObj[key];
    }
  }

  const ctxFrom: FormatterContext = { chainId, strategy: from as AaveV3Strategy };
  const ctxTo: FormatterContext = { chainId, strategy: to as AaveV3Strategy };

  let md = '';
  const changedKeys = sortKeys(
    Object.keys(diffObj)
      .filter((k) => !OMIT_KEYS.includes(k as keyof AaveV3Strategy))
      .filter((key) => isChange(diffObj[key]))
  );
  for (const key of changedKeys) {
    md += `| ${key} | ${formatValue('strategy', key, diffObj[key].from, ctxFrom)} | ${formatValue('strategy', key, diffObj[key].to, ctxTo)} |\n`;
  }
  return md;
}
