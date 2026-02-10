import { describe, it, expect } from 'vitest';
import { readFileSync } from 'fs';
import { resolve } from 'path';
import { diffSnapshots } from '../protocol-diff';
import { diff, isChange, hasChanges } from '../diff';
import { formatValue, type FormatterContext } from '../formatters';

const before = JSON.parse(
  readFileSync(resolve(__dirname, '../../../reports/default_before.json'), 'utf-8')
);
const after = JSON.parse(
  readFileSync(resolve(__dirname, '../../../reports/default_after.json'), 'utf-8')
);

describe('diff utility', () => {
  it('detects no changes for identical objects', () => {
    const result = diff({ a: 1, b: 'hello' }, { a: 1, b: 'hello' }, true);
    expect(Object.keys(result)).toHaveLength(0);
  });

  it('detects changed primitives', () => {
    const result = diff({ a: 1 }, { a: 2 });
    expect(isChange(result.a)).toBe(true);
    expect(result.a).toEqual({ from: 1, to: 2 });
  });

  it('detects added keys', () => {
    const result = diff({}, { a: 1 });
    expect(result.a).toEqual({ from: null, to: 1 });
  });

  it('detects removed keys', () => {
    const result = diff({ a: 1 }, {});
    expect(result.a).toEqual({ from: 1, to: null });
  });

  it('recurses into nested objects', () => {
    const result = diff({ nested: { a: 1 } }, { nested: { a: 2 } });
    expect(result.nested.a).toEqual({ from: 1, to: 2 });
  });

  it('hasChanges returns true when there are changes', () => {
    const result = diff({ a: 1 }, { a: 2 });
    expect(hasChanges(result)).toBe(true);
  });

  it('hasChanges returns false for identical objects', () => {
    const result = diff({ a: 1 }, { a: 1 });
    expect(hasChanges(result)).toBe(false);
  });
});

describe('formatters', () => {
  const ctx: FormatterContext = {
    chainId: 1,
    reserve: {
      id: 0,
      symbol: 'WETH',
      underlying: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
      decimals: 18,
      isActive: true,
      isFrozen: false,
      isPaused: false,
      isSiloed: false,
      isFlashloanable: true,
      isBorrowableInIsolation: false,
      borrowingEnabled: true,
      usageAsCollateralEnabled: true,
      ltv: 8250,
      liquidationThreshold: 8600,
      liquidationBonus: 10500,
      liquidationProtocolFee: 1000,
      reserveFactor: 1500,
      supplyCap: 2000000,
      borrowCap: 1400000,
      debtCeiling: 0,
      oracle: '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419',
      oracleDecimals: 8,
      oracleDescription: 'ETH / USD',
      oracleLatestAnswer: '250000000000',
      interestRateStrategy: '0x9ec6F08190DeA04A54f8Afc53Db96134e5E3FdFB',
      aToken: '0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8',
      aTokenName: 'Aave Ethereum WETH',
      aTokenSymbol: 'aEthWETH',
      aTokenUnderlyingBalance: '1000000000000000000000',
      variableDebtToken: '0xeA51d7853EEFb32b6ee06b1C12E6dcCA88Be0fFE',
      variableDebtTokenName: 'Aave Ethereum Variable Debt WETH',
      variableDebtTokenSymbol: 'variableDebtEthWETH',
      virtualBalance: '1000000000000000000000',
    },
  };

  it('formats ltv as percentage', () => {
    expect(formatValue('reserve', 'ltv', 8250, ctx)).toContain('82.5 %');
  });

  it('formats liquidationBonus with 10000 offset', () => {
    expect(formatValue('reserve', 'liquidationBonus', 10500, ctx)).toBe('5 %');
  });

  it('formats supplyCap with symbol', () => {
    expect(formatValue('reserve', 'supplyCap', 2000000, ctx)).toContain('WETH');
  });

  it('formats oracleLatestAnswer with decimals', () => {
    expect(formatValue('reserve', 'oracleLatestAnswer', '250000000000', ctx)).toBe('2500');
  });

  it('formats strategy rate as percentage', () => {
    const result = formatValue('strategy', 'baseVariableBorrowRate', '10000000000000000000000000', {
      chainId: 1,
    });
    expect(result).toContain('1');
    expect(result).toContain('%');
  });

  it('formats emode ltv as percentage', () => {
    expect(formatValue('emode', 'ltv', 9300, { chainId: 1 })).toBe('93 %');
  });

  it('formats emode liquidationBonus', () => {
    expect(formatValue('emode', 'liquidationBonus', 10100, { chainId: 1 })).toBe('1 %');
  });
});

