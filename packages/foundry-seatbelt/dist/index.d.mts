import { Hex } from "viem";
import { z } from "zod";

//#region snapshot-types.d.ts
declare const CHAIN_ID: {
  readonly MAINNET: 1;
  readonly OPTIMISM: 10;
  readonly POLYGON: 137;
  readonly FANTOM: 250;
  readonly ARBITRUM: 42161;
  readonly AVALANCHE: 43114;
  readonly METIS: 1088;
  readonly BASE: 8453;
  readonly SCROLL: 534352;
  readonly BNB: 56;
  readonly GNOSIS: 100;
  readonly CELO: 42220;
  readonly ZKSYNC: 324;
};
declare const zodChainId: z.ZodEnum<{
  readonly MAINNET: 1;
  readonly OPTIMISM: 10;
  readonly POLYGON: 137;
  readonly FANTOM: 250;
  readonly ARBITRUM: 42161;
  readonly AVALANCHE: 43114;
  readonly METIS: 1088;
  readonly BASE: 8453;
  readonly SCROLL: 534352;
  readonly BNB: 56;
  readonly GNOSIS: 100;
  readonly CELO: 42220;
  readonly ZKSYNC: 324;
}>;
type CHAIN_ID = z.infer<typeof zodChainId>;
declare const aaveV3ConfigSchema: z.ZodObject<{
  oracle: z.ZodString;
  pool: z.ZodString;
  poolAddressesProvider: z.ZodString;
  poolConfigurator: z.ZodString;
  priceOracleSentinel: z.ZodString;
  protocolDataProvider: z.ZodString;
}, z.core.$strip>;
type AaveV3Config = z.infer<typeof aaveV3ConfigSchema>;
declare const aaveV3ReserveSchema: z.ZodObject<{
  id: z.ZodNumber;
  symbol: z.ZodString;
  underlying: z.ZodString;
  decimals: z.ZodNumber;
  isActive: z.ZodBoolean;
  isFrozen: z.ZodBoolean;
  isPaused: z.ZodBoolean;
  isSiloed: z.ZodBoolean;
  isFlashloanable: z.ZodBoolean;
  isBorrowableInIsolation: z.ZodBoolean;
  borrowingEnabled: z.ZodBoolean;
  usageAsCollateralEnabled: z.ZodBoolean;
  ltv: z.ZodNumber;
  liquidationThreshold: z.ZodNumber;
  liquidationBonus: z.ZodNumber;
  liquidationProtocolFee: z.ZodNumber;
  reserveFactor: z.ZodNumber;
  supplyCap: z.ZodNumber;
  borrowCap: z.ZodNumber;
  debtCeiling: z.ZodNumber;
  oracle: z.ZodString;
  oracleDecimals: z.ZodNumber;
  oracleDescription: z.ZodOptional<z.ZodString>;
  oracleName: z.ZodOptional<z.ZodString>;
  oracleLatestAnswer: z.ZodString;
  interestRateStrategy: z.ZodString;
  aToken: z.ZodString;
  aTokenName: z.ZodString;
  aTokenSymbol: z.ZodString;
  aTokenUnderlyingBalance: z.ZodString;
  variableDebtToken: z.ZodString;
  variableDebtTokenName: z.ZodString;
  variableDebtTokenSymbol: z.ZodString;
  virtualBalance: z.ZodString;
}, z.core.$strip>;
type AaveV3Reserve = z.infer<typeof aaveV3ReserveSchema>;
declare const aaveV3StrategySchema: z.ZodObject<{
  address: z.ZodString;
  baseVariableBorrowRate: z.ZodString;
  optimalUsageRatio: z.ZodString;
  variableRateSlope1: z.ZodString;
  variableRateSlope2: z.ZodString;
  maxVariableBorrowRate: z.ZodString;
}, z.core.$strip>;
type AaveV3Strategy = z.infer<typeof aaveV3StrategySchema>;
declare const aaveV3EmodeSchema: z.ZodObject<{
  eModeCategory: z.ZodNumber;
  label: z.ZodString;
  ltv: z.ZodNumber;
  liquidationThreshold: z.ZodNumber;
  liquidationBonus: z.ZodNumber;
  priceSource: z.ZodOptional<z.ZodString>;
  borrowableBitmap: z.ZodString;
  collateralBitmap: z.ZodString;
}, z.core.$strip>;
type AaveV3Emode = z.infer<typeof aaveV3EmodeSchema>;
declare const slotDiffSchema: z.ZodObject<{
  previousValue: z.ZodType<Hex>;
  newValue: z.ZodType<Hex>;
  label: z.ZodOptional<z.ZodString>;
}, z.core.$strip>;
type SlotDiff = z.infer<typeof slotDiffSchema>;
declare const valueDiffSchema: z.ZodObject<{
  previousValue: z.ZodUnion<readonly [z.ZodString, z.ZodNumber]>;
  newValue: z.ZodUnion<readonly [z.ZodString, z.ZodNumber]>;
}, z.core.$strip>;
type ValueDiff = z.infer<typeof valueDiffSchema>;
declare const rawStorageSchema: z.ZodRecord<z.ZodType<`0x${string}`, unknown, z.core.$ZodTypeInternals<`0x${string}`, unknown>>, z.ZodObject<{
  label: z.ZodNullable<z.ZodString>;
  contract: z.ZodNullable<z.ZodString>;
  balanceDiff: z.ZodNullable<z.ZodObject<{
    previousValue: z.ZodUnion<readonly [z.ZodString, z.ZodNumber]>;
    newValue: z.ZodUnion<readonly [z.ZodString, z.ZodNumber]>;
  }, z.core.$strip>>;
  nonceDiff: z.ZodNullable<z.ZodObject<{
    previousValue: z.ZodUnion<readonly [z.ZodString, z.ZodNumber]>;
    newValue: z.ZodUnion<readonly [z.ZodString, z.ZodNumber]>;
  }, z.core.$strip>>;
  stateDiff: z.ZodRecord<z.ZodString, z.ZodObject<{
    previousValue: z.ZodType<Hex>;
    newValue: z.ZodType<Hex>;
    label: z.ZodOptional<z.ZodString>;
  }, z.core.$strip>>;
}, z.core.$strip>>;
type RawStorage = z.infer<typeof rawStorageSchema>;
declare const logSchema: z.ZodObject<{
  topics: z.ZodArray<z.ZodString>;
  data: z.ZodString;
  emitter: z.ZodString;
}, z.core.$strip>;
type Log = z.infer<typeof logSchema>;
declare const aaveV3SnapshotSchema: z.ZodObject<{
  chainId: z.ZodEnum<{
    readonly MAINNET: 1;
    readonly OPTIMISM: 10;
    readonly POLYGON: 137;
    readonly FANTOM: 250;
    readonly ARBITRUM: 42161;
    readonly AVALANCHE: 43114;
    readonly METIS: 1088;
    readonly BASE: 8453;
    readonly SCROLL: 534352;
    readonly BNB: 56;
    readonly GNOSIS: 100;
    readonly CELO: 42220;
    readonly ZKSYNC: 324;
  }>;
  reserves: z.ZodRecord<z.ZodString, z.ZodObject<{
    id: z.ZodNumber;
    symbol: z.ZodString;
    underlying: z.ZodString;
    decimals: z.ZodNumber;
    isActive: z.ZodBoolean;
    isFrozen: z.ZodBoolean;
    isPaused: z.ZodBoolean;
    isSiloed: z.ZodBoolean;
    isFlashloanable: z.ZodBoolean;
    isBorrowableInIsolation: z.ZodBoolean;
    borrowingEnabled: z.ZodBoolean;
    usageAsCollateralEnabled: z.ZodBoolean;
    ltv: z.ZodNumber;
    liquidationThreshold: z.ZodNumber;
    liquidationBonus: z.ZodNumber;
    liquidationProtocolFee: z.ZodNumber;
    reserveFactor: z.ZodNumber;
    supplyCap: z.ZodNumber;
    borrowCap: z.ZodNumber;
    debtCeiling: z.ZodNumber;
    oracle: z.ZodString;
    oracleDecimals: z.ZodNumber;
    oracleDescription: z.ZodOptional<z.ZodString>;
    oracleName: z.ZodOptional<z.ZodString>;
    oracleLatestAnswer: z.ZodString;
    interestRateStrategy: z.ZodString;
    aToken: z.ZodString;
    aTokenName: z.ZodString;
    aTokenSymbol: z.ZodString;
    aTokenUnderlyingBalance: z.ZodString;
    variableDebtToken: z.ZodString;
    variableDebtTokenName: z.ZodString;
    variableDebtTokenSymbol: z.ZodString;
    virtualBalance: z.ZodString;
  }, z.core.$strip>>;
  strategies: z.ZodRecord<z.ZodString, z.ZodObject<{
    address: z.ZodString;
    baseVariableBorrowRate: z.ZodString;
    optimalUsageRatio: z.ZodString;
    variableRateSlope1: z.ZodString;
    variableRateSlope2: z.ZodString;
    maxVariableBorrowRate: z.ZodString;
  }, z.core.$strip>>;
  eModes: z.ZodRecord<z.ZodString, z.ZodObject<{
    eModeCategory: z.ZodNumber;
    label: z.ZodString;
    ltv: z.ZodNumber;
    liquidationThreshold: z.ZodNumber;
    liquidationBonus: z.ZodNumber;
    priceSource: z.ZodOptional<z.ZodString>;
    borrowableBitmap: z.ZodString;
    collateralBitmap: z.ZodString;
  }, z.core.$strip>>;
  poolConfig: z.ZodObject<{
    oracle: z.ZodString;
    pool: z.ZodString;
    poolAddressesProvider: z.ZodString;
    poolConfigurator: z.ZodString;
    priceOracleSentinel: z.ZodString;
    protocolDataProvider: z.ZodString;
  }, z.core.$strip>;
  raw: z.ZodOptional<z.ZodRecord<z.ZodType<`0x${string}`, unknown, z.core.$ZodTypeInternals<`0x${string}`, unknown>>, z.ZodObject<{
    label: z.ZodNullable<z.ZodString>;
    contract: z.ZodNullable<z.ZodString>;
    balanceDiff: z.ZodNullable<z.ZodObject<{
      previousValue: z.ZodUnion<readonly [z.ZodString, z.ZodNumber]>;
      newValue: z.ZodUnion<readonly [z.ZodString, z.ZodNumber]>;
    }, z.core.$strip>>;
    nonceDiff: z.ZodNullable<z.ZodObject<{
      previousValue: z.ZodUnion<readonly [z.ZodString, z.ZodNumber]>;
      newValue: z.ZodUnion<readonly [z.ZodString, z.ZodNumber]>;
    }, z.core.$strip>>;
    stateDiff: z.ZodRecord<z.ZodString, z.ZodObject<{
      previousValue: z.ZodType<Hex>;
      newValue: z.ZodType<Hex>;
      label: z.ZodOptional<z.ZodString>;
    }, z.core.$strip>>;
  }, z.core.$strip>>>;
  logs: z.ZodOptional<z.ZodArray<z.ZodObject<{
    topics: z.ZodArray<z.ZodString>;
    data: z.ZodString;
    emitter: z.ZodString;
  }, z.core.$strip>>>;
}, z.core.$strip>;
type AaveV3Snapshot = z.infer<typeof aaveV3SnapshotSchema>;
//#endregion
//#region protocol-diff.d.ts
/**
 * Diff two Aave V3 protocol snapshots and produce a formatted markdown report.
 *
 * The `raw` and `logs` sections only exist in the "after" snapshot and are
 * rendered as-is (they already represent the diff / changes).
 */
