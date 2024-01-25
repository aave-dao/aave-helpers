# BGD <> AAVE helpers

This package contains various contracts which allow you to streamline testing within the aave protocol in foundry.

## Development

This project uses [Foundry](https://getfoundry.sh). See the [book](https://book.getfoundry.sh/getting-started/installation.html) for detailed instructions on how to install and use Foundry.

Some of the tooling relies on external calls via ffi to [aave-cli](https://github.com/bgd-labs/aave-cli).
Therefore you need to install aave-cli locally.

## Setup

```sh
cp .env.example .env
forge install
yarn
```

## Usage

### GovHelpers (deprecated)

These helpers allow you to create and execute proposals on L1 so you don't have to care about having enough proposition power, timings, etc.

### GovV3Helpers

These helpers allow the creation of proposal for aave governance v3.

The GovernanceV3Helpers also contain scripts to cast a vote directly via foundry.
To do so just run `make vote proposalId=n support=true/false`.

### ProxyHelpers

These helpers allow you to fetch the current implementation & admin for a specified proxy.

### BridgeExecutorHelpers

These helpers allow you to simulate execution of proposals on governance controlled Aave V2/V3 pools.

### ProtocolV3TestBase

The ProtocolV3TestBase is intended to be used with proposals that alter a V3 pool. While the `helpers` are libraries, you can use from where ever you want `ProtocolV3TestBase` is intended to be inherited from in your test via `is ProtocolV3TestBase`.

When inheriting from `ProtocolV3TestBase` you have access to methods to create readable configuration snapshots of a pool and e2e tests of a pool.

### ProtocolV2TestBase

Analog to ProtocolV3TestBase but for v2 pools.
