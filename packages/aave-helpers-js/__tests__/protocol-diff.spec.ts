import { describe, it, expect } from 'vitest';
import { readFileSync } from 'fs';
import { resolve } from 'path';
import { diffSnapshots } from '../protocol-diff';
import { diff, isChange, hasChanges } from '../diff';
import { formatValue, type FormatterContext } from '../formatters';
import { renderLogsSection } from '../sections/logs';

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
      | 1 | ExecutedAction(target: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f, value: 0, signature: execute(), data: 0x, executionTime: 1773490691, withDelegatecall: true, resultData: 0x) |

      #### 0xdAbad81aF85554E9ae636395611C58F7eC1aAEc5 (GovernanceV3Ethereum.PAYLOADS_CONTROLLER)

      | index | event |
      | --- | --- |
      | 2 | PayloadExecuted(payloadId: 414) |

      ## Raw storage changes

      ### 0xdabad81af85554e9ae636395611c58f7ec1aaec5 (GovernanceV3Ethereum.PAYLOADS_CONTROLLER)

      | slot | variable | type | previous value | new value |
      | --- | --- | --- | --- | --- |
      | 0xeca450…9891 | _payloads[414].state | enum IPayloadsControllerCore.PayloadState | 2 (Queued) | 3 (Executed) |
      | 0xeca450…9892 | _payloads[414].executedAt | uint40 | 0 | 1773490691 |


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
      | isolated | - | :x: |


      ### EMode: BTCb Stablecoins (id: 2)

      | description | value before | value after |
      | --- | --- | --- |
      | label | - | BTCb Stablecoins |
      | ltv | - | 70 % |
      | liquidationThreshold | - | 75 % |
      | liquidationBonus | - | 6.5 % [10650] |
      | borrowableBitmap | - | USDT0, USDm |
      | collateralBitmap | - | BTC.b |
      | isolated | - | :x: |


      ### EMode: wstETH Stablecoins (id: 3)

      | description | value before | value after |
      | --- | --- | --- |
      | label | - | wstETH Stablecoins |
      | ltv | - | 75 % |
      | liquidationThreshold | - | 79 % |
      | liquidationBonus | - | 6.5 % [10650] |
      | borrowableBitmap | - | USDT0, USDm |
      | collateralBitmap | - | wstETH |
      | isolated | - | :x: |


      ### EMode: wstETH Correlated (id: 4)

      | description | value before | value after |
      | --- | --- | --- |
      | label | - | wstETH Correlated |
      | ltv | - | 94 % |
      | liquidationThreshold | - | 96 % |
      | liquidationBonus | - | 1 % [10100] |
      | borrowableBitmap | - | WETH |
      | collateralBitmap | - | wstETH |
      | isolated | - | :x: |


      ### EMode: wrsETH Correlated (id: 5)

      | description | value before | value after |
      | --- | --- | --- |
      | label | - | wrsETH Correlated |
      | ltv | - | 93 % |
      | liquidationThreshold | - | 95 % |
      | liquidationBonus | - | 1 % [10100] |
      | borrowableBitmap | - | WETH |
      | collateralBitmap | - | wrsETH |
      | isolated | - | :x: |


      ### EMode: ezETH Correlated (id: 6)

      | description | value before | value after |
      | --- | --- | --- |
      | label | - | ezETH Correlated |
      | ltv | - | 93 % |
      | liquidationThreshold | - | 95 % |
      | liquidationBonus | - | 1 % [10100] |
      | borrowableBitmap | - | WETH |
      | collateralBitmap | - | ezETH |
      | isolated | - | :x: |


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

      #### 0x5cC4f782cFe249286476A7eFfD9D7bd215768194 (AaveV3MegaEth.ASSETS.WETH.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.BTCb.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.USDT0.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.USDm.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.wstETH.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.wrsETH.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.ezETH.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.USDe.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.stcUSD.INTEREST_RATE_STRATEGY)

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

      | slot | variable | type | previous value | new value |
      | --- | --- | --- | --- | --- |
      | 0x000000…0000 | lastInitializedRevision | uint256 | 0 | 5 |
      | 0x000000…0001 | - | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0x000000…0036 | _totalSupply | uint256 | 0 | 2500000000000000 |
      | 0x000000…0037 | _name | string | "" | "Aave MegaEth ezETH" |
      | 0x000000…0038 | _symbol | string | "" | "aMegezETH" |
      | 0x000000…0039 | _decimals | uint8 | 0 | 18 |
      | 0x000000…003b | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x13565618a57ffd83ab99592ef5e80d48c88d90de793f44d372be5602a9a4c4af |
      | 0x000000…003d | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (AaveV3MegaEth.ASSETS.ezETH.UNDERLYING) |
      | 0x001780…85b1 | _userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643 (AaveV3MegaEth.DUST_BIN)].balance | uint120 | 0 | 2500000000000000 |
      | 0x001780…85b1 | _userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643 (AaveV3MegaEth.DUST_BIN)].additionalData | uint128 | 0 | 1000000000000000000000000000 |
      | 0x360894…2bbc | implementation (ERC-1967) | address | 0x0000000000000000000000000000000000000000 | 0x34CA0A24E0b7cbCEB77088AE539f57BA0650fC05 (AaveV3MegaEth.DEFAULT_A_TOKEN_IMPL) |

      ### 0x0889d59ea7178ee5b71da01949a5cb42aafbe337 (AaveV3MegaEth.ASSETS.BTCb.A_TOKEN)

      **Nonce diff**: 0 → 1

      | slot | variable | type | previous value | new value |
      | --- | --- | --- | --- | --- |
      | 0x000000…0000 | lastInitializedRevision | uint256 | 0 | 5 |
      | 0x000000…0001 | - | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0x000000…0036 | _totalSupply | uint256 | 0 | 50000 |
      | 0x000000…0037 | _name | string | "" | "Aave MegaEth BTCb" |
      | 0x000000…0038 | _symbol | string | "" | "aMegBTCb" |
      | 0x000000…0039 | _decimals | uint8 | 0 | 8 |
      | 0x000000…003b | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x24eaa197304464c49cde553f25a253519ae8b932ea10d284f49ccf5468102c46 |
      | 0x000000…003d | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (AaveV3MegaEth.ASSETS.BTCb.UNDERLYING) |
      | 0x001780…85b1 | _userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643 (AaveV3MegaEth.DUST_BIN)].balance | uint120 | 0 | 50000 |
      | 0x001780…85b1 | _userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643 (AaveV3MegaEth.DUST_BIN)].additionalData | uint128 | 0 | 1000000000000000000000000000 |
      | 0x360894…2bbc | implementation (ERC-1967) | address | 0x0000000000000000000000000000000000000000 | 0x34CA0A24E0b7cbCEB77088AE539f57BA0650fC05 (AaveV3MegaEth.DEFAULT_A_TOKEN_IMPL) |

      ### 0x09601a65e7de7bc8a19813d263dd9e98bfdc3c57 (AaveV3MegaEth.ASSETS.ezETH.UNDERLYING)

      | slot | previous value | new value |
      | --- | --- | --- |
      | 0x32e08ec388bd03cb8e0fb9e71795585b8d5c1d03896c545e523e36ce4e50debd | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0x36bfa44cf947ee302f4afd595aee5c8f16493d90642fea969179ba9ea55bca0c | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000008e1bc9bf04000 |
      | 0xce693b0befa09013aa348b2de6dfacddecacae2c838457c156fcf2d9e1b26771 | 0x0000000000000000000000000000000000000000000000000008e1bc9bf04000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |

      ### 0x09adccc7af2abd356c18a4cadf2e5cc250f300e9 (AaveV3MegaEth.ASSETS.WETH.V_TOKEN)

      **Nonce diff**: 0 → 1

      | slot | variable | type | previous value | new value |
      | --- | --- | --- | --- | --- |
      | 0x000000…0000 | lastInitializedRevision | uint256 | 0 | 5 |
      | 0x000000…0001 | - | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0x000000…0035 | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x9badf6634af23284dff0d25ea4236d5b9fff5f22cf00d092dd82a46c8c6a1b04 |
      | 0x000000…0037 | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0x4200000000000000000000000000000000000006 (AaveV3MegaEth.ASSETS.WETH.UNDERLYING) |
      | 0x000000…003b | _name | string | "" | "Aave MegaEth Variable Debt WETH" |
      | 0x000000…003c | _symbol | string | "" | "variableDebtMegWETH" |
      | 0x000000…003d | _decimals | uint8 | 0 | 18 |
      | 0x360894…2bbc | implementation (ERC-1967) | address | 0x0000000000000000000000000000000000000000 | 0xfF01493C22208de3A89FE9CaFBDAE103acc72AF8 (AaveV3MegaEth.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL) |

      ### 0x1505f48bd4db0ff8b28817d2c0fb95abcb8eebbc (AaveV3MegaEth.ASSETS.ezETH.V_TOKEN)

      **Nonce diff**: 0 → 1

      | slot | variable | type | previous value | new value |
      | --- | --- | --- | --- | --- |
      | 0x000000…0000 | lastInitializedRevision | uint256 | 0 | 5 |
      | 0x000000…0001 | - | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0x000000…0035 | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x05e192f9d82dd91e9180f380e2b6fd47e8c7738b734022e264eef964bfc896f6 |
      | 0x000000…0037 | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (AaveV3MegaEth.ASSETS.ezETH.UNDERLYING) |
      | 0x000000…003b | _name | string | "" | (long string, length 32) |
      | 0x000000…003c | _symbol | string | "" | "variableDebtMegezETH" |
      | 0x000000…003d | _decimals | uint8 | 0 | 18 |
      | 0x360894…2bbc | implementation (ERC-1967) | address | 0x0000000000000000000000000000000000000000 | 0xfF01493C22208de3A89FE9CaFBDAE103acc72AF8 (AaveV3MegaEth.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL) |
      | 0xbbe321…1a4d | _name (data) | string | "" | "Aave MegaEth Variable Debt ezETH" |

      ### 0x15b550784928c5b1a93849ca5d6caa18b2545b6d (AaveV3MegaEth.ASSETS.BTCb.V_TOKEN)

      **Nonce diff**: 0 → 1

      | slot | variable | type | previous value | new value |
      | --- | --- | --- | --- | --- |
      | 0x000000…0000 | lastInitializedRevision | uint256 | 0 | 5 |
      | 0x000000…0001 | - | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0x000000…0035 | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0xb495d25c3a7439d697603cfc9a69e6ed5c9894e2c41c6d8537f1e8b34633bd41 |
      | 0x000000…0037 | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (AaveV3MegaEth.ASSETS.BTCb.UNDERLYING) |
      | 0x000000…003b | _name | string | "" | "Aave MegaEth Variable Debt BTCb" |
      | 0x000000…003c | _symbol | string | "" | "variableDebtMegBTCb" |
      | 0x000000…003d | _decimals | uint8 | 0 | 8 |
      | 0x360894…2bbc | implementation (ERC-1967) | address | 0x0000000000000000000000000000000000000000 | 0xfF01493C22208de3A89FE9CaFBDAE103acc72AF8 (AaveV3MegaEth.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL) |

      ### 0x186f45b6e33fcf531c1542509b199646eb7fa968

      **Nonce diff**: 1 → 15

      ### 0x259a9cd7628f6d15ef384887dd90bb7a0283fef9 (AaveV3MegaEth.ASSETS.wstETH.V_TOKEN)

      **Nonce diff**: 0 → 1

      | slot | variable | type | previous value | new value |
      | --- | --- | --- | --- | --- |
      | 0x000000…0000 | lastInitializedRevision | uint256 | 0 | 5 |
      | 0x000000…0001 | - | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0x000000…0035 | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0xbdaa76d0be1d866769579087a017f969e9063e39bc7bf8b32359cacc29a7747f |
      | 0x000000…0037 | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0x601aC63637933D88285A025C685AC4e9a92a98dA (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING) |
      | 0x000000…003b | _name | string | "" | (long string, length 33) |
      | 0x000000…003c | _symbol | string | "" | "variableDebtMegwstETH" |
      | 0x000000…003d | _decimals | uint8 | 0 | 18 |
      | 0x360894…2bbc | implementation (ERC-1967) | address | 0x0000000000000000000000000000000000000000 | 0xfF01493C22208de3A89FE9CaFBDAE103acc72AF8 (AaveV3MegaEth.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL) |
      | 0xbbe321…1a4d | _name (data) | string | "" | "Aave MegaEth Variable Debt wstET" |
      | 0xbbe321…1a4e | _name (data) | string | "" | "H" |

      ### 0x390d369c3878f2c5205cfb6ec7154ffa65491c3d (AaveV3MegaEth.ACL_MANAGER)

      | slot | variable | type | previous value | new value |
      | --- | --- | --- | --- | --- |
      | 0x536634…501a | _roles[RISK_ADMIN].members[0xbcC2Cf1fA3bE94B16061d51970628a87c7Cd5160] | bool | false | true |
      | 0xa03d6b…281f | _roles[POOL_ADMIN].members[0x8126eAd44383cb52Cf6A1bb70F1b4d7399DE34ef (MiscMegaEth.PROTOCOL_GUARDIAN)] | bool | false | true |

      ### 0x3effebdd435217a8b485dfaefdecf766f2a3c05b

      **Nonce diff**: 1 → 15

      ### 0x4200000000000000000000000000000000000006 (AaveV3MegaEth.ASSETS.WETH.UNDERLYING)

      | slot | previous value | new value |
      | --- | --- | --- |
      | 0x2bf78a04e7457c04e9a574860a3452a4ee2ec8e6f1b772904b0abe5ab77e1f4d | 0x0000000000000000000000000000000000000000000000000008e1bc9bf04000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0x5fb783b7747c87664bec596f5e4c5066b3716d6e713eac3a9f8c8f84ec33209f | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0xc4ec3b261f2aa304d6ce449323dfcc88b72da3305ec1e60aaac36458efe3ae7b | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000008e1bc9bf04000 |

      ### 0x421117d7319e96d831972b3f7e970bbfe29c4f21 (AaveV3MegaEth.ORACLE)

      | slot | variable | type | previous value | new value |
      | --- | --- | --- | --- | --- |
      | 0x03ac9a…7898 | assetsSources[0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING)] | contract AggregatorInterface | 0x0000000000000000000000000000000000000000 | 0xe5448B8318493c6e3F72E21e8BDB8242d3299FB5 (AaveV3MegaEth.ASSETS.USDm.ORACLE) |
      | 0x1d0ff4…26dd | assetsSources[0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING)] | contract AggregatorInterface | 0x0000000000000000000000000000000000000000 | 0xAe95ff42e16468AB1DfD405c9533C9b67d87d66A (AaveV3MegaEth.ASSETS.USDT0.ORACLE) |
      | 0x3a9da1…bdf8 | assetsSources[0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (AaveV3MegaEth.ASSETS.wrsETH.UNDERLYING)] | contract AggregatorInterface | 0x0000000000000000000000000000000000000000 | 0x6356b92Bc636CCe722e0F53DDc24a86baE64216E (AaveV3MegaEth.ASSETS.wrsETH.ORACLE) |
      | 0x51a36a…479e | assetsSources[0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (AaveV3MegaEth.ASSETS.BTCb.UNDERLYING)] | contract AggregatorInterface | 0x0000000000000000000000000000000000000000 | 0xc6E3007B597f6F5a6330d43053D1EF73cCbbE721 (AaveV3MegaEth.ASSETS.BTCb.ORACLE) |
      | 0x793e2a…648e | assetsSources[0x601aC63637933D88285A025C685AC4e9a92a98dA (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING)] | contract AggregatorInterface | 0x0000000000000000000000000000000000000000 | 0x376397e34eA968e79DC6F629E6210ba25311a3ce (AaveV3MegaEth.ASSETS.wstETH.ORACLE) |
      | 0x8a77a1…2b1b | assetsSources[0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (AaveV3MegaEth.ASSETS.ezETH.UNDERLYING)] | contract AggregatorInterface | 0x0000000000000000000000000000000000000000 | 0xd7Da71D3acf07C604A925799B0b48E2Ec607584D (AaveV3MegaEth.ASSETS.ezETH.ORACLE) |
      | 0xaa544f…71fe | assetsSources[0x4200000000000000000000000000000000000006 (AaveV3MegaEth.ASSETS.WETH.UNDERLYING)] | contract AggregatorInterface | 0x0000000000000000000000000000000000000000 | 0xcA4e254D95637DE95E2a2F79244b03380d697feD (AaveV3MegaEth.ASSETS.WETH.ORACLE) |

      ### 0x46dcd5f4600319b02649fd76b55aa6c1035ca478 (AaveV3MegaEth.POOL_ADDRESSES_PROVIDER)

      | slot | variable | type | previous value | new value |
      | --- | --- | --- | --- | --- |
      | 0x0d2c1b…3ab8 | _addresses[0x50524943455f4f5241434c455f53454e54494e454c0000000000000000000000] | address | 0x0000000000000000000000000000000000000000 | 0x98F756B77D6Fde14E08bb064b248ec7512F9f8ba |

      ### 0x4fc44be15e9b6e30c1e774e2c87a21d3e8b5403f (AaveV3MegaEth.ASSETS.wrsETH.UNDERLYING)

      | slot | previous value | new value |
      | --- | --- | --- |
      | 0x037acde50a689309ee9a8dbaed20047fbc7ede9f99e5ca3fd2798e835253d672 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000008e1bc9bf04000 |
      | 0x16ca11a1f6f7473ca0434162515ad20750ada68476513902cb0a61bdde8b39b0 | 0x0000000000000000000000000000000000000000000000000008e1bc9bf04000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0xa085589e50594358e6df87719528ac207c811c9816ac1f6fabe3cb3e82ebbf1f | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |

      ### 0x5cc4f782cfe249286476a7effd9d7bd215768194 (AaveV3MegaEth.ASSETS.WETH.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.BTCb.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.USDT0.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.USDm.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.wstETH.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.wrsETH.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.ezETH.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.USDe.INTEREST_RATE_STRATEGY, AaveV3MegaEth.ASSETS.stcUSD.INTEREST_RATE_STRATEGY)

      | slot | previous value | new value |
      | --- | --- | --- |
      | 0x03ac9ad9578832deb4e17901d0a9cf2a6379415f798ad7f51cdc791d06e47898 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000000000000000000003e8000001f4000000002328 |
      | 0x1d0ff494ced46576a72766ecd949bf23dbe61baffa84edfd2f2fdb8eccde26dd | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000000000000000000003e8000001f4000000002328 |
      | 0x3a9da10cda77fa35e870f298bb599f076a0c09664ef0e2bef69036a8ce56bdf8 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000000000000000000007d0000001f4000000002328 |
      | 0x51a36a22faa811b90439043020fbe74f3a8614f1acab147fc297410181cd479e | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000000000000000000007d0000001f4000000002328 |
      | 0x793e2a7b75393aeeb185d0daee999bbb1ad2dd99da6740f844e8ca74abf6648e | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000000000000000000007d0000001f4000000002328 |
      | 0x8a77a10b79a4965383d78e05a40792574f44064054990505e6247afecfae2b1b | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000000000000000000007d0000001f4000000002328 |
      | 0xaa544f6996e1da4967517881576aedff824813d40fbf84798b92a9de03a071fe | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x00000000000000000000000000000000000000000320000000fa000000002328 |

      ### 0x5df82810cb4b8f3e0da3c031ccc9208ee9cf9500 (AaveV3MegaEth.ASSETS.USDm.A_TOKEN)

      **Nonce diff**: 0 → 1

      | slot | variable | type | previous value | new value |
      | --- | --- | --- | --- | --- |
      | 0x000000…0000 | lastInitializedRevision | uint256 | 0 | 5 |
      | 0x000000…0001 | - | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0x000000…0036 | _totalSupply | uint256 | 0 | 10000000000000000000 |
      | 0x000000…0037 | _name | string | "" | "Aave MegaEth USDm" |
      | 0x000000…0038 | _symbol | string | "" | "aMegUSDm" |
      | 0x000000…0039 | _decimals | uint8 | 0 | 18 |
      | 0x000000…003b | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x2270488a78a7ff0e4d693a70a157850e0a2665f34e392a841fea757ea3523b4f |
      | 0x000000…003d | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING) |
      | 0x001780…85b1 | _userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643 (AaveV3MegaEth.DUST_BIN)].balance | uint120 | 0 | 10000000000000000000 |
      | 0x001780…85b1 | _userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643 (AaveV3MegaEth.DUST_BIN)].additionalData | uint128 | 0 | 1000000000000000000000000000 |
      | 0x360894…2bbc | implementation (ERC-1967) | address | 0x0000000000000000000000000000000000000000 | 0x34CA0A24E0b7cbCEB77088AE539f57BA0650fC05 (AaveV3MegaEth.DEFAULT_A_TOKEN_IMPL) |

      ### 0x601ac63637933d88285a025c685ac4e9a92a98da (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING)

      | slot | previous value | new value |
      | --- | --- | --- |
      | 0x428cfd5e8d7cebba8a0c306412105762a84304b4167a9f33d00eb7b630efa30e | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000008e1bc9bf04000 |
      | 0x4ad958461d38e50759ecd2d67cb1a2afbffab25bae32fd33026cf7bbf0f0da07 | 0x0000000000000000000000000000000000000000000000000008e1bc9bf04000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0x5d6747c86b1c081bb00df65b4be0a48ac12eb92eacca7bc2f5ba6afdb3b971d8 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |

      ### 0x6b408d6c479c304794abc60a4693a3ad2d3c2d0d (AaveV3MegaEth.ASSETS.USDm.V_TOKEN)

      **Nonce diff**: 0 → 1

      | slot | variable | type | previous value | new value |
      | --- | --- | --- | --- | --- |
      | 0x000000…0000 | lastInitializedRevision | uint256 | 0 | 5 |
      | 0x000000…0001 | - | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0x000000…0035 | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x772b118aa1ee532d161218687221075d88e5af9380878ecf61c6cba9b4478d6b |
      | 0x000000…0037 | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING) |
      | 0x000000…003b | _name | string | "" | "Aave MegaEth Variable Debt USDm" |
      | 0x000000…003c | _symbol | string | "" | "variableDebtMegUSDm" |
      | 0x000000…003d | _decimals | uint8 | 0 | 18 |
      | 0x360894…2bbc | implementation (ERC-1967) | address | 0x0000000000000000000000000000000000000000 | 0xfF01493C22208de3A89FE9CaFBDAE103acc72AF8 (AaveV3MegaEth.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL) |

      ### 0x7e324abc5de01d112afc03a584966ff199741c28 (AaveV3MegaEth.POOL)

      | slot | variable | type | previous value | new value |
      | --- | --- | --- | --- | --- |
      | 0x000000…003b | _reservesCount | uint16 | 0 | 7 |
      | 0x012905…40d6 | _eModeCategories[6].ltv | uint16 | 0 | 9300 |
      | 0x012905…40d6 | _eModeCategories[6].liquidationThreshold | uint16 | 0 | 9500 |
      | 0x012905…40d6 | _eModeCategories[6].liquidationBonus | uint16 | 0 | 10100 |
      | 0x012905…40d6 | _eModeCategories[6].collateralBitmap | uint128 | 0 | 64 |
      | 0x012905…40d7 | _eModeCategories[6].label | string | "" | "ezETH Correlated" |
      | 0x012905…40d8 | _eModeCategories[6].borrowableBitmap | uint128 | 0 | 1 |
      | 0x426fb8…fe97 | _reservesList[5] | address | 0x0000000000000000000000000000000000000000 | 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (AaveV3MegaEth.ASSETS.wrsETH.UNDERLYING) |
      | 0x448071…9105 | _reservesList[6] | address | 0x0000000000000000000000000000000000000000 | 0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (AaveV3MegaEth.ASSETS.ezETH.UNDERLYING) |
      | 0x4853ba…d92c | _reserves[0x601aC63637933D88285A025C685AC4e9a92a98dA (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING)].configuration.decimals | uint8 | 0 | 18 |
      | 0x4853ba…d92c | _reserves[0x601aC63637933D88285A025C685AC4e9a92a98dA (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING)].configuration.active | bool | false | true |
      | 0x4853ba…d92c | _reserves[0x601aC63637933D88285A025C685AC4e9a92a98dA (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING)].configuration.reserveFactor | uint16 | 0 | 2000 |
      | 0x4853ba…d92c | _reserves[0x601aC63637933D88285A025C685AC4e9a92a98dA (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING)].configuration.borrowCap | uint36 | 0 | 1 |
      | 0x4853ba…d92c | _reserves[0x601aC63637933D88285A025C685AC4e9a92a98dA (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING)].configuration.supplyCap | uint36 | 0 | 20 |
      | 0x4853ba…d92c | _reserves[0x601aC63637933D88285A025C685AC4e9a92a98dA (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING)].configuration.liquidationProtocolFee | uint16 | 0 | 1000 |
      | 0x4853ba…d92c | _reserves[0x601aC63637933D88285A025C685AC4e9a92a98dA (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING)].configuration.flashloaningEnabled | bool | false | true |
      | 0x4853ba…d92c | _reserves[0x601aC63637933D88285A025C685AC4e9a92a98dA (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING)].configuration.virtualAccountingEnabled | bool | false | true |
      | 0x4853ba…d92d | _reserves[0x601aC63637933D88285A025C685AC4e9a92a98dA (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING)].liquidityIndex | uint128 | 0 | 1000000000000000000000000000 |
      | 0x4853ba…d92e | _reserves[0x601aC63637933D88285A025C685AC4e9a92a98dA (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING)].variableBorrowIndex | uint128 | 0 | 1000000000000000000000000000 |
      | 0x4853ba…d92f | _reserves[0x601aC63637933D88285A025C685AC4e9a92a98dA (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING)].lastUpdateTimestamp | uint40 | 0 | 1770659966 |
      | 0x4853ba…d92f | _reserves[0x601aC63637933D88285A025C685AC4e9a92a98dA (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING)].id | uint16 | 0 | 4 |
      | 0x4853ba…d930 | _reserves[0x601aC63637933D88285A025C685AC4e9a92a98dA (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING)].aTokenAddress | address | 0x0000000000000000000000000000000000000000 | 0xaD2de503b5c723371d6B38A5224A2E12E103DfB8 (AaveV3MegaEth.ASSETS.wstETH.A_TOKEN) |
      | 0x4853ba…d932 | _reserves[0x601aC63637933D88285A025C685AC4e9a92a98dA (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING)].variableDebtTokenAddress | address | 0x0000000000000000000000000000000000000000 | 0x259A9Cd7628f6D15ef384887dd90bb7A0283fEf9 (AaveV3MegaEth.ASSETS.wstETH.V_TOKEN) |
      | 0x4853ba…d934 | _reserves[0x601aC63637933D88285A025C685AC4e9a92a98dA (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING)].virtualUnderlyingBalance | uint128 | 0 | 2500000000000000 |
      | 0x49d58e…77eb | _reservesList[2] | address | 0x0000000000000000000000000000000000000000 | 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING) |
      | 0x4c0bd9…efbd | _reservesList[4] | address | 0x0000000000000000000000000000000000000000 | 0x601aC63637933D88285A025C685AC4e9a92a98dA (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING) |
      | 0x4cb2b1…2e00 | _reservesList[0] | address | 0x0000000000000000000000000000000000000000 | 0x4200000000000000000000000000000000000006 (AaveV3MegaEth.ASSETS.WETH.UNDERLYING) |
      | 0x50039c…8257 | _eModeCategories[5].ltv | uint16 | 0 | 9300 |
      | 0x50039c…8257 | _eModeCategories[5].liquidationThreshold | uint16 | 0 | 9500 |
      | 0x50039c…8257 | _eModeCategories[5].liquidationBonus | uint16 | 0 | 10100 |
      | 0x50039c…8257 | _eModeCategories[5].collateralBitmap | uint128 | 0 | 32 |
      | 0x50039c…8258 | _eModeCategories[5].label | string | "" | "wrsETH Correlated" |
      | 0x50039c…8259 | _eModeCategories[5].borrowableBitmap | uint128 | 0 | 1 |
      | 0x533efb…354c | _eModeCategories[4].ltv | uint16 | 0 | 9400 |
      | 0x533efb…354c | _eModeCategories[4].liquidationThreshold | uint16 | 0 | 9600 |
      | 0x533efb…354c | _eModeCategories[4].liquidationBonus | uint16 | 0 | 10100 |
      | 0x533efb…354c | _eModeCategories[4].collateralBitmap | uint128 | 0 | 16 |
      | 0x533efb…354d | _eModeCategories[4].label | string | "" | "wstETH Correlated" |
      | 0x533efb…354e | _eModeCategories[4].borrowableBitmap | uint128 | 0 | 1 |
      | 0x67dcc8…d6b2 | _eModeCategories[2].ltv | uint16 | 0 | 7000 |
      | 0x67dcc8…d6b2 | _eModeCategories[2].liquidationThreshold | uint16 | 0 | 7500 |
      | 0x67dcc8…d6b2 | _eModeCategories[2].liquidationBonus | uint16 | 0 | 10650 |
      | 0x67dcc8…d6b2 | _eModeCategories[2].collateralBitmap | uint128 | 0 | 2 |
      | 0x67dcc8…d6b3 | _eModeCategories[2].label | string | "" | "BTCb Stablecoins" |
      | 0x67dcc8…d6b4 | _eModeCategories[2].borrowableBitmap | uint128 | 0 | 12 |
      | 0x7a18f9…b37b | _reserves[0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (AaveV3MegaEth.ASSETS.BTCb.UNDERLYING)].configuration.decimals | uint8 | 0 | 8 |
      | 0x7a18f9…b37b | _reserves[0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (AaveV3MegaEth.ASSETS.BTCb.UNDERLYING)].configuration.active | bool | false | true |
      | 0x7a18f9…b37b | _reserves[0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (AaveV3MegaEth.ASSETS.BTCb.UNDERLYING)].configuration.reserveFactor | uint16 | 0 | 2000 |
      | 0x7a18f9…b37b | _reserves[0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (AaveV3MegaEth.ASSETS.BTCb.UNDERLYING)].configuration.borrowCap | uint36 | 0 | 1 |
      | 0x7a18f9…b37b | _reserves[0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (AaveV3MegaEth.ASSETS.BTCb.UNDERLYING)].configuration.supplyCap | uint36 | 0 | 2 |
      | 0x7a18f9…b37b | _reserves[0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (AaveV3MegaEth.ASSETS.BTCb.UNDERLYING)].configuration.liquidationProtocolFee | uint16 | 0 | 1000 |
      | 0x7a18f9…b37b | _reserves[0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (AaveV3MegaEth.ASSETS.BTCb.UNDERLYING)].configuration.flashloaningEnabled | bool | false | true |
      | 0x7a18f9…b37b | _reserves[0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (AaveV3MegaEth.ASSETS.BTCb.UNDERLYING)].configuration.virtualAccountingEnabled | bool | false | true |
      | 0x7a18f9…b37c | _reserves[0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (AaveV3MegaEth.ASSETS.BTCb.UNDERLYING)].liquidityIndex | uint128 | 0 | 1000000000000000000000000000 |
      | 0x7a18f9…b37d | _reserves[0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (AaveV3MegaEth.ASSETS.BTCb.UNDERLYING)].variableBorrowIndex | uint128 | 0 | 1000000000000000000000000000 |
      | 0x7a18f9…b37e | _reserves[0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (AaveV3MegaEth.ASSETS.BTCb.UNDERLYING)].lastUpdateTimestamp | uint40 | 0 | 1770659966 |
      | 0x7a18f9…b37e | _reserves[0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (AaveV3MegaEth.ASSETS.BTCb.UNDERLYING)].id | uint16 | 0 | 1 |
      | 0x7a18f9…b37f | _reserves[0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (AaveV3MegaEth.ASSETS.BTCb.UNDERLYING)].aTokenAddress | address | 0x0000000000000000000000000000000000000000 | 0x0889d59eA7178ee5B71DA01949a5cB42aaFBe337 (AaveV3MegaEth.ASSETS.BTCb.A_TOKEN) |
      | 0x7a18f9…b381 | _reserves[0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (AaveV3MegaEth.ASSETS.BTCb.UNDERLYING)].variableDebtTokenAddress | address | 0x0000000000000000000000000000000000000000 | 0x15B550784928C5b1A93849CA5d6caA18B2545B6d (AaveV3MegaEth.ASSETS.BTCb.V_TOKEN) |
      | 0x7a18f9…b383 | _reserves[0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (AaveV3MegaEth.ASSETS.BTCb.UNDERLYING)].virtualUnderlyingBalance | uint128 | 0 | 50000 |
      | 0x80432f…eced | _reserves[0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (AaveV3MegaEth.ASSETS.ezETH.UNDERLYING)].configuration.decimals | uint8 | 0 | 18 |
      | 0x80432f…eced | _reserves[0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (AaveV3MegaEth.ASSETS.ezETH.UNDERLYING)].configuration.active | bool | false | true |
      | 0x80432f…eced | _reserves[0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (AaveV3MegaEth.ASSETS.ezETH.UNDERLYING)].configuration.reserveFactor | uint16 | 0 | 2000 |
      | 0x80432f…eced | _reserves[0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (AaveV3MegaEth.ASSETS.ezETH.UNDERLYING)].configuration.borrowCap | uint36 | 0 | 1 |
      | 0x80432f…eced | _reserves[0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (AaveV3MegaEth.ASSETS.ezETH.UNDERLYING)].configuration.supplyCap | uint36 | 0 | 20 |
      | 0x80432f…eced | _reserves[0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (AaveV3MegaEth.ASSETS.ezETH.UNDERLYING)].configuration.liquidationProtocolFee | uint16 | 0 | 1000 |
      | 0x80432f…eced | _reserves[0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (AaveV3MegaEth.ASSETS.ezETH.UNDERLYING)].configuration.flashloaningEnabled | bool | false | true |
      | 0x80432f…eced | _reserves[0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (AaveV3MegaEth.ASSETS.ezETH.UNDERLYING)].configuration.virtualAccountingEnabled | bool | false | true |
      | 0x80432f…ecee | _reserves[0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (AaveV3MegaEth.ASSETS.ezETH.UNDERLYING)].liquidityIndex | uint128 | 0 | 1000000000000000000000000000 |
      | 0x80432f…ecef | _reserves[0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (AaveV3MegaEth.ASSETS.ezETH.UNDERLYING)].variableBorrowIndex | uint128 | 0 | 1000000000000000000000000000 |
      | 0x80432f…ecf0 | _reserves[0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (AaveV3MegaEth.ASSETS.ezETH.UNDERLYING)].lastUpdateTimestamp | uint40 | 0 | 1770659966 |
      | 0x80432f…ecf0 | _reserves[0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (AaveV3MegaEth.ASSETS.ezETH.UNDERLYING)].id | uint16 | 0 | 6 |
      | 0x80432f…ecf1 | _reserves[0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (AaveV3MegaEth.ASSETS.ezETH.UNDERLYING)].aTokenAddress | address | 0x0000000000000000000000000000000000000000 | 0x03C99Cce547b1c2E74442b73E6f588A66D19597e (AaveV3MegaEth.ASSETS.ezETH.A_TOKEN) |
      | 0x80432f…ecf3 | _reserves[0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (AaveV3MegaEth.ASSETS.ezETH.UNDERLYING)].variableDebtTokenAddress | address | 0x0000000000000000000000000000000000000000 | 0x1505f48Bd4db0fF8B28817D2C0Fb95Abcb8eEbbc (AaveV3MegaEth.ASSETS.ezETH.V_TOKEN) |
      | 0x80432f…ecf5 | _reserves[0x09601A65e7de7BC8A19813D263dD9E98bFdC3c57 (AaveV3MegaEth.ASSETS.ezETH.UNDERLYING)].virtualUnderlyingBalance | uint128 | 0 | 2500000000000000 |
      | 0x81d099…3155 | _eModeCategories[3].ltv | uint16 | 0 | 7500 |
      | 0x81d099…3155 | _eModeCategories[3].liquidationThreshold | uint16 | 0 | 7900 |
      | 0x81d099…3155 | _eModeCategories[3].liquidationBonus | uint16 | 0 | 10650 |
      | 0x81d099…3155 | _eModeCategories[3].collateralBitmap | uint128 | 0 | 16 |
      | 0x81d099…3156 | _eModeCategories[3].label | string | "" | "wstETH Stablecoins" |
      | 0x81d099…3157 | _eModeCategories[3].borrowableBitmap | uint128 | 0 | 12 |
      | 0x8868a5…338c | _reserves[0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (AaveV3MegaEth.ASSETS.wrsETH.UNDERLYING)].configuration.decimals | uint8 | 0 | 18 |
      | 0x8868a5…338c | _reserves[0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (AaveV3MegaEth.ASSETS.wrsETH.UNDERLYING)].configuration.active | bool | false | true |
      | 0x8868a5…338c | _reserves[0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (AaveV3MegaEth.ASSETS.wrsETH.UNDERLYING)].configuration.reserveFactor | uint16 | 0 | 2000 |
      | 0x8868a5…338c | _reserves[0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (AaveV3MegaEth.ASSETS.wrsETH.UNDERLYING)].configuration.borrowCap | uint36 | 0 | 1 |
      | 0x8868a5…338c | _reserves[0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (AaveV3MegaEth.ASSETS.wrsETH.UNDERLYING)].configuration.supplyCap | uint36 | 0 | 20 |
      | 0x8868a5…338c | _reserves[0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (AaveV3MegaEth.ASSETS.wrsETH.UNDERLYING)].configuration.liquidationProtocolFee | uint16 | 0 | 1000 |
      | 0x8868a5…338c | _reserves[0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (AaveV3MegaEth.ASSETS.wrsETH.UNDERLYING)].configuration.flashloaningEnabled | bool | false | true |
      | 0x8868a5…338c | _reserves[0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (AaveV3MegaEth.ASSETS.wrsETH.UNDERLYING)].configuration.virtualAccountingEnabled | bool | false | true |
      | 0x8868a5…338d | _reserves[0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (AaveV3MegaEth.ASSETS.wrsETH.UNDERLYING)].liquidityIndex | uint128 | 0 | 1000000000000000000000000000 |
      | 0x8868a5…338e | _reserves[0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (AaveV3MegaEth.ASSETS.wrsETH.UNDERLYING)].variableBorrowIndex | uint128 | 0 | 1000000000000000000000000000 |
      | 0x8868a5…338f | _reserves[0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (AaveV3MegaEth.ASSETS.wrsETH.UNDERLYING)].lastUpdateTimestamp | uint40 | 0 | 1770659966 |
      | 0x8868a5…338f | _reserves[0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (AaveV3MegaEth.ASSETS.wrsETH.UNDERLYING)].id | uint16 | 0 | 5 |
      | 0x8868a5…3390 | _reserves[0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (AaveV3MegaEth.ASSETS.wrsETH.UNDERLYING)].aTokenAddress | address | 0x0000000000000000000000000000000000000000 | 0xb8578af311353b44B14bb4480EBB4DE608EC7e1B (AaveV3MegaEth.ASSETS.wrsETH.A_TOKEN) |
      | 0x8868a5…3392 | _reserves[0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (AaveV3MegaEth.ASSETS.wrsETH.UNDERLYING)].variableDebtTokenAddress | address | 0x0000000000000000000000000000000000000000 | 0xd7B71D855bBAcd3f11F623400bc870AB3448AfF7 (AaveV3MegaEth.ASSETS.wrsETH.V_TOKEN) |
      | 0x8868a5…3394 | _reserves[0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (AaveV3MegaEth.ASSETS.wrsETH.UNDERLYING)].virtualUnderlyingBalance | uint128 | 0 | 2500000000000000 |
      | 0x8e0cc0…eeb0 | _eModeCategories[1].ltv | uint16 | 0 | 8050 |
      | 0x8e0cc0…eeb0 | _eModeCategories[1].liquidationThreshold | uint16 | 0 | 8300 |
      | 0x8e0cc0…eeb0 | _eModeCategories[1].liquidationBonus | uint16 | 0 | 10550 |
      | 0x8e0cc0…eeb0 | _eModeCategories[1].collateralBitmap | uint128 | 0 | 1 |
      | 0x8e0cc0…eeb1 | _eModeCategories[1].label | string | "" | "WETH Stablecoins" |
      | 0x8e0cc0…eeb2 | _eModeCategories[1].borrowableBitmap | uint128 | 0 | 12 |
      | 0x9f3411…3ade | _reserves[0x4200000000000000000000000000000000000006 (AaveV3MegaEth.ASSETS.WETH.UNDERLYING)].configuration.decimals | uint8 | 0 | 18 |
      | 0x9f3411…3ade | _reserves[0x4200000000000000000000000000000000000006 (AaveV3MegaEth.ASSETS.WETH.UNDERLYING)].configuration.active | bool | false | true |
      | 0x9f3411…3ade | _reserves[0x4200000000000000000000000000000000000006 (AaveV3MegaEth.ASSETS.WETH.UNDERLYING)].configuration.reserveFactor | uint16 | 0 | 1500 |
      | 0x9f3411…3ade | _reserves[0x4200000000000000000000000000000000000006 (AaveV3MegaEth.ASSETS.WETH.UNDERLYING)].configuration.borrowCap | uint36 | 0 | 10 |
      | 0x9f3411…3ade | _reserves[0x4200000000000000000000000000000000000006 (AaveV3MegaEth.ASSETS.WETH.UNDERLYING)].configuration.supplyCap | uint36 | 0 | 20 |
      | 0x9f3411…3ade | _reserves[0x4200000000000000000000000000000000000006 (AaveV3MegaEth.ASSETS.WETH.UNDERLYING)].configuration.liquidationProtocolFee | uint16 | 0 | 1000 |
      | 0x9f3411…3ade | _reserves[0x4200000000000000000000000000000000000006 (AaveV3MegaEth.ASSETS.WETH.UNDERLYING)].configuration.flashloaningEnabled | bool | false | true |
      | 0x9f3411…3ade | _reserves[0x4200000000000000000000000000000000000006 (AaveV3MegaEth.ASSETS.WETH.UNDERLYING)].configuration.virtualAccountingEnabled | bool | false | true |
      | 0x9f3411…3adf | _reserves[0x4200000000000000000000000000000000000006 (AaveV3MegaEth.ASSETS.WETH.UNDERLYING)].liquidityIndex | uint128 | 0 | 1000000000000000000000000000 |
      | 0x9f3411…3ae0 | _reserves[0x4200000000000000000000000000000000000006 (AaveV3MegaEth.ASSETS.WETH.UNDERLYING)].variableBorrowIndex | uint128 | 0 | 1000000000000000000000000000 |
      | 0x9f3411…3ae1 | _reserves[0x4200000000000000000000000000000000000006 (AaveV3MegaEth.ASSETS.WETH.UNDERLYING)].lastUpdateTimestamp | uint40 | 0 | 1770659966 |
      | 0x9f3411…3ae2 | _reserves[0x4200000000000000000000000000000000000006 (AaveV3MegaEth.ASSETS.WETH.UNDERLYING)].aTokenAddress | address | 0x0000000000000000000000000000000000000000 | 0xa31E6b433382062e8A1dA41485f7b234D97c3f4d (AaveV3MegaEth.ASSETS.WETH.A_TOKEN) |
      | 0x9f3411…3ae4 | _reserves[0x4200000000000000000000000000000000000006 (AaveV3MegaEth.ASSETS.WETH.UNDERLYING)].variableDebtTokenAddress | address | 0x0000000000000000000000000000000000000000 | 0x09ADCCC7AF2aBD356c18A4CadF2e5cC250f300E9 (AaveV3MegaEth.ASSETS.WETH.V_TOKEN) |
      | 0x9f3411…3ae6 | _reserves[0x4200000000000000000000000000000000000006 (AaveV3MegaEth.ASSETS.WETH.UNDERLYING)].virtualUnderlyingBalance | uint128 | 0 | 2500000000000000 |
      | 0x9ff805…a6c3 | _reserves[0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING)].configuration.decimals | uint8 | 0 | 18 |
      | 0x9ff805…a6c3 | _reserves[0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING)].configuration.active | bool | false | true |
      | 0x9ff805…a6c3 | _reserves[0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING)].configuration.borrowingEnabled | bool | false | true |
      | 0x9ff805…a6c3 | _reserves[0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING)].configuration.borrowingInIsolation | bool | false | true |
      | 0x9ff805…a6c3 | _reserves[0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING)].configuration.reserveFactor | uint16 | 0 | 1000 |
      | 0x9ff805…a6c3 | _reserves[0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING)].configuration.borrowCap | uint36 | 0 | 20000 |
      | 0x9ff805…a6c3 | _reserves[0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING)].configuration.supplyCap | uint36 | 0 | 50000 |
      | 0x9ff805…a6c3 | _reserves[0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING)].configuration.liquidationProtocolFee | uint16 | 0 | 1000 |
      | 0x9ff805…a6c3 | _reserves[0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING)].configuration.flashloaningEnabled | bool | false | true |
      | 0x9ff805…a6c3 | _reserves[0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING)].configuration.virtualAccountingEnabled | bool | false | true |
      | 0x9ff805…a6c4 | _reserves[0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING)].liquidityIndex | uint128 | 0 | 1000000000000000000000000000 |
      | 0x9ff805…a6c5 | _reserves[0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING)].variableBorrowIndex | uint128 | 0 | 1000000000000000000000000000 |
      | 0x9ff805…a6c6 | _reserves[0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING)].lastUpdateTimestamp | uint40 | 0 | 1770659966 |
      | 0x9ff805…a6c6 | _reserves[0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING)].id | uint16 | 0 | 3 |
      | 0x9ff805…a6c7 | _reserves[0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING)].aTokenAddress | address | 0x0000000000000000000000000000000000000000 | 0x5dF82810CB4B8f3e0Da3c031cCc9208ee9cF9500 (AaveV3MegaEth.ASSETS.USDm.A_TOKEN) |
      | 0x9ff805…a6c9 | _reserves[0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING)].variableDebtTokenAddress | address | 0x0000000000000000000000000000000000000000 | 0x6B408d6c479C304794abC60a4693A3AD2D3c2D0D (AaveV3MegaEth.ASSETS.USDm.V_TOKEN) |
      | 0x9ff805…a6cb | _reserves[0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING)].virtualUnderlyingBalance | uint128 | 0 | 10000000000000000000 |
      | 0xace173…504a | _reserves[0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING)].configuration.decimals | uint8 | 0 | 6 |
      | 0xace173…504a | _reserves[0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING)].configuration.active | bool | false | true |
      | 0xace173…504a | _reserves[0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING)].configuration.borrowingEnabled | bool | false | true |
      | 0xace173…504a | _reserves[0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING)].configuration.borrowingInIsolation | bool | false | true |
      | 0xace173…504a | _reserves[0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING)].configuration.reserveFactor | uint16 | 0 | 1000 |
      | 0xace173…504a | _reserves[0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING)].configuration.borrowCap | uint36 | 0 | 20000 |
      | 0xace173…504a | _reserves[0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING)].configuration.supplyCap | uint36 | 0 | 50000 |
      | 0xace173…504a | _reserves[0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING)].configuration.liquidationProtocolFee | uint16 | 0 | 1000 |
      | 0xace173…504a | _reserves[0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING)].configuration.flashloaningEnabled | bool | false | true |
      | 0xace173…504a | _reserves[0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING)].configuration.virtualAccountingEnabled | bool | false | true |
      | 0xace173…504b | _reserves[0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING)].liquidityIndex | uint128 | 0 | 1000000000000000000000000000 |
      | 0xace173…504c | _reserves[0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING)].variableBorrowIndex | uint128 | 0 | 1000000000000000000000000000 |
      | 0xace173…504d | _reserves[0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING)].lastUpdateTimestamp | uint40 | 0 | 1770659966 |
      | 0xace173…504d | _reserves[0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING)].id | uint16 | 0 | 2 |
      | 0xace173…504e | _reserves[0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING)].aTokenAddress | address | 0x0000000000000000000000000000000000000000 | 0xE2283E01a667b512c340f19B499d86fbc885D5Ef (AaveV3MegaEth.ASSETS.USDT0.A_TOKEN) |
      | 0xace173…5050 | _reserves[0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING)].variableDebtTokenAddress | address | 0x0000000000000000000000000000000000000000 | 0xB951225133b5eed3D88645E4Bb1360136FF70D9a (AaveV3MegaEth.ASSETS.USDT0.V_TOKEN) |
      | 0xace173…5052 | _reserves[0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING)].virtualUnderlyingBalance | uint128 | 0 | 10000000 |
      | 0xbc2f57…cebc | _reservesList[3] | address | 0x0000000000000000000000000000000000000000 | 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7 (AaveV3MegaEth.ASSETS.USDm.UNDERLYING) |
      | 0xc082cf…32f0 | _reservesList[1] | address | 0x0000000000000000000000000000000000000000 | 0xB0F70C0bD6FD87dbEb7C10dC692a2a6106817072 (AaveV3MegaEth.ASSETS.BTCb.UNDERLYING) |

      ### 0x80e11cb895a23c901a990239e5534054c66476b5 (GovernanceV3MegaEth.PAYLOADS_CONTROLLER)

      | slot | variable | type | previous value | new value |
      | --- | --- | --- | --- | --- |
      | 0xa15bc6…054c | _payloads[1].state | enum IPayloadsControllerCore.PayloadState | 2 (Queued) | 3 (Executed) |
      | 0xa15bc6…054d | _payloads[1].executedAt | uint40 | 0 | 1770659966 |

      ### 0xa31e6b433382062e8a1da41485f7b234d97c3f4d (AaveV3MegaEth.ASSETS.WETH.A_TOKEN)

      **Nonce diff**: 0 → 1

      | slot | variable | type | previous value | new value |
      | --- | --- | --- | --- | --- |
      | 0x000000…0000 | lastInitializedRevision | uint256 | 0 | 5 |
      | 0x000000…0001 | - | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0x000000…0036 | _totalSupply | uint256 | 0 | 2500000000000000 |
      | 0x000000…0037 | _name | string | "" | "Aave MegaEth WETH" |
      | 0x000000…0038 | _symbol | string | "" | "aMegWETH" |
      | 0x000000…0039 | _decimals | uint8 | 0 | 18 |
      | 0x000000…003b | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0xe06ffb5ae9c342ea15be81d4f0109a4c670edd9ff6709b05ecdf6b1aec6b18da |
      | 0x000000…003d | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0x4200000000000000000000000000000000000006 (AaveV3MegaEth.ASSETS.WETH.UNDERLYING) |
      | 0x001780…85b1 | _userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643 (AaveV3MegaEth.DUST_BIN)].balance | uint120 | 0 | 2500000000000000 |
      | 0x001780…85b1 | _userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643 (AaveV3MegaEth.DUST_BIN)].additionalData | uint128 | 0 | 1000000000000000000000000000 |
      | 0x360894…2bbc | implementation (ERC-1967) | address | 0x0000000000000000000000000000000000000000 | 0x34CA0A24E0b7cbCEB77088AE539f57BA0650fC05 (AaveV3MegaEth.DEFAULT_A_TOKEN_IMPL) |

      ### 0xad2de503b5c723371d6b38a5224a2e12e103dfb8 (AaveV3MegaEth.ASSETS.wstETH.A_TOKEN)

      **Nonce diff**: 0 → 1

      | slot | variable | type | previous value | new value |
      | --- | --- | --- | --- | --- |
      | 0x000000…0000 | lastInitializedRevision | uint256 | 0 | 5 |
      | 0x000000…0001 | - | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0x000000…0036 | _totalSupply | uint256 | 0 | 2500000000000000 |
      | 0x000000…0037 | _name | string | "" | "Aave MegaEth wstETH" |
      | 0x000000…0038 | _symbol | string | "" | "aMegwstETH" |
      | 0x000000…0039 | _decimals | uint8 | 0 | 18 |
      | 0x000000…003b | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x729b2f6bdb04ae9127148d2e1c0d903f3000fd9d9024ad5d3cda0b904a5b97ee |
      | 0x000000…003d | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0x601aC63637933D88285A025C685AC4e9a92a98dA (AaveV3MegaEth.ASSETS.wstETH.UNDERLYING) |
      | 0x001780…85b1 | _userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643 (AaveV3MegaEth.DUST_BIN)].balance | uint120 | 0 | 2500000000000000 |
      | 0x001780…85b1 | _userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643 (AaveV3MegaEth.DUST_BIN)].additionalData | uint128 | 0 | 1000000000000000000000000000 |
      | 0x360894…2bbc | implementation (ERC-1967) | address | 0x0000000000000000000000000000000000000000 | 0x34CA0A24E0b7cbCEB77088AE539f57BA0650fC05 (AaveV3MegaEth.DEFAULT_A_TOKEN_IMPL) |

      ### 0xb0f70c0bd6fd87dbeb7c10dc692a2a6106817072 (AaveV3MegaEth.ASSETS.BTCb.UNDERLYING)

      | slot | previous value | new value |
      | --- | --- | --- |
      | 0x4ad958461d38e50759ecd2d67cb1a2afbffab25bae32fd33026cf7bbf0f0da07 | 0x000000000000000000000000000000000000000000000000000000000000c350 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0x5d6747c86b1c081bb00df65b4be0a48ac12eb92eacca7bc2f5ba6afdb3b971d8 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0xb4b547208411cd7bf42e5baa224c56ba18cc430f78a68ec4195db75e9d4ab83e | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000000000000000000000000000000000000000c350 |

      ### 0xb8578af311353b44b14bb4480ebb4de608ec7e1b (AaveV3MegaEth.ASSETS.wrsETH.A_TOKEN)

      **Nonce diff**: 0 → 1

      | slot | variable | type | previous value | new value |
      | --- | --- | --- | --- | --- |
      | 0x000000…0000 | lastInitializedRevision | uint256 | 0 | 5 |
      | 0x000000…0001 | - | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0x000000…0036 | _totalSupply | uint256 | 0 | 2500000000000000 |
      | 0x000000…0037 | _name | string | "" | "Aave MegaEth wrsETH" |
      | 0x000000…0038 | _symbol | string | "" | "aMegwrsETH" |
      | 0x000000…0039 | _decimals | uint8 | 0 | 18 |
      | 0x000000…003b | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0xa6bb8b8aa8c594122e9790d3fc797d162c20f39cf3df3fa29a5c58498277da62 |
      | 0x000000…003d | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (AaveV3MegaEth.ASSETS.wrsETH.UNDERLYING) |
      | 0x001780…85b1 | _userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643 (AaveV3MegaEth.DUST_BIN)].balance | uint120 | 0 | 2500000000000000 |
      | 0x001780…85b1 | _userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643 (AaveV3MegaEth.DUST_BIN)].additionalData | uint128 | 0 | 1000000000000000000000000000 |
      | 0x360894…2bbc | implementation (ERC-1967) | address | 0x0000000000000000000000000000000000000000 | 0x34CA0A24E0b7cbCEB77088AE539f57BA0650fC05 (AaveV3MegaEth.DEFAULT_A_TOKEN_IMPL) |

      ### 0xb8ce59fc3717ada4c02eadf9682a9e934f625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING)

      | slot | previous value | new value |
      | --- | --- | --- |
      | 0x32e08ec388bd03cb8e0fb9e71795585b8d5c1d03896c545e523e36ce4e50debd | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0xa5e17f7c4ac04daf02066e2ede19bc9b5191ba392924be2761dc2d5b9f92a203 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000989680 |
      | 0xce693b0befa09013aa348b2de6dfacddecacae2c838457c156fcf2d9e1b26771 | 0x0000000000000000000000000000000000000000000000000000000000989680 | 0x0000000000000000000000000000000000000000000000000000000000000000 |

      ### 0xb951225133b5eed3d88645e4bb1360136ff70d9a (AaveV3MegaEth.ASSETS.USDT0.V_TOKEN)

      **Nonce diff**: 0 → 1

      | slot | variable | type | previous value | new value |
      | --- | --- | --- | --- | --- |
      | 0x000000…0000 | lastInitializedRevision | uint256 | 0 | 5 |
      | 0x000000…0001 | - | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0x000000…0035 | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x75c73e22a7e9e273e671a3b0075a003558700829edae3d3df81a9fa309d2eff7 |
      | 0x000000…0037 | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING) |
      | 0x000000…003b | _name | string | "" | (long string, length 32) |
      | 0x000000…003c | _symbol | string | "" | "variableDebtMegUSDT0" |
      | 0x000000…003d | _decimals | uint8 | 0 | 6 |
      | 0x360894…2bbc | implementation (ERC-1967) | address | 0x0000000000000000000000000000000000000000 | 0xfF01493C22208de3A89FE9CaFBDAE103acc72AF8 (AaveV3MegaEth.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL) |
      | 0xbbe321…1a4d | _name (data) | string | "" | "Aave MegaEth Variable Debt USDT0" |

      ### 0xcfc61568b91414dbf7bb1a4344c633e1ab214bc9 (AaveV3MegaEth.EMISSION_MANAGER)

      | slot | previous value | new value |
      | --- | --- | --- |
      | 0x05646d600895f9405b64cdfed29ca24d3bd29abd3062806028e8f1e75be4f147 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000ac140648435d03f784879cd789130f22ef588fcd |
      | 0x0bbf805957ec48a0e680a47cd4bd7beebbcbdfb036cbe5f35a7fa9ab6fe191fa | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000ac140648435d03f784879cd789130f22ef588fcd |
      | 0x154cdbb7de72e0cdbee7c196a8a50568aec4afa004286ba993d78ad915b7b842 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000ac140648435d03f784879cd789130f22ef588fcd |
      | 0x273f16a71a04931653b755df37eb67b5f4614ddb14d0481764b83ebe0a9a5b81 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000ac140648435d03f784879cd789130f22ef588fcd |
      | 0x39fca1986e805eba3eb484c683d38bb3b07ef9562c90ae148d9a6dbce4752ea7 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000ac140648435d03f784879cd789130f22ef588fcd |
      | 0x4300a6fd716c5e6b8977560a481651e5f3aa4bb226d25e1a437043f381f5020d | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000ac140648435d03f784879cd789130f22ef588fcd |
      | 0x5259c47931d56d1b126a6deead2c72a9d4f2fb2984cb200d5c8c1e15198b5cb9 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000ac140648435d03f784879cd789130f22ef588fcd |
      | 0x6dbba495d6cb19dbc8b749805f9afcc1821fb4f2b173623a9ae8f58f66975d4a | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000ac140648435d03f784879cd789130f22ef588fcd |
      | 0xa5eb4c36c859c44cfebee6c21c783e1757bb8fd486f07b1823522dc4d1891bc1 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000ac140648435d03f784879cd789130f22ef588fcd |
      | 0xad59d8b039d0a49adcf8b040c0a328357753589ae2102d254712da0d90d17318 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000ac140648435d03f784879cd789130f22ef588fcd |
      | 0xb2bd4b661a40c9ccb6f5941be95deb37a4b0677572e7c460d620ba1aa7e821bf | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000ac140648435d03f784879cd789130f22ef588fcd |
      | 0xce728f4767e95b5dd1ff5e19bb2d89e13a71991ed8d9f98b24edfa4741c87ceb | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000ac140648435d03f784879cd789130f22ef588fcd |
      | 0xd1b7595d12b8038d6433c29d38b7d3ee22f9f1b0dbfb3a6680ed4cc0f8e9665e | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000ac140648435d03f784879cd789130f22ef588fcd |
      | 0xe1ad0b1ed5dc2c7bd3c9fbb23c7d5b32b233953cbe1b27174b7f53e78b9a9877 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x000000000000000000000000ac140648435d03f784879cd789130f22ef588fcd |

      ### 0xd7b71d855bbacd3f11f623400bc870ab3448aff7 (AaveV3MegaEth.ASSETS.wrsETH.V_TOKEN)

      **Nonce diff**: 0 → 1

      | slot | variable | type | previous value | new value |
      | --- | --- | --- | --- | --- |
      | 0x000000…0000 | lastInitializedRevision | uint256 | 0 | 5 |
      | 0x000000…0001 | - | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0x000000…0035 | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x2780bc7ac7dec26aab6c8e2fcfd8879e30b4d5c12b6d85249f7fcde7f43ac9ca |
      | 0x000000…0037 | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0x4Fc44BE15e9B6E30C1E774E2C87A21D3E8b5403F (AaveV3MegaEth.ASSETS.wrsETH.UNDERLYING) |
      | 0x000000…003b | _name | string | "" | (long string, length 33) |
      | 0x000000…003c | _symbol | string | "" | "variableDebtMegwrsETH" |
      | 0x000000…003d | _decimals | uint8 | 0 | 18 |
      | 0x360894…2bbc | implementation (ERC-1967) | address | 0x0000000000000000000000000000000000000000 | 0xfF01493C22208de3A89FE9CaFBDAE103acc72AF8 (AaveV3MegaEth.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL) |
      | 0xbbe321…1a4d | _name (data) | string | "" | "Aave MegaEth Variable Debt wrsET" |
      | 0xbbe321…1a4e | _name (data) | string | "" | "H" |

      ### 0xe2283e01a667b512c340f19b499d86fbc885d5ef (AaveV3MegaEth.ASSETS.USDT0.A_TOKEN)

      **Nonce diff**: 0 → 1

      | slot | variable | type | previous value | new value |
      | --- | --- | --- | --- | --- |
      | 0x000000…0000 | lastInitializedRevision | uint256 | 0 | 5 |
      | 0x000000…0001 | - | - | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
      | 0x000000…0036 | _totalSupply | uint256 | 0 | 10000000 |
      | 0x000000…0037 | _name | string | "" | "Aave MegaEth USDT0" |
      | 0x000000…0038 | _symbol | string | "" | "aMegUSDT0" |
      | 0x000000…0039 | _decimals | uint8 | 0 | 6 |
      | 0x000000…003b | _domainSeparator | bytes32 | 0x0000000000000000000000000000000000000000000000000000000000000000 | 0xca3d8725269fe463497f33ccd077c42fb66ca9482b28b8c69d0fe96d070d5021 |
      | 0x000000…003d | _underlyingAsset | address | 0x0000000000000000000000000000000000000000 | 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb (AaveV3MegaEth.ASSETS.USDT0.UNDERLYING) |
      | 0x001780…85b1 | _userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643 (AaveV3MegaEth.DUST_BIN)].balance | uint120 | 0 | 10000000 |
      | 0x001780…85b1 | _userState[0x8d1dac82259FdE48D8086CC42cAa98E825C5B643 (AaveV3MegaEth.DUST_BIN)].additionalData | uint128 | 0 | 1000000000000000000000000000 |
      | 0x360894…2bbc | implementation (ERC-1967) | address | 0x0000000000000000000000000000000000000000 | 0x34CA0A24E0b7cbCEB77088AE539f57BA0650fC05 (AaveV3MegaEth.DEFAULT_A_TOKEN_IMPL) |

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
              "decimals": 18,
              "id": 6,
              "interestRateStrategy": "0x5cC4f782cFe249286476A7eFfD9D7bd215768194",
              "isActive": true,
              "isFlashloanable": true,
              "isFrozen": false,
              "isPaused": false,
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
              "decimals": 18,
              "id": 0,
              "interestRateStrategy": "0x5cC4f782cFe249286476A7eFfD9D7bd215768194",
              "isActive": true,
              "isFlashloanable": true,
              "isFrozen": false,
              "isPaused": false,
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
              "decimals": 18,
              "id": 5,
              "interestRateStrategy": "0x5cC4f782cFe249286476A7eFfD9D7bd215768194",
              "isActive": true,
              "isFlashloanable": true,
              "isFrozen": false,
              "isPaused": false,
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
              "decimals": 18,
              "id": 4,
              "interestRateStrategy": "0x5cC4f782cFe249286476A7eFfD9D7bd215768194",
              "isActive": true,
              "isFlashloanable": true,
              "isFrozen": false,
              "isPaused": false,
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
              "decimals": 8,
              "id": 1,
              "interestRateStrategy": "0x5cC4f782cFe249286476A7eFfD9D7bd215768194",
              "isActive": true,
              "isFlashloanable": true,
              "isFrozen": false,
              "isPaused": false,
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
              "decimals": 6,
              "id": 2,
              "interestRateStrategy": "0x5cC4f782cFe249286476A7eFfD9D7bd215768194",
              "isActive": true,
              "isFlashloanable": true,
              "isFrozen": false,
              "isPaused": false,
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
              "decimals": 18,
              "id": 3,
              "interestRateStrategy": "0x5cC4f782cFe249286476A7eFfD9D7bd215768194",
              "isActive": true,
              "isFlashloanable": true,
              "isFrozen": false,
              "isPaused": false,
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
        },
        "eModes": {
          "1": {
            "from": null,
            "to": {
              "borrowableBitmap": "12",
              "collateralBitmap": "1",
              "eModeCategory": 1,
              "isolated": false,
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
              "isolated": false,
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
              "isolated": false,
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
              "isolated": false,
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
              "isolated": false,
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
              "isolated": false,
              "label": "ezETH Correlated",
              "liquidationBonus": 10100,
              "liquidationThreshold": 9500,
              "ltv": 9300
            }
          }
        }
      }
      \`\`\`
      "
    `);
  });
});

