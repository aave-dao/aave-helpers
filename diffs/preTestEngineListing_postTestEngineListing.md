## Reserve changes

### Reserves added

#### 1INCH ([0x9c2C5fd7b07E95EE044DDeba0E97a665F142394f](https://polygonscan.com/address/0x9c2C5fd7b07E95EE044DDeba0E97a665F142394f))

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
| oracle | [0x443C5116CdF663Eb387e72C688D276e702135C87](https://polygonscan.com/address/0x443C5116CdF663Eb387e72C688D276e702135C87) |
| oracleDecimals | 8 |
| oracleDescription | 1INCH / USD |
| oracleLatestAnswer | 0.41296368 |
| usageAsCollateralEnabled | true |
| ltv | 82.5 % |
| liquidationThreshold | 86 % |
| liquidationBonus | 5 % |
| liquidationProtocolFee | 10 % |
| reserveFactor | 10 % |
| aToken | [0xA4D94019934D8333Ef880ABFFbF2FDd611C762BD](https://polygonscan.com/address/0xA4D94019934D8333Ef880ABFFbF2FDd611C762BD) |
| aTokenImpl | [0xCf85FF1c37c594a10195F7A9Ab85CBb0a03f69dE](https://polygonscan.com/address/0xCf85FF1c37c594a10195F7A9Ab85CBb0a03f69dE) |
| variableDebtToken | [0xE701126012EC0290822eEA17B794454d1AF8b030](https://polygonscan.com/address/0xE701126012EC0290822eEA17B794454d1AF8b030) |
| variableDebtTokenImpl | [0x79b5e91037AE441dE0d9e6fd3Fd85b96B83d4E93](https://polygonscan.com/address/0x79b5e91037AE441dE0d9e6fd3Fd85b96B83d4E93) |
| stableDebtToken | [0xc889e9f8370D14A428a9857205d99BFdB400b757](https://polygonscan.com/address/0xc889e9f8370D14A428a9857205d99BFdB400b757) |
| stableDebtTokenImpl | [0x50ddd0Cd4266299527d25De9CBb55fE0EB8dAc30](https://polygonscan.com/address/0x50ddd0Cd4266299527d25De9CBb55fE0EB8dAc30) |
| borrowingEnabled | true |
| stableBorrowRateEnabled | false |
| isBorrowableInIsolation | false |
| interestRateStrategy | [0x03733F4E008d36f2e37F0080fF1c8DF756622E6F](https://polygonscan.com/address/0x03733F4E008d36f2e37F0080fF1c8DF756622E6F) |
| optimalUsageRatio | 45 % |
| maxExcessUsageRatio | 55 % |
| baseVariableBorrowRate | 0 % |
| variableRateSlope1 | 7 % |
| variableRateSlope2 | 300 % |
| baseStableBorrowRate | 9 % |
| stableRateSlope1 | 0 % |
| stableRateSlope2 | 0 % |
| optimalStableToTotalDebtRatio | 20 % |
| maxExcessStableToTotalDebtRatio | 80 % |
| interestRate | ![ir](/.assets/19b2f23d55d76d891e7d30c29aa97741efed9d17.svg) |

## Raw diff

```json
{
  "reserves": {
    "0x9c2C5fd7b07E95EE044DDeba0E97a665F142394f": {
      "from": null,
      "to": {
        "aToken": "0xA4D94019934D8333Ef880ABFFbF2FDd611C762BD",
        "aTokenImpl": "0xCf85FF1c37c594a10195F7A9Ab85CBb0a03f69dE",
        "borrowCap": 60000,
        "borrowingEnabled": true,
        "debtCeiling": 0,
        "decimals": 18,
        "eModeCategory": 0,
        "interestRateStrategy": "0x03733F4E008d36f2e37F0080fF1c8DF756622E6F",
        "isActive": true,
        "isBorrowableInIsolation": false,
        "isFlashloanable": false,
        "isFrozen": false,
        "isSiloed": false,
        "liquidationBonus": 10500,
        "liquidationProtocolFee": 1000,
        "liquidationThreshold": 8600,
        "ltv": 8250,
        "oracle": "0x443C5116CdF663Eb387e72C688D276e702135C87",
        "oracleDecimals": 8,
        "oracleDescription": "1INCH / USD",
        "oracleLatestAnswer": 41296368,
        "reserveFactor": 1000,
        "stableBorrowRateEnabled": false,
        "stableDebtToken": "0xc889e9f8370D14A428a9857205d99BFdB400b757",
        "stableDebtTokenImpl": "0x50ddd0Cd4266299527d25De9CBb55fE0EB8dAc30",
        "supplyCap": 85000,
        "symbol": "1INCH",
        "underlying": "0x9c2C5fd7b07E95EE044DDeba0E97a665F142394f",
        "usageAsCollateralEnabled": true,
        "variableDebtToken": "0xE701126012EC0290822eEA17B794454d1AF8b030",
        "variableDebtTokenImpl": "0x79b5e91037AE441dE0d9e6fd3Fd85b96B83d4E93"
      }
    }
  }
}
```