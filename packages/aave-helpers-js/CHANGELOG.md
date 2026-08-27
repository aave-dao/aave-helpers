# @aave-dao/aave-helpers-js

## 1.4.2

### Patch Changes

- afde5f6: Decode additional Pool events (reserve state, liquidation grace period, flashloan premium, token upgrades) in protocol diffs.

## 1.4.1

### Patch Changes

- 6c07642: Decode RiskSteward events in protocol diffs.

## 1.4.0

### Minor Changes

- cd50b32: Add `_getTokenizationSpoke`, the reverting counterpart of `_findTokenizationSpoke`, and make `ERC1967_ADMIN_SLOT` private
- f1c2c02: Add V4 payload presets (`V4EngineDefaults`, `V4RoleWiring`) and V4 test helpers (`_findTokenizationSpoke`, `_proxyAdminOwner`, `_assertRolesWired`, `_assertSpokeDeployment`); update address book to 4.62.1

### Patch Changes

- 59efe2a: update address book to 4.65.6
- 59efe2a: Derive V4 tokenization test signers from a random key instead of a fixed `makeAddrAndKey` label, so `*WithSig` flows keep working when the well-known address picks up EIP-7702 code on a live network

## 1.3.7

### Patch Changes

- 882f926: update address book to 4.61.1

## 1.3.6

### Patch Changes

- 5d673a0: update address book to 4.61.0

## 1.3.5

### Patch Changes

- 16aadc4: Add Umbrella RewardsController events

## 1.3.4

### Patch Changes

- d740703: update address book

## 1.3.3

### Patch Changes

- 5891290: add monad support

## 1.3.2

### Patch Changes

- c825023: Add the `UpdateInterestRateData` event from `IAssetInterestRateStrategy` to eventDb, which was missed when the Aave V4 events were added.

## 1.3.1

### Patch Changes

- 2c035ff: Add access manager roles and position managers sections to the Aave V4 snapshot diff, and expand spoke reserves coverage.

## 1.3.0

### Minor Changes

- 11e2207: update to 3.7 e2e tests

## 1.2.1

### Patch Changes

- b2eeeef: update aave-address-book

## 1.2.0

### Minor Changes

- ed1dd75: Add Aave V4 contract events to eventDb (Hub, Spoke, TokenizationSpoke, AccessManager, HubConfigurator, SpokeConfigurator, ConfigEngine, NativeTokenGateway, SignatureGateway, Giver/Taker/Config PositionManagers, LiquidationLogic, SpokeOracle) so downstream consumers like the governance seatbelt can decode V4 transaction logs.

## 1.1.0

### Minor Changes

- 5121107: Add Aave V4 snapshot diff support and CLI command

## 1.0.14

### Patch Changes

- 6c96817: add robot events

## 1.0.13

### Patch Changes

- 7638dc0: Revert partial decoding

## 1.0.12

### Patch Changes

- 8510b30: update toolbox

## 1.0.11

### Patch Changes

- 46cb536: Add new events from SwapSteward and Bridge

## 1.0.10

### Patch Changes

- 53dca12: Added missing umbrella events

## 1.0.9

### Patch Changes

- 39fe0f9: Add missing events

## 1.0.8

### Patch Changes

- 95f11be: Added claude code skill
- 6864719: Add IRangeValidationModule events (DefaultRangeConfigSet, MarketRangeConfigSet) to eventDb so that RANGE_VALIDATION_MODULE contract events are decoded in diff reports instead of showing raw topics. Also fixes a bug where formatValue crashed on decoded struct args containing BigInt values.

## 1.0.7

### Patch Changes

- 8b830cf: Add IAgentConfigurator/IAgentHub event signatures to eventDb so that AgentHub contract events are decoded in diff reports instead of showing raw topics.

## 1.0.4

### Patch Changes

- 207afc9: Replace address-book

## 1.0.3

### Patch Changes

- ee3f583: Migrating to the dao
