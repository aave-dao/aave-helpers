import { type Hex, formatUnits } from 'viem';
import { getClient } from '@bgd-labs/toolbox';
import { toAddressLink, boolToMarkdown } from './utils/markdown';
import type {
  V4SpokeReserve,
  V4HubAsset,
  V4SpokeCap,
  V4SpokeLiquidationConfig,
} from './snapshot-types-v4';

// --- Formatter context ---

export interface V4FormatterContext {
  chainId: number;
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

type SpokeCapKey = keyof V4SpokeCap;

const SPOKE_CAP_BOOL_FIELDS: readonly SpokeCapKey[] = ['active', 'halted'] as const;

export const spokeCapFormatters: Partial<{
  [K in SpokeCapKey]: FieldFormatter<V4SpokeCap[K]>;
}> = {};

for (const field of SPOKE_CAP_BOOL_FIELDS) {
  (spokeCapFormatters[field] as FieldFormatter<boolean>) = (value) => boolToMarkdown(value);
}

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
  spokeCap: typeof spokeCapFormatters;
  spokeLiq: typeof spokeLiqFormatters;
};

const formattersMap: V4SectionFormatters = {
  spokeReserve: spokeReserveFormatters,
  hubAsset: hubAssetFormatters,
  spokeCap: spokeCapFormatters,
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
  return String(value);
}
