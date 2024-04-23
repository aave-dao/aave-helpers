## Reserve changes

### Reserves altered

#### USDT ([0x94b008aA00579c1307B0EF2c499aD98a8ce58e58](https://optimistic.etherscan.io/address/0x94b008aA00579c1307B0EF2c499aD98a8ce58e58))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0xdd5ee22CC6CbbB41518871D95558B648a3551b54](https://optimistic.etherscan.io/address/0xdd5ee22CC6CbbB41518871D95558B648a3551b54) | [0xcf3136a52e6a01C482EdA64d3F0242dc3DBAFa47](https://optimistic.etherscan.io/address/0xcf3136a52e6a01C482EdA64d3F0242dc3DBAFa47) |
| optimalUsageRatio | 90 % | 80 % |
| maxExcessUsageRatio | 10 % | 20 % |
| interestRate | ![before](/.assets/5f00854535bfbb5f41643954ec476f3f67788d90.svg) | ![after](/.assets/5e292b27a90b078d7d1b7766456c23c19546e2a4.svg) |

## Raw diff

```json
{
  "reserves": {
    "0x94b008aA00579c1307B0EF2c499aD98a8ce58e58": {
      "interestRateStrategy": {
        "from": "0xdd5ee22CC6CbbB41518871D95558B648a3551b54",
        "to": "0xcf3136a52e6a01C482EdA64d3F0242dc3DBAFa47"
      }
    }
  },
  "strategies": {
    "0x94b008aA00579c1307B0EF2c499aD98a8ce58e58": {
      "address": {
        "from": "0xdd5ee22CC6CbbB41518871D95558B648a3551b54",
        "to": "0xcf3136a52e6a01C482EdA64d3F0242dc3DBAFa47"
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