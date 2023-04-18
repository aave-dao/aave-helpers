## Reserve changes

### Reserve altered

#### WETH ([0x4200000000000000000000000000000000000006](https://optimistic.etherscan.io/address/0x4200000000000000000000000000000000000006))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | ![[0xeE1BAc9355EaAfCD1B68d272d640d870bC9b4b5C](https://optimistic.etherscan.io/address/0xeE1BAc9355EaAfCD1B68d272d640d870bC9b4b5C)](/.assets/10_0xeE1BAc9355EaAfCD1B68d272d640d870bC9b4b5C.svg) | ![[0xc76EF342898f1AE7E6C4632627Df683FAD8563DD](https://optimistic.etherscan.io/address/0xc76EF342898f1AE7E6C4632627Df683FAD8563DD)](/.assets/10_0xc76EF342898f1AE7E6C4632627Df683FAD8563DD.svg) |
| reserveFactor | 10 % | 15 % |


#### USDT ([0x94b008aA00579c1307B0EF2c499aD98a8ce58e58](https://optimistic.etherscan.io/address/0x94b008aA00579c1307B0EF2c499aD98a8ce58e58))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | ![[0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4](https://optimistic.etherscan.io/address/0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4)](/.assets/10_0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4.svg) | ![[0xA9F3C3caE095527061e6d270DBE163693e6fda9D](https://optimistic.etherscan.io/address/0xA9F3C3caE095527061e6d270DBE163693e6fda9D)](/.assets/10_0xA9F3C3caE095527061e6d270DBE163693e6fda9D.svg) |


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
    "0xc76EF342898f1AE7E6C4632627Df683FAD8563DD": {
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