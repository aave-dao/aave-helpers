## Reserve changes

### Reserve altered

#### WETH.e ([0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB](https://snowtrace.io/address/0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | ![[0x79a906e8c998d2fb5C5D66d23c4c5416Fe0168D6](https://snowtrace.io/address/0x79a906e8c998d2fb5C5D66d23c4c5416Fe0168D6)](/.assets/43114_0x79a906e8c998d2fb5C5D66d23c4c5416Fe0168D6.svg) | ![[0xc76EF342898f1AE7E6C4632627Df683FAD8563DD](https://snowtrace.io/address/0xc76EF342898f1AE7E6C4632627Df683FAD8563DD)](/.assets/43114_0xc76EF342898f1AE7E6C4632627Df683FAD8563DD.svg) |
| reserveFactor | 10 % | 15 % |


#### MAI ([0x5c49b268c9841AFF1Cc3B0a418ff5c3442eE3F3b](https://snowtrace.io/address/0x5c49b268c9841AFF1Cc3B0a418ff5c3442eE3F3b))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | ![[0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82](https://snowtrace.io/address/0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82)](/.assets/43114_0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82.svg) | ![[0xfab05a6aF585da2F96e21452F91E812452996BD3](https://snowtrace.io/address/0xfab05a6aF585da2F96e21452F91E812452996BD3)](/.assets/43114_0xfab05a6aF585da2F96e21452F91E812452996BD3.svg) |
| reserveFactor | 10 % | 20 % |


#### USDt ([0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7](https://snowtrace.io/address/0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | ![[0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82](https://snowtrace.io/address/0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82)](/.assets/43114_0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82.svg) | ![[0xfab05a6aF585da2F96e21452F91E812452996BD3](https://snowtrace.io/address/0xfab05a6aF585da2F96e21452F91E812452996BD3)](/.assets/43114_0xfab05a6aF585da2F96e21452F91E812452996BD3.svg) |


#### FRAX ([0xD24C2Ad096400B6FBcd2ad8B24E7acBc21A1da64](https://snowtrace.io/address/0xD24C2Ad096400B6FBcd2ad8B24E7acBc21A1da64))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | ![[0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82](https://snowtrace.io/address/0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82)](/.assets/43114_0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82.svg) | ![[0xfab05a6aF585da2F96e21452F91E812452996BD3](https://snowtrace.io/address/0xfab05a6aF585da2F96e21452F91E812452996BD3)](/.assets/43114_0xfab05a6aF585da2F96e21452F91E812452996BD3.svg) |


## Raw diff

```json
{
  "reserves": {
    "0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB": {
      "interestRateStrategy": {
        "from": "0x79a906e8c998d2fb5C5D66d23c4c5416Fe0168D6",
        "to": "0xc76EF342898f1AE7E6C4632627Df683FAD8563DD"
      },
      "reserveFactor": {
        "from": 1000,
        "to": 1500
      }
    },
    "0x5c49b268c9841AFF1Cc3B0a418ff5c3442eE3F3b": {
      "interestRateStrategy": {
        "from": "0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82",
        "to": "0xfab05a6aF585da2F96e21452F91E812452996BD3"
      },
      "reserveFactor": {
        "from": 1000,
        "to": 2000
      }
    },
    "0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7": {
      "interestRateStrategy": {
        "from": "0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82",
        "to": "0xfab05a6aF585da2F96e21452F91E812452996BD3"
      }
    },
    "0xD24C2Ad096400B6FBcd2ad8B24E7acBc21A1da64": {
      "interestRateStrategy": {
        "from": "0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82",
        "to": "0xfab05a6aF585da2F96e21452F91E812452996BD3"
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