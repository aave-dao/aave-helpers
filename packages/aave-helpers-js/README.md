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
