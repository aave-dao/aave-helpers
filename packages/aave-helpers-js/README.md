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

`utils/eventDb.json` is a static collection of Solidity event ABIs used to decode transaction logs in reports. If a report shows raw topics/data instead of a decoded event name, the event ABI is likely missing from this file.

To add a missing event, append its ABI entry to the JSON array:

```json
{
  "type": "event",
  "name": "MyEvent",
  "anonymous": false,
  "inputs": [{ "name": "param", "type": "uint256", "indexed": false, "internalType": "uint256" }]
}
```

You can extract event ABIs from contract artifacts (`out/` / `artifacts/`) or from block explorers.
