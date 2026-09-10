---
'@aave-dao/aave-helpers-js': patch
---

Add GSM events to eventDb (BuyAsset, SellAsset, Seized, BurnAfterSeize, BackingProvided, ExposureCapUpdated, FeeStrategyUpdated, FeesDistributedToTreasury, GhoReserveUpdated, GhoTreasuryUpdated, SwapFreeze, TokensRescued) so GSM transaction logs decode. Also adds the GhoReserve (EntityAdded, EntityRemoved, GhoLimitUpdated, GhoUsed, GhoRestored, GhoTransferred) and GsmRegistry (GsmAdded, GsmRemoved) events emitted alongside them.
