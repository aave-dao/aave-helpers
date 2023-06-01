## Reserve changes

### Reserves altered

#### AAVE ([0xD6DF932A45C0f255f85145f286eA0b292B21C90B](https://polygonscan.com/address/0xD6DF932A45C0f255f85145f286eA0b292B21C90B))

| description | value before | value after |
| --- | --- | --- |
| reserveFactor | 0 % | 15 % |
| borrowingEnabled | false | true |


## Raw diff

```json
{
  "reserves": {
    "0xD6DF932A45C0f255f85145f286eA0b292B21C90B": {
      "borrowingEnabled": {
        "from": false,
        "to": true
      },
      "reserveFactor": {
        "from": 0,
        "to": 1500
      }
    }
  }
}
```