import { describe, it, expect } from 'vitest';
import { diffV4Snapshots } from '../protocol-diff-v4';
import { aaveV4SnapshotSchema, type AaveV4Snapshot } from '../snapshot-types-v4';
import { formatV4Value } from '../formatters-v4';

// --- Fixtures ---

const SPOKE_ADDR = '0x1111111111111111111111111111111111111111';
const HUB_ADDR = '0x2222222222222222222222222222222222222222';
const ORACLE_ADDR = '0x3333333333333333333333333333333333333333';
const PRICE_SRC = '0x4444444444444444444444444444444444444444';
const UNDERLYING = '0x5555555555555555555555555555555555555555';
const IR_STRATEGY = '0x6666666666666666666666666666666666666666';
const FEE_RECV = '0x7777777777777777777777777777777777777777';
const REINVEST = '0x8888888888888888888888888888888888888888';

function makeSnapshot(overrides?: Partial<AaveV4Snapshot>): AaveV4Snapshot {
  return {
    chainId: 1,
    spokeReserves: {
      [SPOKE_ADDR]: {
        '0': {
          symbol: 'WETH',
          underlying: UNDERLYING,
          hub: HUB_ADDR,
          assetId: 0,
          decimals: 18,
          collateralRisk: 100,
          paused: false,
          frozen: false,
          borrowable: true,
          receiveSharesEnabled: true,
          dynamicConfigKey: 0,
          collateralFactor: 8000,
          maxLiquidationBonus: 500,
          liquidationFee: 100,
          dynamicConfigs: {},
          oracleAddress: ORACLE_ADDR,
          priceSource: PRICE_SRC,
          oraclePrice: '200000000000',
        },
      },
    },
    spokeLiquidationConfigs: {
      [SPOKE_ADDR]: {
        targetHealthFactor: '1050000000000000000',
        healthFactorForMaxBonus: '1000000000000000000',
        liquidationBonusFactor: 500,
        maxUserReservesLimit: 128,
      },
    },
    hubAssets: {
      [HUB_ADDR]: {
        '0': {
          symbol: 'WETH',
          underlying: UNDERLYING,
          decimals: 18,
          liquidityFee: 1000,
          irStrategy: IR_STRATEGY,
          feeReceiver: FEE_RECV,
          reinvestmentController: REINVEST,
          optimalUsageRatio: 8000,
          baseDrawnRate: 100,
          rateGrowthBeforeOptimal: 400,
          rateGrowthAfterOptimal: 6000,
          maxDrawnRate: '10000',
          deficitRay: '0',
          swept: '0',
          premiumShares: '0',
          premiumOffsetRay: '0',
        },
      },
    },
    spokeConfigs: {
      [`${HUB_ADDR}_0_${SPOKE_ADDR}`]: {
        assetSymbol: 'WETH',
        addCap: 1000000,
        drawCap: 500000,
        riskPremiumThreshold: 100,
        active: true,
        halted: false,
      },
    },
    ...overrides,
  };
}

// --- Schema validation ---

describe('V4 snapshot Zod schema', () => {
  it('validates a well-formed snapshot', () => {
    const result = aaveV4SnapshotSchema.safeParse(makeSnapshot());
    expect(result.success).toBe(true);
  });

  it('rejects a snapshot missing required fields', () => {
    const result = aaveV4SnapshotSchema.safeParse({ chainId: 1 });
    expect(result.success).toBe(false);
  });

  it('accepts optional raw and logs', () => {
    const snap = makeSnapshot({ raw: {}, logs: [] });
    const result = aaveV4SnapshotSchema.safeParse(snap);
    expect(result.success).toBe(true);
  });
});

// --- Formatter ---

