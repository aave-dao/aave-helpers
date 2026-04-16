import { describe, it, expect } from 'vitest';
import { diffV4Snapshots } from '../protocol-diff-v4';
import { aaveV4SnapshotSchema, type AaveV4Snapshot } from '../snapshot-types-v4';
import { formatBps } from '../formatters-v4';

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
        },
      },
    },
    spokeCaps: {
      [`${HUB_ADDR}_0_${SPOKE_ADDR}`]: {
        assetSymbol: 'WETH',
        addCap: '1000000',
        drawCap: '500000',
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

describe('formatBps', () => {
  it('formats 8000 as 80.00 %', () => {
    expect(formatBps(8000)).toBe('80.00 % [8000]');
  });

  it('formats 100 as 1.00 %', () => {
    expect(formatBps(100)).toBe('1.00 % [100]');
  });

  it('formats 50 as 0.50 %', () => {
    expect(formatBps(50)).toBe('0.50 % [50]');
  });

  it('formats 5 as 0.05 %', () => {
    expect(formatBps(5)).toBe('0.05 % [5]');
  });

  it('formats 0 as 0.00 %', () => {
    expect(formatBps(0)).toBe('0.00 % [0]');
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
    after.spokeCaps[capKey] = {
      ...after.spokeCaps[capKey],
      addCap: '2000000',
      halted: true,
    };

    const md = await diffV4Snapshots(before, after);
    expect(md).toContain('## Hub Spoke Cap Changes');
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
});
