## Reserve changes

### Reserves altered

#### WETH ([0x4200000000000000000000000000000000000006](https://explorer.optimism.io/address/0x4200000000000000000000000000000000000006))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0x5f58C25D17C09c9e1892F45DE6dA45ed973A5326](https://explorer.optimism.io/address/0x5f58C25D17C09c9e1892F45DE6dA45ed973A5326) | [0xc76EF342898f1AE7E6C4632627Df683FAD8563DD](https://explorer.optimism.io/address/0xc76EF342898f1AE7E6C4632627Df683FAD8563DD) |
| baseVariableBorrowRate | 0 % | 1 % |
| variableRateSlope1 | 3.3 % | 3.8 % |
| baseStableBorrowRate | 6.3 % | 6.8 % |
| interestRate | ![before](/.assets/715cbb89cad22db0c20f074df5ed4b41cd5a2327.svg) | ![after](/.assets/25b7cbb97d2012b141455f46ee9b3f7e0e40a4b0.svg) |

## Raw diff

```json
{
  "reserves": {
    "0x4200000000000000000000000000000000000006": {
      "interestRateStrategy": {
        "from": "0x5f58C25D17C09c9e1892F45DE6dA45ed973A5326",
        "to": "0xc76EF342898f1AE7E6C4632627Df683FAD8563DD"
      }
    }
  },
  "strategies": {
    "0xc76EF342898f1AE7E6C4632627Df683FAD8563DD": {
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