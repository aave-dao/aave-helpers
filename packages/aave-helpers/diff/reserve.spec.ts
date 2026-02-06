import { describe, it, expect } from 'vitest';
import { renderReserve, renderReserveDiff, renderReserveValue } from '../diff/reserve';
import { AaveV3Reserve } from '../diff/snapshot-types';

describe('reserve rendering', () => {
  const mockReserve: AaveV3Reserve = {
    symbol: 'WETH',
    underlying: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
    decimals: 18,
    isActive: true,
    isFrozen: false,
    supplyCap: 1000000,
    borrowCap: 800000,
    debtCeiling: 0,
    isSiloed: false,
    isFlashloanable: true,
    eModeCategory: 1,
    ltv: 8000,
    liquidationThreshold: 8500,
    liquidationBonus: 10500,
    liquidationProtocolFee: 1000,
    reserveFactor: 1500,
    usageAsCollateralEnabled: true,
    borrowingEnabled: true,
    stableBorrowRateEnabled: false,
    isBorrowableInIsolation: false,
    interestRateStrategy: '0x1234567890123456789012345678901234567890',
    aToken: '0xabcd567890123456789012345678901234567890',
    aTokenImpl: '0xef01234567890123456789012345678901234567',
    stableDebtToken: '0x1111111111111111111111111111111111111111',
    stableDebtTokenImpl: '0x2222222222222222222222222222222222222222',
    variableDebtToken: '0x3333333333333333333333333333333333333333',
    variableDebtTokenImpl: '0x4444444444444444444444444444444444444444',
    liquidityIndex: 1000000000000000000000000000,
    variableBorrowIndex: 1010000000000000000000000000,
    currentLiquidityRate: 0,
    currentVariableBorrowRate: 0,
    aTokenUnderlyingBalance: '1000000000000000000000',
    oracleLatestAnswer: '100000000000',
    oracle: '0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419',
    oracleDecimals: 8,
    oracleName: 'ETH / USD',
    oracleDescription: 'ETH / USD',
    virtualAccountingActive: false,
    virtualBalance: '0',
    id: 0,
  };

  describe('renderReserveValue', () => {
    it('should format percentage values correctly', () => {
      const result = renderReserveValue('ltv', mockReserve, 1);
      expect(result).toContain('80');
      expect(result).toContain('%');
    });

    it('should format supply cap with symbol', () => {
      const result = renderReserveValue('supplyCap', mockReserve, 1);
      expect(result).toContain('1,000,000');
      expect(result).toContain('WETH');
    });

    it('should format borrow cap with symbol', () => {
      const result = renderReserveValue('borrowCap', mockReserve, 1);
      expect(result).toContain('800,000');
      expect(result).toContain('WETH');
    });

    it('should format liquidation bonus correctly', () => {
      const result = renderReserveValue('liquidationBonus', mockReserve, 1);
      expect(result).toContain('5');
      expect(result).toContain('%');
    });

    it('should handle address values', () => {
      const result = renderReserveValue('interestRateStrategy', mockReserve, 1);
      expect(result).toBeTruthy();
      // Should return a link or formatted address
    });

    it('should handle boolean values', () => {
      expect(renderReserveValue('isActive', mockReserve, 1)).toBe(true);
      expect(renderReserveValue('isFrozen', mockReserve, 1)).toBe(false);
    });
  });

  describe('renderReserve', () => {
    it('should render a complete reserve', () => {
      const result = renderReserve(mockReserve, 1);

      // Should contain header with symbol
      expect(result).toContain('WETH');

      // Should be markdown table format
      expect(result).toContain('|');
      expect(result).toContain('description');
      expect(result).toContain('value');

      // Should contain key properties
      expect(result).toContain('ltv');
      expect(result).toContain('liquidationThreshold');
    });

    it('should match snapshot', () => {
      const result = renderReserve(mockReserve, 1);
      expect(result).toMatchSnapshot();
    });
  });

  describe('renderReserveDiff', () => {
    it('should render diff for changed values', () => {
      const diff = {
        symbol: 'WETH',
        underlying: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
        ltv: { from: 8000, to: 8100 },
        liquidationThreshold: { from: 8500, to: 8600 },
        supplyCap: { from: 1000000, to: 1200000 },
        borrowCap: 800000,
        decimals: 18,
      };

      const result = renderReserveDiff(diff as any, 1);

      // Should contain header
      expect(result).toContain('WETH');

      // Should be diff table format
      expect(result).toContain('value before');
      expect(result).toContain('value after');

      // Should contain changed values
      expect(result).toContain('ltv');
      expect(result).toContain('liquidationThreshold');
      expect(result).toContain('supplyCap');
    });

    it('should match snapshot for complex diff', () => {
      const diff = {
        symbol: 'USDC',
        underlying: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
        decimals: 6,
        ltv: { from: 7500, to: 8000 },
        liquidationThreshold: { from: 8000, to: 8500 },
        supplyCap: { from: 2000000000, to: 2500000000 },
        reserveFactor: { from: 1000, to: 1500 },
        isActive: true,
      };

      const result = renderReserveDiff(diff as any, 1);
      expect(result).toMatchSnapshot();
    });
  });
});
