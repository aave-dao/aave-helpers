import { z } from 'zod';
import { rawStorageSchema, logSchema } from './snapshot-types';

// --- Spoke Reserve ---

export const v4SpokeReserveSchema = z.object({
  symbol: z.string(),
  underlying: z.string(),
  hub: z.string(),
  assetId: z.number(),
  decimals: z.number(),
  collateralRisk: z.number(),
  paused: z.boolean(),
  frozen: z.boolean(),
  borrowable: z.boolean(),
  receiveSharesEnabled: z.boolean(),
  dynamicConfigKey: z.number(),
  collateralFactor: z.number(),
  maxLiquidationBonus: z.number(),
  liquidationFee: z.number(),
  oracleAddress: z.string(),
  priceSource: z.string(),
  oraclePrice: z.string(), // uint256 serialized as string
});

export type V4SpokeReserve = z.infer<typeof v4SpokeReserveSchema>;

// --- Spoke Liquidation Config ---

export const v4SpokeLiquidationConfigSchema = z.object({
  targetHealthFactor: z.string(), // uint128 serialized as string
  healthFactorForMaxBonus: z.string(), // uint64 serialized as string
  liquidationBonusFactor: z.number(),
  maxUserReservesLimit: z.number(),
});

export type V4SpokeLiquidationConfig = z.infer<typeof v4SpokeLiquidationConfigSchema>;

// --- Hub Asset ---

export const v4HubAssetSchema = z.object({
  symbol: z.string(),
  underlying: z.string(),
  decimals: z.number(),
  liquidityFee: z.number(),
  irStrategy: z.string(),
  feeReceiver: z.string(),
  reinvestmentController: z.string(),
  optimalUsageRatio: z.number(),
  baseDrawnRate: z.number(),
  rateGrowthBeforeOptimal: z.number(),
  rateGrowthAfterOptimal: z.number(),
  maxDrawnRate: z.string(), // uint256 serialized as string
});

export type V4HubAsset = z.infer<typeof v4HubAssetSchema>;

// --- Spoke Cap ---

export const v4SpokeCapSchema = z.object({
  assetSymbol: z.string(),
  addCap: z.string(), // uint40 serialized as string
  drawCap: z.string(), // uint40 serialized as string
  riskPremiumThreshold: z.number(),
  active: z.boolean(),
  halted: z.boolean(),
});

export type V4SpokeCap = z.infer<typeof v4SpokeCapSchema>;

// --- Full V4 Snapshot ---

export const aaveV4SnapshotSchema = z.object({
  chainId: z.number(),
  spokeReserves: z.record(z.string(), z.record(z.string(), v4SpokeReserveSchema)),
  spokeLiquidationConfigs: z.record(z.string(), v4SpokeLiquidationConfigSchema),
  hubAssets: z.record(z.string(), z.record(z.string(), v4HubAssetSchema)),
  spokeCaps: z.record(z.string(), v4SpokeCapSchema),
  raw: rawStorageSchema.optional(),
  logs: z.array(logSchema).optional(),
});

export type AaveV4Snapshot = z.infer<typeof aaveV4SnapshotSchema>;
