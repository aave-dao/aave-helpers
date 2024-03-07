## Reserve changes

### Reserve altered

#### WETH ([0x82aF49447D8a07e3bd95BD0d56f35241523fBab1](https://arbiscan.io/address/0x82aF49447D8a07e3bd95BD0d56f35241523fBab1))

| description | value before | value after |
| --- | --- | --- |
| reserveFactor | 10 % | 15 % |
| interestRateStrategy | [0x9b34E3e183c9b0d1a08fF57a8fb59c821616295f](https://arbiscan.io/address/0x9b34E3e183c9b0d1a08fF57a8fb59c821616295f) | [0x27eFE5db315b71753b2a38ED3d5dd7E9362ba93F](https://arbiscan.io/address/0x27eFE5db315b71753b2a38ED3d5dd7E9362ba93F) |
| stableRateSlope1 | 0 % | 4 % |
| optimalUsageRatio | 45 % | 80 % |
| maxExcessUsageRatio | 55 % | 20 % |
| baseVariableBorrowRate | 0 % | 1 % |
| variableRateSlope1 | 7 % | 3.8 % |
| variableRateSlope2 | 300 % | 80 % |
| baseStableBorrowRate | 9 % | 6.8 % |
| stableRateSlope2 | 0 % | 80 % |
| interestRate | ![before](/.assets/39aa2c4d3794f6ca689c8304d2485ab3617193e8.svg) | ![after](/.assets/e7c3905f5d41473b5148fbd1df41bdc06ae104fb.svg) |

#### EURS ([0xD22a58f79e9481D1a88e00c343885A588b34b68B](https://arbiscan.io/address/0xD22a58f79e9481D1a88e00c343885A588b34b68B))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4](https://arbiscan.io/address/0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4) | [0xA9F3C3caE095527061e6d270DBE163693e6fda9D](https://arbiscan.io/address/0xA9F3C3caE095527061e6d270DBE163693e6fda9D) |
| variableRateSlope2 | 60 % | 75 % |
| stableRateSlope2 | 60 % | 75 % |
| optimalUsageRatio | 90 % | 80 % |
| maxExcessUsageRatio | 10 % | 20 % |
| interestRate | ![before](/.assets/1baf85e415bd720bc42ec928d822cffbd4236d90.svg) | ![after](/.assets/8a10dd458958b063af4177af8f709f1971c58974.svg) |

#### USDT ([0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9](https://arbiscan.io/address/0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4](https://arbiscan.io/address/0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4) | [0xA9F3C3caE095527061e6d270DBE163693e6fda9D](https://arbiscan.io/address/0xA9F3C3caE095527061e6d270DBE163693e6fda9D) |
| variableRateSlope2 | 60 % | 75 % |
| stableRateSlope2 | 60 % | 75 % |
| optimalUsageRatio | 90 % | 80 % |
| maxExcessUsageRatio | 10 % | 20 % |
| interestRate | ![before](/.assets/1baf85e415bd720bc42ec928d822cffbd4236d90.svg) | ![after](/.assets/8a10dd458958b063af4177af8f709f1971c58974.svg) |

## Raw diff

```json
{
  "reserves": {
    "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1": {
      "interestRateStrategy": {
        "from": "0x9b34E3e183c9b0d1a08fF57a8fb59c821616295f",
        "to": "0x27eFE5db315b71753b2a38ED3d5dd7E9362ba93F"
      },
      "reserveFactor": {
        "from": 1000,
        "to": 1500
      }
    },
    "0xD22a58f79e9481D1a88e00c343885A588b34b68B": {
      "interestRateStrategy": {
        "from": "0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4",
        "to": "0xA9F3C3caE095527061e6d270DBE163693e6fda9D"
      }
    },
    "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9": {
      "interestRateStrategy": {
        "from": "0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4",
        "to": "0xA9F3C3caE095527061e6d270DBE163693e6fda9D"
      }
    }
  },
  "strategies": {
    "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1": {
      "address": {
        "from": "0x9b34E3e183c9b0d1a08fF57a8fb59c821616295f",
        "to": "0x27eFE5db315b71753b2a38ED3d5dd7E9362ba93F"
      },
      "baseStableBorrowRate": {
        "from": "90000000000000000000000000",
        "to": "68000000000000000000000000"
      },
      "baseVariableBorrowRate": {
        "from": 0,
        "to": "10000000000000000000000000"
      },
      "maxExcessUsageRatio": {
        "from": "550000000000000000000000000",
        "to": "200000000000000000000000000"
      },
      "optimalUsageRatio": {
        "from": "450000000000000000000000000",
        "to": "800000000000000000000000000"
      },
      "stableRateSlope1": {
        "from": 0,
        "to": "40000000000000000000000000"
      },
      "stableRateSlope2": {
        "from": 0,
        "to": "800000000000000000000000000"
      },
      "variableRateSlope1": {
        "from": "70000000000000000000000000",
        "to": "38000000000000000000000000"
      },
      "variableRateSlope2": {
        "from": "3000000000000000000000000000",
        "to": "800000000000000000000000000"
      }
    },
    "0xD22a58f79e9481D1a88e00c343885A588b34b68B": {
      "address": {
        "from": "0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4",
        "to": "0xA9F3C3caE095527061e6d270DBE163693e6fda9D"
      },
      "maxExcessUsageRatio": {
        "from": "100000000000000000000000000",
        "to": "200000000000000000000000000"
      },
      "optimalUsageRatio": {
        "from": "900000000000000000000000000",
        "to": "800000000000000000000000000"
      },
      "stableRateSlope2": {
        "from": "600000000000000000000000000",
        "to": "750000000000000000000000000"
      },
      "variableRateSlope2": {
        "from": "600000000000000000000000000",
        "to": "750000000000000000000000000"
      }
    },
    "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9": {
      "address": {
        "from": "0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4",
        "to": "0xA9F3C3caE095527061e6d270DBE163693e6fda9D"
      },
      "maxExcessUsageRatio": {
        "from": "100000000000000000000000000",
        "to": "200000000000000000000000000"
      },
      "optimalUsageRatio": {
        "from": "900000000000000000000000000",
        "to": "800000000000000000000000000"
      },
      "stableRateSlope2": {
        "from": "600000000000000000000000000",
        "to": "750000000000000000000000000"
      },
      "variableRateSlope2": {
        "from": "600000000000000000000000000",
        "to": "750000000000000000000000000"
      }
    }
  }
}
```