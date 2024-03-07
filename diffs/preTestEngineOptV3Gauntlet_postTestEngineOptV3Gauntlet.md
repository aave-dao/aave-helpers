## Reserve changes

### Reserve altered

#### WETH ([0x4200000000000000000000000000000000000006](https://optimistic.etherscan.io/address/0x4200000000000000000000000000000000000006))

| description | value before | value after |
| --- | --- | --- |
| reserveFactor | 10 % | 15 % |
| interestRateStrategy | [0xeE1BAc9355EaAfCD1B68d272d640d870bC9b4b5C](https://optimistic.etherscan.io/address/0xeE1BAc9355EaAfCD1B68d272d640d870bC9b4b5C) | [0xc76EF342898f1AE7E6C4632627Df683FAD8563DD](https://optimistic.etherscan.io/address/0xc76EF342898f1AE7E6C4632627Df683FAD8563DD) |
| stableRateSlope1 | 0 % | 4 % |
| optimalUsageRatio | 45 % | 80 % |
| maxExcessUsageRatio | 55 % | 20 % |
| baseVariableBorrowRate | 0 % | 1 % |
| variableRateSlope1 | 7 % | 3.8 % |
| variableRateSlope2 | 300 % | 80 % |
| baseStableBorrowRate | 9 % | 6.8 % |
| stableRateSlope2 | 0 % | 80 % |
| interestRate | ![before](/.assets/c18882ba19c7c6f494afeacba0f5ffcf2e2e4038.svg) | ![after](/.assets/2bed3d1cc40e3ecced7768caf9f6695c5217d96f.svg) |

#### USDT ([0x94b008aA00579c1307B0EF2c499aD98a8ce58e58](https://optimistic.etherscan.io/address/0x94b008aA00579c1307B0EF2c499aD98a8ce58e58))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4](https://optimistic.etherscan.io/address/0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4) | [0xA9F3C3caE095527061e6d270DBE163693e6fda9D](https://optimistic.etherscan.io/address/0xA9F3C3caE095527061e6d270DBE163693e6fda9D) |
| variableRateSlope2 | 60 % | 75 % |
| stableRateSlope2 | 60 % | 75 % |
| optimalUsageRatio | 90 % | 80 % |
| maxExcessUsageRatio | 10 % | 20 % |
| interestRate | ![before](/.assets/1baf85e415bd720bc42ec928d822cffbd4236d90.svg) | ![after](/.assets/8a10dd458958b063af4177af8f709f1971c58974.svg) |

## Raw diff

```json
{
  "reserves": {
    "0x4200000000000000000000000000000000000006": {
      "interestRateStrategy": {
        "from": "0xeE1BAc9355EaAfCD1B68d272d640d870bC9b4b5C",
        "to": "0xc76EF342898f1AE7E6C4632627Df683FAD8563DD"
      },
      "reserveFactor": {
        "from": 1000,
        "to": 1500
      }
    },
    "0x94b008aA00579c1307B0EF2c499aD98a8ce58e58": {
      "interestRateStrategy": {
        "from": "0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4",
        "to": "0xA9F3C3caE095527061e6d270DBE163693e6fda9D"
      }
    }
  },
  "strategies": {
    "0x4200000000000000000000000000000000000006": {
      "address": {
        "from": "0xeE1BAc9355EaAfCD1B68d272d640d870bC9b4b5C",
        "to": "0xc76EF342898f1AE7E6C4632627Df683FAD8563DD"
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
    "0x94b008aA00579c1307B0EF2c499aD98a8ce58e58": {
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