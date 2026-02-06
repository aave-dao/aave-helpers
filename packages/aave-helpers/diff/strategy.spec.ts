import { describe, it, expect } from 'vitest';
import { renderStrategy, renderStrategyDiff, renderStrategyValue } from '../diff/strategy';
import { AaveV3Strategy } from '../diff/snapshot-types';

describe('strategy rendering', () => {
  const mockStrategy: AaveV3Strategy = {
    address: '0x1234567890123456789012345678901234567890',
    optimalUsageRatio: '800000000000000000000000000',
    baseVariableBorrowRate: '0',
    variableRateSlope1: '40000000000000000000000000',
    variableRateSlope2: '800000000000000000000000000',
    maxVariableBorrowRate: '840000000000000000000000000',
  };

  describe('renderStrategyValue', () => {
    it('should format strategy values as percentages', () => {
      const result = renderStrategyValue('optimalUsageRatio', mockStrategy);
      expect(result).toContain('%');
    });

    it('should handle undefined values', () => {
      const strategy = { ...mockStrategy, baseVariableBorrowRate: undefined };
      const result = renderStrategyValue('baseVariableBorrowRate', strategy as any);
      expect(result).toBe('/');
    });

    it('should handle null values', () => {
      const strategy = { ...mockStrategy, baseVariableBorrowRate: null };
      const result = renderStrategyValue('baseVariableBorrowRate', strategy as any);
      expect(result).toBe('/');
    });
  });

  describe('renderStrategy', () => {
    it('should render a complete strategy', () => {
      const result = renderStrategy(mockStrategy);

      // Should be markdown table rows
      expect(result).toContain('|');

      // Should contain strategy properties
      expect(result).toContain('optimalUsageRatio');
      expect(result).toContain('baseVariableBorrowRate');
      expect(result).toContain('variableRateSlope1');
      expect(result).toContain('variableRateSlope2');

      // Should not contain address (it's omitted)
      expect(result).not.toContain('| address |');
    });

    it('should match snapshot', () => {
      const result = renderStrategy(mockStrategy);
      expect(result).toMatchSnapshot();
    });
  });

  describe('renderStrategyDiff', () => {
    it('should render diff for changed values', () => {
      const diff = {
        address: '0x1234567890123456789012345678901234567890',
        optimalUsageRatio: {
          from: '800000000000000000000000000',
          to: '850000000000000000000000000',
        },
        variableRateSlope1: {
          from: '40000000000000000000000000',
          to: '45000000000000000000000000',
        },
        baseVariableBorrowRate: '0',
        variableRateSlope2: '800000000000000000000000000',
        maxVariableBorrowRate: '840000000000000000000000000',
      };

      const result = renderStrategyDiff(diff as any);

      // Should contain changed properties
      expect(result).toContain('optimalUsageRatio');
      expect(result).toContain('variableRateSlope1');

      // Should be in diff format with before/after columns
      expect(result).toContain('|');
    });

    it('should only include changed values', () => {
      const diff = {
        optimalUsageRatio: {
          from: '800000000000000000000000000',
          to: '850000000000000000000000000',
        },
        baseVariableBorrowRate: '0', // unchanged
      };

      const result = renderStrategyDiff(diff as any);

      // Should contain changed value
      expect(result).toContain('optimalUsageRatio');

      // Should not show address
      expect(result).not.toContain('address');
    });

    it('should match snapshot', () => {
      const diff = {
        optimalUsageRatio: {
          from: '800000000000000000000000000',
          to: '900000000000000000000000000',
        },
        variableRateSlope1: {
          from: '40000000000000000000000000',
          to: '50000000000000000000000000',
        },
        variableRateSlope2: {
          from: '800000000000000000000000000',
          to: '1000000000000000000000000000',
        },
      };

      const result = renderStrategyDiff(diff as any);
      expect(result).toMatchSnapshot();
    });
  });
});
