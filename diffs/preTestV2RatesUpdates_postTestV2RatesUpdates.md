## Reserve changes

### Reserves altered

#### USDC ([0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48](https://etherscan.io/address/0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0xF1722FBCAc1C49bA57a77c3F4373A4bb86a46e60](https://etherscan.io/address/0xF1722FBCAc1C49bA57a77c3F4373A4bb86a46e60) | [0x3c7eb05B1C910542EC236c541f183B07787cC3ff](https://etherscan.io/address/0x3c7eb05B1C910542EC236c541f183B07787cC3ff) |
| variableRateSlope1 | 6.5 % | 42 % |
| stableRateSlope1 | 2 % | 69 % |
| optimalUsageRatio | 90 % | 69 % |
| maxExcessUsageRatio | 10 % | 31 % |
| interestRate | ![before](/.assets/23e67c7d46dd80f36d580b243c5716c84080a34f.svg) | ![after](/.assets/64fd6acec636adec0e975e8031f8e3f7fb87bb7d.svg) |

## Raw diff

```json
{
  "reserves": {
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48": {
      "interestRateStrategy": {
        "from": "0xF1722FBCAc1C49bA57a77c3F4373A4bb86a46e60",
        "to": "0x3c7eb05B1C910542EC236c541f183B07787cC3ff"
      }
    }
  },
  "strategies": {
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48": {
      "address": {
        "from": "0xF1722FBCAc1C49bA57a77c3F4373A4bb86a46e60",
        "to": "0x3c7eb05B1C910542EC236c541f183B07787cC3ff"
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
        "from": "65000000000000000000000000",
        "to": "420000000000000000000000000"
      }
    }
  }
}
```