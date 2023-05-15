## Reserve changes

### Reserve altered

#### WETH ([0x82aF49447D8a07e3bd95BD0d56f35241523fBab1](https://https://arbiscan.io/address/0x82aF49447D8a07e3bd95BD0d56f35241523fBab1))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0x9b34E3e183c9b0d1a08fF57a8fb59c821616295f](https://https://arbiscan.io/address/0x9b34E3e183c9b0d1a08fF57a8fb59c821616295f) | [0x27eFE5db315b71753b2a38ED3d5dd7E9362ba93F](https://https://arbiscan.io/address/0x27eFE5db315b71753b2a38ED3d5dd7E9362ba93F) |
| reserveFactor | 10 % | 15 % |
| optimalUsageRatio | 45 % | 80 % |
| maxExcessUsageRatio | 55 % | 20 % |
| baseVariableBorrowRate | 0 % | 1 % |
| variableRateSlope1 | 7 % | 3.8 % |
| variableRateSlope2 | 300 % | 80 % |
| baseStableBorrowRate | 9 % | 6.8 % |
| stableRateSlope1 | 0 % | 4 % |
| stableRateSlope2 | 0 % | 80 % |
| interestRate | ![before](/.assets/19b2f23d55d76d891e7d30c29aa97741efed9d17.svg) | ![after](/.assets/25b7cbb97d2012b141455f46ee9b3f7e0e40a4b0.svg) |

#### EURS ([0xD22a58f79e9481D1a88e00c343885A588b34b68B](https://https://arbiscan.io/address/0xD22a58f79e9481D1a88e00c343885A588b34b68B))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4](https://https://arbiscan.io/address/0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4) | [0xA9F3C3caE095527061e6d270DBE163693e6fda9D](https://https://arbiscan.io/address/0xA9F3C3caE095527061e6d270DBE163693e6fda9D) |
| optimalUsageRatio | 90 % | 80 % |
| maxExcessUsageRatio | 10 % | 20 % |
| variableRateSlope2 | 60 % | 75 % |
| stableRateSlope2 | 60 % | 75 % |
| interestRate | ![before](/.assets/ea60696e57315a00b0941d7fe1bd186df779165e.svg) | ![after](/.assets/8d9de32bf30b1c9dcf71f07a13b228c69a71a4ce.svg) |

#### USDT ([0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9](https://https://arbiscan.io/address/0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4](https://https://arbiscan.io/address/0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4) | [0xA9F3C3caE095527061e6d270DBE163693e6fda9D](https://https://arbiscan.io/address/0xA9F3C3caE095527061e6d270DBE163693e6fda9D) |
| optimalUsageRatio | 90 % | 80 % |
| maxExcessUsageRatio | 10 % | 20 % |
| variableRateSlope2 | 60 % | 75 % |
| stableRateSlope2 | 60 % | 75 % |
| interestRate | ![before](/.assets/ea60696e57315a00b0941d7fe1bd186df779165e.svg) | ![after](/.assets/8d9de32bf30b1c9dcf71f07a13b228c69a71a4ce.svg) |

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