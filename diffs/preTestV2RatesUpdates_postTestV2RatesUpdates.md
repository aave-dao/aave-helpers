## Reserve changes

### Reserves altered

#### USDC ([0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48](https://etherscan.io/address/0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0x8Cae0596bC1eD42dc3F04c4506cfe442b3E74e27](https://etherscan.io/address/0x8Cae0596bC1eD42dc3F04c4506cfe442b3E74e27) | [0xc76EF342898f1AE7E6C4632627Df683FAD8563DD](https://etherscan.io/address/0xc76EF342898f1AE7E6C4632627Df683FAD8563DD) |
| variableRateSlope1 | 4 % | 42 % |
| stableRateSlope1 | 2 % | 69 % |
| optimalUsageRatio | 90 % | 69 % |
| maxExcessUsageRatio | 10 % | 31 % |
| interestRate | ![before](/.assets/9defa590e93604d91464c4293d3f91bc9a17d069.svg) | ![after](/.assets/4e3bda25f9469c04492ac551019b4fd15d85bd8a.svg) |

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
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48": {
      "address": {
        "from": "0x8Cae0596bC1eD42dc3F04c4506cfe442b3E74e27",
        "to": "0xc76EF342898f1AE7E6C4632627Df683FAD8563DD"
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
        "from": "40000000000000000000000000",
        "to": "420000000000000000000000000"
      }
    }
  }
}
```