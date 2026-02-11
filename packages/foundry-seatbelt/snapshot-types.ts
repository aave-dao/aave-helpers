import type { Address, Hex } from 'viem';
import { zksync } from 'viem/chains';
import { z } from 'zod';

// --- Chain IDs ---

export const CHAIN_ID = {
  MAINNET: 1,
  OPTIMISM: 10,
  POLYGON: 137,
  FANTOM: 250,
  ARBITRUM: 42161,
  AVALANCHE: 43114,
  METIS: 1088,
  BASE: 8453,
  SCROLL: 534352,
  BNB: 56,
  GNOSIS: 100,
  CELO: 42220,
  ZKSYNC: zksync.id,
} as const;

const zodChainId = z.nativeEnum(CHAIN_ID);
export type CHAIN_ID = z.infer<typeof zodChainId>;

// --- Pool Config ---

export const aaveV3ConfigSchema = z.object({
  oracle: z.string(),
  pool: z.string(),
  poolAddressesProvider: z.string(),
  poolConfigurator: z.string(),
  priceOracleSentinel: z.string(),
  protocolDataProvider: z.string(),
});

export type AaveV3Config = z.infer<typeof aaveV3ConfigSchema>;

// --- Reserve ---

export const aaveV3ReserveSchema = z.object({
  id: z.number(),
  symbol: z.string(),
  underlying: z.string(),
  decimals: z.number(),
  isActive: z.boolean(),
  isFrozen: z.boolean(),
  isPaused: z.boolean(),
  isSiloed: z.boolean(),
  isFlashloanable: z.boolean(),
  isBorrowableInIsolation: z.boolean(),
  borrowingEnabled: z.boolean(),
  usageAsCollateralEnabled: z.boolean(),
  ltv: z.number(),
  liquidationThreshold: z.number(),
  liquidationBonus: z.number(),
  liquidationProtocolFee: z.number(),
  reserveFactor: z.number(),
  supplyCap: z.number(),
  borrowCap: z.number(),
  debtCeiling: z.number(),
  oracle: z.string(),
  oracleDecimals: z.number(),
  oracleDescription: z.string().optional(),
  oracleName: z.string().optional(),
  oracleLatestAnswer: z.string(),
  interestRateStrategy: z.string(),
  aToken: z.string(),
  aTokenName: z.string(),
  aTokenSymbol: z.string(),
  aTokenUnderlyingBalance: z.string(),
  variableDebtToken: z.string(),
  variableDebtTokenName: z.string(),
  variableDebtTokenSymbol: z.string(),
  virtualBalance: z.string(),
});

export type AaveV3Reserve = z.infer<typeof aaveV3ReserveSchema>;

// --- Strategy ---

export const aaveV3StrategySchema = z.object({
  address: z.string(),
  baseVariableBorrowRate: z.string(),
  optimalUsageRatio: z.string(),
  variableRateSlope1: z.string(),
  variableRateSlope2: z.string(),
  maxVariableBorrowRate: z.string(),
});

export type AaveV3Strategy = z.infer<typeof aaveV3StrategySchema>;

// --- EMode ---

export const aaveV3EmodeSchema = z.object({
  eModeCategory: z.number(),
  label: z.string(),
  ltv: z.number(),
  liquidationThreshold: z.number(),
  liquidationBonus: z.number(),
  priceSource: z.string().optional(),
  borrowableBitmap: z.string(),
  collateralBitmap: z.string(),
});

export type AaveV3Emode = z.infer<typeof aaveV3EmodeSchema>;

// --- Raw Storage ---

export const slotDiffSchema = z.object({
  previousValue: z.string() as z.ZodType<Hex>,
  newValue: z.string() as z.ZodType<Hex>,
  label: z.string().optional(),
  type: z.string().optional(),
  offset: z.number().optional(),
  slot: z.string().optional(),
  decoded: z
    .object({
      previousValue: z.string(),
      newValue: z.string(),
    })
    .optional(),
  key: z.string().optional(),
});

export type SlotDiff = z.infer<typeof slotDiffSchema>;

export const valueDiffSchema = z.object({
  previousValue: z.union([z.string(), z.number()]),
  newValue: z.union([z.string(), z.number()]),
});

export type ValueDiff = z.infer<typeof valueDiffSchema>;

export const rawStorageSchema = z.record(
  z.string() as z.ZodType<Address>,
  z.object({
    label: z.string().nullable(),
    contract: z.string().nullable(),
    balanceDiff: valueDiffSchema.nullable(),
    nonceDiff: valueDiffSchema.nullable(),
    stateDiff: z.record(z.string(), slotDiffSchema),
  })
);

export type RawStorage = z.infer<typeof rawStorageSchema>;

// --- Logs ---

export const logSchema = z.object({
  topics: z.array(z.string()),
  data: z.string(),
  emitter: z.string(),
});

export type Log = z.infer<typeof logSchema>;

// --- Full Snapshot ---

export const aaveV3SnapshotSchema = z.object({
  chainId: zodChainId,
  reserves: z.record(z.string(), aaveV3ReserveSchema),
  strategies: z.record(z.string(), aaveV3StrategySchema),
  eModes: z.record(z.string(), aaveV3EmodeSchema),
  poolConfig: aaveV3ConfigSchema,
  raw: rawStorageSchema.optional(),
  logs: z.array(logSchema).optional(),
});

export type AaveV3Snapshot = z.infer<typeof aaveV3SnapshotSchema>;
