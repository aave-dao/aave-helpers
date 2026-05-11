import { type Hex, formatUnits } from 'viem';
import { getClient } from '@bgd-labs/toolbox';
import { toAddressLink, boolToMarkdown } from './utils/markdown';
import type {
  V4SpokeReserve,
  V4HubAsset,
  V4SpokeConfig,
  V4SpokeLiquidationConfig,
} from './snapshot-types-v4';

// --- Formatter context ---

export interface V4FormatterContext {
  chainId: number;
  spokeConfig?: V4SpokeConfig;
}

export type FieldFormatter<T = unknown> = (value: T, ctx: V4FormatterContext) => string;

// --- Helpers ---

function getExplorerClient(chainId: number) {
  return getClient(chainId, {});
}

function addressLink(value: string, chainId: number): string {
  return toAddressLink(value as Hex, true, getExplorerClient(chainId));
}

function isAddress(value: unknown): boolean {
  return typeof value === 'string' && /^0x[0-9a-fA-F]{40}$/.test(value);
}

/** Format BPS value as percentage, matching Solidity _ps(): "W.FF % [bps]" */
function formatBps(bps: number): string {
  const w = Math.floor(bps / 100);
  const f = bps % 100;
  const fs = f < 10 ? `0${f}` : `${f}`;
  return `${w}.${fs} % [${bps}]`;
}

/** Render a uint as "1,500,000 (1.5e6) USDT"; suffix (e.g. asset symbol) goes
 *  at the end after the exponential. Values < 1000 skip the exponential.
 *  Exponential uses `Number.toExponential()`, so bigints exceeding
 *  Number.MAX_SAFE_INTEGER (~9e15) the exponent is rounded */
export function formatBigIntWithExp(value: bigint, suffix?: string): string {
  const commas = value.toLocaleString('en-US');
  const useExp = value >= 1000n || value <= -1000n;
  const expPart = useExp ? ` (${Number(value).toExponential().replace('e+', 'e')})` : '';
  const suf = suffix ? ` ${suffix}` : '';
  return `${commas}${expPart}${suf}`;
}

// --- Spoke Reserve formatters ---

type SpokeReserveKey = keyof V4SpokeReserve;

const SPOKE_RESERVE_BPS_FIELDS: readonly SpokeReserveKey[] = [
  'collateralRisk',
  'collateralFactor',
  'maxLiquidationBonus',
  'liquidationFee',
] as const;

const SPOKE_RESERVE_BOOL_FIELDS: readonly SpokeReserveKey[] = [
  'paused',
  'frozen',
  'borrowable',
  'receiveSharesEnabled',
] as const;

const SPOKE_RESERVE_ADDRESS_FIELDS: readonly SpokeReserveKey[] = [
  'underlying',
  'hub',
  'oracleAddress',
  'priceSource',
] as const;

export const spokeReserveFormatters: Partial<{
  [K in SpokeReserveKey]: FieldFormatter<V4SpokeReserve[K]>;
}> = {};

for (const field of SPOKE_RESERVE_BPS_FIELDS) {
  (spokeReserveFormatters[field] as FieldFormatter<number>) = (value) => formatBps(value);
}

for (const field of SPOKE_RESERVE_BOOL_FIELDS) {
  (spokeReserveFormatters[field] as FieldFormatter<boolean>) = (value) => boolToMarkdown(value);
}

for (const field of SPOKE_RESERVE_ADDRESS_FIELDS) {
  (spokeReserveFormatters[field] as FieldFormatter<string>) = (value, ctx) =>
    addressLink(value, ctx.chainId);
}

// --- Hub Asset formatters ---

type HubAssetKey = keyof V4HubAsset;

const HUB_ASSET_BPS_FIELDS: readonly HubAssetKey[] = ['liquidityFee'] as const;

/** IR strategy fields — per-asset on V4, BPS scale (unlike V3 RAY). */
const HUB_ASSET_IR_STRATEGY_BPS_FIELDS: readonly HubAssetKey[] = [
  'optimalUsageRatio',
  'baseDrawnRate',
  'rateGrowthBeforeOptimal',
  'rateGrowthAfterOptimal',
] as const;

const HUB_ASSET_ADDRESS_FIELDS: readonly HubAssetKey[] = [
  'underlying',
  'irStrategy',
  'feeReceiver',
  'reinvestmentController',
] as const;