// Topic hashes for IAgentConfigurator events (keccak256 of signature)
const AGENT_REGISTERED = '0x0d063c6022bff16d09991a9f91882ffa112f5fb2529136f65eb4c77bbd047e43';
const AGENT_ADDRESS_SET = '0x49ae5a2f9400fc9a6874ec8e69cf4dcb82883d824c93388271dca846098e8bfe';
const AGENT_ADMIN_SET = '0xd61d2421c5bb057269066046ce93b137bb1df44332310530dec71fca964485b4';
const AGENT_ENABLED_SET = '0x2d687e7e18d7d5e9fccf01f905bb15b7a6521a83eea31080b430fe99a82c3d82';
const AGENT_PERMISSIONED_STATUS_SET =
  '0xfb39cc5d87e3067ba835813b35ed2181005ece073d76c7cbbdb4779b7a6446ed';
const MARKETS_FROM_AGENT_ENABLED =
  '0x50cdda6e37491918e4a5f7941910c68aa643a311610f9dd213f6d2955a246c0a';
const EXPIRATION_PERIOD_SET = '0x6a8e901a014ecaeac1bf64b55f5cf50d9988250d9f33a56f9b694971592ade43';
const MINIMUM_DELAY_SET = '0x272ec2b5975364e003ffa08930bbafc77472bc7fc2c2b078bf9a09997de6632f';
const AGENT_CONTEXT_SET = '0x62628638a1817b830bc3c14382a2f4df99a461cee4408e978bb6aaaab6a1b036';
const ALLOWED_MARKET_ADDED = '0x2fc0d54cb5ab2406eb24b175bf09b6fff1268acd21ac14c7e3422146a60bb37e';
const ALLOWED_MARKET_REMOVED = '0x65bb60f6360137104c7b1d036ac5e53273c9da5662306bae223c1f8942a01bcd';
const RESTRICTED_MARKET_ADDED =
  '0xa32f8d38bd6f79b28a99f671eafa0d6c7d9ed79a92c6fbf9433124f335b39b84';
