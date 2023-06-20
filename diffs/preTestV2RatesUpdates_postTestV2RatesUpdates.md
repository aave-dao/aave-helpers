## Reserve changes

### Reserves altered

#### USDC ([0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48](https://etherscan.io/address/0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0x8Cae0596bC1eD42dc3F04c4506cfe442b3E74e27](https://etherscan.io/address/0x8Cae0596bC1eD42dc3F04c4506cfe442b3E74e27) | [0xc76EF342898f1AE7E6C4632627Df683FAD8563DD](https://etherscan.io/address/0xc76EF342898f1AE7E6C4632627Df683FAD8563DD) |
| optimalUsageRatio | 90 % | 69 % |
| maxExcessUsageRatio | 10 % | 31 % |
| variableRateSlope1 | 4 % | 42 % |
| stableRateSlope1 | 2 % | 69 % |
| interestRate | ![before](/.assets/1ee1814a06c37c32f0efd02a4fda97a8278b0714.svg) | ![after](/.assets/ad67c5576b64e24c557a73a5bc9c67be904f53bb.svg) |

## Raw diff

```json
{
  "reserves": {
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48": {
      "interestRateStrategy": {
        "from": "0x8Cae0596bC1eD42dc3F04c4506cfe442b3E74e27",
        "to": "0xc76EF342898f1AE7E6C4632627Df683FAD8563DD"
      }
    }
  },
  "strategies": {
    "0xc76EF342898f1AE7E6C4632627Df683FAD8563DD": {
      "from": null,
      "to": {
        "baseVariableBorrowRate": 0,
        "maxExcessUsageRatio": "310000000000000000000000000",
        "optimalUsageRatio": "690000000000000000000000000",
        "stableRateSlope1": "690000000000000000000000000",
        "stableRateSlope2": "600000000000000000000000000",
        "variableRateSlope1": "420000000000000000000000000",
        "variableRateSlope2": "600000000000000000000000000"
      }
    }
  }
}
```