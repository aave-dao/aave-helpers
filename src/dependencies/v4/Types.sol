// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Types {
  /// @notice Accounting state: collateral + debt (drawn + premium), shares + assets.
  struct Accounting {
    // Supply / collateral side
    uint256 collateralShares;
    uint256 collateralAssets;
    // Debt side (drawn + premium)
    uint256 drawnDebt;
    uint256 premiumDebt;
    uint256 totalDebt;
    // Drawn/premium shares
    uint256 drawnShares;
    uint256 premiumShares;
    int256 premiumOffsetRay;
  }

  /// @notice Full position snapshot at spoke-user, spoke-reserve, and hub-spoke levels.
  struct PositionSnapshot {
    Accounting user;
    Accounting reserve;
    Accounting spokeOnHub;
  }

  /// @notice Tokenization spoke snapshot at user, vault, and hub-spoke levels.
  struct TokenizationSnapshot {
    uint256 userShares;
    uint256 userAssets;
    uint256 totalShares;
    uint256 totalAssets;
    Accounting spokeOnHub;
  }

  /// @notice Per-reserve info struct used throughout V4 e2e tests.
  struct ReserveInfo {
    uint256 reserveId;
    address underlying;
    address hub;
    uint16 assetId;
    string symbol;
    uint8 decimals;
    bool paused;
    bool frozen;
    bool borrowable;
    bool receiveSharesEnabled;
    bool collateralEnabled; // collateralFactor > 0
    uint16 collateralFactor; // BPS
    uint32 maxLiquidationBonus; // BPS
    uint16 liquidationFee; // BPS
  }

  /// @notice One DynamicReserveConfig entry, identified by its key. The same
  ///         reserve can have multiple historic keys still anchoring live user
  ///         positions, so snapshots record every non-empty key.
  struct DynamicConfigSnapshot {
    uint32 key;
    uint16 collateralFactor;
    uint32 maxLiquidationBonus;
    uint16 liquidationFee;
  }

  struct SpokeReserveSnapshot {
    address spokeAddress;
    uint256 reserveId;
    address underlying;
    string symbol;
    address hub;
    uint16 assetId;
    uint8 decimals;
    // ReserveConfig
    uint24 collateralRisk;
    bool paused;
    bool frozen;
    bool borrowable;
    bool receiveSharesEnabled;
    // DynamicReserveConfig: `dynamicConfigKey` is the latest key (also the
    // pointer used by `Reserve.dynamicConfigKey`); the `collateralFactor`,
    // `maxLiquidationBonus`, and `liquidationFee` fields mirror that latest
    // key. `dynamicConfigs` records every key in `[1, dynamicConfigKey]` so
    // governance updates to non-latest keys (which still drive existing user
    // positions) remain visible in diffs.
    uint32 dynamicConfigKey;
    uint16 collateralFactor;
    uint32 maxLiquidationBonus;
    uint16 liquidationFee;
    DynamicConfigSnapshot[] dynamicConfigs;
    // Oracle
    address oracleAddress;
    address priceSource;
    uint256 oraclePrice;
  }

  struct SpokeLiquidationSnapshot {
    address spokeAddress;
    uint128 targetHealthFactor;
    uint64 healthFactorForMaxBonus;
    uint16 liquidationBonusFactor;
    uint16 maxUserReservesLimit;
  }

  struct HubAssetSnapshot {
    address hubAddress;
    uint256 assetId;
    address underlying;
    string symbol;
    uint8 decimals;
    uint16 liquidityFee;
    address irStrategy;
    address feeReceiver;
    address reinvestmentController;
    // IR params
    uint16 optimalUsageRatio;
    uint32 baseDrawnRate;
    uint32 rateGrowthBeforeOptimal;
    uint32 rateGrowthAfterOptimal;
    uint256 maxDrawnRate;
    // Asset state (from getAsset)
    uint200 deficitRay;
    uint120 swept;
    uint120 premiumShares;
    int200 premiumOffsetRay;
  }

  struct SpokeConfigSnapshot {
    address hubAddress;
    uint256 assetId;
    string assetSymbol;
    address spokeAddress;
    uint40 addCap;
    uint40 drawCap;
    uint24 riskPremiumThreshold;
    bool active;
    bool halted;
  }

  /// @notice One position-manager registration on a spoke. `updatePositionManager`
  ///         flips `active`, so the snapshot must capture this status to surface
  ///         governance changes that authorize or revoke a delegate.
  struct PositionManagerSnapshot {
    address spokeAddress;
    address positionManager;
    bool active;
  }

  /// @notice One role grant on an AccessManager: members + per-target selectors.
  struct AccessManagerRoleSnapshot {
    address accessManager;
    uint64 roleId;
    string label;
    address[] members;
    AccessManagerTargetSelector[] targetSelectors;
  }

  struct AccessManagerTargetSelector {
    address target;
    bytes4 selector;
  }

  struct V4Snapshot {
    SpokeReserveSnapshot[] spokeReserves;
    SpokeLiquidationSnapshot[] spokeLiquidationConfigs;
    HubAssetSnapshot[] hubAssets;
    SpokeConfigSnapshot[] spokeConfigs;
    PositionManagerSnapshot[] positionManagers;
    AccessManagerRoleSnapshot[] accessManagerRoles;
  }
}