describe('BPS formatting via formatV4Value', () => {
  const ctx = { chainId: 1 };

  it('formats 8000 as 80.00 %', () => {
    expect(formatV4Value('spokeReserve', 'collateralFactor', 8000, ctx)).toBe('80.00 % [8000]');
  });

  it('formats 100 as 1.00 %', () => {
    expect(formatV4Value('spokeReserve', 'liquidationFee', 100, ctx)).toBe('1.00 % [100]');
  });

  it('formats 50 as 0.50 %', () => {
    expect(formatV4Value('spokeReserve', 'collateralFactor', 50, ctx)).toBe('0.50 % [50]');
  });

  it('formats 0 as 0.00 %', () => {
    expect(formatV4Value('spokeReserve', 'collateralFactor', 0, ctx)).toBe('0.00 % [0]');
  });

  it('formats collateralRisk as BPS', () => {
    expect(formatV4Value('spokeReserve', 'collateralRisk', 5000, ctx)).toBe('50.00 % [5000]');
  });

  it('formats maxLiquidationBonus with PERCENTAGE_FACTOR offset (100_00 = 0% bonus)', () => {
    expect(formatV4Value('spokeReserve', 'maxLiquidationBonus', 10100, ctx)).toBe('1.00 % [10100]');
    expect(formatV4Value('spokeReserve', 'maxLiquidationBonus', 10500, ctx)).toBe('5.00 % [10500]');
    expect(formatV4Value('spokeReserve', 'maxLiquidationBonus', 10000, ctx)).toBe('0.00 % [10000]');
    // Uninitialized — guard avoids the misleading "-100.00 % [0]"
    expect(formatV4Value('spokeReserve', 'maxLiquidationBonus', 0, ctx)).toBe('0.00 % [0]');
  });

  it('formats hub asset IR strategy fields as BPS', () => {
    expect(formatV4Value('hubAsset', 'optimalUsageRatio', 9200, ctx)).toBe('92.00 % [9200]');
    expect(formatV4Value('hubAsset', 'baseDrawnRate', 25, ctx)).toBe('0.25 % [25]');
    expect(formatV4Value('hubAsset', 'rateGrowthBeforeOptimal', 450, ctx)).toBe('4.50 % [450]');
    expect(formatV4Value('hubAsset', 'rateGrowthAfterOptimal', 3000, ctx)).toBe('30.00 % [3000]');
    expect(formatV4Value('hubAsset', 'maxDrawnRate', '3450', ctx)).toBe('34.50 % [3450]');
  });

  it('formats hub asset liquidityFee as BPS', () => {
    expect(formatV4Value('hubAsset', 'liquidityFee', 1500, ctx)).toBe('15.00 % [1500]');
  });

  it('formats WAD fields for spoke liquidation', () => {
    expect(formatV4Value('spokeLiq', 'targetHealthFactor', '1050000000000000000', ctx)).toBe(
      '1.05 [1050000000000000000]'
    );
    expect(formatV4Value('spokeLiq', 'healthFactorForMaxBonus', '1000000000000000000', ctx)).toBe(
      '1 [1000000000000000000]'
    );
  });

  it('formats spokeLiq liquidationBonusFactor as BPS', () => {
    expect(formatV4Value('spokeLiq', 'liquidationBonusFactor', 500, ctx)).toBe('5.00 % [500]');
  });

  it('formats RAY fields for hub asset state', () => {
    expect(formatV4Value('hubAsset', 'deficitRay', '1000000000000000000000000000', ctx)).toBe(
      '1 [1000000000000000000000000000]'
    );
    expect(formatV4Value('hubAsset', 'premiumOffsetRay', '-500000000000000000000000000', ctx)).toBe(
      '-0.5 [-500000000000000000000000000]'
    );
  });

  it('formats booleans as checkmarks', () => {
    expect(formatV4Value('spokeReserve', 'paused', true, ctx)).toBe(':white_check_mark:');
    expect(formatV4Value('spokeReserve', 'frozen', false, ctx)).toBe(':x:');
    expect(formatV4Value('spokeConfig', 'active', true, ctx)).toBe(':white_check_mark:');
    expect(formatV4Value('spokeConfig', 'halted', false, ctx)).toBe(':x:');
  });

  it('formats addresses as explorer links', () => {
    const result = formatV4Value('spokeReserve', 'underlying', UNDERLYING, ctx);
    expect(result).toContain(UNDERLYING);
    expect(result).toContain(']('); // markdown link
  });

  it('falls back to raw string for unformatted fields', () => {
    expect(formatV4Value('spokeLiq', 'maxUserReservesLimit', 128, ctx)).toBe('128');
  });

  it('formats spoke cap uint40 fields with separators, asset symbol, and exponential', () => {
    const capCtx = {
      ...ctx,
      spokeConfig: {
        assetSymbol: 'USDT',
        addCap: 0,
        drawCap: 0,
        riskPremiumThreshold: 0,
        active: true,
        halted: false,
      },
    };
    expect(formatV4Value('spokeConfig', 'addCap', 1000000, capCtx)).toBe('1,000,000 (1e6) USDT');
    expect(formatV4Value('spokeConfig', 'drawCap', 1880000, capCtx)).toBe(
      '1,880,000 (1.88e6) USDT'
    );
    // Falls back gracefully when symbol unavailable
    expect(formatV4Value('spokeConfig', 'addCap', 1000000, ctx)).toBe('1,000,000 (1e6)');
    // Small caps (< 1000) skip the exponential
    expect(formatV4Value('spokeConfig', 'addCap', 500, capCtx)).toBe('500 USDT');
    // IHub sentinel (type(uint40).max) renders as "no cap" rather than a literal limit
    const MAX_SPOKE_CAP = 2 ** 40 - 1;
    expect(formatV4Value('spokeConfig', 'addCap', MAX_SPOKE_CAP, capCtx)).toBe(
      'sentinel value - no cap'
    );
    expect(formatV4Value('spokeConfig', 'drawCap', MAX_SPOKE_CAP, capCtx)).toBe(
      'sentinel value - no cap'
    );
    // riskPremiumThreshold sentinel (type(uint24).max) renders as "no threshold"
    const MAX_RISK_THRESHOLD = 2 ** 24 - 1;
    expect(formatV4Value('spokeConfig', 'riskPremiumThreshold', MAX_RISK_THRESHOLD, capCtx)).toBe(
      'sentinel value - no threshold'
    );
  });

  it('formats numeric-string fields (oraclePrice, swept, premiumShares) with separators + exp', () => {
    // Price feed: uint256 oracle price serialized as string — full precision in exp
    expect(formatV4Value('spokeReserve', 'oraclePrice', '99999850', ctx)).toBe(
      '99,999,850 (9.999985e7)'
    );
    expect(formatV4Value('spokeReserve', 'oraclePrice', '150000000', ctx)).toBe(
      '150,000,000 (1.5e8)'
    );
    // Sub-1000 trailing digits stay (1234 -> 1.234e3, not 1.23e3)
    expect(formatV4Value('spokeReserve', 'oraclePrice', '1234', ctx)).toBe('1,234 (1.234e3)');
    // uint120 hub-asset state fields, including values that exceed JS safe-int range.
    // Comma-separated form preserves exact value; exponent's mantissa is rounded by Number.
    expect(formatV4Value('hubAsset', 'swept', '12345678901234567890', ctx)).toBe(
      '12,345,678,901,234,567,890 (1.2345678901234567e19)'
    );
    expect(formatV4Value('hubAsset', 'premiumShares', '1000000', ctx)).toBe('1,000,000 (1e6)');
    // Small numbers (< 1000) — no separators, no exponential
    expect(formatV4Value('spokeReserve', 'oraclePrice', '999', ctx)).toBe('999');
    // Zero
    expect(formatV4Value('hubAsset', 'swept', '0', ctx)).toBe('0');
  });
});

