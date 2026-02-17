# aave-helpers

Solidity and TypeScript toolkit for building, testing, and reviewing Aave governance proposals.

## Solidity

Install with Foundry:

```sh
forge install bgd-labs/aave-helpers
```

### Config Engines

Type-safe payload base contracts for Aave V2 and V3 configuration changes. Inherit from the chain-specific payload (e.g. `AaveV3PayloadEthereum`, `AaveV2PayloadPolygon`) and override the relevant listing/update methods.

### Test Bases

`ProtocolV3TestBase` and `ProtocolV2TestBase` provide snapshot diffing and e2e testing for proposals. Inherit in your test, execute the proposal, and call the snapshot/e2e helpers.

### GovV3Helpers

Utilities for creating and executing Aave Governance V3 proposals in Foundry tests and scripts. Also includes voting scripts (`make vote proposalId=n support=true/false`).

### Other Utilities

- **CollectorUtils** - helpers for interacting with the Aave Collector
- **Bridges** - cross-chain ERC20 bridge implementations (Arbitrum, Optimism, Polygon, CCIP)
- **Swaps** - Milkman-based swap payloads for treasury management

## TypeScript (`@bgd-labs/aave-helpers-js`)

The `packages/aave-helpers-js` package provides snapshot diffing and markdown report generation for Aave V3 pool configurations.

```sh
pnpm add @bgd-labs/aave-helpers-js
```

### CLI

```sh
# Diff two snapshot JSON files
aave-helpers-js --chainId 1 --pre before.json --post after.json
```

### Library

```ts
import { diffSnapshots } from '@bgd-labs/aave-helpers-js';

const report = diffSnapshots(preSnapshot, postSnapshot);
```

## Development

```sh
cp .env.example .env
forge install
pnpm install
```

- Solidity tests: `forge test`
- TypeScript tests: `cd packages/aave-helpers-js && pnpm test`
