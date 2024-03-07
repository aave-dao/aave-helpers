## Reserve changes

### Reserves altered

#### WETH ([0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619](https://polygonscan.com/address/0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0xf6733B9842883BFE0e0a940eA2F572676af31bde](https://polygonscan.com/address/0xf6733B9842883BFE0e0a940eA2F572676af31bde) | [0x27eFE5db315b71753b2a38ED3d5dd7E9362ba93F](https://polygonscan.com/address/0x27eFE5db315b71753b2a38ED3d5dd7E9362ba93F) |
| variableRateSlope1 | 3.3 % | 3.8 % |
| baseStableBorrowRate | 6.3 % | 6.8 % |
| interestRate | ![before](/.assets/bc821e780dbf0cd88aa89ae21f339014e1053ceb.svg) | ![after](/.assets/e7c3905f5d41473b5148fbd1df41bdc06ae104fb.svg) |

## Raw diff

```json
{
  "reserves": {
    "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619": {
      "interestRateStrategy": {
        "from": "0xf6733B9842883BFE0e0a940eA2F572676af31bde",
        "to": "0x27eFE5db315b71753b2a38ED3d5dd7E9362ba93F"
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
    }
  }
}
```