const RESTRICTED_MARKET_REMOVED =
  '0x9fdc8893bd7bb12c1431f72399b7caf70867c7c68b1da755533287dd68c4f1dc';
const PERMISSIONED_SENDER_ADDED =
  '0x0040935b7c4188ff3d4b804d38d3008c9cd5fb141b3b3453904a76cfae835d54';
const PERMISSIONED_SENDER_REMOVED =
  '0xefd1a368b568dd579ddf460ad65587bdc6ed7797375b82f559c40901f1f3ad36';
const MAX_BATCH_SIZE_SET = '0x41122ae347d086d4eca255208d465d964ae84c71bc0dd28e1d2be5861d966e0b';
const UPDATE_INJECTED = '0x3b5f9b036a0fa1bd3e6bda204322458c0667dcc37bbcc038d0903e57e8a058be';

// Padded values reused across tests
const AGENT_ID_0 = '0x0000000000000000000000000000000000000000000000000000000000000000';
const AGENT_ID_1 = '0x0000000000000000000000000000000000000000000000000000000000000001';
const RISK_ORACLE = '0x0000000000000000000000002e4d168044b4532b4182dc00434498082e13e0bf';
const AGENT_ADDRESS = '0x000000000000000000000000a2430ab7ac492d70c2bd4ea83feaf6f8af3e165c';
const ADMIN_ADDRESS = '0x0000000000000000000000001df462e2712496373a347f8ad10802a5e95f053d';
const MARKET_ADDRESS = '0x0000000000000000000000004200000000000000000000000000000000000006';
const SENDER_ADDRESS = '0x000000000000000000000000050e8fc96dd6c1ba971e3633c0b340680043661e';
const BOOL_TRUE = '0x0000000000000000000000000000000000000000000000000000000000000001';
const BOOL_FALSE = '0x0000000000000000000000000000000000000000000000000000000000000000';
const VALUE_1000 = '0x00000000000000000000000000000000000000000000000000000000000003e8';
const VALUE_255 = '0x00000000000000000000000000000000000000000000000000000000000000ff';
const UPDATE_TYPE_HASH = '0xa2a23724fc9bbd60f7d28de9b7010ef0fc522d17af97a644153b859501877e51';
const CONTEXT_HASH = '0x20fb6752da6295cc7038ee3d686e0cc48f953d7463d6801aa3902ce2e84811f0';

