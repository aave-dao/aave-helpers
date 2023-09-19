## Reserve changes

### Reserves added

#### 1INCH ([0x111111111117dC0aa78b770fA6A738034120C302](https://etherscan.io/address/0x111111111117dC0aa78b770fA6A738034120C302))

| description | value |
| --- | --- |
| decimals | 18 |
| isActive | true |
| isFrozen | false |
| supplyCap | 85,000 1INCH |
| borrowCap | 60,000 1INCH |
| debtCeiling | 0 $ |
| isSiloed | false |
| isFlashloanable | false |
| eModeCategory | 0 |
| oracle | [0x72AFAECF99C9d9C8215fF44C77B94B99C28741e8](https://etherscan.io/address/0x72AFAECF99C9d9C8215fF44C77B94B99C28741e8) |
| oracleDecimals | 18 |
| oracleDescription | 1INCH / ETH |
| oracleLatestAnswer | 0.000216287562682828 |
| usageAsCollateralEnabled | true |
| ltv | 82.5 % |
| liquidationThreshold | 86 % |
| liquidationBonus | 5 % |
| liquidationProtocolFee | 10 % |
| reserveFactor | 10 % |
| aToken | [0x545bD6c032eFdde65A377A6719DEF2796C8E0f2e](https://etherscan.io/address/0x545bD6c032eFdde65A377A6719DEF2796C8E0f2e) |
| aTokenImpl | [0x7EfFD7b47Bfd17e52fB7559d3f924201b9DbfF3d](https://etherscan.io/address/0x7EfFD7b47Bfd17e52fB7559d3f924201b9DbfF3d) |
| variableDebtToken | [0xd180D7fdD4092f07428eFE801E17BC03576b3192](https://etherscan.io/address/0xd180D7fdD4092f07428eFE801E17BC03576b3192) |
| variableDebtTokenImpl | [0xaC725CB59D16C81061BDeA61041a8A5e73DA9EC6](https://etherscan.io/address/0xaC725CB59D16C81061BDeA61041a8A5e73DA9EC6) |
| stableDebtToken | [0x7617d02E311CdE347A0cb45BB7DF2926BBaf5347](https://etherscan.io/address/0x7617d02E311CdE347A0cb45BB7DF2926BBaf5347) |
| stableDebtTokenImpl | [0x15C5620dfFaC7c7366EED66C20Ad222DDbB1eD57](https://etherscan.io/address/0x15C5620dfFaC7c7366EED66C20Ad222DDbB1eD57) |
| borrowingEnabled | true |
| stableBorrowRateEnabled | true |
| isBorrowableInIsolation | false |
| interestRateStrategy | [0x24701A6368Ff6D2874d6b8cDadd461552B8A5283](https://etherscan.io/address/0x24701A6368Ff6D2874d6b8cDadd461552B8A5283) |
| aTokenName | Aave Ethereum 1INCH |
| aTokenSymbol | aEth1INCH |
| isPaused | false |
| stableDebtTokenName | Aave Ethereum Stable Debt 1INCH |
| stableDebtTokenSymbol | stableDebtEth1INCH |
| variableDebtTokenName | Aave Ethereum Variable Debt 1INCH |
| variableDebtTokenSymbol | variableDebtEth1INCH |
| optimalUsageRatio | 45 % |
| maxExcessUsageRatio | 55 % |
| baseVariableBorrowRate | 0 % |
| variableRateSlope1 | 7 % |
| variableRateSlope2 | 300 % |
| baseStableBorrowRate | 9 % |
| stableRateSlope1 | 7 % |
| stableRateSlope2 | 300 % |
| optimalStableToTotalDebtRatio | 20 % |
| maxExcessStableToTotalDebtRatio | 80 % |
| interestRate | ![ir](/.assets/b5cb0fd07fde8594230045982589445fc02ace52.svg) |


## Raw diff

```json
{
  "reserves": {
    "0x111111111117dC0aa78b770fA6A738034120C302": {
      "from": null,
      "to": {
        "aToken": "0x545bD6c032eFdde65A377A6719DEF2796C8E0f2e",
        "aTokenImpl": "0x7EfFD7b47Bfd17e52fB7559d3f924201b9DbfF3d",
        "aTokenName": "Aave Ethereum 1INCH",
        "aTokenSymbol": "aEth1INCH",
        "borrowCap": 60000,
        "borrowingEnabled": true,
        "debtCeiling": 0,
        "decimals": 18,
        "eModeCategory": 0,
        "interestRateStrategy": "0x24701A6368Ff6D2874d6b8cDadd461552B8A5283",
        "isActive": true,
        "isBorrowableInIsolation": false,
        "isFlashloanable": false,
        "isFrozen": false,
        "isPaused": false,
        "isSiloed": false,
        "liquidationBonus": 10500,
        "liquidationProtocolFee": 1000,
        "liquidationThreshold": 8600,
        "ltv": 8250,
        "oracle": "0x72AFAECF99C9d9C8215fF44C77B94B99C28741e8",
        "oracleDecimals": 18,
        "oracleDescription": "1INCH / ETH",
        "oracleLatestAnswer": 216287562682828,
        "reserveFactor": 1000,
        "stableBorrowRateEnabled": true,
        "stableDebtToken": "0x7617d02E311CdE347A0cb45BB7DF2926BBaf5347",
        "stableDebtTokenImpl": "0x15C5620dfFaC7c7366EED66C20Ad222DDbB1eD57",
        "stableDebtTokenName": "Aave Ethereum Stable Debt 1INCH",
        "stableDebtTokenSymbol": "stableDebtEth1INCH",
        "supplyCap": 85000,
        "symbol": "1INCH",
        "underlying": "0x111111111117dC0aa78b770fA6A738034120C302",
        "usageAsCollateralEnabled": true,
        "variableDebtToken": "0xd180D7fdD4092f07428eFE801E17BC03576b3192",
        "variableDebtTokenImpl": "0xaC725CB59D16C81061BDeA61041a8A5e73DA9EC6",
        "variableDebtTokenName": "Aave Ethereum Variable Debt 1INCH",
        "variableDebtTokenSymbol": "variableDebtEth1INCH"
      }
    }
  }
}
```