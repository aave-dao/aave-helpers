## Reserve changes

### Reserve altered

#### WETH.e ([0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB](https://snowscan.xyz/address/0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB))

| description | value before | value after |
| --- | --- | --- |
| reserveFactor | 10 % | 15 % |
| interestRateStrategy | [0x79a906e8c998d2fb5C5D66d23c4c5416Fe0168D6](https://snowscan.xyz/address/0x79a906e8c998d2fb5C5D66d23c4c5416Fe0168D6) | [0xc76EF342898f1AE7E6C4632627Df683FAD8563DD](https://snowscan.xyz/address/0xc76EF342898f1AE7E6C4632627Df683FAD8563DD) |
| stableRateSlope1 | 0 % | 4 % |
| optimalUsageRatio | 45 % | 80 % |
| maxExcessUsageRatio | 55 % | 20 % |
| baseVariableBorrowRate | 0 % | 1 % |
| variableRateSlope1 | 7 % | 3.8 % |
| variableRateSlope2 | 300 % | 80 % |
| baseStableBorrowRate | 9 % | 6.8 % |
| stableRateSlope2 | 0 % | 80 % |
| interestRate | ![before](/.assets/be291dc02d59fb42923f19f29caa401129501a47.svg) | ![after](/.assets/2bed3d1cc40e3ecced7768caf9f6695c5217d96f.svg) |

#### MAI ([0x5c49b268c9841AFF1Cc3B0a418ff5c3442eE3F3b](https://snowscan.xyz/address/0x5c49b268c9841AFF1Cc3B0a418ff5c3442eE3F3b))

| description | value before | value after |
| --- | --- | --- |
| reserveFactor | 10 % | 20 % |
| interestRateStrategy | [0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82](https://snowscan.xyz/address/0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82) | [0xfab05a6aF585da2F96e21452F91E812452996BD3](https://snowscan.xyz/address/0xfab05a6aF585da2F96e21452F91E812452996BD3) |
| variableRateSlope2 | 60 % | 75 % |
| stableRateSlope2 | 60 % | 75 % |
| optimalUsageRatio | 90 % | 80 % |
| maxExcessUsageRatio | 10 % | 20 % |
| interestRate | ![before](/.assets/24aea288aafbdead424aa0c4d79f42141f457a50.svg) | ![after](/.assets/b075925b933e4a9a254e5b3a21a83a6eae64a797.svg) |

#### USDt ([0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7](https://snowscan.xyz/address/0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82](https://snowscan.xyz/address/0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82) | [0xfab05a6aF585da2F96e21452F91E812452996BD3](https://snowscan.xyz/address/0xfab05a6aF585da2F96e21452F91E812452996BD3) |
| variableRateSlope2 | 60 % | 75 % |
| stableRateSlope2 | 60 % | 75 % |
| optimalUsageRatio | 90 % | 80 % |
| maxExcessUsageRatio | 10 % | 20 % |
| interestRate | ![before](/.assets/24aea288aafbdead424aa0c4d79f42141f457a50.svg) | ![after](/.assets/b075925b933e4a9a254e5b3a21a83a6eae64a797.svg) |

#### FRAX ([0xD24C2Ad096400B6FBcd2ad8B24E7acBc21A1da64](https://snowscan.xyz/address/0xD24C2Ad096400B6FBcd2ad8B24E7acBc21A1da64))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82](https://snowscan.xyz/address/0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82) | [0xfab05a6aF585da2F96e21452F91E812452996BD3](https://snowscan.xyz/address/0xfab05a6aF585da2F96e21452F91E812452996BD3) |
| variableRateSlope2 | 60 % | 75 % |
| stableRateSlope2 | 60 % | 75 % |
| optimalUsageRatio | 90 % | 80 % |
| maxExcessUsageRatio | 10 % | 20 % |
| interestRate | ![before](/.assets/24aea288aafbdead424aa0c4d79f42141f457a50.svg) | ![after](/.assets/b075925b933e4a9a254e5b3a21a83a6eae64a797.svg) |

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
    "0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB": {
      "address": {
        "from": "0x79a906e8c998d2fb5C5D66d23c4c5416Fe0168D6",
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
    "0x5c49b268c9841AFF1Cc3B0a418ff5c3442eE3F3b": {
      "address": {
        "from": "0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82",
        "to": "0xfab05a6aF585da2F96e21452F91E812452996BD3"
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
    "0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7": {
      "address": {
        "from": "0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82",
        "to": "0xfab05a6aF585da2F96e21452F91E812452996BD3"
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
    "0xD24C2Ad096400B6FBcd2ad8B24E7acBc21A1da64": {
      "address": {
        "from": "0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82",
        "to": "0xfab05a6aF585da2F96e21452F91E812452996BD3"
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