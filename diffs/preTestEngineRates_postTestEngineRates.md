## Reserve changes

### Reserves altered

#### USDT ([0x94b008aA00579c1307B0EF2c499aD98a8ce58e58](https://optimistic.etherscan.io/address/0x94b008aA00579c1307B0EF2c499aD98a8ce58e58))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4](https://optimistic.etherscan.io/address/0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4) | [0xA9F3C3caE095527061e6d270DBE163693e6fda9D](https://optimistic.etherscan.io/address/0xA9F3C3caE095527061e6d270DBE163693e6fda9D) |
| optimalUsageRatio | 90 % | 80 % |
| maxExcessUsageRatio | 10 % | 20 % |
| variableRateSlope2 | 60 % | 75 % |
| stableRateSlope2 | 60 % | 75 % |
| interestRate | ![before](/.assets/ea60696e57315a00b0941d7fe1bd186df779165e.svg) | ![after](/.assets/8d9de32bf30b1c9dcf71f07a13b228c69a71a4ce.svg) |

## Raw diff

```json
{
  "reserves": {
    "0x94b008aA00579c1307B0EF2c499aD98a8ce58e58": {
      "interestRateStrategy": {
        "from": "0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4",
        "to": "0xA9F3C3caE095527061e6d270DBE163693e6fda9D"
      }
    }
  }
}
```