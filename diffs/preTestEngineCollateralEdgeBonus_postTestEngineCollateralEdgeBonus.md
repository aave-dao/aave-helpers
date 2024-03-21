## Reserve changes

### Reserves altered

#### AAVE.e ([0x63a72806098Bd3D9520cC43356dD78afe5D386D9](https://snowscan.xyz/address/0x63a72806098Bd3D9520cC43356dD78afe5D386D9))

| description | value before | value after |
| --- | --- | --- |
| ltv | 60 % | 62 % |
| liquidationThreshold | 71.3 % | 90 % |
| liquidationBonus | 7.5 % | 11 % |


## Raw diff

```json
{
  "reserves": {
    "0x63a72806098Bd3D9520cC43356dD78afe5D386D9": {
      "liquidationBonus": {
        "from": 10750,
        "to": 11100
      },
      "liquidationThreshold": {
        "from": 7130,
        "to": 9000
      },
      "ltv": {
        "from": 6000,
        "to": 6200
      }
    }
  }
}
```