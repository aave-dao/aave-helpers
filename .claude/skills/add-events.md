# Add Events from Explorer

Adds missing ABI events from a verified contract to the event database.

## Trigger

When the user wants to add events from a block explorer URL (e.g. etherscan, polygonscan, etc.) or provides a chain ID + contract address for event decoding.

## Instructions

1. Parse the input to extract the **chain ID** and **contract address**:

   - If given an explorer URL like `https://etherscan.io/address/0x...`, extract the address and infer chain ID from the domain:
     - `etherscan.io` → chain 1
     - `polygonscan.com` → chain 137
     - `arbiscan.io` → chain 42161
     - `optimistic.etherscan.io` → chain 10
     - `basescan.org` → chain 8453
     - `snowscan.xyz` or `snowtrace.io` → chain 43114
     - `bscscan.com` → chain 56
     - `gnosisscan.io` → chain 100
     - `scrollscan.com` → chain 534352
     - `era.zksync.network` → chain 324
     - `lineascan.build` → chain 59144
     - For other explorers, ask the user for the chain ID
   - If given a chain ID and address directly, use those
   - Strip any URL fragments (e.g. `#code`) and query parameters

2. Run the script:

   ```bash
   cd /Volumes/sensitive/BGD/aave-helpers/packages/aave-helpers-js && npx tsx scripts/add-events.ts <chainId> <address>
   ```

3. Report the results to the user (how many events were added, which ones).
