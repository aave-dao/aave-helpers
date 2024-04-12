## Reserve changes

### Reserve altered

#### WETH ([0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619](https://polygonscan.com/address/0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0xf6733B9842883BFE0e0a940eA2F572676af31bde](https://polygonscan.com/address/0xf6733B9842883BFE0e0a940eA2F572676af31bde) | [0x27eFE5db315b71753b2a38ED3d5dd7E9362ba93F](https://polygonscan.com/address/0x27eFE5db315b71753b2a38ED3d5dd7E9362ba93F) |
| variableRateSlope1 | 3.3 % | 3.8 % |
| baseStableBorrowRate | 6.3 % | 6.8 % |
| interestRate | ![before](/.assets/bc821e780dbf0cd88aa89ae21f339014e1053ceb.svg) | ![after](/.assets/e7c3905f5d41473b5148fbd1df41bdc06ae104fb.svg) |

#### miMATIC ([0xa3Fa99A148fA48D14Ed51d610c367C61876997F1](https://polygonscan.com/address/0xa3Fa99A148fA48D14Ed51d610c367C61876997F1))

| description | value before | value after |
| --- | --- | --- |
| reserveFactor | 95 % | 20 % |
| interestRateStrategy | [0x44CaDF6E49895640D9De85ac01d97D44429Ad0A4](https://polygonscan.com/address/0x44CaDF6E49895640D9De85ac01d97D44429Ad0A4) | [0x8F183Ee74C790CB558232a141099b316D6C8Ba6E](https://polygonscan.com/address/0x8F183Ee74C790CB558232a141099b316D6C8Ba6E) |
| optimalUsageRatio | 45 % | 80 % |
| variableRateSlope2 | 300 % | 75 % |
| maxExcessUsageRatio | 55 % | 20 % |
| interestRate | ![before](/.assets/c0ca34be405c22dc36ffd20c54b1dc8cf5ac741b.svg) | ![after](/.assets/8f84201aa8a64dd4068a65bba6c43cc7622ae5b8.svg) |

#### USDT ([0xc2132D05D31c914a87C6611C10748AEb04B58e8F](https://polygonscan.com/address/0xc2132D05D31c914a87C6611C10748AEb04B58e8F))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0x2402C25e7E45b1466c53Ef7766AAd878A4CbC237](https://polygonscan.com/address/0x2402C25e7E45b1466c53Ef7766AAd878A4CbC237) | [0xC0B875907514131C2Fd43f0FBf59EdaB84C7e260](https://polygonscan.com/address/0xC0B875907514131C2Fd43f0FBf59EdaB84C7e260) |
| optimalUsageRatio | 90 % | 80 % |
| maxExcessUsageRatio | 10 % | 20 % |
| interestRate | ![before](/.assets/249bca66f2e25caf04da3e3bc7e387fbf24599b2.svg) | ![after](/.assets/973f0be01f7b244858ae3b53b46574f4a94ae9e0.svg) |

## Raw diff

```json
{
  "reserves": {
    "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619": {
      "interestRateStrategy": {
        "from": "0xf6733B9842883BFE0e0a940eA2F572676af31bde",
        "to": "0x27eFE5db315b71753b2a38ED3d5dd7E9362ba93F"
      }
    },
    "0xa3Fa99A148fA48D14Ed51d610c367C61876997F1": {
      "interestRateStrategy": {
        "from": "0x44CaDF6E49895640D9De85ac01d97D44429Ad0A4",
        "to": "0x8F183Ee74C790CB558232a141099b316D6C8Ba6E"
      },
      "reserveFactor": {
        "from": 9500,
        "to": 2000
      }
    },
    "0xc2132D05D31c914a87C6611C10748AEb04B58e8F": {
      "interestRateStrategy": {
        "from": "0x2402C25e7E45b1466c53Ef7766AAd878A4CbC237",
        "to": "0xC0B875907514131C2Fd43f0FBf59EdaB84C7e260"
      }
    }
  },
  "strategies": {
    "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619": {
      "address": {
        "from": "0xf6733B9842883BFE0e0a940eA2F572676af31bde",
        "to": "0x27eFE5db315b71753b2a38ED3d5dd7E9362ba93F"
      },
      "baseStableBorrowRate": {
        "from": "63000000000000000000000000",
        "to": "68000000000000000000000000"
      },
      "variableRateSlope1": {
        "from": "33000000000000000000000000",
        "to": "38000000000000000000000000"
      }
    },
    "0xa3Fa99A148fA48D14Ed51d610c367C61876997F1": {
      "address": {
        "from": "0x44CaDF6E49895640D9De85ac01d97D44429Ad0A4",
        "to": "0x8F183Ee74C790CB558232a141099b316D6C8Ba6E"
      },
      "maxExcessUsageRatio": {
        "from": "550000000000000000000000000",
        "to": "200000000000000000000000000"
      },
      "optimalUsageRatio": {
        "from": "450000000000000000000000000",
        "to": "800000000000000000000000000"
      },
      "variableRateSlope2": {
        "from": "3000000000000000000000000000",
        "to": "750000000000000000000000000"
      }
    },
    "0xc2132D05D31c914a87C6611C10748AEb04B58e8F": {
      "address": {
        "from": "0x2402C25e7E45b1466c53Ef7766AAd878A4CbC237",
        "to": "0xC0B875907514131C2Fd43f0FBf59EdaB84C7e260"
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