const AGENT_HUB = '0x17781Ba226b359e5C1E1ee5ac9E28Ec5b84fd039';
// Ink chain id
const INK_CHAIN_ID = 57073;

describe('renderLogsSection - IAgentConfigurator events', () => {
  it('decodes AgentRegistered', async () => {
    const result = await renderLogsSection(
      [
        {
          emitter: AGENT_HUB,
          topics: [AGENT_REGISTERED, AGENT_ID_0, RISK_ORACLE, UPDATE_TYPE_HASH],
          data: '0x',
        },
      ],
      INK_CHAIN_ID
    );
    expect(result).toContain('AgentRegistered(');
    expect(result).not.toContain('topics:');
  });

  it('decodes AgentAddressSet', async () => {
    const result = await renderLogsSection(
      [{ emitter: AGENT_HUB, topics: [AGENT_ADDRESS_SET, AGENT_ID_0, AGENT_ADDRESS], data: '0x' }],
      INK_CHAIN_ID
    );
    expect(result).toContain('AgentAddressSet(');
    expect(result).not.toContain('topics:');
  });

  it('decodes AgentAdminSet', async () => {
    const result = await renderLogsSection(
      [{ emitter: AGENT_HUB, topics: [AGENT_ADMIN_SET, AGENT_ID_0, ADMIN_ADDRESS], data: '0x' }],
      INK_CHAIN_ID
    );
    expect(result).toContain('AgentAdminSet(');
    expect(result).not.toContain('topics:');
  });

  it('decodes AgentEnabledSet', async () => {
    const result = await renderLogsSection(
      [{ emitter: AGENT_HUB, topics: [AGENT_ENABLED_SET, AGENT_ID_0, BOOL_TRUE], data: '0x' }],
      INK_CHAIN_ID
    );
    expect(result).toContain('AgentEnabledSet(');
    expect(result).not.toContain('topics:');
  });

  it('decodes AgentPermissionedStatusSet', async () => {
    const result = await renderLogsSection(
      [
        {
          emitter: AGENT_HUB,
          topics: [AGENT_PERMISSIONED_STATUS_SET, AGENT_ID_0, BOOL_FALSE],
          data: '0x',
        },
      ],
      INK_CHAIN_ID
    );
    expect(result).toContain('AgentPermissionedStatusSet(');
    expect(result).not.toContain('topics:');
  });

  it('decodes MarketsFromAgentEnabled', async () => {
    const result = await renderLogsSection(
      [
        {
          emitter: AGENT_HUB,
          topics: [MARKETS_FROM_AGENT_ENABLED, AGENT_ID_0, BOOL_TRUE],
          data: '0x',
        },
      ],
      INK_CHAIN_ID
    );
    expect(result).toContain('MarketsFromAgentEnabled(');
    expect(result).not.toContain('topics:');
  });

  it('decodes ExpirationPeriodSet', async () => {
    const result = await renderLogsSection(
      [
        {
          emitter: AGENT_HUB,
          topics: [EXPIRATION_PERIOD_SET, AGENT_ID_0, VALUE_1000],
          data: '0x',
        },
      ],
      INK_CHAIN_ID
    );
    expect(result).toContain('ExpirationPeriodSet(');
    expect(result).not.toContain('topics:');
  });

  it('decodes MinimumDelaySet', async () => {
    const result = await renderLogsSection(
      [{ emitter: AGENT_HUB, topics: [MINIMUM_DELAY_SET, AGENT_ID_0, VALUE_1000], data: '0x' }],
      INK_CHAIN_ID
    );
    expect(result).toContain('MinimumDelaySet(');
    expect(result).not.toContain('topics:');
  });

  it('decodes AgentContextSet', async () => {
    const result = await renderLogsSection(
      [{ emitter: AGENT_HUB, topics: [AGENT_CONTEXT_SET, AGENT_ID_0, CONTEXT_HASH], data: '0x' }],
      INK_CHAIN_ID
    );
    expect(result).toContain('AgentContextSet(');
    expect(result).not.toContain('topics:');
  });

  it('decodes AllowedMarketAdded', async () => {
    const result = await renderLogsSection(
      [
        {
          emitter: AGENT_HUB,
          topics: [ALLOWED_MARKET_ADDED, AGENT_ID_0, MARKET_ADDRESS],
          data: '0x',
        },
      ],
      INK_CHAIN_ID
    );
    expect(result).toContain('AllowedMarketAdded(');
    expect(result).not.toContain('topics:');
  });

  it('decodes AllowedMarketRemoved', async () => {
    const result = await renderLogsSection(
      [
        {
          emitter: AGENT_HUB,
          topics: [ALLOWED_MARKET_REMOVED, AGENT_ID_0, MARKET_ADDRESS],
          data: '0x',
        },
      ],
      INK_CHAIN_ID
    );
    expect(result).toContain('AllowedMarketRemoved(');
    expect(result).not.toContain('topics:');
  });

  it('decodes RestrictedMarketAdded', async () => {
    const result = await renderLogsSection(
      [
        {
          emitter: AGENT_HUB,
          topics: [RESTRICTED_MARKET_ADDED, AGENT_ID_0, MARKET_ADDRESS],
          data: '0x',
        },
      ],
      INK_CHAIN_ID
    );
    expect(result).toContain('RestrictedMarketAdded(');
    expect(result).not.toContain('topics:');
  });

  it('decodes RestrictedMarketRemoved', async () => {
    const result = await renderLogsSection(
      [
        {
          emitter: AGENT_HUB,
          topics: [RESTRICTED_MARKET_REMOVED, AGENT_ID_0, MARKET_ADDRESS],
          data: '0x',
        },
      ],
      INK_CHAIN_ID
    );
    expect(result).toContain('RestrictedMarketRemoved(');
    expect(result).not.toContain('topics:');
  });

  it('decodes PermissionedSenderAdded', async () => {
    const result = await renderLogsSection(
      [
        {
          emitter: AGENT_HUB,
          topics: [PERMISSIONED_SENDER_ADDED, AGENT_ID_0, SENDER_ADDRESS],
          data: '0x',
        },
      ],
      INK_CHAIN_ID
    );
    expect(result).toContain('PermissionedSenderAdded(');
    expect(result).not.toContain('topics:');
  });

  it('decodes PermissionedSenderRemoved', async () => {
    const result = await renderLogsSection(
      [
        {
          emitter: AGENT_HUB,
          topics: [PERMISSIONED_SENDER_REMOVED, AGENT_ID_0, SENDER_ADDRESS],
          data: '0x',
        },
      ],
      INK_CHAIN_ID
    );
    expect(result).toContain('PermissionedSenderRemoved(');
    expect(result).not.toContain('topics:');
  });

  it('decodes MaxBatchSizeSet', async () => {
    const result = await renderLogsSection(
      [{ emitter: AGENT_HUB, topics: [MAX_BATCH_SIZE_SET, VALUE_255], data: '0x' }],
      INK_CHAIN_ID
    );
    expect(result).toContain('MaxBatchSizeSet(');
    expect(result).not.toContain('topics:');
  });

  it('decodes UpdateInjected', async () => {
    const result = await renderLogsSection(
      [
        {
          emitter: AGENT_HUB,
          topics: [UPDATE_INJECTED, AGENT_ID_1, MARKET_ADDRESS, UPDATE_TYPE_HASH],
          data:
            '0x' +
            '0000000000000000000000000000000000000000000000000000000000000001' + // updateId
            '0000000000000000000000000000000000000000000000000000000000000040' + // offset for newValue bytes
            '0000000000000000000000000000000000000000000000000000000000000004' + // length of newValue
            '0000000000000000000000000000000000000000000000000000000000000000', // newValue padded
        },
      ],
      INK_CHAIN_ID
    );
    expect(result).toContain('UpdateInjected(');
    expect(result).not.toContain('topics:');
  });

  it('decodes all agent hub events in a single batch', async () => {
    const logs = [
      {
        emitter: AGENT_HUB,
        topics: [AGENT_REGISTERED, AGENT_ID_0, RISK_ORACLE, UPDATE_TYPE_HASH],
        data: '0x',
      },
      { emitter: AGENT_HUB, topics: [AGENT_ADDRESS_SET, AGENT_ID_0, AGENT_ADDRESS], data: '0x' },
      { emitter: AGENT_HUB, topics: [AGENT_ADMIN_SET, AGENT_ID_0, ADMIN_ADDRESS], data: '0x' },
      { emitter: AGENT_HUB, topics: [AGENT_ENABLED_SET, AGENT_ID_0, BOOL_TRUE], data: '0x' },
      {
        emitter: AGENT_HUB,
        topics: [AGENT_PERMISSIONED_STATUS_SET, AGENT_ID_0, BOOL_FALSE],
        data: '0x',
      },
      {
        emitter: AGENT_HUB,
        topics: [MARKETS_FROM_AGENT_ENABLED, AGENT_ID_0, BOOL_TRUE],
        data: '0x',
      },
      { emitter: AGENT_HUB, topics: [EXPIRATION_PERIOD_SET, AGENT_ID_0, VALUE_1000], data: '0x' },
      { emitter: AGENT_HUB, topics: [MINIMUM_DELAY_SET, AGENT_ID_0, VALUE_1000], data: '0x' },
      { emitter: AGENT_HUB, topics: [AGENT_CONTEXT_SET, AGENT_ID_0, CONTEXT_HASH], data: '0x' },
      {
        emitter: AGENT_HUB,
        topics: [ALLOWED_MARKET_ADDED, AGENT_ID_0, MARKET_ADDRESS],
        data: '0x',
      },
    ];
    const result = await renderLogsSection(logs, INK_CHAIN_ID);
    expect(result).toContain('AgentRegistered(');
    expect(result).toContain('AgentAddressSet(');
    expect(result).toContain('AgentAdminSet(');
    expect(result).toContain('AgentEnabledSet(');
    expect(result).toContain('AgentPermissionedStatusSet(');
    expect(result).toContain('MarketsFromAgentEnabled(');
    expect(result).toContain('ExpirationPeriodSet(');
    expect(result).toContain('MinimumDelaySet(');
    expect(result).toContain('AgentContextSet(');
    expect(result).toContain('AllowedMarketAdded(');
    expect(result).not.toContain('topics:');
  });
});

