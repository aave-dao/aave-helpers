## Reserve changes

### Reserve altered

#### WETH ([0x4200000000000000000000000000000000000006](https://optimistic.etherscan.io/address/0x4200000000000000000000000000000000000006))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0x5f58C25D17C09c9e1892F45DE6dA45ed973A5326](https://optimistic.etherscan.io/address/0x5f58C25D17C09c9e1892F45DE6dA45ed973A5326) | [0xc76EF342898f1AE7E6C4632627Df683FAD8563DD](https://optimistic.etherscan.io/address/0xc76EF342898f1AE7E6C4632627Df683FAD8563DD) |
| baseVariableBorrowRate | 0 % | 1 % |
| variableRateSlope1 | 3.3 % | 3.8 % |
| baseStableBorrowRate | 6.3 % | 6.8 % |
| interestRate | ![before](/.assets/44f8b63555df7a9d81101549741bd958deb27588.svg) | ![after](/.assets/2bed3d1cc40e3ecced7768caf9f6695c5217d96f.svg) |

#### USDT ([0x94b008aA00579c1307B0EF2c499aD98a8ce58e58](https://optimistic.etherscan.io/address/0x94b008aA00579c1307B0EF2c499aD98a8ce58e58))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0xd5CA18a70189309664e34FB8150799ff13722308](https://optimistic.etherscan.io/address/0xd5CA18a70189309664e34FB8150799ff13722308) | [0x424883C7dD9Bd129BC346A65E8455CDe9fC0c43C](https://optimistic.etherscan.io/address/0x424883C7dD9Bd129BC346A65E8455CDe9fC0c43C) |
| optimalUsageRatio | 90 % | 80 % |
| maxExcessUsageRatio | 10 % | 20 % |
| interestRate | ![before](/.assets/19d720ba733a698f9e5c8714853876f8759c351e.svg) | ![after](/.assets/4c96597d8e0f135353f37321358e767ebe5eb8a8.svg) |

## Raw diff

```json
{
  "reserves": {
    "0x4200000000000000000000000000000000000006": {
      "interestRateStrategy": {
        "from": "0x5f58C25D17C09c9e1892F45DE6dA45ed973A5326",
        "to": "0xc76EF342898f1AE7E6C4632627Df683FAD8563DD"
      }
    },
    "0x94b008aA00579c1307B0EF2c499aD98a8ce58e58": {
      "interestRateStrategy": {
        "from": "0xd5CA18a70189309664e34FB8150799ff13722308",
        "to": "0x424883C7dD9Bd129BC346A65E8455CDe9fC0c43C"
      }
    }
  },
  "strategies": {
    "0x4200000000000000000000000000000000000006": {
      "address": {
        "from": "0x5f58C25D17C09c9e1892F45DE6dA45ed973A5326",
        "to": "0xc76EF342898f1AE7E6C4632627Df683FAD8563DD"
      },
      "baseStableBorrowRate": {
        "from": "63000000000000000000000000",
        "to": "68000000000000000000000000"
      },
      "baseVariableBorrowRate": {
        "from": 0,
        "to": "10000000000000000000000000"
      },
      "variableRateSlope1": {
        "from": "33000000000000000000000000",
        "to": "38000000000000000000000000"
      }
    },
    "0x94b008aA00579c1307B0EF2c499aD98a8ce58e58": {
      "address": {
        "from": "0xd5CA18a70189309664e34FB8150799ff13722308",
        "to": "0x424883C7dD9Bd129BC346A65E8455CDe9fC0c43C"
      },
      "maxExcessUsageRatio": {
        "from": "100000000000000000000000000",
        "to": "200000000000000000000000000"
      },
      "optimalUsageRatio": {
        "from": "900000000000000000000000000",
        "to": "800000000000000000000000000"
      }
    }
  }
}
```