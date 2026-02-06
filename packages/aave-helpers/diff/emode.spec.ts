import { describe, it, expect } from 'vitest';
import { renderEmodeDiff, renderEModeValue } from '../diff/emode';
import { AaveV3Emode, AaveV3Snapshot } from '../diff/snapshot-types';

describe('emode rendering', () => {
  const mockSnapshot: AaveV3Snapshot = {
    chainId: 1,
    reserves: {
      WETH: {
        id: 0,
        symbol: 'WETH',
        underlying: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
        decimals: 18,
      } as any,
      wstETH: {
        id: 1,
        symbol: 'wstETH',
        underlying: '0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0',
        decimals: 18,
      } as any,
    },
    strategies: {},
    eModes: {},
    poolConfig: {} as any,
  };

  const mockEmode: AaveV3Emode = {
    eModeCategory: 1,
    label: 'ETH correlated',
    ltv: 9300,
    liquidationThreshold: 9500,
    liquidationBonus: 10100,
    priceSource: '0x0000000000000000000000000000000000000000',
    borrowableBitmap: '1',
    collateralBitmap: '3',
  };

  describe('renderEModeValue', () => {
    it('should format percentage values correctly', () => {
      const result = renderEModeValue('ltv', mockEmode, mockSnapshot);
      expect(result).toContain('%');
    });

    it('should format liquidation bonus correctly', () => {
      const result = renderEModeValue('liquidationBonus', mockEmode, mockSnapshot);
      expect(result).toContain('1');
      expect(result).toContain('%');
    });

    it('should handle zero liquidation bonus', () => {
      const emode = { ...mockEmode, liquidationBonus: 0 };
      const result = renderEModeValue('liquidationBonus', emode, mockSnapshot);
      expect(result).toBe('0 %');
    });

    it('should render borrowable bitmap as symbols', () => {
      const result = renderEModeValue('borrowableBitmap', mockEmode, mockSnapshot);
      expect(result).toContain('WETH'); // id 0, bit 0 set
    });

    it('should render collateral bitmap as symbols', () => {
      const result = renderEModeValue('collateralBitmap', mockEmode, mockSnapshot);
      // Bitmap 3 = 0b11, so both id 0 and 1
      expect(result).toContain('WETH');
      expect(result).toContain('wstETH');
    });

    it('should handle empty values', () => {
      const emode = { ...mockEmode, label: '' };
      const result = renderEModeValue('label', emode, mockSnapshot);
      expect(result).toBe('-');
    });

    it('should return value as-is for simple properties', () => {
      const result = renderEModeValue('label', mockEmode, mockSnapshot);
      expect(result).toBe('ETH correlated');
    });
  });

  describe('renderEmodeDiff', () => {
    it('should render diff for changed emode', () => {
      const diff = {
        eModeCategory: 1,
        label: 'ETH correlated',
        ltv: { from: 9300, to: 9400 },
        liquidationThreshold: { from: 9500, to: 9600 },
        liquidationBonus: 10100,
        priceSource: '0x0000000000000000000000000000000000000000',
      };

      const result = renderEmodeDiff(diff as any, mockSnapshot, mockSnapshot);

      // Should be diff table format
      expect(result).toContain('value before');
      expect(result).toContain('value after');

      // Should contain changed values
      expect(result).toContain('eMode.ltv');
      expect(result).toContain('eMode.liquidationThreshold');
    });

    it('should show unchanged values', () => {
      const diff = {
        eModeCategory: 1,
        label: 'ETH correlated',
        ltv: { from: 9300, to: 9400 },
        liquidationBonus: 10100, // unchanged
      };

      const result = renderEmodeDiff(diff as any, mockSnapshot, mockSnapshot);

      // Should show unchanged with notation
      expect(result).toContain('(unchanged)');
    });

    it('should sort keys in the correct order', () => {
      const diff = {
        priceSource: '0x0000000000000000000000000000000000000000',
        ltv: { from: '9300', to: '9400' },
        label: 'ETH correlated',
        eModeCategory: 1,
      };

      const result = renderEmodeDiff(diff as any, mockSnapshot, mockSnapshot);

      // Check order by finding indices
      const labelIndex = result.indexOf('eMode.label');
      const ltvIndex = result.indexOf('eMode.ltv');
      const priceIndex = result.indexOf('eMode.priceSource');

      // label should come before ltv, which should come before priceSource
      expect(labelIndex).toBeLessThan(ltvIndex);
      expect(ltvIndex).toBeLessThan(priceIndex);
    });

    it('should not include eModeCategory in output', () => {
      const diff = {
        eModeCategory: { from: 1, to: 2 },
        label: 'ETH correlated',
      };

      const result = renderEmodeDiff(diff as any, mockSnapshot, mockSnapshot);

      // eModeCategory is in OMIT_KEYS
      expect(result).not.toContain('eModeCategory');
    });

    it('should match snapshot', () => {
      const diff = {
        eModeCategory: 1,
        label: 'ETH correlated',
        ltv: { from: 9300, to: 9400 },
        liquidationThreshold: { from: 9500, to: 9600 },
        liquidationBonus: { from: 10100, to: 10200 },
        borrowableBitmap: { from: '1', to: '3' },
      };

      const result = renderEmodeDiff(diff as any, mockSnapshot, mockSnapshot);
      expect(result).toMatchSnapshot();
    });
  });
});