const DEFAULT_RANGE_CONFIG_SET =
  '0xd277e912eff2e23b18786458bede5c399d8f47442262dc054ddf0f6462b5afaf';
const MARKET_RANGE_CONFIG_SET =
  '0x4666070bf03e7e4884898dfcc3348243da2fda61acc197ce66d0a3da1b60d793';

const RANGE_VALIDATION_MODULE = '0xd24790E75799968CE3feD6E27285baD0a26e7e36';
const AGENT_HUB_PADDED = '0x00000000000000000000000017781ba226b359e5c1e1ee5ac9e28ec5b84fd039';
// ABI-encoded RangeConfig(maxIncrease=3000, maxDecrease=3000, isIncreaseRelative=false, isDecreaseRelative=false)
const RANGE_CONFIG_DATA =
  '0x' +
  '0000000000000000000000000000000000000000000000000000000000000bb8' + // maxIncrease = 3000
  '0000000000000000000000000000000000000000000000000000000000000bb8' + // maxDecrease = 3000
  '0000000000000000000000000000000000000000000000000000000000000000' + // isIncreaseRelative = false
  '0000000000000000000000000000000000000000000000000000000000000000'; // isDecreaseRelative = false

// ABI-encoded (string updateType, RangeConfig config) for MarketRangeConfigSet
// RangeConfig is a static tuple, so its fields are encoded inline in the head.
// Head: [offset_to_string(5*32=160), maxIncrease, maxDecrease, isIncreaseRelative, isDecreaseRelative]
// Tail: [string_length, string_data]
const MARKET_RANGE_CONFIG_DATA =
  '0x' +
  '00000000000000000000000000000000000000000000000000000000000000a0' + // offset to string = 5*32 = 160
  '0000000000000000000000000000000000000000000000000000000000000bb8' + // maxIncrease = 3000
  '0000000000000000000000000000000000000000000000000000000000000bb8' + // maxDecrease = 3000
  '0000000000000000000000000000000000000000000000000000000000000000' + // isIncreaseRelative = false
  '0000000000000000000000000000000000000000000000000000000000000000' + // isDecreaseRelative = false
  '0000000000000000000000000000000000000000000000000000000000000012' + // length of "RateStrategyUpdate" = 18
  '5261746553747261746567795570646174650000000000000000000000000000'; // "RateStrategyUpdate" padded

describe('renderLogsSection - IRangeValidationModule events', () => {
  it('decodes DefaultRangeConfigSet', async () => {
    const result = await renderLogsSection(
      [
        {
          emitter: RANGE_VALIDATION_MODULE,
          topics: [DEFAULT_RANGE_CONFIG_SET, AGENT_HUB_PADDED, AGENT_ID_0, UPDATE_TYPE_HASH],
          data: RANGE_CONFIG_DATA,
        },
      ],
      INK_CHAIN_ID
    );
    expect(result).toContain('DefaultRangeConfigSet(');
    expect(result).not.toContain('topics:');
  });

  it('decodes MarketRangeConfigSet', async () => {
    const result = await renderLogsSection(
      [
        {
          emitter: RANGE_VALIDATION_MODULE,
          topics: [MARKET_RANGE_CONFIG_SET, AGENT_HUB_PADDED, AGENT_ID_0, MARKET_ADDRESS],
          data: MARKET_RANGE_CONFIG_DATA,
        },
      ],
      INK_CHAIN_ID
    );
    expect(result).toContain('MarketRangeConfigSet(');
    expect(result).not.toContain('topics:');
  });
});
