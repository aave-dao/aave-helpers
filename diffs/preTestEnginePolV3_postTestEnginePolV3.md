## Reserve changes

### Reserves altered

#### WETH ([0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619](https://polygonscan.com/address/0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0xf6733B9842883BFE0e0a940eA2F572676af31bde](https://polygonscan.com/address/0xf6733B9842883BFE0e0a940eA2F572676af31bde) | [0x27eFE5db315b71753b2a38ED3d5dd7E9362ba93F](https://polygonscan.com/address/0x27eFE5db315b71753b2a38ED3d5dd7E9362ba93F) |
| variableRateSlope1 | 3.3 % | 3.8 % |
| baseStableBorrowRate | 6.3 % | 6.8 % |
| interestRate | ![before](/.assets/0503ddc95c9ff90b6308f1ba4175b90d670e81ed.svg) | ![after](/.assets/25b7cbb97d2012b141455f46ee9b3f7e0e40a4b0.svg) |

## Raw diff

```json
{
  "reserves": {
    "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619": {
      "interestRateStrategy": {
        "from": "0xf6733B9842883BFE0e0a940eA2F572676af31bde",
        "to": "0x27eFE5db315b71753b2a38ED3d5dd7E9362ba93F"
      }
    }
  },
  "strategies": {
    "0x27eFE5db315b71753b2a38ED3d5dd7E9362ba93F": {
      "from": null,
      "to": {
        "baseStableBorrowRate": "68000000000000000000000000",
        "baseVariableBorrowRate": "10000000000000000000000000",
        "maxExcessStableToTotalDebtRatio": "800000000000000000000000000",
        "maxExcessUsageRatio": "200000000000000000000000000",
        "optimalStableToTotalDebtRatio": "200000000000000000000000000",
        "optimalUsageRatio": "800000000000000000000000000",
        "stableRateSlope1": "40000000000000000000000000",
        "stableRateSlope2": "800000000000000000000000000",
        "variableRateSlope1": "38000000000000000000000000",
        "variableRateSlope2": "800000000000000000000000000"
      }
    }
  }
}
```