export const hubAssetFormatters: Partial<{
  [K in HubAssetKey]: FieldFormatter<V4HubAsset[K]>;
}> = {};

for (const field of HUB_ASSET_BPS_FIELDS) {
  (hubAssetFormatters[field] as FieldFormatter<number>) = (value) => formatBps(value);
}

for (const field of HUB_ASSET_IR_STRATEGY_BPS_FIELDS) {
  (hubAssetFormatters[field] as FieldFormatter<number>) = (value) => formatBps(value);
}

hubAssetFormatters['maxDrawnRate'] = (value) => formatBps(Number(value));

for (const field of HUB_ASSET_ADDRESS_FIELDS) {
  (hubAssetFormatters[field] as FieldFormatter<string>) = (value, ctx) =>
    addressLink(value, ctx.chainId);
}

// Asset state — RAY fields (1e27)
hubAssetFormatters['deficitRay'] = (value) => `${formatUnits(BigInt(value), 27)} [${value}]`;
hubAssetFormatters['premiumOffsetRay'] = (value) => `${formatUnits(BigInt(value), 27)} [${value}]`;

// --- Spoke Cap formatters ---

type SpokeConfigKey = keyof V4SpokeConfig;

const SPOKE_CONFIG_FLAGS: readonly SpokeConfigKey[] = ['active', 'halted'] as const;

/** uint40 token-unit cap fields — formatted with thousands separators + asset symbol. */
const SPOKE_CONFIG_TOKEN_AMOUNT_FIELDS: readonly SpokeConfigKey[] = ['addCap', 'drawCap'] as const;

export const spokeConfigFormatters: Partial<{
  [K in SpokeConfigKey]: FieldFormatter<V4SpokeConfig[K]>;
}> = {};

for (const field of SPOKE_CONFIG_FLAGS) {
  (spokeConfigFormatters[field] as FieldFormatter<boolean>) = (value) => boolToMarkdown(value);
}

for (const field of SPOKE_CONFIG_TOKEN_AMOUNT_FIELDS) {
  (spokeConfigFormatters[field] as FieldFormatter<number>) = (value, ctx) =>
    formatBigIntWithExp(BigInt(value), ctx.spokeConfig?.assetSymbol);
}

spokeConfigFormatters['riskPremiumThreshold'] = (value) => formatBps(value);

// --- Spoke Liquidation Config formatters ---

type SpokeLiqKey = keyof V4SpokeLiquidationConfig;

export const spokeLiqFormatters: Partial<{
  [K in SpokeLiqKey]: FieldFormatter<V4SpokeLiquidationConfig[K]>;
}> = {};

// WAD fields (1e18) — serialized as strings
spokeLiqFormatters['targetHealthFactor'] = (value) =>
  `${formatUnits(BigInt(value), 18)} [${value}]`;
spokeLiqFormatters['healthFactorForMaxBonus'] = (value) =>
  `${formatUnits(BigInt(value), 18)} [${value}]`;

// BPS field
spokeLiqFormatters['liquidationBonusFactor'] = (value) => formatBps(value);

// --- Generic format function ---

type V4SectionFormatters = {
  spokeReserve: typeof spokeReserveFormatters;
  hubAsset: typeof hubAssetFormatters;
  spokeConfig: typeof spokeConfigFormatters;
  spokeLiq: typeof spokeLiqFormatters;
};

const formattersMap: V4SectionFormatters = {
  spokeReserve: spokeReserveFormatters,
  hubAsset: hubAssetFormatters,
  spokeConfig: spokeConfigFormatters,
  spokeLiq: spokeLiqFormatters,
} as const;

export function formatV4Value(
  section: keyof V4SectionFormatters,
  key: string,
  value: unknown,
  ctx: V4FormatterContext
): string {
  const formatter = (formattersMap[section] as Record<string, FieldFormatter | undefined>)[key];
  if (formatter) return formatter(value, ctx);

  // Default formatting
  if (typeof value === 'boolean') return boolToMarkdown(value);
  if (typeof value === 'number') return value.toLocaleString('en-US');
  if (isAddress(value)) return addressLink(value as string, ctx.chainId);
  // Pure numeric strings (uint serialized as string) — render with thousand separators
  // and exponent in parens ("1,500,000 (1.5e6)") so price feeds and large uints
  // are easy to scan at both scales.
  if (typeof value === 'string' && /^-?\d+$/.test(value)) {
    return formatBigIntWithExp(BigInt(value));
  }
  return String(value);
}
