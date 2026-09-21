---
'@aave-dao/aave-helpers-js': minor
---

Add the Base V4 bindings (`AaveV4PayloadBase`, `ProtocolV4TestBaseBase`) and update address book to 4.69.0. `_patchedDeal` now mints the Base B20 equities from their `MINT_ROLE` holder, since their balances live outside EVM storage and `deal` has no slot to patch, and `_safeSymbol` caps the gas it forwards so a token whose code the EVM cannot run does not starve the snapshot.
