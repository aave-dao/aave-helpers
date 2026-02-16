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

const megaethBefore = JSON.parse(
  readFileSync(resolve(__dirname, '../../../reports/megaeth_before.json'), 'utf-8')
);
const megaethAfter = JSON.parse(
  readFileSync(resolve(__dirname, '../../../reports/megaeth_after.json'), 'utf-8')
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
    expect(formatValue('reserve', 'liquidationBonus', 10500, ctx)).toBe('5 % [10500]');
  });

  it('formats supplyCap with symbol', () => {
    expect(formatValue('reserve', 'supplyCap', 2000000, ctx)).toContain('WETH');
  });

  it('formats oracleLatestAnswer with decimals', () => {
    expect(formatValue('reserve', 'oracleLatestAnswer', '250000000000', ctx)).toBe('2500 $');
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
    expect(formatValue('emode', 'liquidationBonus', 10100, { chainId: 1 })).toBe('1 % [10100]');
  });
});

describe('diffSnapshots', () => {
  it('produces a markdown report', async () => {
    const result = await diffSnapshots(before, after);
    expect(result).toMatchInlineSnapshot(`
      "## Event logs

      #### 0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A (AaveV2Ethereum.POOL_ADMIN, AaveV2EthereumAMM.POOL_ADMIN, AaveV3Ethereum.ACL_ADMIN, AaveV3EthereumEtherFi.ACL_ADMIN, AaveV3EthereumHorizon.ACL_ADMIN, AaveV3EthereumLido.ACL_ADMIN, GovernanceV3Ethereum.EXECUTOR_LVL_1)

      | index | event |
      | --- | --- |
      | 0 | topics: \`0x24ec1d3ff24c2f6ff210738839dbc339cd45a5294d85c79361016243157aae7b\`, data: \`0x\` |
      | 1 | ExecutedAction(target: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, value: 0, signature: execute(), data: 0x, executionTime: 1751561531, withDelegatecall: true, resultData: 0x) |

      #### 0xdAbad81aF85554E9ae636395611C58F7eC1aAEc5 (GovernanceV3Ethereum.PAYLOADS_CONTROLLER)

      | index | event |
      | --- | --- |
      | 2 | PayloadExecuted(payloadId: 313) |

      ## Raw storage changes

      ### 0xdabad81af85554e9ae636395611c58f7ec1aaec5 (GovernanceV3Ethereum.PAYLOADS_CONTROLLER)

      | slot | previous value | new value |
      | --- | --- | --- |
      | 0xb37666113f25c36e5647d28f516926089a55950439f4c66b538876823712f8aa (_payloads[313]) | 0x006866b53a000000000002000000000000000000000000000000000000000000 | 0x006866b53a000000000003000000000000000000000000000000000000000000 |
      | 0xb37666113f25c36e5647d28f516926089a55950439f4c66b538876823712f8ab | 0x000000000000000000093a800000000000006894d9bb00000000000000000000 | 0x000000000000000000093a800000000000006894d9bb0000000000006866b53b |


      ## Raw diff

      \`\`\`json
      {}
      \`\`\`
      "
    `);
  });

  it('contains expected sections', async () => {
    const result = await diffSnapshots(before, after);
    expect(result).toContain('## Raw storage changes');
    expect(result).toContain('## Event logs');
    expect(result).toContain('## Raw diff');
  });

  it('renders reserve changes when reserves differ', async () => {
    const modifiedAfter = JSON.parse(JSON.stringify(after));
    // Change the LTV of the first reserve
    const firstKey = Object.keys(modifiedAfter.reserves)[0];
    modifiedAfter.reserves[firstKey].ltv = 6000;
    const result = await diffSnapshots(before, modifiedAfter);
    expect(result).toContain('## Reserve changes');
    expect(result).toContain('### Reserves altered');
    expect(result).toContain('value before');
    expect(result).toContain('value after');
  });

  it('renders added reserves', async () => {
    const modifiedAfter = JSON.parse(JSON.stringify(after));
    modifiedAfter.reserves['0x0000000000000000000000000000000000000001'] = {
      ...modifiedAfter.reserves[Object.keys(modifiedAfter.reserves)[0]],
      symbol: 'NEW_TOKEN',
      underlying: '0x0000000000000000000000000000000000000001',
    };
    const result = await diffSnapshots(before, modifiedAfter);
    expect(result).toContain('### Reserves added');
    expect(result).toContain('NEW_TOKEN');
  });

  it('megaeth new pool deployment', async () => {
    const result = await diffSnapshots(megaethBefore, megaethAfter);
    expect(result).toMatchInlineSnapshot(`
      "## Reserve changes

      ### Reserves added

      #### ezETH ([0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57](https://mega.etherscan.io/address/0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57))

      | description | value |
      | --- | --- |
      | id | 6 |
      | decimals | 18 |
      | isActive | :white_check_mark: |
      | isFrozen | :x: |
      | isPaused | :x: |
      | supplyCap | 20 ezETH |
      | borrowCap | 1 ezETH |
      | debtCeiling | 0 $ [0] |
      | isSiloed | :x: |
      | isFlashloanable | :white_check_mark: |
      | oracle | [0xd7Da71D3acf07C604A925799B0b48E2Ec607584D](https://mega.etherscan.io/address/0xd7Da71D3acf07C604A925799B0b48E2Ec607584D) |
      | oracleDecimals | 8 |
      | oracleDescription | Capped ezETH / ETH / USD |
      | oracleLatestAnswer | 2282.74433677 $ |
      | usageAsCollateralEnabled | :x: |
      | ltv | 0 % [0] |
      | liquidationThreshold | 0 % [0] |
      | liquidationBonus | 0 % |
      | liquidationProtocolFee | 10 % [1000] |
      | reserveFactor | 20 % [2000] |
      | aToken | [0x03C99Cce547b1c2E74442b73E6f588A66D19597e](https://mega.etherscan.io/address/0x03C99Cce547b1c2E74442b73E6f588A66D19597e) |
      | aTokenName | Aave MegaEth ezETH |
      | aTokenSymbol | aMegezETH |
      | variableDebtToken | [0x1505f48Bd4db0fF8B28817D2C0Fb95Abcb8eEbbc](https://mega.etherscan.io/address/0x1505f48Bd4db0fF8B28817D2C0Fb95Abcb8eEbbc) |
      | variableDebtTokenName | Aave MegaEth Variable Debt ezETH |
      | variableDebtTokenSymbol | variableDebtMegezETH |
      | borrowingEnabled | :x: |
      | isBorrowableInIsolation | :x: |
      | interestRateStrategy | [0x5cC4f782cFe249286476A7eFfD9D7bd215768194](https://mega.etherscan.io/address/0x5cC4f782cFe249286476A7eFfD9D7bd215768194) |
      | aTokenUnderlyingBalance | 0.0025 ezETH [2500000000000000] |
      | virtualBalance | 0.0025 ezETH [2500000000000000] |
      | optimalUsageRatio | 90 % |
      | maxVariableBorrowRate | 25 % |
      | baseVariableBorrowRate | 0 % |
      | variableRateSlope1 | 5 % |
      | variableRateSlope2 | 20 % |
      | interestRate | <pre lang="mermaid">xychart-beta&#13;title "Interest Rate Model"&#13;x-axis "Utilization (%)" [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100]&#13;y-axis "Rate (%)"&#13;line [0, 0.2777777777777778, 0.5555555555555556, 0.8333333333333334, 1.1111111111111112, 1.3888888888888888, 1.6666666666666667, 1.9444444444444444, 2.2222222222222223, 2.5, 2.7777777777777777, 3.0555555555555554, 3.3333333333333335, 3.611111111111111, 3.888888888888889, 4.166666666666667, 4.444444444444445, 4.722222222222222, 5, 15, 25]&#13;</pre> |


      #### WETH ([0x4200000000000000000000000000000000000006](https://mega.etherscan.io/address/0x4200000000000000000000000000000000000006))

      | description | value |
      | --- | --- |
      | id | 0 |
      | decimals | 18 |
      | isActive | :white_check_mark: |
      | isFrozen | :x: |
      | isPaused | :x: |
      | supplyCap | 20 WETH |
      | borrowCap | 10 WETH |
      | debtCeiling | 0 $ [0] |
      | isSiloed | :x: |
      | isFlashloanable | :white_check_mark: |
      | oracle | [0xcA4e254D95637DE95E2a2F79244b03380d697feD](https://mega.etherscan.io/address/0xcA4e254D95637DE95E2a2F79244b03380d697feD) |
      | oracleDecimals | 8 |
      | oracleDescription | ETH / USD |
      | oracleLatestAnswer | 2130.504188 $ |
      | usageAsCollateralEnabled | :x: |
      | ltv | 0 % [0] |
      | liquidationThreshold | 0 % [0] |
      | liquidationBonus | 0 % |
      | liquidationProtocolFee | 10 % [1000] |
      | reserveFactor | 15 % [1500] |
      | aToken | [0xa31E6b433382062e8A1dA41485f7b234D97c3f4d](https://mega.etherscan.io/address/0xa31E6b433382062e8A1dA41485f7b234D97c3f4d) |
      | aTokenName | Aave MegaEth WETH |
      | aTokenSymbol | aMegWETH |
      | variableDebtToken | [0x09ADCCC7AF2aBD356c18A4CadF2e5cC250f300E9](https://mega.etherscan.io/address/0x09ADCCC7AF2aBD356c18A4CadF2e5cC250f300E9) |
      | variableDebtTokenName | Aave MegaEth Variable Debt WETH |
      | variableDebtTokenSymbol | variableDebtMegWETH |
      | borrowingEnabled | :x: |
      | isBorrowableInIsolation | :x: |
      | interestRateStrategy | [0x5cC4f782cFe249286476A7eFfD9D7bd215768194](https://mega.etherscan.io/address/0x5cC4f782cFe249286476A7eFfD9D7bd215768194) |
      | aTokenUnderlyingBalance | 0.0025 WETH [2500000000000000] |
      | virtualBalance | 0.0025 WETH [2500000000000000] |
      | optimalUsageRatio | 90 % |
      | maxVariableBorrowRate | 10.5 % |
      | baseVariableBorrowRate | 0 % |
      | variableRateSlope1 | 2.5 % |
      | variableRateSlope2 | 8 % |
      | interestRate | <pre lang="mermaid">xychart-beta&#13;title "Interest Rate Model"&#13;x-axis "Utilization (%)" [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100]&#13;y-axis "Rate (%)"&#13;line [0, 0.1388888888888889, 0.2777777777777778, 0.4166666666666667, 0.5555555555555556, 0.6944444444444444, 0.8333333333333334, 0.9722222222222222, 1.1111111111111112, 1.25, 1.3888888888888888, 1.5277777777777777, 1.6666666666666667, 1.8055555555555556, 1.9444444444444444, 2.0833333333333335, 2.2222222222222223, 2.361111111111111, 2.5, 6.5, 10.5]&#13;</pre> |


      #### wrsETH ([0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F](https://mega.etherscan.io/address/0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F))

      | description | value |
      | --- | --- |
      | id | 5 |
      | decimals | 18 |
      | isActive | :white_check_mark: |
      | isFrozen | :x: |
      | isPaused | :x: |
      | supplyCap | 20 wrsETH |
      | borrowCap | 1 wrsETH |
      | debtCeiling | 0 $ [0] |
      | isSiloed | :x: |
      | isFlashloanable | :white_check_mark: |
      | oracle | [0x6356b92Bc636CCe722e0F53DDc24a86baE64216E](https://mega.etherscan.io/address/0x6356b92Bc636CCe722e0F53DDc24a86baE64216E) |
      | oracleDecimals | 8 |
      | oracleDescription | Capped wrsETH / ETH / USD |
      | oracleLatestAnswer | 2268.21838195 $ |
      | usageAsCollateralEnabled | :x: |
      | ltv | 0 % [0] |
      | liquidationThreshold | 0 % [0] |
      | liquidationBonus | 0 % |
      | liquidationProtocolFee | 10 % [1000] |
      | reserveFactor | 20 % [2000] |
      | aToken | [0xb8578af311353b44B14bb4480EBB4DE608EC7e1B](https://mega.etherscan.io/address/0xb8578af311353b44B14bb4480EBB4DE608EC7e1B) |
      | aTokenName | Aave MegaEth wrsETH |
      | aTokenSymbol | aMegwrsETH |
      | variableDebtToken | [0xd7B71D855bBAcd3f11F623400bc870AB3448AfF7](https://mega.etherscan.io/address/0xd7B71D855bBAcd3f11F623400bc870AB3448AfF7) |
      | variableDebtTokenName | Aave MegaEth Variable Debt wrsETH |
      | variableDebtTokenSymbol | variableDebtMegwrsETH |
      | borrowingEnabled | :x: |
      | isBorrowableInIsolation | :x: |
      | interestRateStrategy | [0x5cC4f782cFe249286476A7eFfD9D7bd215768194](https://mega.etherscan.io/address/0x5cC4f782cFe249286476A7eFfD9D7bd215768194) |
      | aTokenUnderlyingBalance | 0.0025 wrsETH [2500000000000000] |
      | virtualBalance | 0.0025 wrsETH [2500000000000000] |
      | optimalUsageRatio | 90 % |
      | maxVariableBorrowRate | 25 % |
      | baseVariableBorrowRate | 0 % |
      | variableRateSlope1 | 5 % |
      | variableRateSlope2 | 20 % |
      | interestRate | <pre lang="mermaid">xychart-beta&#13;title "Interest Rate Model"&#13;x-axis "Utilization (%)" [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100]&#13;y-axis "Rate (%)"&#13;line [0, 0.2777777777777778, 0.5555555555555556, 0.8333333333333334, 1.1111111111111112, 1.3888888888888888, 1.6666666666666667, 1.9444444444444444, 2.2222222222222223, 2.5, 2.7777777777777777, 3.0555555555555554, 3.3333333333333335, 3.611111111111111, 3.888888888888889, 4.166666666666667, 4.444444444444445, 4.722222222222222, 5, 15, 25]&#13;</pre> |


      #### wstETH ([0x601aC63637933D88285A025C685AC4e9a92a98dA](https://mega.etherscan.io/address/0x601aC63637933D88285A025C685AC4e9a92a98dA))

      | description | value |
      | --- | --- |
      | id | 4 |
      | decimals | 18 |
      | isActive | :white_check_mark: |
      | isFrozen | :x: |
      | isPaused | :x: |
      | supplyCap | 20 wstETH |
      | borrowCap | 1 wstETH |
      | debtCeiling | 0 $ [0] |
      | isSiloed | :x: |
      | isFlashloanable | :white_check_mark: |
      | oracle | [0x376397e34eA968e79DC6F629E6210ba25311a3ce](https://mega.etherscan.io/address/0x376397e34eA968e79DC6F629E6210ba25311a3ce) |
      | oracleDecimals | 8 |
      | oracleDescription | Capped wstETH / stETH(ETH) / USD |
      | oracleLatestAnswer | 2613.17687457 $ |
      | usageAsCollateralEnabled | :x: |
      | ltv | 0 % [0] |
      | liquidationThreshold | 0 % [0] |
      | liquidationBonus | 0 % |
      | liquidationProtocolFee | 10 % [1000] |
      | reserveFactor | 20 % [2000] |
      | aToken | [0xaD2de503b5c723371d6B38A5224A2E12E103DfB8](https://mega.etherscan.io/address/0xaD2de503b5c723371d6B38A5224A2E12E103DfB8) |
      | aTokenName | Aave MegaEth wstETH |
      | aTokenSymbol | aMegwstETH |
      | variableDebtToken | [0x259A9Cd7628f6D15ef384887dd90bb7A0283fEf9](https://mega.etherscan.io/address/0x259A9Cd7628f6D15ef384887dd90bb7A0283fEf9) |
      | variableDebtTokenName | Aave MegaEth Variable Debt wstETH |
      | variableDebtTokenSymbol | variableDebtMegwstETH |
      | borrowingEnabled | :x: |
      | isBorrowableInIsolation | :x: |
      | interestRateStrategy | [0x5cC4f782cFe249286476A7eFfD9D7bd215768194](https://mega.etherscan.io/address/0x5cC4f782cFe249286476A7eFfD9D7bd215768194) |
      | aTokenUnderlyingBalance | 0.0025 wstETH [2500000000000000] |
      | virtualBalance | 0.0025 wstETH [2500000000000000] |
      | optimalUsageRatio | 90 % |
      | maxVariableBorrowRate | 25 % |
      | baseVariableBorrowRate | 0 % |
      | variableRateSlope1 | 5 % |
      | variableRateSlope2 | 20 % |
      | interestRate | <pre lang="mermaid">xychart-beta&#13;title "Interest Rate Model"&#13;x-axis "Utilization (%)" [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100]&#13;y-axis "Rate (%)"&#13;line [0, 0.2777777777777778, 0.5555555555555556, 0.8333333333333334, 1.1111111111111112, 1.3888888888888888, 1.6666666666666667, 1.9444444444444444, 2.2222222222222223, 2.5, 2.7777777777777777, 3.0555555555555554, 3.3333333333333335, 3.611111111111111, 3.888888888888889, 4.166666666666667, 4.444444444444445, 4.722222222222222, 5, 15, 25]&#13;</pre> |


      #### BTC.b ([0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072](https://mega.etherscan.io/address/0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072))

      | description | value |
      | --- | --- |
      | id | 1 |
      | decimals | 8 |
      | isActive | :white_check_mark: |
      | isFrozen | :x: |
      | isPaused | :x: |
      | supplyCap | 2 BTC.b |
      | borrowCap | 1 BTC.b |
      | debtCeiling | 0 $ [0] |
      | isSiloed | :x: |
      | isFlashloanable | :white_check_mark: |
      | oracle | [0xc6E3007B597f6F5a6330d43053D1EF73cCbbE721](https://mega.etherscan.io/address/0xc6E3007B597f6F5a6330d43053D1EF73cCbbE721) |
      | oracleDecimals | 8 |
      | oracleDescription | BTC / USD |
      | oracleLatestAnswer | 70815.89948 $ |
      | usageAsCollateralEnabled | :x: |
      | ltv | 0 % [0] |
      | liquidationThreshold | 0 % [0] |
      | liquidationBonus | 0 % |
      | liquidationProtocolFee | 10 % [1000] |
      | reserveFactor | 20 % [2000] |
      | aToken | [0x0889d59eA7178ee5B71DA01949a5cB42aaFBe337](https://mega.etherscan.io/address/0x0889d59eA7178ee5B71DA01949a5cB42aaFBe337) |
      | aTokenName | Aave MegaEth BTCb |
      | aTokenSymbol | aMegBTCb |
      | variableDebtToken | [0x15B550784928C5b1A93849CA5d6caA18B2545B6d](https://mega.etherscan.io/address/0x15B550784928C5b1A93849CA5d6caA18B2545B6d) |
      | variableDebtTokenName | Aave MegaEth Variable Debt BTCb |
      | variableDebtTokenSymbol | variableDebtMegBTCb |
      | borrowingEnabled | :x: |
      | isBorrowableInIsolation | :x: |
      | interestRateStrategy | [0x5cC4f782cFe249286476A7eFfD9D7bd215768194](https://mega.etherscan.io/address/0x5cC4f782cFe249286476A7eFfD9D7bd215768194) |
      | aTokenUnderlyingBalance | 0.0005 BTC.b [50000] |
      | virtualBalance | 0.0005 BTC.b [50000] |
      | optimalUsageRatio | 90 % |
      | maxVariableBorrowRate | 25 % |
      | baseVariableBorrowRate | 0 % |
      | variableRateSlope1 | 5 % |
      | variableRateSlope2 | 20 % |
      | interestRate | <pre lang="mermaid">xychart-beta&#13;title "Interest Rate Model"&#13;x-axis "Utilization (%)" [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100]&#13;y-axis "Rate (%)"&#13;line [0, 0.2777777777777778, 0.5555555555555556, 0.8333333333333334, 1.1111111111111112, 1.3888888888888888, 1.6666666666666667, 1.9444444444444444, 2.2222222222222223, 2.5, 2.7777777777777777, 3.0555555555555554, 3.3333333333333335, 3.611111111111111, 3.888888888888889, 4.166666666666667, 4.444444444444445, 4.722222222222222, 5, 15, 25]&#13;</pre> |


      #### USDT0 ([0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb](https://mega.etherscan.io/address/0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb))

      | description | value |
      | --- | --- |
      | id | 2 |
      | decimals | 6 |
      | isActive | :white_check_mark: |
      | isFrozen | :x: |
      | isPaused | :x: |
      | supplyCap | 50,000 USDT0 |
      | borrowCap | 20,000 USDT0 |
      | debtCeiling | 0 $ [0] |
      | isSiloed | :x: |
      | isFlashloanable | :white_check_mark: |
      | oracle | [0xAe95ff42e16468AB1DfD405c9533C9b67d87d66A](https://mega.etherscan.io/address/0xAe95ff42e16468AB1DfD405c9533C9b67d87d66A) |
      | oracleDecimals | 8 |
      | oracleDescription | Capped USDT/USD |
      | oracleLatestAnswer | 0.99931 $ |
      | usageAsCollateralEnabled | :x: |
      | ltv | 0 % [0] |
      | liquidationThreshold | 0 % [0] |
      | liquidationBonus | 0 % |
      | liquidationProtocolFee | 10 % [1000] |
      | reserveFactor | 10 % [1000] |
      | aToken | [0xE2283E01a667b512c340f19B499d86fbc885D5Ef](https://mega.etherscan.io/address/0xE2283E01a667b512c340f19B499d86fbc885D5Ef) |
      | aTokenName | Aave MegaEth USDT0 |
      | aTokenSymbol | aMegUSDT0 |
      | variableDebtToken | [0xB951225133b5eed3D88645E4Bb1360136FF70D9a](https://mega.etherscan.io/address/0xB951225133b5eed3D88645E4Bb1360136FF70D9a) |
      | variableDebtTokenName | Aave MegaEth Variable Debt USDT0 |
      | variableDebtTokenSymbol | variableDebtMegUSDT0 |
      | borrowingEnabled | :white_check_mark: |
      | isBorrowableInIsolation | :white_check_mark: |
      | interestRateStrategy | [0x5cC4f782cFe249286476A7eFfD9D7bd215768194](https://mega.etherscan.io/address/0x5cC4f782cFe249286476A7eFfD9D7bd215768194) |
      | aTokenUnderlyingBalance | 10 USDT0 [10000000] |
      | virtualBalance | 10 USDT0 [10000000] |
      | optimalUsageRatio | 90 % |
      | maxVariableBorrowRate | 15 % |
      | baseVariableBorrowRate | 0 % |
      | variableRateSlope1 | 5 % |
      | variableRateSlope2 | 10 % |
      | interestRate | <pre lang="mermaid">xychart-beta&#13;title "Interest Rate Model"&#13;x-axis "Utilization (%)" [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100]&#13;y-axis "Rate (%)"&#13;line [0, 0.2777777777777778, 0.5555555555555556, 0.8333333333333334, 1.1111111111111112, 1.3888888888888888, 1.6666666666666667, 1.9444444444444444, 2.2222222222222223, 2.5, 2.7777777777777777, 3.0555555555555554, 3.3333333333333335, 3.611111111111111, 3.888888888888889, 4.166666666666667, 4.444444444444445, 4.722222222222222, 5, 10, 15]&#13;</pre> |


      #### USDm ([0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7](https://mega.etherscan.io/address/0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7))

      | description | value |
      | --- | --- |
      | id | 3 |
      | decimals | 18 |
      | isActive | :white_check_mark: |
      | isFrozen | :x: |
      | isPaused | :x: |
      | supplyCap | 50,000 USDm |
      | borrowCap | 20,000 USDm |
      | debtCeiling | 0 $ [0] |
      | isSiloed | :x: |
      | isFlashloanable | :white_check_mark: |
      | oracle | [0xe5448B8318493c6e3F72E21e8BDB8242d3299FB5](https://mega.etherscan.io/address/0xe5448B8318493c6e3F72E21e8BDB8242d3299FB5) |
      | oracleDecimals | 8 |
      | oracleDescription | ONE USD |
      | oracleLatestAnswer | 1 $ |
      | usageAsCollateralEnabled | :x: |
      | ltv | 0 % [0] |
      | liquidationThreshold | 0 % [0] |
      | liquidationBonus | 0 % |
      | liquidationProtocolFee | 10 % [1000] |
      | reserveFactor | 10 % [1000] |
      | aToken | [0x5dF82810CB4B8f3e0Da3c031cCc9208ee9cF9500](https://mega.etherscan.io/address/0x5dF82810CB4B8f3e0Da3c031cCc9208ee9cF9500) |
      | aTokenName | Aave MegaEth USDm |
      | aTokenSymbol | aMegUSDm |
      | variableDebtToken | [0x6B408d6c479C304794abC60a4693A3AD2D3c2D0D](https://mega.etherscan.io/address/0x6B408d6c479C304794abC60a4693A3AD2D3c2D0D) |
      | variableDebtTokenName | Aave MegaEth Variable Debt USDm |
      | variableDebtTokenSymbol | variableDebtMegUSDm |
      | borrowingEnabled | :white_check_mark: |
      | isBorrowableInIsolation | :white_check_mark: |
      | interestRateStrategy | [0x5cC4f782cFe249286476A7eFfD9D7bd215768194](https://mega.etherscan.io/address/0x5cC4f782cFe249286476A7eFfD9D7bd215768194) |
      | aTokenUnderlyingBalance | 10 USDm [10000000000000000000] |
      | virtualBalance | 10 USDm [10000000000000000000] |
      | optimalUsageRatio | 90 % |
      | maxVariableBorrowRate | 15 % |
      | baseVariableBorrowRate | 0 % |
      | variableRateSlope1 | 5 % |
      | variableRateSlope2 | 10 % |
      | interestRate | <pre lang="mermaid">xychart-beta&#13;title "Interest Rate Model"&#13;x-axis "Utilization (%)" [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100]&#13;y-axis "Rate (%)"&#13;line [0, 0.2777777777777778, 0.5555555555555556, 0.8333333333333334, 1.1111111111111112, 1.3888888888888888, 1.6666666666666667, 1.9444444444444444, 2.2222222222222223, 2.5, 2.7777777777777777, 3.0555555555555554, 3.3333333333333335, 3.611111111111111, 3.888888888888889, 4.166666666666667, 4.444444444444445, 4.722222222222222, 5, 10, 15]&#13;</pre> |


      ## EMode changes

      ### EMode: WETH Stablecoins (id: 1)

      | description | value before | value after |
      | --- | --- | --- |
      | label | - | WETH Stablecoins |
      | ltv | - | 80.5 % |
      | liquidationThreshold | - | 83 % |
      | liquidationBonus | - | 5.5 % [10550] |
      | borrowableBitmap | - | USDT0, USDm |
      | collateralBitmap | - | WETH |


      ### EMode: BTCb Stablecoins (id: 2)

      | description | value before | value after |
      | --- | --- | --- |
      | label | - | BTCb Stablecoins |
      | ltv | - | 70 % |
      | liquidationThreshold | - | 75 % |
      | liquidationBonus | - | 6.5 % [10650] |
      | borrowableBitmap | - | USDT0, USDm |
      | collateralBitmap | - | BTC.b |


      ### EMode: wstETH Stablecoins (id: 3)

      | description | value before | value after |
      | --- | --- | --- |
      | label | - | wstETH Stablecoins |
      | ltv | - | 75 % |
      | liquidationThreshold | - | 79 % |
      | liquidationBonus | - | 6.5 % [10650] |
      | borrowableBitmap | - | USDT0, USDm |
      | collateralBitmap | - | wstETH |


      ### EMode: wstETH Correlated (id: 4)

      | description | value before | value after |
      | --- | --- | --- |
      | label | - | wstETH Correlated |
      | ltv | - | 94 % |
      | liquidationThreshold | - | 96 % |
      | liquidationBonus | - | 1 % [10100] |
      | borrowableBitmap | - | WETH |
      | collateralBitmap | - | wstETH |


      ### EMode: wrsETH Correlated (id: 5)

      | description | value before | value after |
      | --- | --- | --- |
      | label | - | wrsETH Correlated |
      | ltv | - | 93 % |
      | liquidationThreshold | - | 95 % |
      | liquidationBonus | - | 1 % [10100] |
      | borrowableBitmap | - | WETH |
      | collateralBitmap | - | wrsETH |


      ### EMode: ezETH Correlated (id: 6)

      | description | value before | value after |
      | --- | --- | --- |
      | label | - | ezETH Correlated |
      | ltv | - | 93 % |
      | liquidationThreshold | - | 95 % |
      | liquidationBonus | - | 1 % [10100] |
      | borrowableBitmap | - | WETH |
      | collateralBitmap | - | ezETH |


      ## Pool config changes

      | description | value before | value after |
      | --- | --- | --- |
      | priceOracleSentinel | [0x0000000000000000000000000000000000000000](https://mega.etherscan.io/address/0x0000000000000000000000000000000000000000) | [0x98F756B77D6Fde14E08bb064b248ec7512F9f8ba](https://mega.etherscan.io/address/0x98F756B77D6Fde14E08bb064b248ec7512F9f8ba) |


      ## Event logs

      #### 0x421117D7319E96d831972b3F7e970bbfe29C4F21 (AaveV3MegaEth.ORACLE)

      | index | event |
      | --- | --- |
      | 0 | AssetSourceUpdated(asset: 0x4200000000000000000000000000000000000006 (symbol: WETH), source: 0xcA4e254D95637DE95E2a2F79244b03380d697feD) |
      | 1 | AssetSourceUpdated(asset: 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (symbol: BTC.b), source: 0xc6E3007B597f6F5a6330d43053D1EF73cCbbE721) |
      | 2 | AssetSourceUpdated(asset: 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (symbol: USDT0), source: 0xAe95ff42e16468AB1DfD405c9533C9b67d87d66A) |
      | 3 | AssetSourceUpdated(asset: 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (symbol: USDm), source: 0xe5448B8318493c6e3F72E21e8BDB8242d3299FB5) |
      | 4 | AssetSourceUpdated(asset: 0x601aC63637933D88285A025C685AC4e9a92a98dA (symbol: wstETH), source: 0x376397e34eA968e79DC6F629E6210ba25311a3ce) |
      | 5 | AssetSourceUpdated(asset: 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (symbol: wrsETH), source: 0x6356b92Bc636CCe722e0F53DDc24a86baE64216E) |
      | 6 | AssetSourceUpdated(asset: 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (symbol: ezETH), source: 0xd7Da71D3acf07C604A925799B0b48E2Ec607584D) |

      #### 0xa31E6b433382062e8A1dA41485f7b234D97c3f4d (AaveV3MegaEth.ASSETS.WETH.A_TOKEN)

      | index | event |
      | --- | --- |
      | 7 | Initialized(underlyingAsset: 0x4200000000000000000000000000000000000006, pool: 0x7e324AbC5De01d112AfC03a584966ff199741C28, treasury: 0x7E195b3fc91fDd51A9CD5070cC044602212Ac983, incentivesController: 0x3691FF69e22c1353df9F8b2c0B1B16aA5fEEc389, aTokenDecimals: 18, aTokenName: Aave MegaEth WETH, aTokenSymbol: aMegWETH, params: 0x) |
      | 129 | Transfer(from: 0x0000000000000000000000000000000000000000, to: 0x8d1dac82259FdE48D8086CC42cAa98E825C5B643, value: 0.0025 [2500000000000000, 18 decimals]) |
      | 130 | Mint(caller: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, onBehalfOf: 0x8d1dac82259FdE48D8086CC42cAa98E825C5B643, value: 0.0025 [2500000000000000, 18 decimals], balanceIncrease: 0, index: 1 [1000000000000000000000000000, 27 decimals]) |

      #### 0x09ADCCC7AF2aBD356c18A4CadF2e5cC250f300E9 (AaveV3MegaEth.ASSETS.WETH.V_TOKEN)

      | index | event |
      | --- | --- |
      | 8 | Initialized(underlyingAsset: 0x4200000000000000000000000000000000000006, pool: 0x7e324AbC5De01d112AfC03a584966ff199741C28, incentivesController: 0x3691FF69e22c1353df9F8b2c0B1B16aA5fEEc389, debtTokenDecimals: 18, debtTokenName: Aave MegaEth Variable Debt WETH, debtTokenSymbol: variableDebtMegWETH, params: 0x) |

      #### 0x5cC4f782cFe249286476A7eFfD9D7bd215768194 (AaveV3MegaEth.ASSETS.WETH.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.BTCb.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.USDT0.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.USDm.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.wstETH.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.wrsETH.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.ezETH.INTEREST_RATE_STRATEGY)

      | index | event |
      | --- | --- |
      | 9 | RateDataUpdate(reserve: 0x4200000000000000000000000000000000000006 (symbol: WETH), optimalUsageRatio: 9000, baseVariableBorrowRate: 0, variableRateSlope1: 250, variableRateSlope2: 800) |
      | 14 | RateDataUpdate(reserve: 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (symbol: BTC.b), optimalUsageRatio: 9000, baseVariableBorrowRate: 0, variableRateSlope1: 500, variableRateSlope2: 2000) |
      | 19 | RateDataUpdate(reserve: 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (symbol: USDT0), optimalUsageRatio: 9000, baseVariableBorrowRate: 0, variableRateSlope1: 500, variableRateSlope2: 1000) |
      | 24 | RateDataUpdate(reserve: 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (symbol: USDm), optimalUsageRatio: 9000, baseVariableBorrowRate: 0, variableRateSlope1: 500, variableRateSlope2: 1000) |
      | 29 | RateDataUpdate(reserve: 0x601aC63637933D88285A025C685AC4e9a92a98dA (symbol: wstETH), optimalUsageRatio: 9000, baseVariableBorrowRate: 0, variableRateSlope1: 500, variableRateSlope2: 2000) |
      | 34 | RateDataUpdate(reserve: 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (symbol: wrsETH), optimalUsageRatio: 9000, baseVariableBorrowRate: 0, variableRateSlope1: 500, variableRateSlope2: 2000) |
      | 39 | RateDataUpdate(reserve: 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (symbol: ezETH), optimalUsageRatio: 9000, baseVariableBorrowRate: 0, variableRateSlope1: 500, variableRateSlope2: 2000) |

      #### 0xF15D31Bc839A853C9068686043cEc6EC5995DAbB (AaveV3MegaEth.POOL_CONFIGURATOR)

      | index | event |
      | --- | --- |
      | 10 | ReserveInitialized(asset: 0x4200000000000000000000000000000000000006 (symbol: WETH), aToken: 0xa31E6b433382062e8A1dA41485f7b234D97c3f4d, stableDebtToken: 0x0000000000000000000000000000000000000000, variableDebtToken: 0x09ADCCC7AF2aBD356c18A4CadF2e5cC250f300E9, interestRateStrategyAddress: 0x5cC4f782cFe249286476A7eFfD9D7bd215768194) |
      | 11 | ReserveInterestRateDataChanged(asset: 0x4200000000000000000000000000000000000006 (symbol: WETH), strategy: 0x5cC4f782cFe249286476A7eFfD9D7bd215768194, data: 0x0000000000000000000000000000000000000000000000000000000000002328000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fa0000000000000000000000000000000000000000000000000000000000000320) |
      | 15 | ReserveInitialized(asset: 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (symbol: BTC.b), aToken: 0x0889d59eA7178ee5B71DA01949a5cB42aaFBe337, stableDebtToken: 0x0000000000000000000000000000000000000000, variableDebtToken: 0x15B550784928C5b1A93849CA5d6caA18B2545B6d, interestRateStrategyAddress: 0x5cC4f782cFe249286476A7eFfD9D7bd215768194) |
      | 16 | ReserveInterestRateDataChanged(asset: 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (symbol: BTC.b), strategy: 0x5cC4f782cFe249286476A7eFfD9D7bd215768194, data: 0x0000000000000000000000000000000000000000000000000000000000002328000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001f400000000000000000000000000000000000000000000000000000000000007d0) |
      | 20 | ReserveInitialized(asset: 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (symbol: USDT0), aToken: 0xE2283E01a667b512c340f19B499d86fbc885D5Ef, stableDebtToken: 0x0000000000000000000000000000000000000000, variableDebtToken: 0xB951225133b5eed3D88645E4Bb1360136FF70D9a, interestRateStrategyAddress: 0x5cC4f782cFe249286476A7eFfD9D7bd215768194) |
      | 21 | ReserveInterestRateDataChanged(asset: 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (symbol: USDT0), strategy: 0x5cC4f782cFe249286476A7eFfD9D7bd215768194, data: 0x0000000000000000000000000000000000000000000000000000000000002328000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001f400000000000000000000000000000000000000000000000000000000000003e8) |
      | 25 | ReserveInitialized(asset: 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (symbol: USDm), aToken: 0x5dF82810CB4B8f3e0Da3c031cCc9208ee9cF9500, stableDebtToken: 0x0000000000000000000000000000000000000000, variableDebtToken: 0x6B408d6c479C304794abC60a4693A3AD2D3c2D0D, interestRateStrategyAddress: 0x5cC4f782cFe249286476A7eFfD9D7bd215768194) |
      | 26 | ReserveInterestRateDataChanged(asset: 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (symbol: USDm), strategy: 0x5cC4f782cFe249286476A7eFfD9D7bd215768194, data: 0x0000000000000000000000000000000000000000000000000000000000002328000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001f400000000000000000000000000000000000000000000000000000000000003e8) |
      | 30 | ReserveInitialized(asset: 0x601aC63637933D88285A025C685AC4e9a92a98dA (symbol: wstETH), aToken: 0xaD2de503b5c723371d6B38A5224A2E12E103DfB8, stableDebtToken: 0x0000000000000000000000000000000000000000, variableDebtToken: 0x259A9Cd7628f6D15ef384887dd90bb7A0283fEf9, interestRateStrategyAddress: 0x5cC4f782cFe249286476A7eFfD9D7bd215768194) |
      | 31 | ReserveInterestRateDataChanged(asset: 0x601aC63637933D88285A025C685AC4e9a92a98dA (symbol: wstETH), strategy: 0x5cC4f782cFe249286476A7eFfD9D7bd215768194, data: 0x0000000000000000000000000000000000000000000000000000000000002328000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001f400000000000000000000000000000000000000000000000000000000000007d0) |
      | 35 | ReserveInitialized(asset: 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (symbol: wrsETH), aToken: 0xb8578af311353b44B14bb4480EBB4DE608EC7e1B, stableDebtToken: 0x0000000000000000000000000000000000000000, variableDebtToken: 0xd7B71D855bBAcd3f11F623400bc870AB3448AfF7, interestRateStrategyAddress: 0x5cC4f782cFe249286476A7eFfD9D7bd215768194) |
      | 36 | ReserveInterestRateDataChanged(asset: 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (symbol: wrsETH), strategy: 0x5cC4f782cFe249286476A7eFfD9D7bd215768194, data: 0x0000000000000000000000000000000000000000000000000000000000002328000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001f400000000000000000000000000000000000000000000000000000000000007d0) |
      | 40 | ReserveInitialized(asset: 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (symbol: ezETH), aToken: 0x03C99Cce547b1c2E74442b73E6f588A66D19597e, stableDebtToken: 0x0000000000000000000000000000000000000000, variableDebtToken: 0x1505f48Bd4db0fF8B28817D2C0Fb95Abcb8eEbbc, interestRateStrategyAddress: 0x5cC4f782cFe249286476A7eFfD9D7bd215768194) |
      | 41 | ReserveInterestRateDataChanged(asset: 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (symbol: ezETH), strategy: 0x5cC4f782cFe249286476A7eFfD9D7bd215768194, data: 0x0000000000000000000000000000000000000000000000000000000000002328000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001f400000000000000000000000000000000000000000000000000000000000007d0) |
      | 42 | SupplyCapChanged(asset: 0x4200000000000000000000000000000000000006 (symbol: WETH), oldSupplyCap: 0, newSupplyCap: 20) |
      | 43 | BorrowCapChanged(asset: 0x4200000000000000000000000000000000000006 (symbol: WETH), oldBorrowCap: 0, newBorrowCap: 10) |
      | 44 | SupplyCapChanged(asset: 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (symbol: BTC.b), oldSupplyCap: 0, newSupplyCap: 2) |
      | 45 | BorrowCapChanged(asset: 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (symbol: BTC.b), oldBorrowCap: 0, newBorrowCap: 1) |
      | 46 | SupplyCapChanged(asset: 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (symbol: USDT0), oldSupplyCap: 0, newSupplyCap: 50000) |
      | 47 | BorrowCapChanged(asset: 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (symbol: USDT0), oldBorrowCap: 0, newBorrowCap: 20000) |
      | 48 | SupplyCapChanged(asset: 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (symbol: USDm), oldSupplyCap: 0, newSupplyCap: 50000) |
      | 49 | BorrowCapChanged(asset: 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (symbol: USDm), oldBorrowCap: 0, newBorrowCap: 20000) |
      | 50 | SupplyCapChanged(asset: 0x601aC63637933D88285A025C685AC4e9a92a98dA (symbol: wstETH), oldSupplyCap: 0, newSupplyCap: 20) |
      | 51 | BorrowCapChanged(asset: 0x601aC63637933D88285A025C685AC4e9a92a98dA (symbol: wstETH), oldBorrowCap: 0, newBorrowCap: 1) |
      | 52 | SupplyCapChanged(asset: 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (symbol: wrsETH), oldSupplyCap: 0, newSupplyCap: 20) |
      | 53 | BorrowCapChanged(asset: 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (symbol: wrsETH), oldBorrowCap: 0, newBorrowCap: 1) |
      | 54 | SupplyCapChanged(asset: 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (symbol: ezETH), oldSupplyCap: 0, newSupplyCap: 20) |
      | 55 | BorrowCapChanged(asset: 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (symbol: ezETH), oldBorrowCap: 0, newBorrowCap: 1) |
      | 56 | ReserveBorrowing(asset: 0x4200000000000000000000000000000000000006 (symbol: WETH), enabled: false) |
      | 57 | BorrowableInIsolationChanged(asset: 0x4200000000000000000000000000000000000006 (symbol: WETH), borrowable: false) |
      | 58 | SiloedBorrowingChanged(asset: 0x4200000000000000000000000000000000000006 (symbol: WETH), oldState: false, newState: false) |
      | 59 | ReserveFactorChanged(asset: 0x4200000000000000000000000000000000000006 (symbol: WETH), oldReserveFactor: 0, newReserveFactor: 1500) |
      | 61 | ReserveFlashLoaning(asset: 0x4200000000000000000000000000000000000006 (symbol: WETH), enabled: true) |
      | 62 | ReserveBorrowing(asset: 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (symbol: BTC.b), enabled: false) |
      | 63 | BorrowableInIsolationChanged(asset: 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (symbol: BTC.b), borrowable: false) |
      | 64 | SiloedBorrowingChanged(asset: 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (symbol: BTC.b), oldState: false, newState: false) |
      | 65 | ReserveFactorChanged(asset: 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (symbol: BTC.b), oldReserveFactor: 0, newReserveFactor: 2000) |
      | 67 | ReserveFlashLoaning(asset: 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (symbol: BTC.b), enabled: true) |
      | 68 | ReserveBorrowing(asset: 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (symbol: USDT0), enabled: true) |
      | 69 | BorrowableInIsolationChanged(asset: 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (symbol: USDT0), borrowable: true) |
      | 70 | SiloedBorrowingChanged(asset: 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (symbol: USDT0), oldState: false, newState: false) |
      | 71 | ReserveFactorChanged(asset: 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (symbol: USDT0), oldReserveFactor: 0, newReserveFactor: 1000) |
      | 73 | ReserveFlashLoaning(asset: 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (symbol: USDT0), enabled: true) |
      | 74 | ReserveBorrowing(asset: 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (symbol: USDm), enabled: true) |
      | 75 | BorrowableInIsolationChanged(asset: 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (symbol: USDm), borrowable: true) |
      | 76 | SiloedBorrowingChanged(asset: 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (symbol: USDm), oldState: false, newState: false) |
      | 77 | ReserveFactorChanged(asset: 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (symbol: USDm), oldReserveFactor: 0, newReserveFactor: 1000) |
      | 79 | ReserveFlashLoaning(asset: 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (symbol: USDm), enabled: true) |
      | 80 | ReserveBorrowing(asset: 0x601aC63637933D88285A025C685AC4e9a92a98dA (symbol: wstETH), enabled: false) |
      | 81 | BorrowableInIsolationChanged(asset: 0x601aC63637933D88285A025C685AC4e9a92a98dA (symbol: wstETH), borrowable: false) |
      | 82 | SiloedBorrowingChanged(asset: 0x601aC63637933D88285A025C685AC4e9a92a98dA (symbol: wstETH), oldState: false, newState: false) |
      | 83 | ReserveFactorChanged(asset: 0x601aC63637933D88285A025C685AC4e9a92a98dA (symbol: wstETH), oldReserveFactor: 0, newReserveFactor: 2000) |
      | 85 | ReserveFlashLoaning(asset: 0x601aC63637933D88285A025C685AC4e9a92a98dA (symbol: wstETH), enabled: true) |
      | 86 | ReserveBorrowing(asset: 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (symbol: wrsETH), enabled: false) |
      | 87 | BorrowableInIsolationChanged(asset: 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (symbol: wrsETH), borrowable: false) |
      | 88 | SiloedBorrowingChanged(asset: 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (symbol: wrsETH), oldState: false, newState: false) |
      | 89 | ReserveFactorChanged(asset: 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (symbol: wrsETH), oldReserveFactor: 0, newReserveFactor: 2000) |
      | 91 | ReserveFlashLoaning(asset: 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (symbol: wrsETH), enabled: true) |
      | 92 | ReserveBorrowing(asset: 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (symbol: ezETH), enabled: false) |
      | 93 | BorrowableInIsolationChanged(asset: 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (symbol: ezETH), borrowable: false) |
      | 94 | SiloedBorrowingChanged(asset: 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (symbol: ezETH), oldState: false, newState: false) |
      | 95 | ReserveFactorChanged(asset: 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (symbol: ezETH), oldReserveFactor: 0, newReserveFactor: 2000) |
      | 97 | ReserveFlashLoaning(asset: 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (symbol: ezETH), enabled: true) |
      | 98 | LiquidationProtocolFeeChanged(asset: 0x4200000000000000000000000000000000000006 (symbol: WETH), oldFee: 0, newFee: 1000) |
      | 99 | LiquidationProtocolFeeChanged(asset: 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (symbol: BTC.b), oldFee: 0, newFee: 1000) |
      | 100 | LiquidationProtocolFeeChanged(asset: 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (symbol: USDT0), oldFee: 0, newFee: 1000) |
      | 101 | LiquidationProtocolFeeChanged(asset: 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (symbol: USDm), oldFee: 0, newFee: 1000) |
      | 102 | LiquidationProtocolFeeChanged(asset: 0x601aC63637933D88285A025C685AC4e9a92a98dA (symbol: wstETH), oldFee: 0, newFee: 1000) |
      | 103 | LiquidationProtocolFeeChanged(asset: 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (symbol: wrsETH), oldFee: 0, newFee: 1000) |
      | 104 | LiquidationProtocolFeeChanged(asset: 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (symbol: ezETH), oldFee: 0, newFee: 1000) |
      | 105 | EModeCategoryAdded(categoryId: 1, ltv: 8050, liquidationThreshold: 8300, liquidationBonus: 10550, oracle: 0x0000000000000000000000000000000000000000, label: WETH Stablecoins) |
      | 106 | AssetCollateralInEModeChanged(asset: 0x4200000000000000000000000000000000000006 (symbol: WETH), categoryId: 1, collateral: true) |
      | 107 | AssetBorrowableInEModeChanged(asset: 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (symbol: USDT0), categoryId: 1, borrowable: true) |
      | 108 | AssetBorrowableInEModeChanged(asset: 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (symbol: USDm), categoryId: 1, borrowable: true) |
      | 109 | EModeCategoryAdded(categoryId: 2, ltv: 7000, liquidationThreshold: 7500, liquidationBonus: 10650, oracle: 0x0000000000000000000000000000000000000000, label: BTCb Stablecoins) |
      | 110 | AssetCollateralInEModeChanged(asset: 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (symbol: BTC.b), categoryId: 2, collateral: true) |
      | 111 | AssetBorrowableInEModeChanged(asset: 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (symbol: USDT0), categoryId: 2, borrowable: true) |
      | 112 | AssetBorrowableInEModeChanged(asset: 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (symbol: USDm), categoryId: 2, borrowable: true) |
      | 113 | EModeCategoryAdded(categoryId: 3, ltv: 7500, liquidationThreshold: 7900, liquidationBonus: 10650, oracle: 0x0000000000000000000000000000000000000000, label: wstETH Stablecoins) |
      | 114 | AssetCollateralInEModeChanged(asset: 0x601aC63637933D88285A025C685AC4e9a92a98dA (symbol: wstETH), categoryId: 3, collateral: true) |
      | 115 | AssetBorrowableInEModeChanged(asset: 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (symbol: USDT0), categoryId: 3, borrowable: true) |
      | 116 | AssetBorrowableInEModeChanged(asset: 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (symbol: USDm), categoryId: 3, borrowable: true) |
      | 117 | EModeCategoryAdded(categoryId: 4, ltv: 9400, liquidationThreshold: 9600, liquidationBonus: 10100, oracle: 0x0000000000000000000000000000000000000000, label: wstETH Correlated) |
      | 118 | AssetCollateralInEModeChanged(asset: 0x601aC63637933D88285A025C685AC4e9a92a98dA (symbol: wstETH), categoryId: 4, collateral: true) |
      | 119 | AssetBorrowableInEModeChanged(asset: 0x4200000000000000000000000000000000000006 (symbol: WETH), categoryId: 4, borrowable: true) |
      | 120 | EModeCategoryAdded(categoryId: 5, ltv: 9300, liquidationThreshold: 9500, liquidationBonus: 10100, oracle: 0x0000000000000000000000000000000000000000, label: wrsETH Correlated) |
      | 121 | AssetCollateralInEModeChanged(asset: 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (symbol: wrsETH), categoryId: 5, collateral: true) |
      | 122 | AssetBorrowableInEModeChanged(asset: 0x4200000000000000000000000000000000000006 (symbol: WETH), categoryId: 5, borrowable: true) |
      | 123 | EModeCategoryAdded(categoryId: 6, ltv: 9300, liquidationThreshold: 9500, liquidationBonus: 10100, oracle: 0x0000000000000000000000000000000000000000, label: ezETH Correlated) |
      | 124 | AssetCollateralInEModeChanged(asset: 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (symbol: ezETH), categoryId: 6, collateral: true) |
      | 125 | AssetBorrowableInEModeChanged(asset: 0x4200000000000000000000000000000000000006 (symbol: WETH), categoryId: 6, borrowable: true) |

      #### 0x0889d59eA7178ee5B71DA01949a5cB42aaFBe337 (AaveV3MegaEth.ASSETS.BTCb.A_TOKEN)

      | index | event |
      | --- | --- |
      | 12 | Initialized(underlyingAsset: 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072, pool: 0x7e324AbC5De01d112AfC03a584966ff199741C28, treasury: 0x7E195b3fc91fDd51A9CD5070cC044602212Ac983, incentivesController: 0x3691FF69e22c1353df9F8b2c0B1B16aA5fEEc389, aTokenDecimals: 8, aTokenName: Aave MegaEth BTCb, aTokenSymbol: aMegBTCb, params: 0x) |
      | 137 | Transfer(from: 0x0000000000000000000000000000000000000000, to: 0x8d1dac82259FdE48D8086CC42cAa98E825C5B643, value: 0.0005 [50000, 8 decimals]) |
      | 138 | Mint(caller: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, onBehalfOf: 0x8d1dac82259FdE48D8086CC42cAa98E825C5B643, value: 0.0005 [50000, 8 decimals], balanceIncrease: 0, index: 1 [1000000000000000000000000000, 27 decimals]) |

      #### 0x15B550784928C5b1A93849CA5d6caA18B2545B6d (AaveV3MegaEth.ASSETS.BTCb.V_TOKEN)

      | index | event |
      | --- | --- |
      | 13 | Initialized(underlyingAsset: 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072, pool: 0x7e324AbC5De01d112AfC03a584966ff199741C28, incentivesController: 0x3691FF69e22c1353df9F8b2c0B1B16aA5fEEc389, debtTokenDecimals: 8, debtTokenName: Aave MegaEth Variable Debt BTCb, debtTokenSymbol: variableDebtMegBTCb, params: 0x) |

      #### 0xE2283E01a667b512c340f19B499d86fbc885D5Ef (AaveV3MegaEth.ASSETS.USDT0.A_TOKEN)

      | index | event |
      | --- | --- |
      | 17 | Initialized(underlyingAsset: 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb, pool: 0x7e324AbC5De01d112AfC03a584966ff199741C28, treasury: 0x7E195b3fc91fDd51A9CD5070cC044602212Ac983, incentivesController: 0x3691FF69e22c1353df9F8b2c0B1B16aA5fEEc389, aTokenDecimals: 6, aTokenName: Aave MegaEth USDT0, aTokenSymbol: aMegUSDT0, params: 0x) |
      | 146 | Transfer(from: 0x0000000000000000000000000000000000000000, to: 0x8d1dac82259FdE48D8086CC42cAa98E825C5B643, value: 10 [10000000, 6 decimals]) |
      | 147 | Mint(caller: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, onBehalfOf: 0x8d1dac82259FdE48D8086CC42cAa98E825C5B643, value: 10 [10000000, 6 decimals], balanceIncrease: 0, index: 1 [1000000000000000000000000000, 27 decimals]) |

      #### 0xB951225133b5eed3D88645E4Bb1360136FF70D9a (AaveV3MegaEth.ASSETS.USDT0.V_TOKEN)

      | index | event |
      | --- | --- |
      | 18 | Initialized(underlyingAsset: 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb, pool: 0x7e324AbC5De01d112AfC03a584966ff199741C28, incentivesController: 0x3691FF69e22c1353df9F8b2c0B1B16aA5fEEc389, debtTokenDecimals: 6, debtTokenName: Aave MegaEth Variable Debt USDT0, debtTokenSymbol: variableDebtMegUSDT0, params: 0x) |

      #### 0x5dF82810CB4B8f3e0Da3c031cCc9208ee9cF9500 (AaveV3MegaEth.ASSETS.USDm.A_TOKEN)

      | index | event |
      | --- | --- |
      | 22 | Initialized(underlyingAsset: 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7, pool: 0x7e324AbC5De01d112AfC03a584966ff199741C28, treasury: 0x7E195b3fc91fDd51A9CD5070cC044602212Ac983, incentivesController: 0x3691FF69e22c1353df9F8b2c0B1B16aA5fEEc389, aTokenDecimals: 18, aTokenName: Aave MegaEth USDm, aTokenSymbol: aMegUSDm, params: 0x) |
      | 154 | Transfer(from: 0x0000000000000000000000000000000000000000, to: 0x8d1dac82259FdE48D8086CC42cAa98E825C5B643, value: 10 [10000000000000000000, 18 decimals]) |
      | 155 | Mint(caller: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, onBehalfOf: 0x8d1dac82259FdE48D8086CC42cAa98E825C5B643, value: 10 [10000000000000000000, 18 decimals], balanceIncrease: 0, index: 1 [1000000000000000000000000000, 27 decimals]) |

      #### 0x6B408d6c479C304794abC60a4693A3AD2D3c2D0D (AaveV3MegaEth.ASSETS.USDm.V_TOKEN)

      | index | event |
      | --- | --- |
      | 23 | Initialized(underlyingAsset: 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7, pool: 0x7e324AbC5De01d112AfC03a584966ff199741C28, incentivesController: 0x3691FF69e22c1353df9F8b2c0B1B16aA5fEEc389, debtTokenDecimals: 18, debtTokenName: Aave MegaEth Variable Debt USDm, debtTokenSymbol: variableDebtMegUSDm, params: 0x) |

      #### 0xaD2de503b5c723371d6B38A5224A2E12E103DfB8 (AaveV3MegaEth.ASSETS.wstETH.A_TOKEN)

      | index | event |
      | --- | --- |
      | 27 | Initialized(underlyingAsset: 0x601aC63637933D88285A025C685AC4e9a92a98dA, pool: 0x7e324AbC5De01d112AfC03a584966ff199741C28, treasury: 0x7E195b3fc91fDd51A9CD5070cC044602212Ac983, incentivesController: 0x3691FF69e22c1353df9F8b2c0B1B16aA5fEEc389, aTokenDecimals: 18, aTokenName: Aave MegaEth wstETH, aTokenSymbol: aMegwstETH, params: 0x) |
      | 162 | Transfer(from: 0x0000000000000000000000000000000000000000, to: 0x8d1dac82259FdE48D8086CC42cAa98E825C5B643, value: 0.0025 [2500000000000000, 18 decimals]) |
      | 163 | Mint(caller: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, onBehalfOf: 0x8d1dac82259FdE48D8086CC42cAa98E825C5B643, value: 0.0025 [2500000000000000, 18 decimals], balanceIncrease: 0, index: 1 [1000000000000000000000000000, 27 decimals]) |

      #### 0x259A9Cd7628f6D15ef384887dd90bb7A0283fEf9 (AaveV3MegaEth.ASSETS.wstETH.V_TOKEN)

      | index | event |
      | --- | --- |
      | 28 | Initialized(underlyingAsset: 0x601aC63637933D88285A025C685AC4e9a92a98dA, pool: 0x7e324AbC5De01d112AfC03a584966ff199741C28, incentivesController: 0x3691FF69e22c1353df9F8b2c0B1B16aA5fEEc389, debtTokenDecimals: 18, debtTokenName: Aave MegaEth Variable Debt wstETH, debtTokenSymbol: variableDebtMegwstETH, params: 0x) |

      #### 0xb8578af311353b44B14bb4480EBB4DE608EC7e1B (AaveV3MegaEth.ASSETS.wrsETH.A_TOKEN)

      | index | event |
      | --- | --- |
      | 32 | Initialized(underlyingAsset: 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F, pool: 0x7e324AbC5De01d112AfC03a584966ff199741C28, treasury: 0x7E195b3fc91fDd51A9CD5070cC044602212Ac983, incentivesController: 0x3691FF69e22c1353df9F8b2c0B1B16aA5fEEc389, aTokenDecimals: 18, aTokenName: Aave MegaEth wrsETH, aTokenSymbol: aMegwrsETH, params: 0x) |
      | 171 | Transfer(from: 0x0000000000000000000000000000000000000000, to: 0x8d1dac82259FdE48D8086CC42cAa98E825C5B643, value: 0.0025 [2500000000000000, 18 decimals]) |
      | 172 | Mint(caller: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, onBehalfOf: 0x8d1dac82259FdE48D8086CC42cAa98E825C5B643, value: 0.0025 [2500000000000000, 18 decimals], balanceIncrease: 0, index: 1 [1000000000000000000000000000, 27 decimals]) |

      #### 0xd7B71D855bBAcd3f11F623400bc870AB3448AfF7 (AaveV3MegaEth.ASSETS.wrsETH.V_TOKEN)

      | index | event |
      | --- | --- |
      | 33 | Initialized(underlyingAsset: 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F, pool: 0x7e324AbC5De01d112AfC03a584966ff199741C28, incentivesController: 0x3691FF69e22c1353df9F8b2c0B1B16aA5fEEc389, debtTokenDecimals: 18, debtTokenName: Aave MegaEth Variable Debt wrsETH, debtTokenSymbol: variableDebtMegwrsETH, params: 0x) |

      #### 0x03C99Cce547b1c2E74442b73E6f588A66D19597e (AaveV3MegaEth.ASSETS.ezETH.A_TOKEN)

      | index | event |
      | --- | --- |
      | 37 | Initialized(underlyingAsset: 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57, pool: 0x7e324AbC5De01d112AfC03a584966ff199741C28, treasury: 0x7E195b3fc91fDd51A9CD5070cC044602212Ac983, incentivesController: 0x3691FF69e22c1353df9F8b2c0B1B16aA5fEEc389, aTokenDecimals: 18, aTokenName: Aave MegaEth ezETH, aTokenSymbol: aMegezETH, params: 0x) |
      | 180 | Transfer(from: 0x0000000000000000000000000000000000000000, to: 0x8d1dac82259FdE48D8086CC42cAa98E825C5B643, value: 0.0025 [2500000000000000, 18 decimals]) |
      | 181 | Mint(caller: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, onBehalfOf: 0x8d1dac82259FdE48D8086CC42cAa98E825C5B643, value: 0.0025 [2500000000000000, 18 decimals], balanceIncrease: 0, index: 1 [1000000000000000000000000000, 27 decimals]) |

      #### 0x1505f48Bd4db0fF8B28817D2C0Fb95Abcb8eEbbc (AaveV3MegaEth.ASSETS.ezETH.V_TOKEN)

      | index | event |
      | --- | --- |
      | 38 | Initialized(underlyingAsset: 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57, pool: 0x7e324AbC5De01d112AfC03a584966ff199741C28, incentivesController: 0x3691FF69e22c1353df9F8b2c0B1B16aA5fEEc389, debtTokenDecimals: 18, debtTokenName: Aave MegaEth Variable Debt ezETH, debtTokenSymbol: variableDebtMegezETH, params: 0x) |

      #### 0x7e324AbC5De01d112AfC03a584966ff199741C28 (AaveV3MegaEth.POOL)

      | index | event |
      | --- | --- |
      | 60 | ReserveDataUpdated(reserve: 0x4200000000000000000000000000000000000006 (symbol: WETH), liquidityRate: 0, stableBorrowRate: 0, variableBorrowRate: 0, liquidityIndex: 1 [1000000000000000000000000000, 27 decimals], variableBorrowIndex: 1 [1000000000000000000000000000, 27 decimals]) |
      | 66 | ReserveDataUpdated(reserve: 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (symbol: BTC.b), liquidityRate: 0, stableBorrowRate: 0, variableBorrowRate: 0, liquidityIndex: 1 [1000000000000000000000000000, 27 decimals], variableBorrowIndex: 1 [1000000000000000000000000000, 27 decimals]) |
      | 72 | ReserveDataUpdated(reserve: 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (symbol: USDT0), liquidityRate: 0, stableBorrowRate: 0, variableBorrowRate: 0, liquidityIndex: 1 [1000000000000000000000000000, 27 decimals], variableBorrowIndex: 1 [1000000000000000000000000000, 27 decimals]) |
      | 78 | ReserveDataUpdated(reserve: 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (symbol: USDm), liquidityRate: 0, stableBorrowRate: 0, variableBorrowRate: 0, liquidityIndex: 1 [1000000000000000000000000000, 27 decimals], variableBorrowIndex: 1 [1000000000000000000000000000, 27 decimals]) |
      | 84 | ReserveDataUpdated(reserve: 0x601aC63637933D88285A025C685AC4e9a92a98dA (symbol: wstETH), liquidityRate: 0, stableBorrowRate: 0, variableBorrowRate: 0, liquidityIndex: 1 [1000000000000000000000000000, 27 decimals], variableBorrowIndex: 1 [1000000000000000000000000000, 27 decimals]) |
      | 90 | ReserveDataUpdated(reserve: 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (symbol: wrsETH), liquidityRate: 0, stableBorrowRate: 0, variableBorrowRate: 0, liquidityIndex: 1 [1000000000000000000000000000, 27 decimals], variableBorrowIndex: 1 [1000000000000000000000000000, 27 decimals]) |
      | 96 | ReserveDataUpdated(reserve: 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (symbol: ezETH), liquidityRate: 0, stableBorrowRate: 0, variableBorrowRate: 0, liquidityIndex: 1 [1000000000000000000000000000, 27 decimals], variableBorrowIndex: 1 [1000000000000000000000000000, 27 decimals]) |
      | 127 | ReserveDataUpdated(reserve: 0x4200000000000000000000000000000000000006 (symbol: WETH), liquidityRate: 0, stableBorrowRate: 0, variableBorrowRate: 0, liquidityIndex: 1 [1000000000000000000000000000, 27 decimals], variableBorrowIndex: 1 [1000000000000000000000000000, 27 decimals]) |
      | 131 | Supply(reserve: 0x4200000000000000000000000000000000000006 (symbol: WETH), onBehalfOf: 0x8d1dac82259FdE48D8086CC42cAa98E825C5B643, referralCode: 0, user: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, amount: 0.0025 [2500000000000000, 18 decimals]) |
      | 135 | ReserveDataUpdated(reserve: 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (symbol: BTC.b), liquidityRate: 0, stableBorrowRate: 0, variableBorrowRate: 0, liquidityIndex: 1 [1000000000000000000000000000, 27 decimals], variableBorrowIndex: 1 [1000000000000000000000000000, 27 decimals]) |
      | 139 | Supply(reserve: 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (symbol: BTC.b), onBehalfOf: 0x8d1dac82259FdE48D8086CC42cAa98E825C5B643, referralCode: 0, user: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, amount: 0.0005 [50000, 8 decimals]) |
      | 143 | ReserveDataUpdated(reserve: 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (symbol: USDT0), liquidityRate: 0, stableBorrowRate: 0, variableBorrowRate: 0, liquidityIndex: 1 [1000000000000000000000000000, 27 decimals], variableBorrowIndex: 1 [1000000000000000000000000000, 27 decimals]) |
      | 148 | Supply(reserve: 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (symbol: USDT0), onBehalfOf: 0x8d1dac82259FdE48D8086CC42cAa98E825C5B643, referralCode: 0, user: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, amount: 10 [10000000, 6 decimals]) |
      | 152 | ReserveDataUpdated(reserve: 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (symbol: USDm), liquidityRate: 0, stableBorrowRate: 0, variableBorrowRate: 0, liquidityIndex: 1 [1000000000000000000000000000, 27 decimals], variableBorrowIndex: 1 [1000000000000000000000000000, 27 decimals]) |
      | 156 | Supply(reserve: 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (symbol: USDm), onBehalfOf: 0x8d1dac82259FdE48D8086CC42cAa98E825C5B643, referralCode: 0, user: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, amount: 10 [10000000000000000000, 18 decimals]) |
      | 160 | ReserveDataUpdated(reserve: 0x601aC63637933D88285A025C685AC4e9a92a98dA (symbol: wstETH), liquidityRate: 0, stableBorrowRate: 0, variableBorrowRate: 0, liquidityIndex: 1 [1000000000000000000000000000, 27 decimals], variableBorrowIndex: 1 [1000000000000000000000000000, 27 decimals]) |
      | 164 | Supply(reserve: 0x601aC63637933D88285A025C685AC4e9a92a98dA (symbol: wstETH), onBehalfOf: 0x8d1dac82259FdE48D8086CC42cAa98E825C5B643, referralCode: 0, user: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, amount: 0.0025 [2500000000000000, 18 decimals]) |
      | 168 | ReserveDataUpdated(reserve: 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (symbol: wrsETH), liquidityRate: 0, stableBorrowRate: 0, variableBorrowRate: 0, liquidityIndex: 1 [1000000000000000000000000000, 27 decimals], variableBorrowIndex: 1 [1000000000000000000000000000, 27 decimals]) |
      | 173 | Supply(reserve: 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (symbol: wrsETH), onBehalfOf: 0x8d1dac82259FdE48D8086CC42cAa98E825C5B643, referralCode: 0, user: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, amount: 0.0025 [2500000000000000, 18 decimals]) |
      | 177 | ReserveDataUpdated(reserve: 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (symbol: ezETH), liquidityRate: 0, stableBorrowRate: 0, variableBorrowRate: 0, liquidityIndex: 1 [1000000000000000000000000000, 27 decimals], variableBorrowIndex: 1 [1000000000000000000000000000, 27 decimals]) |
      | 182 | Supply(reserve: 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (symbol: ezETH), onBehalfOf: 0x8d1dac82259FdE48D8086CC42cAa98E825C5B643, referralCode: 0, user: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, amount: 0.0025 [2500000000000000, 18 decimals]) |

      #### 0x4200000000000000000000000000000000000006 (AaveV3MegaEth.ASSETS.WETH.UNDERLYING)

      | index | event |
      | --- | --- |
      | 126 | Approval(owner: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, spender: 0x7e324AbC5De01d112AfC03a584966ff199741C28, value: 0.0025 [2500000000000000, 18 decimals]) |
      | 128 | Transfer(from: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, to: 0xa31E6b433382062e8A1dA41485f7b234D97c3f4d, value: 0.0025 [2500000000000000, 18 decimals]) |

      #### 0xCfC61568b91414DBf7Bb1a4344C633E1aB214bC9 (AaveV3MegaEth.EMISSION_MANAGER)

      | index | event |
      | --- | --- |
      | 132 | EmissionAdminUpdated(reward: 0x4200000000000000000000000000000000000006, oldAdmin: 0x0000000000000000000000000000000000000000, newAdmin: 0xac140648435d03f784879cd789130F22Ef588Fcd) |
      | 133 | EmissionAdminUpdated(reward: 0xa31E6b433382062e8A1dA41485f7b234D97c3f4d, oldAdmin: 0x0000000000000000000000000000000000000000, newAdmin: 0xac140648435d03f784879cd789130F22Ef588Fcd) |
      | 140 | EmissionAdminUpdated(reward: 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072, oldAdmin: 0x0000000000000000000000000000000000000000, newAdmin: 0xac140648435d03f784879cd789130F22Ef588Fcd) |
      | 141 | EmissionAdminUpdated(reward: 0x0889d59eA7178ee5B71DA01949a5cB42aaFBe337, oldAdmin: 0x0000000000000000000000000000000000000000, newAdmin: 0xac140648435d03f784879cd789130F22Ef588Fcd) |
      | 149 | EmissionAdminUpdated(reward: 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb, oldAdmin: 0x0000000000000000000000000000000000000000, newAdmin: 0xac140648435d03f784879cd789130F22Ef588Fcd) |
      | 150 | EmissionAdminUpdated(reward: 0xE2283E01a667b512c340f19B499d86fbc885D5Ef, oldAdmin: 0x0000000000000000000000000000000000000000, newAdmin: 0xac140648435d03f784879cd789130F22Ef588Fcd) |
      | 157 | EmissionAdminUpdated(reward: 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7, oldAdmin: 0x0000000000000000000000000000000000000000, newAdmin: 0xac140648435d03f784879cd789130F22Ef588Fcd) |
      | 158 | EmissionAdminUpdated(reward: 0x5dF82810CB4B8f3e0Da3c031cCc9208ee9cF9500, oldAdmin: 0x0000000000000000000000000000000000000000, newAdmin: 0xac140648435d03f784879cd789130F22Ef588Fcd) |
      | 165 | EmissionAdminUpdated(reward: 0x601aC63637933D88285A025C685AC4e9a92a98dA, oldAdmin: 0x0000000000000000000000000000000000000000, newAdmin: 0xac140648435d03f784879cd789130F22Ef588Fcd) |
      | 166 | EmissionAdminUpdated(reward: 0xaD2de503b5c723371d6B38A5224A2E12E103DfB8, oldAdmin: 0x0000000000000000000000000000000000000000, newAdmin: 0xac140648435d03f784879cd789130F22Ef588Fcd) |
      | 174 | EmissionAdminUpdated(reward: 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F, oldAdmin: 0x0000000000000000000000000000000000000000, newAdmin: 0xac140648435d03f784879cd789130F22Ef588Fcd) |
      | 175 | EmissionAdminUpdated(reward: 0xb8578af311353b44B14bb4480EBB4DE608EC7e1B, oldAdmin: 0x0000000000000000000000000000000000000000, newAdmin: 0xac140648435d03f784879cd789130F22Ef588Fcd) |
      | 183 | EmissionAdminUpdated(reward: 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57, oldAdmin: 0x0000000000000000000000000000000000000000, newAdmin: 0xac140648435d03f784879cd789130F22Ef588Fcd) |
      | 184 | EmissionAdminUpdated(reward: 0x03C99Cce547b1c2E74442b73E6f588A66D19597e, oldAdmin: 0x0000000000000000000000000000000000000000, newAdmin: 0xac140648435d03f784879cd789130F22Ef588Fcd) |

      #### 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (AaveV3MegaEth.ASSETS.BTCb.UNDERLYING)

      | index | event |
      | --- | --- |
      | 134 | Approval(owner: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, spender: 0x7e324AbC5De01d112AfC03a584966ff199741C28, value: 0.0005 [50000, 8 decimals]) |
      | 136 | Transfer(from: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, to: 0x0889d59eA7178ee5B71DA01949a5cB42aaFBe337, value: 0.0005 [50000, 8 decimals]) |

      #### 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING)

      | index | event |
      | --- | --- |
      | 142 | Approval(owner: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, spender: 0x7e324AbC5De01d112AfC03a584966ff199741C28, value: 10 [10000000, 6 decimals]) |
      | 144 | Transfer(from: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, to: 0xE2283E01a667b512c340f19B499d86fbc885D5Ef, value: 10 [10000000, 6 decimals]) |
      | 145 | Approval(owner: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, spender: 0x7e324AbC5De01d112AfC03a584966ff199741C28, value: 0 [0, 6 decimals]) |

      #### 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING)

      | index | event |
      | --- | --- |
      | 151 | Approval(owner: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, spender: 0x7e324AbC5De01d112AfC03a584966ff199741C28, value: 10 [10000000000000000000, 18 decimals]) |
      | 153 | Transfer(from: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, to: 0x5dF82810CB4B8f3e0Da3c031cCc9208ee9cF9500, value: 10 [10000000000000000000, 18 decimals]) |

      #### 0x601aC63637933D88285A025C685AC4e9a92a98dA (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING)

      | index | event |
      | --- | --- |
      | 159 | Approval(owner: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, spender: 0x7e324AbC5De01d112AfC03a584966ff199741C28, value: 0.0025 [2500000000000000, 18 decimals]) |
      | 161 | Transfer(from: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, to: 0xaD2de503b5c723371d6B38A5224A2E12E103DfB8, value: 0.0025 [2500000000000000, 18 decimals]) |

      #### 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (AaveV3MegaEth.ASSETS.wrsETH.UNDERLYING)

      | index | event |
      | --- | --- |
      | 167 | Approval(owner: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, spender: 0x7e324AbC5De01d112AfC03a584966ff199741C28, value: 0.0025 [2500000000000000, 18 decimals]) |
      | 169 | Approval(owner: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, spender: 0x7e324AbC5De01d112AfC03a584966ff199741C28, value: 0 [0, 18 decimals]) |
      | 170 | Transfer(from: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, to: 0xb8578af311353b44B14bb4480EBB4DE608EC7e1B, value: 0.0025 [2500000000000000, 18 decimals]) |

      #### 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (AaveV3MegaEth.ASSETS.ezETH.UNDERLYING)

      | index | event |
      | --- | --- |
      | 176 | Approval(owner: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, spender: 0x7e324AbC5De01d112AfC03a584966ff199741C28, value: 0.0025 [2500000000000000, 18 decimals]) |
      | 178 | Approval(owner: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, spender: 0x7e324AbC5De01d112AfC03a584966ff199741C28, value: 0 [0, 18 decimals]) |
      | 179 | Transfer(from: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19, to: 0x03C99Cce547b1c2E74442b73E6f588A66D19597e, value: 0.0025 [2500000000000000, 18 decimals]) |

      #### 0x390D369C3878F2C5205CFb6Ec7154FfA65491c3D (AaveV3MegaEth.ACL_MANAGER)

      | index | event |
      | --- | --- |
      | 185 | RoleGranted(role: 0x12ad05bde78c5ab75238ce885307f96ecd482bb402ef831f99e7018a0f169b7b, account: 0x8126eAd44383cb52Cf6A1bb70F1b4d7399DE34ef, sender: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19) |
      | 186 | RoleGranted(role: 0x8aa855a911518ecfbe5bc3088c8f3dda7badf130faaf8ace33fdc33828e18167, account: 0xbcC2Cf1fA3bE94B16061d51970628a87c7Cd5160, sender: 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19) |

      #### 0x46Dcd5F4600319b02649Fd76B55aA6c1035CA478 (AaveV3MegaEth.POOL_ADDRESSES_PROVIDER)

      | index | event |
      | --- | --- |
      | 187 | topics: \`0x5326514eeca90494a14bedabcff812a0e683029ee85d1e23824d44fd14cd6ae7\`, \`0x0000000000000000000000000000000000000000000000000000000000000000\`, \`0x00000000000000000000000098f756b77d6fde14e08bb064b248ec7512f9f8ba\`, data: \`0x\` |

      #### 0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19 (AaveV3MegaEth.ACL_ADMIN, GovernanceV3MegaEth.EXECUTOR_LVL_1)

      | index | event |
      | --- | --- |
      | 188 | ExecutedAction(target: 0x3a0A755D940283cD96D69F88645BeaA2bAfBC0bb, value: 0, signature: execute(), data: 0x, executionTime: 1770659966, withDelegatecall: true, resultData: 0x) |

      #### 0x80e11cB895a23C901a990239E5534054C66476B5 (GovernanceV3MegaEth.PAYLOADS_CONTROLLER)

      | index | event |
      | --- | --- |
      | 189 | PayloadExecuted(payloadId: 1) |

      ## Raw storage changes

      ### 0x03c99cce547b1c2e74442b73e6f588a66d19597e (AaveV3MegaEth.ASSETS.ezETH.A_TOKEN)

      **Nonce diff**: 0 → 1

      | label | type | decoded previous value | decoded new value |
      | --- | --- | --- | --- |
      | lastInitializedRevision | uint256 | 0 | 5 |
      | initializing | bool | false | false |
      | _totalSupply | uint256 | 0 | 2500000000000000 |
      | _name | string |  | Aave MegaEth ezETH |
      | _symbol | string |  | aMegezETH |
      | _decimals | uint8 | 0 | 18 |
      | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x13565618a57ffd83ab99592ef5e80d48c88d90de793f44d372be5602a9a4c4af |
      | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 |
      | _userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643] | mapping(address => struct IncentivizedERC20.UserState) | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x00000000033b2e3c9fd0803ce800000000000000000000000008e1bc9bf04000 |
      | 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x00000000000000000000000034ca0a24e0b7cbceb77088ae539f57ba0650fc05 |

      ### 0x0889d59ea7178ee5b71da01949a5cb42aafbe337 (AaveV3MegaEth.ASSETS.BTCb.A_TOKEN)

      **Nonce diff**: 0 → 1

      | label | type | decoded previous value | decoded new value |
      | --- | --- | --- | --- |
      | lastInitializedRevision | uint256 | 0 | 5 |
      | initializing | bool | false | false |
      | _totalSupply | uint256 | 0 | 50000 |
      | _name | string |  | Aave MegaEth BTCb |
      | _symbol | string |  | aMegBTCb |
      | _decimals | uint8 | 0 | 8 |
      | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x24eaa197304464c49cde553f25a253519ae8b932ea10d284f49ccf5468102c46 |
      | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 |
      | _userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643] | mapping(address => struct IncentivizedERC20.UserState) | 0x | 0x00000000033b2e3c9fd0803ce80000000000000000000000000000000000c3 |
      | 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x00000000000000000000000034ca0a24e0b7cbceb77088ae539f57ba0650fc05 |

      ### 0x09601a65e7de7bc8a19813d263dd9e98bfdc3c57 (AaveV3MegaEth.ASSETS.ezETH.UNDERLYING)

      | slot | previous value | new value |
      | --- | --- | --- |
      | 0x32e08ec388bd03cb8e0fb9e71795585b8d5c1d03896c545e523e36ce4e50debd | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0x36bfa44cf947ee302f4afd595aee5c8f16493d90642fea969179ba9ea55bca0c | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000008e1bc9bf04000 |
      | 0xce693b0befa09013aa348b2de6dfacddecacae2c838457c156fcf2d9e1b26771 | 0x0000000000000000000000000000000000000000000000000008e1bc9bf04000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |

      ### 0x09adccc7af2abd356c18a4cadf2e5cc250f300e9 (AaveV3MegaEth.ASSETS.WETH.V_TOKEN)

      **Nonce diff**: 0 → 1

      | label | type | decoded previous value | decoded new value |
      | --- | --- | --- | --- |
      | lastInitializedRevision | uint256 | 0 | 5 |
      | initializing | bool | false | false |
      | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x9badf6634af23284dff0d25ea4236d5b9fff5f22cf00d092dd82a46c8c6a1b04 |
      | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0x4200000000000000000000000000000000000006 |
      | _name | string |  | Aave MegaEth Variable Debt WETH |
      | _symbol | string |  | variableDebtMegWETH |
      | _decimals | uint8 | 0 | 18 |
      | 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000ff01493c22208de3a89fe9cafbdae103acc72af8 |

      ### 0x1505f48bd4db0ff8b28817d2c0fb95abcb8eebbc (AaveV3MegaEth.ASSETS.ezETH.V_TOKEN)

      **Nonce diff**: 0 → 1

      | label | type | decoded previous value | decoded new value |
      | --- | --- | --- | --- |
      | lastInitializedRevision | uint256 | 0 | 5 |
      | initializing | bool | false | false |
      | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x05e192f9d82dd91e9180f380e2b6fd47e8c7738b734022e264eef964bfc896f6 |
      | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 |
      | _name | string |  | Aave MegaEth Variable Debt ezETH |
      | _symbol | string |  | variableDebtMegezETH |
      | _decimals | uint8 | 0 | 18 |
      | 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000ff01493c22208de3a89fe9cafbdae103acc72af8 |
      | _name[0] | string | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x41617665204d656761457468205661726961626c65204465627420657a455448 |

      ### 0x15b550784928c5b1a93849ca5d6caa18b2545b6d (AaveV3MegaEth.ASSETS.BTCb.V_TOKEN)

      **Nonce diff**: 0 → 1

      | label | type | decoded previous value | decoded new value |
      | --- | --- | --- | --- |
      | lastInitializedRevision | uint256 | 0 | 5 |
      | initializing | bool | false | false |
      | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0xb495d25c3a7439d697603cfc9a69e6ed5c9894e2c41c6d8537f1e8b34633bd41 |
      | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 |
      | _name | string |  | Aave MegaEth Variable Debt BTCb |
      | _symbol | string |  | variableDebtMegBTCb |
      | _decimals | uint8 | 0 | 8 |
      | 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000ff01493c22208de3a89fe9cafbdae103acc72af8 |

      ### 0x186f45b6e33fcf531c1542509b199646eb7fa968

      **Nonce diff**: 1 → 15

      ### 0x259a9cd7628f6d15ef384887dd90bb7a0283fef9 (AaveV3MegaEth.ASSETS.wstETH.V_TOKEN)

      **Nonce diff**: 0 → 1

      | label | type | decoded previous value | decoded new value |
      | --- | --- | --- | --- |
      | lastInitializedRevision | uint256 | 0 | 5 |
      | initializing | bool | false | false |
      | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0xbdaa76d0be1d866769579087a017f969e9063e39bc7bf8b32359cacc29a7747f |
      | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0x601aC63637933D88285A025C685AC4e9a92a98dA |
      | _name | string |  | Aave MegaEth Variable Debt wstETH |
      | _symbol | string |  | variableDebtMegwstETH |
      | _decimals | uint8 | 0 | 18 |
      | 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000ff01493c22208de3a89fe9cafbdae103acc72af8 |
      | _name[0] | string | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x41617665204d656761457468205661726961626c652044656274207773744554 |
      | _name[1] | string | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x4800000000000000000000000000000000000000000000000000000000000000 |

      ### 0x390d369c3878f2c5205cfb6ec7154ffa65491c3d (AaveV3MegaEth.ACL_MANAGER)

      | slot | previous value | new value |
      | --- | --- | --- |
      | 0x53663448c060bd36a5250c5239b57cf713dae04a12c7f2c9f938bfa5631a501a (_roles[0x8aa855a911518ecfbe5bc3088c8f3dda7badf130faaf8ace33fdc33828e18167][0x000000000000000000000000bcc2cf1fa3be94b16061d51970628a87c7cd5160]) | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000001 |
      | 0xa03d6bf8018d7e48609bfb04c4ec836e309957a573d719d6849321188e2d281f (_roles[0x12ad05bde78c5ab75238ce885307f96ecd482bb402ef831f99e7018a0f169b7b][0x0000000000000000000000008126ead44383cb52cf6a1bb70f1b4d7399de34ef]) | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000001 |

      ### 0x3effebdd435217a8b485dfaefdecf766f2a3c05b (AaveV3MegaEth.POOL_CONFIGURATOR_IMPL)

      **Nonce diff**: 1 → 15

      ### 0x4200000000000000000000000000000000000006 (AaveV3MegaEth.ASSETS.WETH.UNDERLYING)

      | label | type | decoded previous value | decoded new value |
      | --- | --- | --- | --- |
      | _balanceOf[0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19] | mapping(address => uint256) | 2500000000000000 | 0 |
      | _allowance[0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19][0x7e324AbC5De01d112AfC03a584966ff199741C28] | mapping(address => mapping(address => uint256)) | 0 | 0 |
      | _balanceOf[0xa31E6b433382062e8A1dA41485f7b234D97c3f4d] | mapping(address => uint256) | 0 | 2500000000000000 |

      ### 0x421117d7319e96d831972b3f7e970bbfe29c4f21 (AaveV3MegaEth.ORACLE)

      | label | type | decoded previous value | decoded new value |
      | --- | --- | --- | --- |
      | assetsSources[0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7] | mapping(address => contract AggregatorInterface) | 0x0000000000000000000000000000000000000000 | 0xe5448B8318493c6e3F72E21e8BDB8242d3299FB5 |
      | assetsSources[0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb] | mapping(address => contract AggregatorInterface) | 0x0000000000000000000000000000000000000000 | 0xAe95ff42e16468AB1DfD405c9533C9b67d87d66A |
      | assetsSources[0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F] | mapping(address => contract AggregatorInterface) | 0x0000000000000000000000000000000000000000 | 0x6356b92Bc636CCe722e0F53DDc24a86baE64216E |
      | assetsSources[0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072] | mapping(address => contract AggregatorInterface) | 0x0000000000000000000000000000000000000000 | 0xc6E3007B597f6F5a6330d43053D1EF73cCbbE721 |
      | assetsSources[0x601aC63637933D88285A025C685AC4e9a92a98dA] | mapping(address => contract AggregatorInterface) | 0x0000000000000000000000000000000000000000 | 0x376397e34eA968e79DC6F629E6210ba25311a3ce |
      | assetsSources[0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57] | mapping(address => contract AggregatorInterface) | 0x0000000000000000000000000000000000000000 | 0xd7Da71D3acf07C604A925799B0b48E2Ec607584D |
      | assetsSources[0x4200000000000000000000000000000000000006] | mapping(address => contract AggregatorInterface) | 0x0000000000000000000000000000000000000000 | 0xcA4e254D95637DE95E2a2F79244b03380d697feD |

      ### 0x46dcd5f4600319b02649fd76b55aa6c1035ca478 (AaveV3MegaEth.POOL_ADDRESSES_PROVIDER)

      | slot | previous value | new value |
      | --- | --- | --- |
      | 0x0d2c1bcee56447b4f46248272f34207a580a5c40f666a31f4e2fbb470ea53ab8 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x00000000000000000000000098f756b77d6fde14e08bb064b248ec7512f9f8ba |

      ### 0x4fc44be15e9b6e30c1e774e2c87a21d3e8b5403f (AaveV3MegaEth.ASSETS.wrsETH.UNDERLYING)

      | slot | previous value | new value |
      | --- | --- | --- |
      | 0x037acde50a689309ee9a8dbaed20047fbc7ede9f99e5ca3fd2798e835253d672 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000008e1bc9bf04000 |
      | 0x16ca11a1f6f7473ca0434162515ad20750ada68476513902cb0a61bdde8b39b0 | 0x0000000000000000000000000000000000000000000000000008e1bc9bf04000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0xa085589e50594358e6df87719528ac207c811c9816ac1f6fabe3cb3e82ebbf1f | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |

      ### 0x5cc4f782cfe249286476a7effd9d7bd215768194 (AaveV3MegaEth.ASSETS.WETH.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.BTCb.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.USDT0.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.USDm.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.wstETH.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.wrsETH.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.ezETH.INTEREST_RATE_STRATEGY)

      | label | type | decoded previous value | decoded new value |
      | --- | --- | --- | --- |
      | _interestRateData[0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7] | mapping(address => struct IDefaultInterestRateStrategyV2.InterestRateData) | 0x | 0x0000000000000000000000000000000000000000 |
      | _interestRateData[0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb] | mapping(address => struct IDefaultInterestRateStrategyV2.InterestRateData) | 0x | 0x0000000000000000000000000000000000000000 |
      | _interestRateData[0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F] | mapping(address => struct IDefaultInterestRateStrategyV2.InterestRateData) | 0x | 0x0000000000000000000000000000000000000000 |
      | _interestRateData[0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072] | mapping(address => struct IDefaultInterestRateStrategyV2.InterestRateData) | 0x | 0x0000000000000000000000000000000000000000 |
      | _interestRateData[0x601aC63637933D88285A025C685AC4e9a92a98dA] | mapping(address => struct IDefaultInterestRateStrategyV2.InterestRateData) | 0x | 0x0000000000000000000000000000000000000000 |
      | _interestRateData[0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57] | mapping(address => struct IDefaultInterestRateStrategyV2.InterestRateData) | 0x | 0x0000000000000000000000000000000000000000 |
      | _interestRateData[0x4200000000000000000000000000000000000006] | mapping(address => struct IDefaultInterestRateStrategyV2.InterestRateData) | 0x | 0x0000000000000000000000000000000000000000 |

      ### 0x5df82810cb4b8f3e0da3c031ccc9208ee9cf9500 (AaveV3MegaEth.ASSETS.USDm.A_TOKEN)

      **Nonce diff**: 0 → 1

      | label | type | decoded previous value | decoded new value |
      | --- | --- | --- | --- |
      | lastInitializedRevision | uint256 | 0 | 5 |
      | initializing | bool | false | false |
      | _totalSupply | uint256 | 0 | 10000000000000000000 |
      | _name | string |  | Aave MegaEth USDm |
      | _symbol | string |  | aMegUSDm |
      | _decimals | uint8 | 0 | 18 |
      | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x2270488a78a7ff0e4d693a70a157850e0a2665f34e392a841fea757ea3523b4f |
      | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 |
      | _userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643] | mapping(address => struct IncentivizedERC20.UserState) | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x00000000033b2e3c9fd0803ce800000000000000000000008ac7230489e80000 |
      | 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x00000000000000000000000034ca0a24e0b7cbceb77088ae539f57ba0650fc05 |

      ### 0x601ac63637933d88285a025c685ac4e9a92a98da (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING)

      | slot | previous value | new value |
      | --- | --- | --- |
      | 0x428cfd5e8d7cebba8a0c306412105762a84304b4167a9f33d00eb7b630efa30e | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000008e1bc9bf04000 |
      | 0x4ad958461d38e50759ecd2d67cb1a2afbffab25bae32fd33026cf7bbf0f0da07 | 0x0000000000000000000000000000000000000000000000000008e1bc9bf04000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0x5d6747c86b1c081bb00df65b4be0a48ac12eb92eacca7bc2f5ba6afdb3b971d8 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |

      ### 0x6b408d6c479c304794abc60a4693a3ad2d3c2d0d (AaveV3MegaEth.ASSETS.USDm.V_TOKEN)

      **Nonce diff**: 0 → 1

      | label | type | decoded previous value | decoded new value |
      | --- | --- | --- | --- |
      | lastInitializedRevision | uint256 | 0 | 5 |
      | initializing | bool | false | false |
      | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x772b118aa1ee532d161218687221075d88e5af9380878ecf61c6cba9b4478d6b |
      | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 |
      | _name | string |  | Aave MegaEth Variable Debt USDm |
      | _symbol | string |  | variableDebtMegUSDm |
      | _decimals | uint8 | 0 | 18 |
      | 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000ff01493c22208de3a89fe9cafbdae103acc72af8 |

      ### 0x7e324abc5de01d112afc03a584966ff199741c28 (AaveV3MegaEth.POOL)

      | label | type | decoded previous value | decoded new value |
      | --- | --- | --- | --- |
      | __DEPRECATED_maxStableRateBorrowSizePercent | uint64 | 0 | 129127208515966861312 |
      | _eModeCategories[6] | mapping(uint8 => struct DataTypes.EModeCategory) | 0x00000000000000000000000000000000000000000000000000002774251c24 | 0x00000000000000000000000000000000000000000000000000402774251c24 |
      | 0x01290583d43e205f46f8d824d1236df318521e471f570a5b36fa1844856e40d7 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x657a45544820436f7272656c6174656400000000000000000000000000000020 |
      | 0x01290583d43e205f46f8d824d1236df318521e471f570a5b36fa1844856e40d8 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000001 |
      | _reservesList[5] | mapping(uint256 => address) | 0x0000000000000000000000000000000000000000 | 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F |
      | _reservesList[6] | mapping(uint256 => address) | 0x0000000000000000000000000000000000000000 | 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 |
      | _reserves[0x601aC63637933D88285A025C685AC4e9a92a98dA] | mapping(address => struct DataTypes.ReserveData) | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x100000000000000000000003e800000001400000000107d08112000000000000 |
      | 0x4853baaf8dbe8a1046261c0b8387595b5dac8597867ac12c5138507a4775d92d | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000033b2e3c9fd0803ce8000000 |
      | 0x4853baaf8dbe8a1046261c0b8387595b5dac8597867ac12c5138507a4775d92e | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000033b2e3c9fd0803ce8000000 |
      | 0x4853baaf8dbe8a1046261c0b8387595b5dac8597867ac12c5138507a4775d92f | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000400698a207e00000000000000000000000000000000 |
      | 0x4853baaf8dbe8a1046261c0b8387595b5dac8597867ac12c5138507a4775d930 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000ad2de503b5c723371d6b38a5224a2e12e103dfb8 |
      | 0x4853baaf8dbe8a1046261c0b8387595b5dac8597867ac12c5138507a4775d932 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000259a9cd7628f6d15ef384887dd90bb7a0283fef9 |
      | 0x4853baaf8dbe8a1046261c0b8387595b5dac8597867ac12c5138507a4775d934 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x00000000000000000008e1bc9bf0400000000000000000000000000000000000 |
      | _reservesList[2] | mapping(uint256 => address) | 0x0000000000000000000000000000000000000000 | 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb |
      | _reservesList[4] | mapping(uint256 => address) | 0x0000000000000000000000000000000000000000 | 0x601aC63637933D88285A025C685AC4e9a92a98dA |
      | _reservesList[0] | mapping(uint256 => address) | 0x0000000000000000000000000000000000000000 | 0x4200000000000000000000000000000000000006 |
      | _eModeCategories[5] | mapping(uint8 => struct DataTypes.EModeCategory) | 0x00000000000000000000000000000000000000000000000000002774251c24 | 0x00000000000000000000000000000000000000000000000000202774251c24 |
      | 0x50039cf134a124858bd88bbc9225ec3c537b89a0e9237ce39fe1813e6edf8258 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x77727345544820436f7272656c61746564000000000000000000000000000022 |
      | 0x50039cf134a124858bd88bbc9225ec3c537b89a0e9237ce39fe1813e6edf8259 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000001 |
      | _eModeCategories[4] | mapping(uint8 => struct DataTypes.EModeCategory) | 0x00000000000000000000000000000000000000000000000000002774258024 | 0x00000000000000000000000000000000000000000000000000102774258024 |
      | 0x533efb5c9f032d0e72b35f5d59b231dc7a9fb94625f73b3c45c394126326354d | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x77737445544820436f7272656c61746564000000000000000000000000000022 |
      | 0x533efb5c9f032d0e72b35f5d59b231dc7a9fb94625f73b3c45c394126326354e | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000001 |
      | _eModeCategories[2] | mapping(uint8 => struct DataTypes.EModeCategory) | 0x0000000000000000000000000000000000000000000000000000299a1d4c1b | 0x0000000000000000000000000000000000000000000000000002299a1d4c1b |
      | 0x67dcc86da9aaaf40a183002157e56801115aa6057705e43279b4c1c90942d6b3 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x4254436220537461626c65636f696e7300000000000000000000000000000020 |
      | 0x67dcc86da9aaaf40a183002157e56801115aa6057705e43279b4c1c90942d6b4 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000000000000000000000000000000000000000000c |
      | _reserves[0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072] | mapping(address => struct DataTypes.ReserveData) | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x100000000000000000000003e800000000200000000107d08108000000000000 |
      | 0x7a18f972cb3c30997624be86bf2fd31e3cd44e3df901d4f88e0579aa778bb37c | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000033b2e3c9fd0803ce8000000 |
      | 0x7a18f972cb3c30997624be86bf2fd31e3cd44e3df901d4f88e0579aa778bb37d | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000033b2e3c9fd0803ce8000000 |
      | 0x7a18f972cb3c30997624be86bf2fd31e3cd44e3df901d4f88e0579aa778bb37e | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000100698a207e00000000000000000000000000000000 |
      | 0x7a18f972cb3c30997624be86bf2fd31e3cd44e3df901d4f88e0579aa778bb37f | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000889d59ea7178ee5b71da01949a5cb42aafbe337 |
      | 0x7a18f972cb3c30997624be86bf2fd31e3cd44e3df901d4f88e0579aa778bb381 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x00000000000000000000000015b550784928c5b1a93849ca5d6caa18b2545b6d |
      | 0x7a18f972cb3c30997624be86bf2fd31e3cd44e3df901d4f88e0579aa778bb383 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000c35000000000000000000000000000000000 |
      | _reserves[0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57] | mapping(address => struct DataTypes.ReserveData) | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x100000000000000000000003e800000001400000000107d08112000000000000 |
      | 0x80432f665e0bdbfe261b656dbe8c35e7f08625c01f0327d4e88f6aaee03aecee | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000033b2e3c9fd0803ce8000000 |
      | 0x80432f665e0bdbfe261b656dbe8c35e7f08625c01f0327d4e88f6aaee03aecef | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000033b2e3c9fd0803ce8000000 |
      | 0x80432f665e0bdbfe261b656dbe8c35e7f08625c01f0327d4e88f6aaee03aecf0 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000600698a207e00000000000000000000000000000000 |
      | 0x80432f665e0bdbfe261b656dbe8c35e7f08625c01f0327d4e88f6aaee03aecf1 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x00000000000000000000000003c99cce547b1c2e74442b73e6f588a66d19597e |
      | 0x80432f665e0bdbfe261b656dbe8c35e7f08625c01f0327d4e88f6aaee03aecf3 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000001505f48bd4db0ff8b28817d2c0fb95abcb8eebbc |
      | 0x80432f665e0bdbfe261b656dbe8c35e7f08625c01f0327d4e88f6aaee03aecf5 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x00000000000000000008e1bc9bf0400000000000000000000000000000000000 |
      | _eModeCategories[3] | mapping(uint8 => struct DataTypes.EModeCategory) | 0x0000000000000000000000000000000000000000000000000000299a1edc1d | 0x0000000000000000000000000000000000000000000000000010299a1edc1d |
      | 0x81d0999fde243adcc41b7fa1be5cea14f789e3a6065b815ac58f4bc0838c3156 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x77737445544820537461626c65636f696e730000000000000000000000000024 |
      | 0x81d0999fde243adcc41b7fa1be5cea14f789e3a6065b815ac58f4bc0838c3157 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000000000000000000000000000000000000000000c |
      | _reserves[0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F] | mapping(address => struct DataTypes.ReserveData) | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x100000000000000000000003e800000001400000000107d08112000000000000 |
      | 0x8868a55b276168fe4e9b1d77859b72352206ee587e0f77d39380f4763c63338d | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000033b2e3c9fd0803ce8000000 |
      | 0x8868a55b276168fe4e9b1d77859b72352206ee587e0f77d39380f4763c63338e | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000033b2e3c9fd0803ce8000000 |
      | 0x8868a55b276168fe4e9b1d77859b72352206ee587e0f77d39380f4763c63338f | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000500698a207e00000000000000000000000000000000 |
      | 0x8868a55b276168fe4e9b1d77859b72352206ee587e0f77d39380f4763c633390 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000b8578af311353b44b14bb4480ebb4de608ec7e1b |
      | 0x8868a55b276168fe4e9b1d77859b72352206ee587e0f77d39380f4763c633392 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000d7b71d855bbacd3f11f623400bc870ab3448aff7 |
      | 0x8868a55b276168fe4e9b1d77859b72352206ee587e0f77d39380f4763c633394 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x00000000000000000008e1bc9bf0400000000000000000000000000000000000 |
      | _eModeCategories[1] | mapping(uint8 => struct DataTypes.EModeCategory) | 0x00000000000000000000000000000000000000000000000000002936206c1f | 0x00000000000000000000000000000000000000000000000000012936206c1f |
      | 0x8e0cc0f1f0504b4cb44a23b328568106915b169e79003737a7b094503cdbeeb1 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x5745544820537461626c65636f696e7300000000000000000000000000000020 |
      | 0x8e0cc0f1f0504b4cb44a23b328568106915b169e79003737a7b094503cdbeeb2 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000000000000000000000000000000000000000000c |
      | _reserves[0x4200000000000000000000000000000000000006] | mapping(address => struct DataTypes.ReserveData) | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x100000000000000000000003e800000001400000000a05dc8112000000000000 |
      | 0x9f34118313d08abcbe5d630066a42015e9c14ddd958820a505759421525c3adf | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000033b2e3c9fd0803ce8000000 |
      | 0x9f34118313d08abcbe5d630066a42015e9c14ddd958820a505759421525c3ae0 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000033b2e3c9fd0803ce8000000 |
      | 0x9f34118313d08abcbe5d630066a42015e9c14ddd958820a505759421525c3ae1 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000698a207e00000000000000000000000000000000 |
      | 0x9f34118313d08abcbe5d630066a42015e9c14ddd958820a505759421525c3ae2 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000a31e6b433382062e8a1da41485f7b234d97c3f4d |
      | 0x9f34118313d08abcbe5d630066a42015e9c14ddd958820a505759421525c3ae4 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x00000000000000000000000009adccc7af2abd356c18a4cadf2e5cc250f300e9 |
      | 0x9f34118313d08abcbe5d630066a42015e9c14ddd958820a505759421525c3ae6 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x00000000000000000008e1bc9bf0400000000000000000000000000000000000 |
      | _reserves[0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7] | mapping(address => struct DataTypes.ReserveData) | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x100000000000000000000003e800000c350000004e2003e8a512000000000000 |
      | 0x9ff805b90c1892cbb0a31579cc27c582558b288e0e349f90918280cb67cda6c4 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000033b2e3c9fd0803ce8000000 |
      | 0x9ff805b90c1892cbb0a31579cc27c582558b288e0e349f90918280cb67cda6c5 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000033b2e3c9fd0803ce8000000 |
      | 0x9ff805b90c1892cbb0a31579cc27c582558b288e0e349f90918280cb67cda6c6 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000300698a207e00000000000000000000000000000000 |
      | 0x9ff805b90c1892cbb0a31579cc27c582558b288e0e349f90918280cb67cda6c7 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000005df82810cb4b8f3e0da3c031ccc9208ee9cf9500 |
      | 0x9ff805b90c1892cbb0a31579cc27c582558b288e0e349f90918280cb67cda6c9 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000006b408d6c479c304794abc60a4693a3ad2d3c2d0d |
      | 0x9ff805b90c1892cbb0a31579cc27c582558b288e0e349f90918280cb67cda6cb | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x00000000000000008ac7230489e8000000000000000000000000000000000000 |
      | _reserves[0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb] | mapping(address => struct DataTypes.ReserveData) | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x100000000000000000000003e800000c350000004e2003e8a506000000000000 |
      | 0xace1738bd21dfb38ab702aadd1277b4df729315c49e6743bfbebb5a89576504b | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000033b2e3c9fd0803ce8000000 |
      | 0xace1738bd21dfb38ab702aadd1277b4df729315c49e6743bfbebb5a89576504c | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000033b2e3c9fd0803ce8000000 |
      | 0xace1738bd21dfb38ab702aadd1277b4df729315c49e6743bfbebb5a89576504d | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000200698a207e00000000000000000000000000000000 |
      | 0xace1738bd21dfb38ab702aadd1277b4df729315c49e6743bfbebb5a89576504e | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000e2283e01a667b512c340f19b499d86fbc885d5ef |
      | 0xace1738bd21dfb38ab702aadd1277b4df729315c49e6743bfbebb5a895765050 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000b951225133b5eed3d88645e4bb1360136ff70d9a |
      | 0xace1738bd21dfb38ab702aadd1277b4df729315c49e6743bfbebb5a895765052 | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000098968000000000000000000000000000000000 |
      | _reservesList[3] | mapping(uint256 => address) | 0x0000000000000000000000000000000000000000 | 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 |
      | _reservesList[1] | mapping(uint256 => address) | 0x0000000000000000000000000000000000000000 | 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 |

      ### 0x80e11cb895a23c901a990239e5534054c66476b5 (GovernanceV3MegaEth.PAYLOADS_CONTROLLER)

      | slot | previous value | new value |
      | --- | --- | --- |
      | 0xa15bc60c955c405d20d9149c709e2460f1c2d9a497496a7f46004d1772c3054c (_payloads[1]) | 0x00698a207d000000000002000000000000000000000000000000000000000000 | 0x00698a207d000000000003000000000000000000000000000000000000000000 |
      | 0xa15bc60c955c405d20d9149c709e2460f1c2d9a497496a7f46004d1772c3054d | 0x000000000000000000093a8000000000000069b844fe00000000000000000000 | 0x000000000000000000093a8000000000000069b844fe000000000000698a207e |

      ### 0xa31e6b433382062e8a1da41485f7b234d97c3f4d (AaveV3MegaEth.ASSETS.WETH.A_TOKEN)

      **Nonce diff**: 0 → 1

      | label | type | decoded previous value | decoded new value |
      | --- | --- | --- | --- |
      | lastInitializedRevision | uint256 | 0 | 5 |
      | initializing | bool | false | false |
      | _totalSupply | uint256 | 0 | 2500000000000000 |
      | _name | string |  | Aave MegaEth WETH |
      | _symbol | string |  | aMegWETH |
      | _decimals | uint8 | 0 | 18 |
      | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0xe06ffb5ae9c342ea15be81d4f0109a4c670edd9ff6709b05ecdf6b1aec6b18da |
      | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0x4200000000000000000000000000000000000006 |
      | _userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643] | mapping(address => struct IncentivizedERC20.UserState) | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x00000000033b2e3c9fd0803ce800000000000000000000000008e1bc9bf04000 |
      | 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x00000000000000000000000034ca0a24e0b7cbceb77088ae539f57ba0650fc05 |

      ### 0xad2de503b5c723371d6b38a5224a2e12e103dfb8 (AaveV3MegaEth.ASSETS.wstETH.A_TOKEN)

      **Nonce diff**: 0 → 1

      | label | type | decoded previous value | decoded new value |
      | --- | --- | --- | --- |
      | lastInitializedRevision | uint256 | 0 | 5 |
      | initializing | bool | false | false |
      | _totalSupply | uint256 | 0 | 2500000000000000 |
      | _name | string |  | Aave MegaEth wstETH |
      | _symbol | string |  | aMegwstETH |
      | _decimals | uint8 | 0 | 18 |
      | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x729b2f6bdb04ae9127148d2e1c0d903f3000fd9d9024ad5d3cda0b904a5b97ee |
      | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0x601aC63637933D88285A025C685AC4e9a92a98dA |
      | _userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643] | mapping(address => struct IncentivizedERC20.UserState) | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x00000000033b2e3c9fd0803ce800000000000000000000000008e1bc9bf04000 |
      | 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x00000000000000000000000034ca0a24e0b7cbceb77088ae539f57ba0650fc05 |

      ### 0xb0f70c0bd6fd87dbeb7c10dc692a2a6106817072 (AaveV3MegaEth.ASSETS.BTCb.UNDERLYING)

      | slot | previous value | new value |
      | --- | --- | --- |
      | 0x4ad958461d38e50759ecd2d67cb1a2afbffab25bae32fd33026cf7bbf0f0da07 | 0x000000000000000000000000000000000000000000000000000000000000c350 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0x5d6747c86b1c081bb00df65b4be0a48ac12eb92eacca7bc2f5ba6afdb3b971d8 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0xb4b547208411cd7bf42e5baa224c56ba18cc430f78a68ec4195db75e9d4ab83e | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000000000000000000000000000000000000000c350 |

      ### 0xb8578af311353b44b14bb4480ebb4de608ec7e1b (AaveV3MegaEth.ASSETS.wrsETH.A_TOKEN)

      **Nonce diff**: 0 → 1

      | label | type | decoded previous value | decoded new value |
      | --- | --- | --- | --- |
      | lastInitializedRevision | uint256 | 0 | 5 |
      | initializing | bool | false | false |
      | _totalSupply | uint256 | 0 | 2500000000000000 |
      | _name | string |  | Aave MegaEth wrsETH |
      | _symbol | string |  | aMegwrsETH |
      | _decimals | uint8 | 0 | 18 |
      | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0xa6bb8b8aa8c594122e9790d3fc797d162c20f39cf3df3fa29a5c58498277da62 |
      | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F |
      | _userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643] | mapping(address => struct IncentivizedERC20.UserState) | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x00000000033b2e3c9fd0803ce800000000000000000000000008e1bc9bf04000 |
      | 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x00000000000000000000000034ca0a24e0b7cbceb77088ae539f57ba0650fc05 |

      ### 0xb8ce59fc3717ada4c02eadf9682a9e934f625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING)

      | label | type | decoded previous value | decoded new value |
      | --- | --- | --- | --- |
      | _allowances[0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19][0x7e324AbC5De01d112AfC03a584966ff199741C28] | mapping(address => mapping(address => uint256)) | 0 | 0 |
      | _balances[0xE2283E01a667b512c340f19B499d86fbc885D5Ef] | mapping(address => uint256) | 0 | 10000000 |
      | _balances[0xE2E8Badc5d50f8a6188577B89f50701cDE2D4e19] | mapping(address => uint256) | 10000000 | 0 |

      ### 0xb951225133b5eed3d88645e4bb1360136ff70d9a (AaveV3MegaEth.ASSETS.USDT0.V_TOKEN)

      **Nonce diff**: 0 → 1

      | label | type | decoded previous value | decoded new value |
      | --- | --- | --- | --- |
      | lastInitializedRevision | uint256 | 0 | 5 |
      | initializing | bool | false | false |
      | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x75c73e22a7e9e273e671a3b0075a003558700829edae3d3df81a9fa309d2eff7 |
      | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb |
      | _name | string |  | Aave MegaEth Variable Debt USDT0 |
      | _symbol | string |  | variableDebtMegUSDT0 |
      | _decimals | uint8 | 0 | 6 |
      | 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000ff01493c22208de3a89fe9cafbdae103acc72af8 |
      | _name[0] | string | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x41617665204d656761457468205661726961626c652044656274205553445430 |

      ### 0xcfc61568b91414dbf7bb1a4344c633e1ab214bc9 (AaveV3MegaEth.EMISSION_MANAGER)

      | label | type | decoded previous value | decoded new value |
      | --- | --- | --- | --- |
      | _emissionAdmins[0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb] | mapping(address => address) | 0x0000000000000000000000000000000000000000 | 0xac140648435d03f784879cd789130F22Ef588Fcd |
      | _emissionAdmins[0xa31E6b433382062e8A1dA41485f7b234D97c3f4d] | mapping(address => address) | 0x0000000000000000000000000000000000000000 | 0xac140648435d03f784879cd789130F22Ef588Fcd |
      | _emissionAdmins[0xaD2de503b5c723371d6B38A5224A2E12E103DfB8] | mapping(address => address) | 0x0000000000000000000000000000000000000000 | 0xac140648435d03f784879cd789130F22Ef588Fcd |
      | _emissionAdmins[0x0889d59eA7178ee5B71DA01949a5cB42aaFBe337] | mapping(address => address) | 0x0000000000000000000000000000000000000000 | 0xac140648435d03f784879cd789130F22Ef588Fcd |
      | _emissionAdmins[0x5dF82810CB4B8f3e0Da3c031cCc9208ee9cF9500] | mapping(address => address) | 0x0000000000000000000000000000000000000000 | 0xac140648435d03f784879cd789130F22Ef588Fcd |
      | _emissionAdmins[0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7] | mapping(address => address) | 0x0000000000000000000000000000000000000000 | 0xac140648435d03f784879cd789130F22Ef588Fcd |
      | _emissionAdmins[0xb8578af311353b44B14bb4480EBB4DE608EC7e1B] | mapping(address => address) | 0x0000000000000000000000000000000000000000 | 0xac140648435d03f784879cd789130F22Ef588Fcd |
      | _emissionAdmins[0x03C99Cce547b1c2E74442b73E6f588A66D19597e] | mapping(address => address) | 0x0000000000000000000000000000000000000000 | 0xac140648435d03f784879cd789130F22Ef588Fcd |
      | _emissionAdmins[0x601aC63637933D88285A025C685AC4e9a92a98dA] | mapping(address => address) | 0x0000000000000000000000000000000000000000 | 0xac140648435d03f784879cd789130F22Ef588Fcd |
      | _emissionAdmins[0x4200000000000000000000000000000000000006] | mapping(address => address) | 0x0000000000000000000000000000000000000000 | 0xac140648435d03f784879cd789130F22Ef588Fcd |
      | _emissionAdmins[0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57] | mapping(address => address) | 0x0000000000000000000000000000000000000000 | 0xac140648435d03f784879cd789130F22Ef588Fcd |
      | _emissionAdmins[0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F] | mapping(address => address) | 0x0000000000000000000000000000000000000000 | 0xac140648435d03f784879cd789130F22Ef588Fcd |
      | _emissionAdmins[0xE2283E01a667b512c340f19B499d86fbc885D5Ef] | mapping(address => address) | 0x0000000000000000000000000000000000000000 | 0xac140648435d03f784879cd789130F22Ef588Fcd |
      | _emissionAdmins[0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072] | mapping(address => address) | 0x0000000000000000000000000000000000000000 | 0xac140648435d03f784879cd789130F22Ef588Fcd |

      ### 0xd7b71d855bbacd3f11f623400bc870ab3448aff7 (AaveV3MegaEth.ASSETS.wrsETH.V_TOKEN)

      **Nonce diff**: 0 → 1

      | label | type | decoded previous value | decoded new value |
      | --- | --- | --- | --- |
      | lastInitializedRevision | uint256 | 0 | 5 |
      | initializing | bool | false | false |
      | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x2780bc7ac7dec26aab6c8e2fcfd8879e30b4d5c12b6d85249f7fcde7f43ac9ca |
      | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F |
      | _name | string |  | Aave MegaEth Variable Debt wrsETH |
      | _symbol | string |  | variableDebtMegwrsETH |
      | _decimals | uint8 | 0 | 18 |
      | 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000ff01493c22208de3a89fe9cafbdae103acc72af8 |
      | _name[0] | string | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x41617665204d656761457468205661726961626c652044656274207772734554 |
      | _name[1] | string | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x4800000000000000000000000000000000000000000000000000000000000000 |

      ### 0xe2283e01a667b512c340f19b499d86fbc885d5ef (AaveV3MegaEth.ASSETS.USDT0.A_TOKEN)

      **Nonce diff**: 0 → 1

      | label | type | decoded previous value | decoded new value |
      | --- | --- | --- | --- |
      | lastInitializedRevision | uint256 | 0 | 5 |
      | initializing | bool | false | false |
      | _totalSupply | uint256 | 0 | 10000000 |
      | _name | string |  | Aave MegaEth USDT0 |
      | _symbol | string |  | aMegUSDT0 |
      | _decimals | uint8 | 0 | 6 |
      | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0xca3d8725269fe463497f33ccd077c42fb66ca9482b28b8c69d0fe96d070d5021 |
      | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb |
      | _userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643] | mapping(address => struct IncentivizedERC20.UserState) | 0x | 0x00000000033b2e3c9fd0803ce8000000000000000000000000000000009896 |
      | 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x00000000000000000000000034ca0a24e0b7cbceb77088ae539f57ba0650fc05 |

      ### 0xf15d31bc839a853c9068686043cec6ec5995dabb (AaveV3MegaEth.POOL_CONFIGURATOR)

      **Nonce diff**: 1 → 15

      ### 0xfafddbb3fc7688494971a79cc65dca3ef82079e7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING)

      | slot | previous value | new value |
      | --- | --- | --- |
      | 0x4ad958461d38e50759ecd2d67cb1a2afbffab25bae32fd33026cf7bbf0f0da07 | 0x0000000000000000000000000000000000000000000000008ac7230489e80000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0x5d6747c86b1c081bb00df65b4be0a48ac12eb92eacca7bc2f5ba6afdb3b971d8 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0xc03b2437653423c049b75df3021c2d05cb14ca872ccc99833e9937382f78b9b0 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000008ac7230489e80000 |


      ## Raw diff

      \`\`\`json
      {
        "eModes": {
          "1": {
            "from": null,
            "to": {
              "borrowableBitmap": "12",
              "collateralBitmap": "1",
              "eModeCategory": 1,
              "label": "WETH Stablecoins",
              "liquidationBonus": 10550,
              "liquidationThreshold": 8300,
              "ltv": 8050
            }
          },
          "2": {
            "from": null,
            "to": {
              "borrowableBitmap": "12",
              "collateralBitmap": "2",
              "eModeCategory": 2,
              "label": "BTCb Stablecoins",
              "liquidationBonus": 10650,
              "liquidationThreshold": 7500,
              "ltv": 7000
            }
          },
          "3": {
            "from": null,
            "to": {
              "borrowableBitmap": "12",
              "collateralBitmap": "16",
              "eModeCategory": 3,
              "label": "wstETH Stablecoins",
              "liquidationBonus": 10650,
              "liquidationThreshold": 7900,
              "ltv": 7500
            }
          },
          "4": {
            "from": null,
            "to": {
              "borrowableBitmap": "1",
              "collateralBitmap": "16",
              "eModeCategory": 4,
              "label": "wstETH Correlated",
              "liquidationBonus": 10100,
              "liquidationThreshold": 9600,
              "ltv": 9400
            }
          },
          "5": {
            "from": null,
            "to": {
              "borrowableBitmap": "1",
              "collateralBitmap": "32",
              "eModeCategory": 5,
              "label": "wrsETH Correlated",
              "liquidationBonus": 10100,
              "liquidationThreshold": 9500,
              "ltv": 9300
            }
          },
          "6": {
            "from": null,
            "to": {
              "borrowableBitmap": "1",
              "collateralBitmap": "64",
              "eModeCategory": 6,
              "label": "ezETH Correlated",
              "liquidationBonus": 10100,
              "liquidationThreshold": 9500,
              "ltv": 9300
            }
          }
        },
        "poolConfig": {
          "priceOracleSentinel": {
            "from": "0x0000000000000000000000000000000000000000",
            "to": "0x98F756B77D6Fde14E08bb064b248ec7512F9f8ba"
          }
        },
        "reserves": {
          "0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57": {
            "from": null,
            "to": {
              "aToken": "0x03C99Cce547b1c2E74442b73E6f588A66D19597e",
              "aTokenName": "Aave MegaEth ezETH",
              "aTokenSymbol": "aMegezETH",
              "aTokenUnderlyingBalance": "2500000000000000",
              "borrowCap": 1,
              "borrowingEnabled": false,
              "debtCeiling": 0,
              "decimals": 18,
              "id": 6,
              "interestRateStrategy": "0x5cC4f782cFe249286476A7eFfD9D7bd215768194",
              "isActive": true,
              "isBorrowableInIsolation": false,
              "isFlashloanable": true,
              "isFrozen": false,
              "isPaused": false,
              "isSiloed": false,
              "liquidationBonus": 0,
              "liquidationProtocolFee": 1000,
              "liquidationThreshold": 0,
              "ltv": 0,
              "oracle": "0xd7Da71D3acf07C604A925799B0b48E2Ec607584D",
              "oracleDecimals": 8,
              "oracleDescription": "Capped ezETH / ETH / USD",
              "oracleLatestAnswer": "228274433677",
              "reserveFactor": 2000,
              "supplyCap": 20,
              "symbol": "ezETH",
              "underlying": "0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57",
              "usageAsCollateralEnabled": false,
              "variableDebtToken": "0x1505f48Bd4db0fF8B28817D2C0Fb95Abcb8eEbbc",
              "variableDebtTokenName": "Aave MegaEth Variable Debt ezETH",
              "variableDebtTokenSymbol": "variableDebtMegezETH",
              "virtualBalance": "2500000000000000"
            }
          },
          "0x4200000000000000000000000000000000000006": {
            "from": null,
            "to": {
              "aToken": "0xa31E6b433382062e8A1dA41485f7b234D97c3f4d",
              "aTokenName": "Aave MegaEth WETH",
              "aTokenSymbol": "aMegWETH",
              "aTokenUnderlyingBalance": "2500000000000000",
              "borrowCap": 10,
              "borrowingEnabled": false,
              "debtCeiling": 0,
              "decimals": 18,
              "id": 0,
              "interestRateStrategy": "0x5cC4f782cFe249286476A7eFfD9D7bd215768194",
              "isActive": true,
              "isBorrowableInIsolation": false,
              "isFlashloanable": true,
              "isFrozen": false,
              "isPaused": false,
              "isSiloed": false,
              "liquidationBonus": 0,
              "liquidationProtocolFee": 1000,
              "liquidationThreshold": 0,
              "ltv": 0,
              "oracle": "0xcA4e254D95637DE95E2a2F79244b03380d697feD",
              "oracleDecimals": 8,
              "oracleDescription": "ETH / USD",
              "oracleLatestAnswer": "213050418800",
              "reserveFactor": 1500,
              "supplyCap": 20,
              "symbol": "WETH",
              "underlying": "0x4200000000000000000000000000000000000006",
              "usageAsCollateralEnabled": false,
              "variableDebtToken": "0x09ADCCC7AF2aBD356c18A4CadF2e5cC250f300E9",
              "variableDebtTokenName": "Aave MegaEth Variable Debt WETH",
              "variableDebtTokenSymbol": "variableDebtMegWETH",
              "virtualBalance": "2500000000000000"
            }
          },
          "0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F": {
            "from": null,
            "to": {
              "aToken": "0xb8578af311353b44B14bb4480EBB4DE608EC7e1B",
              "aTokenName": "Aave MegaEth wrsETH",
              "aTokenSymbol": "aMegwrsETH",
              "aTokenUnderlyingBalance": "2500000000000000",
              "borrowCap": 1,
              "borrowingEnabled": false,
              "debtCeiling": 0,
              "decimals": 18,
              "id": 5,
              "interestRateStrategy": "0x5cC4f782cFe249286476A7eFfD9D7bd215768194",
              "isActive": true,
              "isBorrowableInIsolation": false,
              "isFlashloanable": true,
              "isFrozen": false,
              "isPaused": false,
              "isSiloed": false,
              "liquidationBonus": 0,
              "liquidationProtocolFee": 1000,
              "liquidationThreshold": 0,
              "ltv": 0,
              "oracle": "0x6356b92Bc636CCe722e0F53DDc24a86baE64216E",
              "oracleDecimals": 8,
              "oracleDescription": "Capped wrsETH / ETH / USD",
              "oracleLatestAnswer": "226821838195",
              "reserveFactor": 2000,
              "supplyCap": 20,
              "symbol": "wrsETH",
              "underlying": "0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F",
              "usageAsCollateralEnabled": false,
              "variableDebtToken": "0xd7B71D855bBAcd3f11F623400bc870AB3448AfF7",
              "variableDebtTokenName": "Aave MegaEth Variable Debt wrsETH",
              "variableDebtTokenSymbol": "variableDebtMegwrsETH",
              "virtualBalance": "2500000000000000"
            }
          },
          "0x601aC63637933D88285A025C685AC4e9a92a98dA": {
            "from": null,
            "to": {
              "aToken": "0xaD2de503b5c723371d6B38A5224A2E12E103DfB8",
              "aTokenName": "Aave MegaEth wstETH",
              "aTokenSymbol": "aMegwstETH",
              "aTokenUnderlyingBalance": "2500000000000000",
              "borrowCap": 1,
              "borrowingEnabled": false,
              "debtCeiling": 0,
              "decimals": 18,
              "id": 4,
              "interestRateStrategy": "0x5cC4f782cFe249286476A7eFfD9D7bd215768194",
              "isActive": true,
              "isBorrowableInIsolation": false,
              "isFlashloanable": true,
              "isFrozen": false,
              "isPaused": false,
              "isSiloed": false,
              "liquidationBonus": 0,
              "liquidationProtocolFee": 1000,
              "liquidationThreshold": 0,
              "ltv": 0,
              "oracle": "0x376397e34eA968e79DC6F629E6210ba25311a3ce",
              "oracleDecimals": 8,
              "oracleDescription": "Capped wstETH / stETH(ETH) / USD",
              "oracleLatestAnswer": "261317687457",
              "reserveFactor": 2000,
              "supplyCap": 20,
              "symbol": "wstETH",
              "underlying": "0x601aC63637933D88285A025C685AC4e9a92a98dA",
              "usageAsCollateralEnabled": false,
              "variableDebtToken": "0x259A9Cd7628f6D15ef384887dd90bb7A0283fEf9",
              "variableDebtTokenName": "Aave MegaEth Variable Debt wstETH",
              "variableDebtTokenSymbol": "variableDebtMegwstETH",
              "virtualBalance": "2500000000000000"
            }
          },
          "0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072": {
            "from": null,
            "to": {
              "aToken": "0x0889d59eA7178ee5B71DA01949a5cB42aaFBe337",
              "aTokenName": "Aave MegaEth BTCb",
              "aTokenSymbol": "aMegBTCb",
              "aTokenUnderlyingBalance": "50000",
              "borrowCap": 1,
              "borrowingEnabled": false,
              "debtCeiling": 0,
              "decimals": 8,
              "id": 1,
              "interestRateStrategy": "0x5cC4f782cFe249286476A7eFfD9D7bd215768194",
              "isActive": true,
              "isBorrowableInIsolation": false,
              "isFlashloanable": true,
              "isFrozen": false,
              "isPaused": false,
              "isSiloed": false,
              "liquidationBonus": 0,
              "liquidationProtocolFee": 1000,
              "liquidationThreshold": 0,
              "ltv": 0,
              "oracle": "0xc6E3007B597f6F5a6330d43053D1EF73cCbbE721",
              "oracleDecimals": 8,
              "oracleDescription": "BTC / USD",
              "oracleLatestAnswer": "7081589948000",
              "reserveFactor": 2000,
              "supplyCap": 2,
              "symbol": "BTC.b",
              "underlying": "0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072",
              "usageAsCollateralEnabled": false,
              "variableDebtToken": "0x15B550784928C5b1A93849CA5d6caA18B2545B6d",
              "variableDebtTokenName": "Aave MegaEth Variable Debt BTCb",
              "variableDebtTokenSymbol": "variableDebtMegBTCb",
              "virtualBalance": "50000"
            }
          },
          "0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb": {
            "from": null,
            "to": {
              "aToken": "0xE2283E01a667b512c340f19B499d86fbc885D5Ef",
              "aTokenName": "Aave MegaEth USDT0",
              "aTokenSymbol": "aMegUSDT0",
              "aTokenUnderlyingBalance": "10000000",
              "borrowCap": 20000,
              "borrowingEnabled": true,
              "debtCeiling": 0,
              "decimals": 6,
              "id": 2,
              "interestRateStrategy": "0x5cC4f782cFe249286476A7eFfD9D7bd215768194",
              "isActive": true,
              "isBorrowableInIsolation": true,
              "isFlashloanable": true,
              "isFrozen": false,
              "isPaused": false,
              "isSiloed": false,
              "liquidationBonus": 0,
              "liquidationProtocolFee": 1000,
              "liquidationThreshold": 0,
              "ltv": 0,
              "oracle": "0xAe95ff42e16468AB1DfD405c9533C9b67d87d66A",
              "oracleDecimals": 8,
              "oracleDescription": "Capped USDT/USD",
              "oracleLatestAnswer": "99931000",
              "reserveFactor": 1000,
              "supplyCap": 50000,
              "symbol": "USDT0",
              "underlying": "0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb",
              "usageAsCollateralEnabled": false,
              "variableDebtToken": "0xB951225133b5eed3D88645E4Bb1360136FF70D9a",
              "variableDebtTokenName": "Aave MegaEth Variable Debt USDT0",
              "variableDebtTokenSymbol": "variableDebtMegUSDT0",
              "virtualBalance": "10000000"
            }
          },
          "0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7": {
            "from": null,
            "to": {
              "aToken": "0x5dF82810CB4B8f3e0Da3c031cCc9208ee9cF9500",
              "aTokenName": "Aave MegaEth USDm",
              "aTokenSymbol": "aMegUSDm",
              "aTokenUnderlyingBalance": "10000000000000000000",
              "borrowCap": 20000,
              "borrowingEnabled": true,
              "debtCeiling": 0,
              "decimals": 18,
              "id": 3,
              "interestRateStrategy": "0x5cC4f782cFe249286476A7eFfD9D7bd215768194",
              "isActive": true,
              "isBorrowableInIsolation": true,
              "isFlashloanable": true,
              "isFrozen": false,
              "isPaused": false,
              "isSiloed": false,
              "liquidationBonus": 0,
              "liquidationProtocolFee": 1000,
              "liquidationThreshold": 0,
              "ltv": 0,
              "oracle": "0xe5448B8318493c6e3F72E21e8BDB8242d3299FB5",
              "oracleDecimals": 8,
              "oracleDescription": "ONE USD",
              "oracleLatestAnswer": "100000000",
              "reserveFactor": 1000,
              "supplyCap": 50000,
              "symbol": "USDm",
              "underlying": "0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7",
              "usageAsCollateralEnabled": false,
              "variableDebtToken": "0x6B408d6c479C304794abC60a4693A3AD2D3c2D0D",
              "variableDebtTokenName": "Aave MegaEth Variable Debt USDm",
              "variableDebtTokenSymbol": "variableDebtMegUSDm",
              "virtualBalance": "10000000000000000000"
            }
          }
        },
        "strategies": {
          "0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57": {
            "from": null,
            "to": {
              "address": "0x5cC4f782cFe249286476A7eFfD9D7bd215768194",
              "baseVariableBorrowRate": "0",
              "maxVariableBorrowRate": "250000000000000000000000000",
              "optimalUsageRatio": "900000000000000000000000000",
              "variableRateSlope1": "50000000000000000000000000",
              "variableRateSlope2": "200000000000000000000000000"
            }
          },
          "0x4200000000000000000000000000000000000006": {
            "from": null,
            "to": {
              "address": "0x5cC4f782cFe249286476A7eFfD9D7bd215768194",
              "baseVariableBorrowRate": "0",
              "maxVariableBorrowRate": "105000000000000000000000000",
              "optimalUsageRatio": "900000000000000000000000000",
              "variableRateSlope1": "25000000000000000000000000",
              "variableRateSlope2": "80000000000000000000000000"
            }
          },
          "0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F": {
            "from": null,
            "to": {
              "address": "0x5cC4f782cFe249286476A7eFfD9D7bd215768194",
              "baseVariableBorrowRate": "0",
              "maxVariableBorrowRate": "250000000000000000000000000",
              "optimalUsageRatio": "900000000000000000000000000",
              "variableRateSlope1": "50000000000000000000000000",
              "variableRateSlope2": "200000000000000000000000000"
            }
          },
          "0x601aC63637933D88285A025C685AC4e9a92a98dA": {
            "from": null,
            "to": {
              "address": "0x5cC4f782cFe249286476A7eFfD9D7bd215768194",
              "baseVariableBorrowRate": "0",
              "maxVariableBorrowRate": "250000000000000000000000000",
              "optimalUsageRatio": "900000000000000000000000000",
              "variableRateSlope1": "50000000000000000000000000",
              "variableRateSlope2": "200000000000000000000000000"
            }
          },
          "0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072": {
            "from": null,
            "to": {
              "address": "0x5cC4f782cFe249286476A7eFfD9D7bd215768194",
              "baseVariableBorrowRate": "0",
              "maxVariableBorrowRate": "250000000000000000000000000",
              "optimalUsageRatio": "900000000000000000000000000",
              "variableRateSlope1": "50000000000000000000000000",
              "variableRateSlope2": "200000000000000000000000000"
            }
          },
          "0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb": {
            "from": null,
            "to": {
              "address": "0x5cC4f782cFe249286476A7eFfD9D7bd215768194",
              "baseVariableBorrowRate": "0",
              "maxVariableBorrowRate": "150000000000000000000000000",
              "optimalUsageRatio": "900000000000000000000000000",
              "variableRateSlope1": "50000000000000000000000000",
              "variableRateSlope2": "100000000000000000000000000"
            }
          },
          "0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7": {
            "from": null,
            "to": {
              "address": "0x5cC4f782cFe249286476A7eFfD9D7bd215768194",
              "baseVariableBorrowRate": "0",
              "maxVariableBorrowRate": "150000000000000000000000000",
              "optimalUsageRatio": "900000000000000000000000000",
              "variableRateSlope1": "50000000000000000000000000",
              "variableRateSlope2": "100000000000000000000000000"
            }
          }
        }
      }
      \`\`\`
      "
    `);
  });
});
