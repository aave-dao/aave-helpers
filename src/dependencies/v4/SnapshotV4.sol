// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {ISpoke, IHub, IAaveOracle} from 'aave-address-book/AaveV4.sol';
import {IAssetInterestRateStrategy} from 'aave-v4/hub/interfaces/IAssetInterestRateStrategy.sol';
import {IAccessManagerEnumerable} from 'aave-v4/access/interfaces/IAccessManagerEnumerable.sol';
import {IAccessManaged} from 'aave-v4/dependencies/openzeppelin/IAccessManaged.sol';
import {Types} from 'src/dependencies/v4/Types.sol';
import {V4DiffWriter} from 'src/dependencies/v4/V4DiffWriter.sol';
import {Helpers} from 'src/dependencies/v4/Helpers.sol';

/// @title SnapshotV4
/// @notice Snapshot capture for Aave V4. JSON serialization via V4DiffWriter, diff via TypeScript FFI.
abstract contract SnapshotV4 is Helpers {
  /// @notice Capture a full V4 configuration snapshot from the given spokes and hubs.
  /// @dev Leaves `positionManagers` and `accessManagerRoles` empty. Use the
  ///      4-arg overload to fill those sections.
  function createV4Snapshot(
    ISpoke[] memory spokes,
    IHub[] memory hubs
  ) internal view returns (Types.V4Snapshot memory snapshot) {
    address[] memory noManagers;
    address[] memory noAccessManagers;
    snapshot = createV4Snapshot(spokes, hubs, noManagers, noAccessManagers);
  }

  /// @notice Capture a full V4 configuration snapshot, including position-manager
  ///         activations per spoke and AccessManager role assignments.
  /// @param positionManagerCandidates Curated list of position-manager addresses
  ///        to check on each spoke. `updatePositionManager` flips their `active`
  ///        flag; without snapshotting, payloads that authorize a new manager
  ///        would produce no visible diff.
  /// @param accessManagers AccessManager contracts to enumerate (typically one
  ///        per hub, deduped). Role members and target-selector grants are
  ///        recorded so role-grant payloads show up in the diff.
  function createV4Snapshot(
    ISpoke[] memory spokes,
    IHub[] memory hubs,
    address[] memory positionManagerCandidates,
    address[] memory accessManagers
  ) internal view returns (Types.V4Snapshot memory snapshot) {
    snapshot.spokeReserves = _snapshotSpokeReserves(spokes);
    snapshot.spokeLiquidationConfigs = _snapshotSpokeLiqConfigs(spokes);
    snapshot.hubAssets = _snapshotHubAssets(hubs);
    snapshot.spokeConfigs = _snapshotSpokeConfigs(hubs);
    snapshot.positionManagers = _snapshotPositionManagers(spokes, positionManagerCandidates);
    snapshot.accessManagerRoles = _snapshotAccessManagerRoles(accessManagers);
  }

  /// @notice Write a V4 snapshot to JSON file.
  function writeV4SnapshotJson(string memory name, Types.V4Snapshot memory snap) internal {
    V4DiffWriter.writeSnapshotJson(name, snap);
  }

  /// @notice Generate markdown diff between two snapshots via TypeScript CLI (FFI).
  function diffV4Snapshots(string memory reportName) internal {
    string memory beforePath = string.concat('./reports/', reportName, '_before.json');
    string memory afterPath = string.concat('./reports/', reportName, '_after.json');
    string memory outPath = string.concat(
      './diffs/',
      reportName,
      '_before_',
      reportName,
      '_after.md'
    );

    string[] memory inputs = new string[](7);
    inputs[0] = 'npx';
    inputs[1] = '@aave-dao/aave-helpers-js@^1.2.1';
    inputs[2] = 'diff-v4-snapshots';
    inputs[3] = beforePath;
    inputs[4] = afterPath;
    inputs[5] = '-o';
    inputs[6] = outPath;
    vm.ffi(inputs);
  }

  // Spoke reserves
  function _snapshotSpokeReserves(
    ISpoke[] memory spokes
  ) private view returns (Types.SpokeReserveSnapshot[] memory) {
    uint256 total;
    for (uint256 s; s < spokes.length; s++) total += spokes[s].getReserveCount();

    Types.SpokeReserveSnapshot[] memory result = new Types.SpokeReserveSnapshot[](total);
    uint256 idx;
    for (uint256 s; s < spokes.length; s++) {
      uint256 count = spokes[s].getReserveCount();
      for (uint256 i; i < count; i++) {
        result[idx++] = _snapshotReserve(spokes[s], i);
      }
    }
    return result;
  }

  function _snapshotReserve(
    ISpoke spoke,
    uint256 reserveId
  ) private view returns (Types.SpokeReserveSnapshot memory snap) {
    ISpoke.Reserve memory reserve = spoke.getReserve(reserveId);
    ISpoke.ReserveConfig memory config = spoke.getReserveConfig(reserveId);
    ISpoke.DynamicReserveConfig memory dyn = spoke.getDynamicReserveConfig(
      reserveId,
      reserve.dynamicConfigKey
    );

    snap.spokeAddress = address(spoke);
    snap.reserveId = reserveId;
    snap.underlying = reserve.underlying;
    snap.symbol = _safeSymbol(reserve.underlying);
    snap.hub = address(reserve.hub);
    snap.assetId = reserve.assetId;
    snap.decimals = reserve.decimals;
    snap.collateralRisk = config.collateralRisk;
    snap.paused = config.paused;
    snap.frozen = config.frozen;
    snap.borrowable = config.borrowable;
    snap.receiveSharesEnabled = config.receiveSharesEnabled;
    snap.dynamicConfigKey = reserve.dynamicConfigKey;
    snap.collateralFactor = dyn.collateralFactor;
    snap.maxLiquidationBonus = dyn.maxLiquidationBonus;
    snap.liquidationFee = dyn.liquidationFee;
    snap.dynamicConfigs = _snapshotDynamicConfigs(spoke, reserveId, reserve.dynamicConfigKey);

    address oracleAddr = spoke.ORACLE();
    snap.oracleAddress = oracleAddr;
    snap.priceSource = IAaveOracle(oracleAddr).getReserveSource(reserveId);
    snap.oraclePrice = IAaveOracle(oracleAddr).getReservePrice(reserveId);
  }

  /// @dev Walks `[0, latestKey]` and records every non-empty DynamicReserveConfig.
  ///      `getDynamicReserveConfig` returns the zero struct for unset keys, so
  ///      we use a populated-field check to detect real entries.
  function _snapshotDynamicConfigs(
    ISpoke spoke,
    uint256 reserveId,
    uint32 latestKey
  ) private view returns (Types.DynamicConfigSnapshot[] memory) {
    Types.DynamicConfigSnapshot[] memory buf = new Types.DynamicConfigSnapshot[](
      uint256(latestKey) + 1
    );
    uint256 count;
    for (uint32 key; key <= latestKey; key++) {
      ISpoke.DynamicReserveConfig memory cfg = spoke.getDynamicReserveConfig(reserveId, key);
      if (cfg.collateralFactor == 0 && cfg.maxLiquidationBonus == 0 && cfg.liquidationFee == 0) {
        continue;
      }
      buf[count++] = Types.DynamicConfigSnapshot({
        key: key,
        collateralFactor: cfg.collateralFactor,
        maxLiquidationBonus: cfg.maxLiquidationBonus,
        liquidationFee: cfg.liquidationFee
      });
    }
    Types.DynamicConfigSnapshot[] memory result = new Types.DynamicConfigSnapshot[](count);
    for (uint256 i; i < count; i++) {
      result[i] = buf[i];
    }
    return result;
  }

  // Spoke liquidation configs

  function _snapshotSpokeLiqConfigs(
    ISpoke[] memory spokes
  ) private view returns (Types.SpokeLiquidationSnapshot[] memory) {
    Types.SpokeLiquidationSnapshot[] memory result = new Types.SpokeLiquidationSnapshot[](
      spokes.length
    );
    for (uint256 s; s < spokes.length; s++) {
      ISpoke.LiquidationConfig memory liq = spokes[s].getLiquidationConfig();
      result[s] = Types.SpokeLiquidationSnapshot({
        spokeAddress: address(spokes[s]),
        targetHealthFactor: liq.targetHealthFactor,
        healthFactorForMaxBonus: liq.healthFactorForMaxBonus,
        liquidationBonusFactor: liq.liquidationBonusFactor,
        maxUserReservesLimit: spokes[s].MAX_USER_RESERVES_LIMIT()
      });
    }
    return result;
  }

  // Hub assets

  function _snapshotHubAssets(
    IHub[] memory hubs
  ) private view returns (Types.HubAssetSnapshot[] memory) {
    uint256 total;
    for (uint256 h; h < hubs.length; h++) total += hubs[h].getAssetCount();

    Types.HubAssetSnapshot[] memory result = new Types.HubAssetSnapshot[](total);
    uint256 idx;
    for (uint256 h; h < hubs.length; h++) {
      uint256 count = hubs[h].getAssetCount();
      for (uint256 a; a < count; a++) {
        result[idx++] = _snapshotHubAsset(hubs[h], a);
      }
    }
    return result;
  }

  function _snapshotHubAsset(
    IHub hub,
    uint256 assetId
  ) private view returns (Types.HubAssetSnapshot memory snap) {
    IHub.AssetConfig memory config = hub.getAssetConfig(assetId);
    IHub.Asset memory asset = hub.getAsset(assetId);
    (address underlying, uint8 decimals) = hub.getAssetUnderlyingAndDecimals(assetId);

    snap.hubAddress = address(hub);
    snap.assetId = assetId;
    snap.underlying = underlying;
    snap.symbol = _safeSymbol(underlying);
    snap.decimals = decimals;
    snap.liquidityFee = config.liquidityFee;
    snap.irStrategy = config.irStrategy;
    snap.feeReceiver = config.feeReceiver;
    snap.reinvestmentController = config.reinvestmentController;

    if (config.irStrategy != address(0)) {
      IAssetInterestRateStrategy.InterestRateData memory irData = IAssetInterestRateStrategy(
        config.irStrategy
      ).getInterestRateData(assetId);
      snap.optimalUsageRatio = irData.optimalUsageRatio;
      snap.baseDrawnRate = irData.baseDrawnRate;
      snap.rateGrowthBeforeOptimal = irData.rateGrowthBeforeOptimal;
      snap.rateGrowthAfterOptimal = irData.rateGrowthAfterOptimal;
      snap.maxDrawnRate = IAssetInterestRateStrategy(config.irStrategy).getMaxDrawnRate(assetId);
    }

    // Asset state
    snap.deficitRay = asset.deficitRay;
    snap.swept = asset.swept;
    snap.premiumShares = asset.premiumShares;
    snap.premiumOffsetRay = asset.premiumOffsetRay;
  }

  // Hub spoke caps

  function _snapshotSpokeConfigs(
    IHub[] memory hubs
  ) private view returns (Types.SpokeConfigSnapshot[] memory) {
    uint256 total;
    for (uint256 h; h < hubs.length; h++) {
      uint256 ac = hubs[h].getAssetCount();
      for (uint256 a; a < ac; a++) total += hubs[h].getSpokeCount(a);
    }

    Types.SpokeConfigSnapshot[] memory result = new Types.SpokeConfigSnapshot[](total);
    uint256 idx;
    for (uint256 h; h < hubs.length; h++) {
      idx = _snapshotCapsForHub(hubs[h], result, idx);
    }
    return result;
  }

  function _snapshotCapsForHub(
    IHub hub,
    Types.SpokeConfigSnapshot[] memory result,
    uint256 idx
  ) private view returns (uint256) {
    uint256 ac = hub.getAssetCount();
    for (uint256 a; a < ac; a++) {
      (address underlying, ) = hub.getAssetUnderlyingAndDecimals(a);
      string memory sym = _safeSymbol(underlying);
      uint256 sc = hub.getSpokeCount(a);
      for (uint256 sp; sp < sc; sp++) {
        address spokeAddr = hub.getSpokeAddress(a, sp);
        IHub.SpokeConfig memory cfg = hub.getSpokeConfig(a, spokeAddr);
        result[idx++] = Types.SpokeConfigSnapshot({
          hubAddress: address(hub),
          assetId: a,
          assetSymbol: sym,
          spokeAddress: spokeAddr,
          addCap: cfg.addCap,
          drawCap: cfg.drawCap,
          riskPremiumThreshold: cfg.riskPremiumThreshold,
          active: cfg.active,
          halted: cfg.halted
        });
      }
    }
    return idx;
  }

  // Position managers

  function _snapshotPositionManagers(
    ISpoke[] memory spokes,
    address[] memory candidates
  ) private view returns (Types.PositionManagerSnapshot[] memory) {
    uint256 total = spokes.length * candidates.length;
    Types.PositionManagerSnapshot[] memory result = new Types.PositionManagerSnapshot[](total);
    uint256 idx;
    for (uint256 s; s < spokes.length; s++) {
      for (uint256 c; c < candidates.length; c++) {
        bool active;
        try spokes[s].isPositionManagerActive(candidates[c]) returns (bool a) {
          active = a;
        } catch {
          active = false;
        }
        result[idx++] = Types.PositionManagerSnapshot({
          spokeAddress: address(spokes[s]),
          positionManager: candidates[c],
          active: active
        });
      }
    }
    return result;
  }

  // AccessManager roles

  function _snapshotAccessManagerRoles(
    address[] memory accessManagers
  ) private view returns (Types.AccessManagerRoleSnapshot[] memory) {
    // Count total roles up front to size the output array.
    uint256 total;
    for (uint256 m; m < accessManagers.length; m++) {
      total += IAccessManagerEnumerable(accessManagers[m]).getRoleCount();
    }
    Types.AccessManagerRoleSnapshot[] memory result = new Types.AccessManagerRoleSnapshot[](total);
    uint256 idx;
    for (uint256 m; m < accessManagers.length; m++) {
      IAccessManagerEnumerable am = IAccessManagerEnumerable(accessManagers[m]);
      uint256 roleCount = am.getRoleCount();
      for (uint256 r; r < roleCount; r++) {
        uint64 roleId = am.getRole(r);
        result[idx++] = _snapshotAccessManagerRole(am, roleId);
      }
    }
    return result;
  }

  function _snapshotAccessManagerRole(
    IAccessManagerEnumerable am,
    uint64 roleId
  ) private view returns (Types.AccessManagerRoleSnapshot memory snap) {
    snap.accessManager = address(am);
    snap.roleId = roleId;
    // `getLabelOfRole` reverts if the role has no label; treat as empty.
    try am.getLabelOfRole(roleId) returns (string memory label) {
      snap.label = label;
    } catch {
      snap.label = '';
    }

    uint256 memberCount = am.getRoleMemberCount(roleId);
    snap.members = am.getRoleMembers(roleId, 0, memberCount);

    uint256 targetCount = am.getRoleTargetCount(roleId);
    address[] memory targets = am.getRoleTargets(roleId, 0, targetCount);

    uint256 totalSelectors;
    for (uint256 i; i < targets.length; i++) {
      totalSelectors += am.getRoleTargetSelectorCount(roleId, targets[i]);
    }
    snap.targetSelectors = new Types.AccessManagerTargetSelector[](totalSelectors);
    uint256 selIdx;
    for (uint256 i; i < targets.length; i++) {
      uint256 selCount = am.getRoleTargetSelectorCount(roleId, targets[i]);
      bytes4[] memory sels = am.getRoleTargetSelectors(roleId, targets[i], 0, selCount);
      for (uint256 j; j < sels.length; j++) {
        snap.targetSelectors[selIdx++] = Types.AccessManagerTargetSelector({
          target: targets[i],
          selector: sels[j]
        });
      }
    }
  }
}
