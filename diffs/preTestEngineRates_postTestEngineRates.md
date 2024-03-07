## Reserve changes

### Reserves altered

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
    "0x94b008aA00579c1307B0EF2c499aD98a8ce58e58": {
      "interestRateStrategy": {
        "from": "0xd5CA18a70189309664e34FB8150799ff13722308",
        "to": "0x424883C7dD9Bd129BC346A65E8455CDe9fC0c43C"
      }
    }
  },
  "strategies": {
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