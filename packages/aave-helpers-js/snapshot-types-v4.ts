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
  // Asset state
  deficitRay: z.string(), // uint200 serialized as string (RAY)
  swept: z.string(), // uint120 serialized as string
  premiumShares: z.string(), // uint120 serialized as string
  premiumOffsetRay: z.string(), // int200 serialized as string (RAY, signed)
});

export type V4HubAsset = z.infer<typeof v4HubAssetSchema>;

// --- Spoke Config ---

export const v4SpokeConfigSchema = z.object({
  assetSymbol: z.string(),
  addCap: z.number(), // uint40 — fits in JS safe int
  drawCap: z.number(), // uint40 — fits in JS safe int
  riskPremiumThreshold: z.number(),
  active: z.boolean(),
  halted: z.boolean(),
});

export type V4SpokeConfig = z.infer<typeof v4SpokeConfigSchema>;

// --- Full V4 Snapshot ---

export const aaveV4SnapshotSchema = z.object({
  chainId: z.number(),
  spokeReserves: z.record(z.string(), z.record(z.string(), v4SpokeReserveSchema)),
  spokeLiquidationConfigs: z.record(z.string(), v4SpokeLiquidationConfigSchema),
  hubAssets: z.record(z.string(), z.record(z.string(), v4HubAssetSchema)),
  spokeConfigs: z.record(z.string(), v4SpokeConfigSchema),
  raw: rawStorageSchema.optional(),
  logs: z.array(logSchema).optional(),
});

export type AaveV4Snapshot = z.infer<typeof aaveV4SnapshotSchema>;
