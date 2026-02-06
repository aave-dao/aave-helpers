import { Address, Hex } from 'viem';
import { zksync } from 'viem/chains';
import { z } from 'zod';

export const aaveV3ConfigSchema = z.object({
  oracle: z.string(),
  pool: z.string(),
  poolAddressesProvider: z.string(),
  poolConfigurator: z.string(),
  poolConfiguratorImpl: z.string(),
  poolImpl: z.string(),
  protocolDataProvider: z.string(),
});

export type AaveV3Config = z.infer<typeof aaveV3ConfigSchema>;

export const aaveV3ReserveSchema = z.object({
  id: z.number(),
  isBorrowableInIsolation: z.boolean(),
  borrowCap: z.number(),
  liquidationBonus: z.number(),
  underlying: z.string(),
  isFrozen: z.boolean(),
  stableDebtToken: z.string(),
  variableDebtToken: z.string(),
  reserveFactor: z.number(),
  liquidationProtocolFee: z.number(),
  usageAsCollateralEnabled: z.boolean(),
  ltv: z.number(),
  supplyCap: z.number(),
  debtCeiling: z.number(),
  borrowingEnabled: z.boolean(),
  isActive: z.boolean(),
  eModeCategory: z.number(),
  symbol: z.string(),
  stableBorrowRateEnabled: z.boolean(),
  isFlashloanable: z.boolean(),
  aToken: z.string(),
  liquidationThreshold: z.number(),
  aTokenImpl: z.string(),
  stableDebtTokenImpl: z.string(),
  interestRateStrategy: z.string(),
  variableDebtTokenImpl: z.string(),
  oracleLatestAnswer: z.string(),
  oracle: z.string(),
  oracleDecimals: z.number(),
  oracleName: z.string(),
  oracleDescription: z.string(),
  decimals: z.number(),
  isSiloed: z.boolean(),
  liquidityIndex: z.number(),
  variableBorrowIndex: z.number(),
  currentLiquidityRate: z.number(),
  currentVariableBorrowRate: z.number(),
  aTokenUnderlyingBalance: z.string(),
  virtualAccountingActive: z.boolean(),
  virtualBalance: z.string(),
});

export type AaveV3Reserve = z.infer<typeof aaveV3ReserveSchema>;

export const aaveV3StrategySchema = z.object({
  address: z.string(),
  baseVariableBorrowRate: z.string(),
  optimalUsageRatio: z.string(),
  variableRateSlope1: z.string(),
  variableRateSlope2: z.string(),
  maxVariableBorrowRate: z.string(),
});

export type AaveV3Strategy = z.infer<typeof aaveV3StrategySchema>;

export const aaveV3EmodeSchema = z.object({
  eModeCategory: z.number(),
  liquidationBonus: z.number(),
  label: z.string(),
  liquidationThreshold: z.number(),
  priceSource: z.string(),
  ltv: z.number(),
  borrowableBitmap: z.string(),
  collateralBitmap: z.string(),
});

export type AaveV3Emode = z.infer<typeof aaveV3EmodeSchema>;

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

export const slotDiff = z.object({
  previousValue: z.string() as z.ZodType<Hex>,
  newValue: z.string() as z.ZodType<Hex>,
  label: z.string().optional(), // does not initially exist, but we might want to inject information here
});

export const rawStorageSchema = z.record(
  z.string() as z.ZodType<Address>,
  z.object({
    label: z.string().nullable(),
    balanceDiff: z.string().nullable(),
    stateDiff: z.record(z.string(), slotDiff),
  })
);

export type RawStorage = z.infer<typeof rawStorageSchema>;

export type SlotDiff = z.infer<typeof slotDiff>;

export const aaveV3SnapshotSchema = z.object({
  reserves: z.record(z.string(), aaveV3ReserveSchema),
  strategies: z.record(z.string(), aaveV3StrategySchema),
  eModes: z.record(z.string(), aaveV3EmodeSchema),
  poolConfig: aaveV3ConfigSchema,
  chainId: zodChainId,
  raw: rawStorageSchema.optional(),
});

export const aDIReceiverConfigSchema = z.object({
  requiredConfirmations: z.number(),
  validityTimestamp: z.number(),
});
export const aDIAdapterSchema = z.record(z.string(), z.string());

export const aDISnapshotSchema = z.object({
  receiverConfigs: z.record(zodChainId, aDIReceiverConfigSchema),
  forwarderAdaptersByChain: z.record(zodChainId, aDIAdapterSchema),
  receiverAdaptersByChain: z.record(zodChainId, aDIAdapterSchema),
  chainId: zodChainId,
});

export type AaveV3Snapshot = z.infer<typeof aaveV3SnapshotSchema>;
export type ADISnapshot = z.infer<typeof aDISnapshotSchema>;

export const capoPriceSchema = z.object({
  referencePrice: z.number(),
  sourcePrice: z.number(),
  timestamp: z.number(),
  dayToDayGrowth: z.number(),
  smoothedGrowth: z.number(),
});

export const capoSnapshotSchema = z.object({
  decimals: z.number(),
  reference: z.string(),
  source: z.string(),
  maxYearlyGrowthPercent: z.number(),
  minSnapshotDelay: z.number(),
  prices: z.record(z.string(), capoPriceSchema),
});

export type CapoSnapshot = z.infer<typeof capoSnapshotSchema>;

export const capoSvrPriceSchema = z.object({
  regularAdapterPrice: z.number(),
  svrAdapterPrice: z.number(),
  timestamp: z.number(),
});

export const capoSvrSnapshotSchema = z.object({
  sourceName: z.string(),
  decimals: z.number(),
  minSnapshotDelay: z.number(),
  comparative: z.record(z.string(), capoSvrPriceSchema),
});

export type CapoSvrSnapshot = z.infer<typeof capoSvrSnapshotSchema>;