// --- Diff ---

describe('diffV4Snapshots', () => {
  it('returns no-change message for identical snapshots', async () => {
    const snap = makeSnapshot();
    const result = await diffV4Snapshots(snap, snap);
    expect(result).toBe('No configuration changes detected.\n');
  });

  it('detects spoke reserve changes', async () => {
    const before = makeSnapshot();
    const after = makeSnapshot();
    after.spokeReserves[SPOKE_ADDR]['0'] = {
      ...after.spokeReserves[SPOKE_ADDR]['0'],
      collateralFactor: 7500,
      frozen: true,
    };

    const md = await diffV4Snapshots(before, after);
    expect(md).toContain('## Spoke Reserve Changes');
    expect(md).toContain('WETH');
    expect(md).toContain('collateralFactor');
    expect(md).toContain('80.00 % [8000]');
    expect(md).toContain('75.00 % [7500]');
    expect(md).toContain('frozen');
  });

  it('detects new spoke reserve', async () => {
    const before = makeSnapshot();
    const after = makeSnapshot();
    after.spokeReserves[SPOKE_ADDR]['1'] = {
      symbol: 'USDC',
      underlying: '0x9999999999999999999999999999999999999999',
      hub: HUB_ADDR,
      assetId: 1,
      decimals: 6,
      collateralRisk: 50,
      paused: false,
      frozen: false,
      borrowable: true,
      receiveSharesEnabled: false,
      dynamicConfigKey: 0,
      collateralFactor: 8500,
      maxLiquidationBonus: 400,
      liquidationFee: 50,
      oracleAddress: ORACLE_ADDR,
      priceSource: PRICE_SRC,
      oraclePrice: '100000000',
    };

    const md = await diffV4Snapshots(before, after);
    expect(md).toContain('NEW RESERVE');
    expect(md).toContain('USDC');
  });

  it('detects removed spoke reserve', async () => {
    const before = makeSnapshot();
    const after = makeSnapshot();
    delete after.spokeReserves[SPOKE_ADDR]['0'];
    after.spokeReserves[SPOKE_ADDR] = {};

    const md = await diffV4Snapshots(before, after);
    expect(md).toContain('REMOVED');
    expect(md).toContain('WETH');
  });

  it('detects hub asset changes', async () => {
    const before = makeSnapshot();
    const after = makeSnapshot();
    after.hubAssets[HUB_ADDR]['0'] = {
      ...after.hubAssets[HUB_ADDR]['0'],
      baseDrawnRate: 200,
      optimalUsageRatio: 7500,
    };

    const md = await diffV4Snapshots(before, after);
    expect(md).toContain('## Hub Asset Changes');
    expect(md).toContain('baseDrawnRate');
    expect(md).toContain('optimalUsageRatio');
  });

  it('detects spoke cap changes', async () => {
    const before = makeSnapshot();
    const after = makeSnapshot();
    const capKey = `${HUB_ADDR}_0_${SPOKE_ADDR}`;
    after.spokeConfigs[capKey] = {
      ...after.spokeConfigs[capKey],
      addCap: 2000000,
      halted: true,
    };

    const md = await diffV4Snapshots(before, after);
    expect(md).toContain('## Hub Spoke Config Changes');
    expect(md).toContain('addCap');
    expect(md).toContain('halted');
  });

  it('detects spoke liquidation config changes', async () => {
    const before = makeSnapshot();
    const after = makeSnapshot();
    after.spokeLiquidationConfigs[SPOKE_ADDR] = {
      ...after.spokeLiquidationConfigs[SPOKE_ADDR],
      liquidationBonusFactor: 600,
    };

    const md = await diffV4Snapshots(before, after);
    expect(md).toContain('## Spoke Liquidation Config Changes');
    expect(md).toContain('liquidationBonusFactor');
  });

  it('includes raw JSON diff section', async () => {
    const before = makeSnapshot();
    const after = makeSnapshot();
    after.spokeReserves[SPOKE_ADDR]['0'] = {
      ...after.spokeReserves[SPOKE_ADDR]['0'],
      collateralFactor: 7500,
    };

    const md = await diffV4Snapshots(before, after);
    expect(md).toContain('## Raw diff');
    expect(md).toContain('```json');
  });

  // --- New/removed for all section types ---

  it('detects new hub asset', async () => {
    const before = makeSnapshot();
    const after = makeSnapshot();
    after.hubAssets[HUB_ADDR]['1'] = {
      symbol: 'USDC',
      underlying: '0x9999999999999999999999999999999999999999',
      decimals: 6,
      liquidityFee: 1500,
      irStrategy: IR_STRATEGY,
      feeReceiver: FEE_RECV,
      reinvestmentController: REINVEST,
      optimalUsageRatio: 9200,
      baseDrawnRate: 0,
      rateGrowthBeforeOptimal: 450,
      rateGrowthAfterOptimal: 2000,
      maxDrawnRate: '2450',
      deficitRay: '0',
      swept: '0',
      premiumShares: '0',
      premiumOffsetRay: '0',
    };

    const md = await diffV4Snapshots(before, after);
    expect(md).toContain('## Hub Asset Changes');
    expect(md).toContain('NEW ASSET');
    expect(md).toContain('USDC');
  });

  it('detects removed hub asset', async () => {
    const before = makeSnapshot();
    const after = makeSnapshot();
    after.hubAssets[HUB_ADDR] = {};

    const md = await diffV4Snapshots(before, after);
    expect(md).toContain('## Hub Asset Changes');
    expect(md).toContain('REMOVED');
  });

  it('detects new spoke cap', async () => {
    const before = makeSnapshot();
    const after = makeSnapshot();
    const newCapKey = `${HUB_ADDR}_1_${SPOKE_ADDR}`;
    after.spokeConfigs[newCapKey] = {
      assetSymbol: 'USDC',
      addCap: 500000,
      drawCap: 250000,
      riskPremiumThreshold: 50,
      active: true,
      halted: false,
    };

    const md = await diffV4Snapshots(before, after);
    expect(md).toContain('## Hub Spoke Config Changes');
    expect(md).toContain('NEW SPOKE');
    expect(md).toContain('USDC');
  });

  it('detects removed spoke cap', async () => {
    const before = makeSnapshot();
    const after = makeSnapshot();
    const capKey = `${HUB_ADDR}_0_${SPOKE_ADDR}`;
    delete after.spokeConfigs[capKey];

    const md = await diffV4Snapshots(before, after);
    expect(md).toContain('## Hub Spoke Config Changes');
    expect(md).toContain('REMOVED');
  });

  it('detects new spoke liquidation config', async () => {
    const before = makeSnapshot();
    const after = makeSnapshot();
    const newSpoke = '0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
    after.spokeLiquidationConfigs[newSpoke] = {
      targetHealthFactor: '1100000000000000000',
      healthFactorForMaxBonus: '1050000000000000000',
      liquidationBonusFactor: 400,
      maxUserReservesLimit: 64,
    };

    const md = await diffV4Snapshots(before, after);
    expect(md).toContain('## Spoke Liquidation Config Changes');
    expect(md).toContain('NEW');
  });

  it('detects removed spoke liquidation config', async () => {
    const before = makeSnapshot();
    const after = makeSnapshot();
    delete after.spokeLiquidationConfigs[SPOKE_ADDR];

    const md = await diffV4Snapshots(before, after);
    expect(md).toContain('## Spoke Liquidation Config Changes');
    expect(md).toContain('REMOVED');
  });

  // --- Hub asset state fields ---

  it('detects hub asset state changes (deficit, swept, premiumShares)', async () => {
    const before = makeSnapshot();
    const after = makeSnapshot();
    after.hubAssets[HUB_ADDR]['0'] = {
      ...after.hubAssets[HUB_ADDR]['0'],
      deficitRay: '1000000000000000000000000000',
      swept: '5000000',
      premiumShares: '100000',
      premiumOffsetRay: '-500000000000000000000000000',
    };

    const md = await diffV4Snapshots(before, after);
    expect(md).toContain('## Hub Asset Changes');
    expect(md).toContain('deficitRay');
    expect(md).toContain('swept');
    expect(md).toContain('premiumShares');
    expect(md).toContain('premiumOffsetRay');
  });

  // --- Spoke cap composite key parsing ---

  it('parses spoke cap composite key correctly in headers', async () => {
    const before = makeSnapshot();
    const after = makeSnapshot();
    const capKey = `${HUB_ADDR}_0_${SPOKE_ADDR}`;
    after.spokeConfigs[capKey] = {
      ...after.spokeConfigs[capKey],
      addCap: 9999999,
    };

    const md = await diffV4Snapshots(before, after);
    // Header should contain the hub and spoke addresses from the parsed key
    expect(md).toContain(HUB_ADDR);
    expect(md).toContain(SPOKE_ADDR);
    expect(md).toContain('assetId: 0');
  });
});
