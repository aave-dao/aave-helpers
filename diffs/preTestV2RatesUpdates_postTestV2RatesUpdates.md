## Reserve changes

### Reserves altered

#### USDC ([0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48](https://etherscan.io/address/0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0xb72F23adE9b9980c2E731Ca504105fC860643619](https://etherscan.io/address/0xb72F23adE9b9980c2E731Ca504105fC860643619) | [0x7A297125a0Ea56cCC237Cb87b1Ab1F729353d4D2](https://etherscan.io/address/0x7A297125a0Ea56cCC237Cb87b1Ab1F729353d4D2) |
| optimalUsageRatio | 90 % | 69 % |
| maxExcessUsageRatio | 10 % | 31 % |
| variableRateSlope1 | 6 % | 42 % |
| stableRateSlope1 | 2 % | 69 % |
| interestRate | ![before](/.assets/faca7fdf8c83324f67a2ee404d914301ae9aae49.svg) | ![after](/.assets/ad67c5576b64e24c557a73a5bc9c67be904f53bb.svg) |

## Raw diff

```json
{
  "reserves": {
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48": {
      "interestRateStrategy": {
        "from": "0xb72F23adE9b9980c2E731Ca504105fC860643619",
        "to": "0x7A297125a0Ea56cCC237Cb87b1Ab1F729353d4D2"
      }
    }
  },
  "strategies": {
    "0x7A297125a0Ea56cCC237Cb87b1Ab1F729353d4D2": {
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