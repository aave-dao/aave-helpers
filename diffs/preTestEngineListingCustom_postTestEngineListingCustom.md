## Reserve changes

### Reserves added

#### PSP ([0xcAfE001067cDEF266AfB7Eb5A286dCFD277f3dE5](https://etherscan.io/address/0xcAfE001067cDEF266AfB7Eb5A286dCFD277f3dE5))

| description | value |
| --- | --- |
| decimals | 18 |
| isActive | true |
| isFrozen | false |
| supplyCap | 85,000 PSP |
| borrowCap | 60,000 PSP |
| debtCeiling | 0 $ |
| isSiloed | false |
| isFlashloanable | false |
| eModeCategory | 0 |
| oracle | [0x72AFAECF99C9d9C8215fF44C77B94B99C28741e8](https://etherscan.io/address/0x72AFAECF99C9d9C8215fF44C77B94B99C28741e8) |
| oracleDecimals | 18 |
| oracleDescription | 1INCH / ETH |
| oracleLatestAnswer | 0.000186571062207223 |
| usageAsCollateralEnabled | true |
| ltv | 82.5 % |
| liquidationThreshold | 86 % |
| liquidationBonus | 5 % |
| liquidationProtocolFee | 10 % |
| reserveFactor | 10 % |
| aToken | [0x82F9c5ad306BBa1AD0De49bB5FA6F01bf61085ef](https://etherscan.io/address/0x82F9c5ad306BBa1AD0De49bB5FA6F01bf61085ef) |
| aTokenImpl | [0x7EfFD7b47Bfd17e52fB7559d3f924201b9DbfF3d](https://etherscan.io/address/0x7EfFD7b47Bfd17e52fB7559d3f924201b9DbfF3d) |
| variableDebtToken | [0x68e9f0aD4e6f8F5DB70F6923d4d6d5b225B83b16](https://etherscan.io/address/0x68e9f0aD4e6f8F5DB70F6923d4d6d5b225B83b16) |
| variableDebtTokenImpl | [0xaC725CB59D16C81061BDeA61041a8A5e73DA9EC6](https://etherscan.io/address/0xaC725CB59D16C81061BDeA61041a8A5e73DA9EC6) |
| stableDebtToken | [0x61dFd349140C239d3B61fEe203Efc811b518a317](https://etherscan.io/address/0x61dFd349140C239d3B61fEe203Efc811b518a317) |
| stableDebtTokenImpl | [0x15C5620dfFaC7c7366EED66C20Ad222DDbB1eD57](https://etherscan.io/address/0x15C5620dfFaC7c7366EED66C20Ad222DDbB1eD57) |
| borrowingEnabled | true |
| stableBorrowRateEnabled | true |
| isBorrowableInIsolation | false |
| interestRateStrategy | [0x24701A6368Ff6D2874d6b8cDadd461552B8A5283](https://etherscan.io/address/0x24701A6368Ff6D2874d6b8cDadd461552B8A5283) |
| aTokenName | Aave Ethereum PSP |
| aTokenSymbol | aEthPSP |
| isPaused | false |
| stableDebtTokenName | Aave Ethereum Stable Debt PSP |
| stableDebtTokenSymbol | stableDebtEthPSP |
| variableDebtTokenName | Aave Ethereum Variable Debt PSP |
| variableDebtTokenSymbol | variableDebtEthPSP |
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
    "0xcAfE001067cDEF266AfB7Eb5A286dCFD277f3dE5": {
      "from": null,
      "to": {
        "aToken": "0x82F9c5ad306BBa1AD0De49bB5FA6F01bf61085ef",
        "aTokenImpl": "0x7EfFD7b47Bfd17e52fB7559d3f924201b9DbfF3d",
        "aTokenName": "Aave Ethereum PSP",
        "aTokenSymbol": "aEthPSP",
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
        "oracleLatestAnswer": 186571062207223,
        "reserveFactor": 1000,
        "stableBorrowRateEnabled": true,
        "stableDebtToken": "0x61dFd349140C239d3B61fEe203Efc811b518a317",
        "stableDebtTokenImpl": "0x15C5620dfFaC7c7366EED66C20Ad222DDbB1eD57",
        "stableDebtTokenName": "Aave Ethereum Stable Debt PSP",
        "stableDebtTokenSymbol": "stableDebtEthPSP",
        "supplyCap": 85000,
        "symbol": "PSP",
        "underlying": "0xcAfE001067cDEF266AfB7Eb5A286dCFD277f3dE5",
        "usageAsCollateralEnabled": true,
        "variableDebtToken": "0x68e9f0aD4e6f8F5DB70F6923d4d6d5b225B83b16",
        "variableDebtTokenImpl": "0xaC725CB59D16C81061BDeA61041a8A5e73DA9EC6",
        "variableDebtTokenName": "Aave Ethereum Variable Debt PSP",
        "variableDebtTokenSymbol": "variableDebtEthPSP"
      }
    }
  }
}
```