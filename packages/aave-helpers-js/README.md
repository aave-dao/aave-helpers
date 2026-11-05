# @aave-dao/aave-helpers-js

Snapshot diffing, reporting, and governance utilities for Aave V3.

## Installation

```sh
pnpm add @aave-dao/aave-helpers-js
```

## CLI

```sh
# Diff two snapshot JSON files into a markdown report
aave-helpers-js diff-snapshots <before.json> <after.json> -o <output.md>

# Compute IPFS hash (optionally upload to Pinata + The Graph)
aave-helpers-js ipfs <file> [-u]

# Generate a Tenderly seatbelt report for a payload
aave-helpers-js seatbelt-report -c <chainId> --pc <payloadsController> [--pi <payloadId>] [--pa <payloadAddress>] [--pb <payloadBytecode>] [-o <output>]
```

## Library

```ts
import { diffSnapshots } from '@aave-dao/aave-helpers-js';

const md = await diffSnapshots(preSnapshot, postSnapshot);
```

### Exports

- `diffSnapshots(pre, post)` - diff two `AaveV3Snapshot` objects into a markdown report
- `diff(a, b)` / `isChange()` / `hasChanges()` - generic deep-diff utilities
- TypeScript types: `AaveV3Snapshot`, `AaveV3Reserve`, `AaveV3Strategy`, `AaveV3Emode`, etc.

## Event Database

`utils/eventDb.ts` is a collection of Solidity event ABIs used to decode transaction logs in reports. If a report shows raw topics/data instead of a decoded event name, the event ABI is likely missing from this file.

### Adding events from a verified contract

Use the `add-events` script to automatically fetch events from a block explorer and add any missing ones to the database:

```sh
# By chain ID and address
npx tsx scripts/add-events.ts <chainId> <address>

# Examples
npx tsx scripts/add-events.ts 1 0x5ac4182a1dd41aeef465e40b82fd326bf66ab82c
npx tsx scripts/add-events.ts 137 0xSomePolygonAddress
```

The script will:

- Fetch the contract ABI from the block explorer (Etherscan, etc.)
- If the contract is a proxy, also fetch the implementation ABI
- Compare against the existing event database and add only missing events
- Running it twice on the same contract is safe (idempotent)

Requires `ETHERSCAN_API_KEY` environment variable. Optionally set `EXPLORER_PROXY` to override the explorer API URL.

### Claude Code skill

If you're using Claude Code, you can ask it to add events by providing an explorer URL:

> add events from https://etherscan.io/address/0x5ac4182a1dd41aeef465e40b82fd326bf66ab82c

It will parse the URL, determine the chain ID, and run the script automatically.

## Storage Layout Database

`utils/storageLayoutDb.ts` is the storage-slot counterpart of the event database: `forge inspect ... storage` layouts for known contract kinds (Pool, aToken/vToken, PayloadsController, Hub/Spoke, …), used to decode the "Raw storage changes" section of reports into named variables instead of raw slot hex — e.g. `_payloads[414].state: 2 (Queued) → 3 (Executed)` or `_reserves[0x…(wstETH)].configuration.reserveFactor: 0 → 2000`.

Decoding happens at report-render time (`utils/decodeStorage.ts`) and is best-effort and pure (no RPC):

- contracts are matched to a layout kind via the snapshot's own data (fresh deployments included), pinned `chainId:address` entries, then address-book key patterns
- packed slots emit one row per changed field; `ReserveConfigurationMap` words are split into per-setting diffs
- mapping slots are resolved by preimaging candidate keys gathered from the snapshot, the raw diff, and decoded event args (keccak matching is exact, so false positives are cryptographically negligible)
- anything that cannot be decoded stays visible as raw hex

### Adding a storage layout

Use the `add-storage-layout` script to register a contract kind. Three sources are supported:

```sh
# from a local/vendored foundry project
npx tsx scripts/add-storage-layout.ts --kind PoolInstance \
  --root ../../lib/aave-address-book/lib/aave-v3-origin \
  --contract src/contracts/instances/PoolInstance.sol:PoolInstance

# from a github repo (shallow clone, incl. submodules)
npx tsx scripts/add-storage-layout.ts --kind PayloadsController \
  --repo aave-dao/aave-governance-v3 \
  --contract src/contracts/payloads/PayloadsController.sol:PayloadsController

# from a verified contract on etherscan (follows proxies, recompiles with the verified solc)
npx tsx scripts/add-storage-layout.ts --kind SomeContract --chainId 1 --address 0x...

# pin deployments to an existing kind (repeatable, also accepted by the modes above)
npx tsx scripts/add-storage-layout.ts --kind V3RiskSteward --pin 1:0x... --pin 8453:0x...
```

The layout is written to `utils/storage-layouts/<Kind>.ts` and registered in `storageLayoutDb`. Etherscan mode requires `ETHERSCAN_API_KEY`. Pass `FOUNDRY_PROFILE` explicitly, since the script runs `forge inspect` in the target project.

Resolution by address-book key (`REFERENCE_SEGMENT_TO_KIND` in `utils/resolveContractKind.ts`) only works when every deployment behind that key shares one layout. When the layout depends on the deployed version, pin each deployment with `--pin` instead. Risk stewards are the example: three V3 generations are live under the same `RISK_STEWARD` / `EDGE_RISK_STEWARD_*` keys.

| Kind                       | Source                                                         | Pinned deployments |
| -------------------------- | -------------------------------------------------------------- | ------------------ |
| `V3RiskSteward`            | aave-v3-risk-stewards `d45f2fe`                                | 17                 |
| `V3RiskStewardDebtCeiling` | `1:0x80CFd14236409107c220d1D0a3dE845b48fdcDfc` (etherscan)     | 11                 |
| `V3RiskStewardFlatConfig`  | `43114:0x57218F3aB422A39115951c3Eb06881a7A719DfdD` (etherscan) | 4                  |
| `V4RiskSteward`            | aave-v4-risk-stewards `c103f21`                                | 3                  |

Not pinned, because their source could not be verified: V3 `RISK_STEWARD` on Scroll, zkSync, Ink (no etherscan v2 support), Soneium and XLayer (verified source does not compile standalone), and V4 `RISK_STEWARD` on Arc. They render as raw hex.
