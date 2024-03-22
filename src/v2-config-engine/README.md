## Aave v2 config engine

<img width="819" alt="Screenshot 2023-03-10 at 1 28 03 PM" src="https://user-images.githubusercontent.com/22850280/224257171-98fc6350-e7d5-4537-ade4-9b61217978e2.png">

## What is the AaveV2ConfigEngine?

Similar to `AaveV3ConfigEngine` the `AaveV2ConfigEngine` is a helper smart contract to abstract good practices when doing "admin" interactions with the Aave v2 protocol, but built on top, without touching the core contracts.

At the same time, it defines a new interface oriented to simplify developer experience when coding proposal payloads: the `AaveV2ConfigEngine` is built from our experience supervising governance payloads review.

Currently the V2 engine supports interest rates strategy updates using the `V2RateStrategyFactory`

## How to use the engine?

The engine is not designed to be used directly when writing a payload, but through abstract contracts that we will call `Base Aave v2 Payloads`.

As base for any payload, you only need to inherit from the corresponding (per pool) `Base Aave v2 Payload`, for example inheriting from `AaveV2PayloadEthereum` in the case of Ethereum, `AaveV2PayloadPolygon` in the case of Polygon, and so on.

If you want to change interest rates strategy, you only need to define the rates strategy updates within a `updateRateStrategies()` function, and the base payload will take care of executing it correctly for you.

### Internal aspects to consider

The `Base Aave v2 Payload` defines `_preExecute()` and `_postExecute()` hook functions, that you can redefine on your payload and will the execute before and after all changes you define.

## Links to examples

- [Simple rates updates (changing some, keeping current values on others) on Aave v2 Ethereum](../test/mocks/AaveV2EthereumRatesUpdate.sol)
