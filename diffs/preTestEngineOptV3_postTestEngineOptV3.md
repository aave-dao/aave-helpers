## Reserve changes

### Reserve altered

#### WETH ([0x4200000000000000000000000000000000000006](https://optimistic.etherscan.io/address/0x4200000000000000000000000000000000000006))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0x16F9bBeE415e519F184Fe1c09d653C6567e4eb2f](https://optimistic.etherscan.io/address/0x16F9bBeE415e519F184Fe1c09d653C6567e4eb2f) | [0xc76EF342898f1AE7E6C4632627Df683FAD8563DD](https://optimistic.etherscan.io/address/0xc76EF342898f1AE7E6C4632627Df683FAD8563DD) |
| optimalUsageRatio | 90 % | 80 % |
| maxExcessUsageRatio | 10 % | 20 % |
| baseVariableBorrowRate | 0 % | 1 % |
| variableRateSlope1 | 3 % | 3.8 % |
| baseStableBorrowRate | 6 % | 6.8 % |
| interestRate | ![before](/.assets/5a987481fcd21ac926a7663682a9aa4ac8703d67.svg) | ![after](/.assets/2bed3d1cc40e3ecced7768caf9f6695c5217d96f.svg) |

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
    "0x4200000000000000000000000000000000000006": {
      "interestRateStrategy": {
        "from": "0x16F9bBeE415e519F184Fe1c09d653C6567e4eb2f",
        "to": "0xc76EF342898f1AE7E6C4632627Df683FAD8563DD"
      }
    },
    "0x94b008aA00579c1307B0EF2c499aD98a8ce58e58": {
      "interestRateStrategy": {
        "from": "0xdd5ee22CC6CbbB41518871D95558B648a3551b54",
        "to": "0xcf3136a52e6a01C482EdA64d3F0242dc3DBAFa47"
      }
    }
  },
  "strategies": {
    "0x4200000000000000000000000000000000000006": {
      "address": {
        "from": "0x16F9bBeE415e519F184Fe1c09d653C6567e4eb2f",
        "to": "0xc76EF342898f1AE7E6C4632627Df683FAD8563DD"
      },
      "baseStableBorrowRate": {
        "from": "60000000000000000000000000",
        "to": "68000000000000000000000000"
      },
      "baseVariableBorrowRate": {
        "from": 0,
        "to": "10000000000000000000000000"
      },
      "maxExcessUsageRatio": {
        "from": "100000000000000000000000000",
        "to": "200000000000000000000000000"
      },
      "optimalUsageRatio": {
        "from": "900000000000000000000000000",
        "to": "800000000000000000000000000"
      },
      "variableRateSlope1": {
        "from": "30000000000000000000000000",
        "to": "38000000000000000000000000"
      }
    },
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