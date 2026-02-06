import { describe, it, expect } from 'vitest';
import { diff } from '../diff/diff';

describe('diff utility', () => {
  describe('basic object diffing', () => {
    it('should detect added properties', () => {
      const a = { foo: 'bar' };
      const b = { foo: 'bar', baz: 'qux' };

      const result = diff(a, b);

      expect(result.baz).toEqual({ from: null, to: 'qux' });
    });

    it('should detect removed properties', () => {
      const a = { foo: 'bar', baz: 'qux' };
      const b = { foo: 'bar' };

      const result = diff(a, b);

      expect(result.baz).toEqual({ from: 'qux', to: null });
    });

    it('should detect changed properties', () => {
      const a = { foo: 'bar' };
      const b = { foo: 'changed' };

      const result = diff(a, b);

      expect(result.foo).toEqual({ from: 'bar', to: 'changed' });
    });

    it('should keep unchanged properties when removeUnchanged is false', () => {
      const a = { foo: 'bar', baz: 'same' };
      const b = { foo: 'changed', baz: 'same' };

      const result = diff(a, b, false);

      expect(result.baz).toBe('same');
    });

    it('should remove unchanged properties when removeUnchanged is true', () => {
      const a = { foo: 'bar', baz: 'same' };
      const b = { foo: 'changed', baz: 'same' };

      const result = diff(a, b, true);

      expect(result.baz).toBeUndefined();
    });
  });

  describe('nested object diffing', () => {
    it('should handle nested objects', () => {
      const a = {
        outer: {
          inner: 'value1',
          unchanged: 'same',
        },
      };
      const b = {
        outer: {
          inner: 'value2',
          unchanged: 'same',
        },
      };

      const result = diff(a, b);

      expect(result.outer.inner).toEqual({ from: 'value1', to: 'value2' });
      expect(result.outer.unchanged).toBe('same');
    });

    it('should handle deeply nested changes', () => {
      const a = {
        level1: {
          level2: {
            level3: 'old',
          },
        },
      };
      const b = {
        level1: {
          level2: {
            level3: 'new',
          },
        },
      };

      const result = diff(a, b);

      expect(result.level1.level2.level3).toEqual({ from: 'old', to: 'new' });
    });

    it('should remove empty nested diffs when removeUnchanged is true', () => {
      const a = {
        unchanged: {
          nested: 'same',
        },
      };
      const b = {
        unchanged: {
          nested: 'same',
        },
      };

      const result = diff(a, b, true);

      // Empty objects should not be included
      expect(Object.keys(result)).toHaveLength(0);
    });
  });

  describe('complex scenarios', () => {
    it('should handle numeric values', () => {
      const a = { count: 1 };
      const b = { count: 2 };

      const result = diff(a, b);

      expect(result.count).toEqual({ from: 1, to: 2 });
    });

    it('should handle boolean values', () => {
      const a = { enabled: true };
      const b = { enabled: false };

      const result = diff(a, b);

      expect(result.enabled).toEqual({ from: true, to: false });
    });

    it('should handle mixed types', () => {
      const a = {
        string: 'text',
        number: 42,
        boolean: true,
        nested: { value: 'old' },
      };
      const b = {
        string: 'changed',
        number: 42,
        boolean: false,
        nested: { value: 'new' },
      };

      const result = diff(a, b);

      expect(result.string).toEqual({ from: 'text', to: 'changed' });
      expect(result.number).toBe(42);
      expect(result.boolean).toEqual({ from: true, to: false });
      expect(result.nested.value).toEqual({ from: 'old', to: 'new' });
    });

    it('should create snapshot for complex diff', () => {
      const a = {
        reserves: {
          WETH: { ltv: 8000, liquidationThreshold: 8500 },
          USDC: { ltv: 7500, liquidationThreshold: 8000 },
        },
        poolConfig: {
          flashLoanPremiumTotal: 9,
        },
      };
      const b = {
        reserves: {
          WETH: { ltv: 8100, liquidationThreshold: 8500 },
          USDC: { ltv: 7500, liquidationThreshold: 8000 },
          DAI: { ltv: 7500, liquidationThreshold: 8000 },
        },
        poolConfig: {
          flashLoanPremiumTotal: 10,
        },
      };

      const result = diff(a, b);

      expect(result).toMatchSnapshot();
    });
  });
});
