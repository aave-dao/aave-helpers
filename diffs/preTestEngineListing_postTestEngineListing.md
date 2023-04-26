## Reserve changes

### Reserves added

#### 1INCH ([0x9c2C5fd7b07E95EE044DDeba0E97a665F142394f](https://polygonscan.com/address/0x9c2C5fd7b07E95EE044DDeba0E97a665F142394f))

| description | value |
| --- | --- |
| supplyCap | 85,000 1INCH |
| borrowCap | 60,000 1INCH |
| oracle | [0x443C5116CdF663Eb387e72C688D276e702135C87](https://polygonscan.com/address/0x443C5116CdF663Eb387e72C688D276e702135C87) |
| oracleDecimals | 8 |
| oracleDescription | 1INCH / USD |
| oracleLatestAnswer | 0.52690564 |
| aToken | [0xf59036CAEBeA7dC4b86638DFA2E3C97dA9FcCd40](https://polygonscan.com/address/0xf59036CAEBeA7dC4b86638DFA2E3C97dA9FcCd40) |
| aTokenImpl | [0xa5ba6E5EC19a1Bf23C857991c857dB62b2Aa187B](https://polygonscan.com/address/0xa5ba6E5EC19a1Bf23C857991c857dB62b2Aa187B) |
| borrowingEnabled | true |
| debtCeiling | 0 |
| decimals | 18 |
| eModeCategory | 0 |
| interestRateStrategy | [0x03733F4E008d36f2e37F0080fF1c8DF756622E6F](https://polygonscan.com/address/0x03733F4E008d36f2e37F0080fF1c8DF756622E6F) |
| isActive | true |
| isBorrowableInIsolation | false |
| isFlashloanable | false |
| isFrozen | false |
| isSiloed | false |
| liquidationBonus | 5 % |
| liquidationProtocolFee | 10 % |
| liquidationThreshold | 86 % |
| ltv | 82.5 % |
| reserveFactor | 10 % |
| stableBorrowRateEnabled | false |
| stableDebtToken | [0x173e54325AE58B072985DbF232436961981EA000](https://polygonscan.com/address/0x173e54325AE58B072985DbF232436961981EA000) |
| stableDebtTokenImpl | [0x52A1CeB68Ee6b7B5D13E0376A1E0E4423A8cE26e](https://polygonscan.com/address/0x52A1CeB68Ee6b7B5D13E0376A1E0E4423A8cE26e) |
| usageAsCollateralEnabled | true |
| variableDebtToken | [0x77fA66882a8854d883101Fb8501BD3CaD347Fc32](https://polygonscan.com/address/0x77fA66882a8854d883101Fb8501BD3CaD347Fc32) |
| variableDebtTokenImpl | [0x81387c40EB75acB02757C1Ae55D5936E78c9dEd3](https://polygonscan.com/address/0x81387c40EB75acB02757C1Ae55D5936E78c9dEd3) |
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
        "aToken": "0xf59036CAEBeA7dC4b86638DFA2E3C97dA9FcCd40",
        "aTokenImpl": "0xa5ba6E5EC19a1Bf23C857991c857dB62b2Aa187B",
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
        "oracleLatestAnswer": 52690564,
        "reserveFactor": 1000,
        "stableBorrowRateEnabled": false,
        "stableDebtToken": "0x173e54325AE58B072985DbF232436961981EA000",
        "stableDebtTokenImpl": "0x52A1CeB68Ee6b7B5D13E0376A1E0E4423A8cE26e",
        "supplyCap": 85000,
        "symbol": "1INCH",
        "underlying": "0x9c2C5fd7b07E95EE044DDeba0E97a665F142394f",
        "usageAsCollateralEnabled": true,
        "variableDebtToken": "0x77fA66882a8854d883101Fb8501BD3CaD347Fc32",
        "variableDebtTokenImpl": "0x81387c40EB75acB02757C1Ae55D5936E78c9dEd3"
      }
    }
  }
}
```