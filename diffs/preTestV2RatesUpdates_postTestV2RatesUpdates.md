## Reserve changes

### Reserves altered

#### USDC ([0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48](https://etherscan.io/address/0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0x4e1494475048fa155F1D837B6bD51458bD170f48](https://etherscan.io/address/0x4e1494475048fa155F1D837B6bD51458bD170f48) | [0x8821c6B6cd3C45Ad8b5EF43168BBbD094b63a03c](https://etherscan.io/address/0x8821c6B6cd3C45Ad8b5EF43168BBbD094b63a03c) |
| variableRateSlope1 | 12.5 % | 42 % |
| stableRateSlope1 | 2 % | 69 % |
| optimalUsageRatio | 90 % | 69 % |
| maxExcessUsageRatio | 10 % | 31 % |
| interestRate | ![before](https://dash.onaave.com/api/static?variableRateSlope1=125000000000000000000000000&variableRateSlope2=600000000000000000000000000&optimalUsageRatio=900000000000000000000000000&baseVariableBorrowRate=0&maxVariableBorrowRate=undefined) | ![after](https://dash.onaave.com/api/static?variableRateSlope1=420000000000000000000000000&variableRateSlope2=600000000000000000000000000&optimalUsageRatio=690000000000000000000000000&baseVariableBorrowRate=0&maxVariableBorrowRate=undefined) |

## Raw diff

```json
{
  "reserves": {
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48": {
      "interestRateStrategy": {
        "from": "0x4e1494475048fa155F1D837B6bD51458bD170f48",
        "to": "0x8821c6B6cd3C45Ad8b5EF43168BBbD094b63a03c"
      }
    }
  },
  "strategies": {
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48": {
      "address": {
        "from": "0x4e1494475048fa155F1D837B6bD51458bD170f48",
        "to": "0x8821c6B6cd3C45Ad8b5EF43168BBbD094b63a03c"
      },
      "maxExcessUsageRatio": {
        "from": "100000000000000000000000000",
        "to": "310000000000000000000000000"
      },
      "optimalUsageRatio": {
        "from": "900000000000000000000000000",
        "to": "690000000000000000000000000"
      },
      "stableRateSlope1": {
        "from": "20000000000000000000000000",
        "to": "690000000000000000000000000"
      },
      "variableRateSlope1": {
        "from": "125000000000000000000000000",
        "to": "420000000000000000000000000"
      }
    }
  }
}
```