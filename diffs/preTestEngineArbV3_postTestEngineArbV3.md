## Reserve changes

### Reserves altered

#### WETH ([0x82aF49447D8a07e3bd95BD0d56f35241523fBab1](https://arbiscan.io/address/0x82aF49447D8a07e3bd95BD0d56f35241523fBab1))

| description | value before | value after |
| --- | --- | --- |
| interestRateStrategy | [0x9a158802cD924747EF336cA3F9DE3bdb60Cf43D3](https://arbiscan.io/address/0x9a158802cD924747EF336cA3F9DE3bdb60Cf43D3) | [0x27eFE5db315b71753b2a38ED3d5dd7E9362ba93F](https://arbiscan.io/address/0x27eFE5db315b71753b2a38ED3d5dd7E9362ba93F) |
| baseVariableBorrowRate | 0 % | 1 % |
| variableRateSlope1 | 3.3 % | 3.8 % |
| baseStableBorrowRate | 6.3 % | 6.8 % |
| interestRate | ![before](/.assets/3d8eed0f38805dea3da835c8c9505d09e57e6996.svg) | ![after](/.assets/e7c3905f5d41473b5148fbd1df41bdc06ae104fb.svg) |

## Raw diff

```json
{
  "reserves": {
    "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1": {
      "interestRateStrategy": {
        "from": "0x9a158802cD924747EF336cA3F9DE3bdb60Cf43D3",
        "to": "0x27eFE5db315b71753b2a38ED3d5dd7E9362ba93F"
      }
    }
  },
  "strategies": {
    "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1": {
      "address": {
        "from": "0x9a158802cD924747EF336cA3F9DE3bdb60Cf43D3",
        "to": "0x27eFE5db315b71753b2a38ED3d5dd7E9362ba93F"
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
    }
  }
}
```