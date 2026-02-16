import { type Hex, formatUnits } from 'viem';
import { getClient } from '@bgd-labs/toolbox';
import { prettifyNumber, toAddressLink, boolToMarkdown } from './utils/markdown';
import { bitmapToIndexes } from '@bgd-labs/toolbox';
import type {
  AaveV3Reserve,
  AaveV3Strategy,
  AaveV3Emode,
  AaveV3Snapshot,
  CHAIN_ID,
} from './snapshot-types';

// --- Formatter context passed to every formatter ---

export interface FormatterContext {
  chainId: CHAIN_ID;
  reserve?: AaveV3Reserve;
  strategy?: AaveV3Strategy;
  emode?: AaveV3Emode;
  snapshot?: AaveV3Snapshot;
}

export type FieldFormatter<T = unknown> = (value: T, ctx: FormatterContext) => string;

// --- Helper to get a viem client for address links ---

function getExplorerClient(chainId: CHAIN_ID) {
  return getClient(chainId, {});
}

function addressLink(value: string, chainId: CHAIN_ID): string {
  return toAddressLink(value as Hex, true, getExplorerClient(chainId));
}

function isAddress(value: any): boolean {
  return typeof value === 'string' && /^0x[0-9a-fA-F]{40}$/.test(value);
}

// --- Reserve formatters ---

type ReserveKey = keyof AaveV3Reserve;

const RESERVE_PERCENTAGE_FIELDS: readonly ReserveKey[] = [
  'ltv',
  'liquidationThreshold',
  'reserveFactor',
  'liquidationProtocolFee',
] as const;

const RESERVE_BALANCE_FIELDS: readonly ReserveKey[] = [
  'aTokenUnderlyingBalance',
  'virtualBalance',
] as const;

const RESERVE_ADDRESS_FIELDS: readonly ReserveKey[] = [
  'interestRateStrategy',
  'oracle',
  'aToken',
  'variableDebtToken',
  'underlying',
] as const;

const RESERVE_BOOL_FIELDS: readonly ReserveKey[] = [
  'isActive',
  'isFrozen',
  'isPaused',
  'isSiloed',
  'isFlashloanable',
  'isBorrowableInIsolation',
  'borrowingEnabled',
  'usageAsCollateralEnabled',
] as const;

export const reserveFormatters: Partial<{ [K in ReserveKey]: FieldFormatter<AaveV3Reserve[K]> }> =
  {};

for (const field of RESERVE_PERCENTAGE_FIELDS) {
  (reserveFormatters[field] as FieldFormatter<number>) = (value, ctx) =>
    prettifyNumber({ value, decimals: 2, suffix: '%' });
}

reserveFormatters['liquidationBonus'] = (value) =>
  value === 0 ? '0 %' : `${(value - 10000) / 100} % [${value}]`;

reserveFormatters['supplyCap'] = (value, ctx) =>
  `${value.toLocaleString('en-US')} ${ctx.reserve?.symbol ?? ''}`;

reserveFormatters['borrowCap'] = (value, ctx) =>
  `${value.toLocaleString('en-US')} ${ctx.reserve?.symbol ?? ''}`;

reserveFormatters['debtCeiling'] = (value) => prettifyNumber({ value, decimals: 2, suffix: '$' });

for (const field of RESERVE_BALANCE_FIELDS) {
  (reserveFormatters[field] as FieldFormatter<string>) = (value, ctx) =>
    prettifyNumber({
      value,
      decimals: ctx.reserve?.decimals ?? 18,
      suffix: ctx.reserve?.symbol ?? '',
    });
}

reserveFormatters['oracleLatestAnswer'] = (value, ctx) => {
  const decimals = ctx.reserve?.oracleDecimals ?? 8;
  return formatUnits(BigInt(value), decimals) + ' $';
};

for (const field of RESERVE_ADDRESS_FIELDS) {
  (reserveFormatters[field] as FieldFormatter<string>) = (value, ctx) =>
    addressLink(value, ctx.chainId);
}

for (const field of RESERVE_BOOL_FIELDS) {
  (reserveFormatters[field] as FieldFormatter<boolean>) = (value) => boolToMarkdown(value);
}

// --- Strategy formatters ---

type StrategyKey = keyof AaveV3Strategy;

const STRATEGY_RATE_FIELDS: readonly StrategyKey[] = [
  'baseVariableBorrowRate',
  'optimalUsageRatio',
  'variableRateSlope1',
  'variableRateSlope2',
  'maxVariableBorrowRate',
] as const;

export const strategyFormatters: Partial<{
  [K in StrategyKey]: FieldFormatter<AaveV3Strategy[K]>;
}> = {};

for (const field of STRATEGY_RATE_FIELDS) {
  (strategyFormatters[field] as FieldFormatter<string>) = (value) =>
    `${formatUnits(BigInt(value), 25)} %`;
}

strategyFormatters['address'] = (value, ctx) => addressLink(value, ctx.chainId);

// --- EMode formatters ---

type EmodeKey = keyof AaveV3Emode;

export const emodeFormatters: Partial<{ [K in EmodeKey]: FieldFormatter<AaveV3Emode[K]> }> = {};

emodeFormatters['ltv'] = (value) => `${formatUnits(BigInt(value), 2)} %`;
emodeFormatters['liquidationThreshold'] = (value) => `${formatUnits(BigInt(value), 2)} %`;
emodeFormatters['liquidationBonus'] = (value) =>
  value === 0 ? '0 %' : `${(value - 10000) / 100} % [${value}]`;

emodeFormatters['borrowableBitmap'] = (value, ctx) => {
  const indexes = bitmapToIndexes(BigInt(value));
  if (!ctx.snapshot) return indexes.join(', ');
  const reserveKeys = Object.keys(ctx.snapshot.reserves);
  return indexes
    .map((i) => {
      const key = reserveKeys.find((k) => ctx.snapshot!.reserves[k].id === i);
      return key ? ctx.snapshot!.reserves[key].symbol : `unknown(id:${i})`;
    })
    .join(', ');
};

emodeFormatters['collateralBitmap'] = emodeFormatters['borrowableBitmap'];

emodeFormatters['priceSource'] = (value, ctx) => addressLink(value!, ctx.chainId);

// --- Generic format function ---

type SectionKey = {
  reserve: ReserveKey;
  strategy: StrategyKey;
  emode: EmodeKey;
};

const formattersMap = {
  reserve: reserveFormatters,
  strategy: strategyFormatters,
  emode: emodeFormatters,
} as const;

export function formatValue<S extends keyof SectionKey>(
  section: S,
  key: string,
  value: unknown,
  ctx: FormatterContext
): string {
  const formatter = (formattersMap[section] as Record<string, FieldFormatter | undefined>)[key];
  if (formatter) return formatter(value, ctx);

  // Default formatting
  if (typeof value === 'boolean') return boolToMarkdown(value);
  if (typeof value === 'number') return value.toLocaleString('en-US');
  if (isAddress(value)) return addressLink(value as string, ctx.chainId);
  return String(value);
}
