---
'@aave-dao/aave-helpers-js': major
---

Decode raw storage slot changes for known contracts in snapshot diff reports. A new storage layout database (grown via `scripts/add-storage-layout.ts`, analogous to the eventDb) plus a pure render-time decoder turn raw slot hex into named variables: packed struct fields, `ReserveConfigurationMap` per-setting diffs, mapping entries (keys preimaged from snapshot and event data), enums, strings, and ERC-1967 slots. Undecodable slots keep rendering as raw hex; regenerated diff reports will change format once in the "Raw storage changes" section. V4 hubs and spokes resolve from their nested address-book groups (`HUBS.*`, `SPOKES.*`), and a PermissionedPayloadsController layout is included. Risk steward layouts ship for V3 (three deployed generations, pinned per deployment) and V4, and `decodeRawStorage` / `renderRawSection` / `parseSnapshotLogs` are exported for callers without a protocol snapshot (pass `{ chainId }`).