describe('diffSnapshots', () => {
  it('produces a markdown report', () => {
    const result = diffSnapshots(before, after);
    expect(result).toMatchInlineSnapshot(`
      "## Raw storage changes

      ### 0xdabad81af85554e9ae636395611c58f7ec1aaec5 (GovernanceV3Ethereum.PAYLOADS_CONTROLLER)

      | slot | previous value | new value |
      | --- | --- | --- |
      | 0xb37666113f25c36e5647d28f516926089a55950439f4c66b538876823712f8aa | 0x006866b53a000000000002000000000000000000000000000000000000000000 | 0x006866b53a000000000003000000000000000000000000000000000000000000 |
      | 0xb37666113f25c36e5647d28f516926089a55950439f4c66b538876823712f8ab | 0x000000000000000000093a800000000000006894d9bb00000000000000000000 | 0x000000000000000000093a800000000000006894d9bb0000000000006866b53b |


      ## Event logs

      | index | emitter | topics | data |
      | --- | --- | --- | --- |
      | 0 | 0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A | \`0x24ec1d3ff24c2f6ff210738839dbc339cd45a5294d85c79361016243157aae7b\` | \`0x\` |
      | 1 | 0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A | \`0x528c26f4cc05f95dc8bad30284946548f08ec44f7dd536473f28b08c65334cdd\`, \`0x0000000000000000000000005615deb798bb3e4dfa0139dfa1b3d433cc23b72f\` | \`0x0000000000000000000000000000000000000000000000000000000000000000...\` |
      | 2 | 0xdAbad81aF85554E9ae636395611C58F7eC1aAEc5 | \`0xda6084bb0aa902a7f6da10ba185d4aa129414651c90772417eff02a52112af2a\` | \`0x0000000000000000000000000000000000000000000000000000000000000139\` |

      ## Raw diff

      \`\`\`json
      {
        "raw": {
          "0xdabad81af85554e9ae636395611c58f7ec1aaec5": {
            "label": null,
            "contract": null,
            "balanceDiff": null,
            "nonceDiff": null,
            "stateDiff": {
              "0xb37666113f25c36e5647d28f516926089a55950439f4c66b538876823712f8aa": {
                "previousValue": "0x006866b53a000000000002000000000000000000000000000000000000000000",
                "newValue": "0x006866b53a000000000003000000000000000000000000000000000000000000"
              },
              "0xb37666113f25c36e5647d28f516926089a55950439f4c66b538876823712f8ab": {
                "previousValue": "0x000000000000000000093a800000000000006894d9bb00000000000000000000",
                "newValue": "0x000000000000000000093a800000000000006894d9bb0000000000006866b53b"
              }
            }
          }
        },
        "logs": [
          {
            "topics": [
              "0x24ec1d3ff24c2f6ff210738839dbc339cd45a5294d85c79361016243157aae7b"
            ],
            "data": "0x",
            "emitter": "0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A"
          },
          {
            "topics": [
              "0x528c26f4cc05f95dc8bad30284946548f08ec44f7dd536473f28b08c65334cdd",
              "0x0000000000000000000000005615deb798bb3e4dfa0139dfa1b3d433cc23b72f"
            ],
            "data": "0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000006866b53b000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000009657865637574652829000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "emitter": "0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A"
          },
          {
            "topics": [
              "0xda6084bb0aa902a7f6da10ba185d4aa129414651c90772417eff02a52112af2a"
            ],
            "data": "0x0000000000000000000000000000000000000000000000000000000000000139",
            "emitter": "0xdAbad81aF85554E9ae636395611C58F7eC1aAEc5"
          }
        ]
      }
      \`\`\`
      "
    `);
  });

  it('contains expected sections', () => {
    const result = diffSnapshots(before, after);
    expect(result).toContain('## Raw storage changes');
    expect(result).toContain('## Event logs');
    expect(result).toContain('## Raw diff');
  });

  it('renders reserve changes when reserves differ', () => {
    const modifiedAfter = JSON.parse(JSON.stringify(after));
    // Change the LTV of the first reserve
    const firstKey = Object.keys(modifiedAfter.reserves)[0];
    modifiedAfter.reserves[firstKey].ltv = 6000;
    const result = diffSnapshots(before, modifiedAfter);
    expect(result).toContain('## Reserve changes');
    expect(result).toContain('### Reserves altered');
    expect(result).toContain('value before');
    expect(result).toContain('value after');
  });

  it('renders added reserves', () => {
    const modifiedAfter = JSON.parse(JSON.stringify(after));
    modifiedAfter.reserves['0x0000000000000000000000000000000000000001'] = {
      ...modifiedAfter.reserves[Object.keys(modifiedAfter.reserves)[0]],
      symbol: 'NEW_TOKEN',
      underlying: '0x0000000000000000000000000000000000000001',
    };
    const result = diffSnapshots(before, modifiedAfter);
    expect(result).toContain('### Reserves added');
    expect(result).toContain('NEW_TOKEN');
  });
});