declare function diffSnapshots(before: AaveV3Snapshot, after: AaveV3Snapshot): Promise<string>;
//#endregion
//#region diff.d.ts
/**
 * Generic recursive object diff.
 *
 * For each key present in either `a` or `b`:
 * - If both have the key and the values are objects, recurse.
 * - If both have the key and the values are equal primitives, keep as-is (or omit if `removeUnchanged`).
 * - If both have the key but values differ, produce `{ from, to }`.
 * - If only `a` has the key, produce `{ from: value, to: null }`.
 * - If only `b` has the key, produce `{ from: null, to: value }`.
 */
/** A changed field: carries the old and new value. */
type Change<T> = {
  from: T | null;
  to: T | null;
};
/** Recursively maps each field to either its unchanged value, a Change, or a nested diff. */
type DiffResult<T extends Record<string, any>> = { [K in keyof T]?: T[K] extends Record<string, any> ? DiffResult<T[K]> | Change<T[K]> : T[K] | Change<T[K]> };
declare function diff<T extends Record<string, any>>(a: T, b: T, removeUnchanged?: boolean): DiffResult<T>;
/**
 * Check if a diff entry represents a changed value (has `from`/`to` shape).
 */
declare function isChange<T = any>(value: any): value is Change<T>;
/**
 * Check if any direct child of the diff object has changes.
 */
declare function hasChanges<T extends Record<string, any>>(diffObj: DiffResult<T> | Record<string, unknown> | null | undefined): boolean;
//#endregion
export { type AaveV3Config, type AaveV3Emode, type AaveV3Reserve, type AaveV3Snapshot, type AaveV3Strategy, type CHAIN_ID, type Change, type DiffResult, type Log, type RawStorage, type SlotDiff, type ValueDiff, diff, diffSnapshots, hasChanges, isChange };