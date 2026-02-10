import { type Hex, formatUnits } from 'viem';
import { getClient } from '@bgd-labs/toolbox';
import { prettifyNumber, toAddressLink, boolToMarkdown } from './utils/markdown';
import { bitMapToIndexes } from './utils/storageSlots';
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

export type FieldFormatter = (value: any, ctx: FormatterContext) => string;

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

const RESERVE_PERCENTAGE_FIELDS = [
  'ltv',
  'liquidationThreshold',
  'reserveFactor',
  'liquidationProtocolFee',
];

const RESERVE_BALANCE_FIELDS = ['aTokenUnderlyingBalance', 'virtualBalance'];

const RESERVE_ADDRESS_FIELDS = [
  'interestRateStrategy',
  'oracle',
  'aToken',
  'variableDebtToken',
  'underlying',
];

const RESERVE_BOOL_FIELDS = [
  'isActive',
  'isFrozen',
  'isPaused',
  'isSiloed',
  'isFlashloanable',
  'isBorrowableInIsolation',
  'borrowingEnabled',
  'usageAsCollateralEnabled',
];

export const reserveFormatters: Record<string, FieldFormatter> = {};

for (const field of RESERVE_PERCENTAGE_FIELDS) {
  reserveFormatters[field] = (value, ctx) =>
    prettifyNumber({ value, decimals: 2, suffix: '%' });
}

reserveFormatters['liquidationBonus'] = (value) =>
  value === 0 ? '0 %' : `${((value as number) - 10000) / 100} %`;

reserveFormatters['supplyCap'] = (value, ctx) =>
  `${(value as number).toLocaleString('en-US')} ${ctx.reserve?.symbol ?? ''}`;

reserveFormatters['borrowCap'] = (value, ctx) =>
  `${(value as number).toLocaleString('en-US')} ${ctx.reserve?.symbol ?? ''}`;

reserveFormatters['debtCeiling'] = (value) =>
  prettifyNumber({ value, decimals: 2, suffix: '$' });

for (const field of RESERVE_BALANCE_FIELDS) {
  reserveFormatters[field] = (value, ctx) =>
    prettifyNumber({
      value,
      decimals: ctx.reserve?.decimals ?? 18,
      suffix: ctx.reserve?.symbol ?? '',
    });
}

reserveFormatters['oracleLatestAnswer'] = (value, ctx) => {
  const decimals = ctx.reserve?.oracleDecimals ?? 8;
  return formatUnits(BigInt(value), decimals);
};

for (const field of RESERVE_ADDRESS_FIELDS) {
  reserveFormatters[field] = (value, ctx) => addressLink(value, ctx.chainId);
}

for (const field of RESERVE_BOOL_FIELDS) {
  reserveFormatters[field] = (value) => boolToMarkdown(value as boolean);
}

// --- Strategy formatters ---

const STRATEGY_RATE_FIELDS = [
  'baseVariableBorrowRate',
  'optimalUsageRatio',
  'variableRateSlope1',
  'variableRateSlope2',
  'maxVariableBorrowRate',
];

export const strategyFormatters: Record<string, FieldFormatter> = {};

for (const field of STRATEGY_RATE_FIELDS) {
  strategyFormatters[field] = (value) =>
    `${formatUnits(BigInt(value), 25)} %`;
}

strategyFormatters['address'] = (value, ctx) => addressLink(value, ctx.chainId);

// --- EMode formatters ---

export const emodeFormatters: Record<string, FieldFormatter> = {};

emodeFormatters['ltv'] = (value) => `${formatUnits(BigInt(value), 2)} %`;
emodeFormatters['liquidationThreshold'] = (value) => `${formatUnits(BigInt(value), 2)} %`;
emodeFormatters['liquidationBonus'] = (value) =>
  value === 0 ? '0 %' : `${((value as number) - 10000) / 100} %`;

emodeFormatters['borrowableBitmap'] = (value, ctx) => {
  const indexes = bitMapToIndexes(BigInt(value));
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

emodeFormatters['priceSource'] = (value, ctx) => addressLink(value, ctx.chainId);

// --- Generic format function ---

export function formatValue(
  section: 'reserve' | 'strategy' | 'emode',
  key: string,
  value: any,
  ctx: FormatterContext
): string {
  const formattersMap = {
    reserve: reserveFormatters,
    strategy: strategyFormatters,
    emode: emodeFormatters,
  };

  const formatter = formattersMap[section][key];
  if (formatter) return formatter(value, ctx);

  // Default formatting
  if (typeof value === 'boolean') return boolToMarkdown(value);
  if (typeof value === 'number') return value.toLocaleString('en-US');
  if (isAddress(value)) return addressLink(value, ctx.chainId);
  return String(value);
}
