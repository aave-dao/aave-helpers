// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Vm} from 'forge-std/Vm.sol';
import {Types} from 'src/dependencies/v4/Types.sol';

/// @title V4DiffWriter
/// @notice Internal library for V4 JSON serialization.
/// Markdown diff generation is handled by the TypeScript CLI (aave-helpers-js).
/// Using an internal library means functions are inlined via delegatecall context,
/// keeping cheatcodes working while avoiding stack-too-deep in the inheritance chain.
library V4DiffWriter {
  Vm private constant vm = Vm(address(uint160(uint256(keccak256('hevm cheat code')))));

  function writeSnapshotJson(string memory reportName, Types.V4Snapshot memory snapshot) internal {
    string memory path = string.concat('./reports/', reportName, '.json');
    vm.writeFile(
      path,
      '{ "spokeReserves": {}, "spokeLiquidationConfigs": {}, "hubAssets": {}, "spokeConfigs": {}, "positionManagers": {}, "accessManagerRoles": {} }'
    );
    vm.serializeUint('root', 'chainId', block.chainid);

    _writeSpokeReserves(path, snapshot.spokeReserves);
    _writeSpokeLiqConfigs(path, snapshot.spokeLiquidationConfigs);
    _writeHubAssets(path, snapshot.hubAssets);
    _writeSpokeConfigs(path, snapshot.spokeConfigs);
    _writePositionManagers(path, snapshot.positionManagers);
    _writeAccessManagerRoles(path, snapshot.accessManagerRoles);
  }

  function _writeSpokeReserves(
    string memory path,
    Types.SpokeReserveSnapshot[] memory reserves
  ) internal {
    string memory sectionKey = 'spokeReserves';
    vm.serializeJson(sectionKey, '{}');

    if (reserves.length == 0) {
      vm.writeJson(vm.serializeString('root', 'spokeReserves', '{}'), path);
      vm.writeJson('{}', path, '$.spokeReserves');
      return;
    }

    string memory content;
    for (uint256 i; i < reserves.length; i++) {
      string memory obj = _serReserve(reserves[i]);

      string memory spokeKey = string.concat('spoke_', vm.toString(reserves[i].spokeAddress));
      if (reserves[i].reserveId == 0) {
        vm.serializeJson(spokeKey, '{}');
      }
      string memory spokeObj = vm.serializeString(
        spokeKey,
        vm.toString(reserves[i].reserveId),
        obj
      );

      if (i + 1 == reserves.length || reserves[i + 1].spokeAddress != reserves[i].spokeAddress) {
        content = vm.serializeString(sectionKey, vm.toString(reserves[i].spokeAddress), spokeObj);
      }
    }
    vm.writeJson(vm.serializeString('root', 'spokeReserves', content), path);
  }

  function _serReserve(Types.SpokeReserveSnapshot memory r) internal returns (string memory) {
    string memory k = string.concat(vm.toString(r.spokeAddress), '_', vm.toString(r.reserveId));
    vm.serializeJson(k, '{}');
    vm.serializeString(k, 'symbol', r.symbol);
    vm.serializeAddress(k, 'underlying', r.underlying);
    vm.serializeAddress(k, 'hub', r.hub);
    vm.serializeUint(k, 'assetId', r.assetId);
    vm.serializeUint(k, 'decimals', r.decimals);
    vm.serializeUint(k, 'collateralRisk', r.collateralRisk);
    vm.serializeBool(k, 'paused', r.paused);
    vm.serializeBool(k, 'frozen', r.frozen);
    vm.serializeBool(k, 'borrowable', r.borrowable);
    vm.serializeBool(k, 'receiveSharesEnabled', r.receiveSharesEnabled);
    vm.serializeUint(k, 'dynamicConfigKey', r.dynamicConfigKey);
    vm.serializeUint(k, 'collateralFactor', r.collateralFactor);
    vm.serializeUint(k, 'maxLiquidationBonus', r.maxLiquidationBonus);
    vm.serializeUint(k, 'liquidationFee', r.liquidationFee);
    vm.serializeString(k, 'dynamicConfigs', _serDynamicConfigs(k, r.dynamicConfigs));
    vm.serializeAddress(k, 'oracleAddress', r.oracleAddress);
    vm.serializeAddress(k, 'priceSource', r.priceSource);
    return vm.serializeString(k, 'oraclePrice', vm.toString(r.oraclePrice));
  }

  function _serDynamicConfigs(
    string memory parentKey,
    Types.DynamicConfigSnapshot[] memory configs
  ) private returns (string memory) {
    string memory bucket = string.concat(parentKey, '__dynamicConfigs');
    string memory result = vm.serializeJson(bucket, '{}');
    for (uint256 i; i < configs.length; i++) {
      string memory entryKey = string.concat(bucket, '_', vm.toString(configs[i].key));
      vm.serializeJson(entryKey, '{}');
      vm.serializeUint(entryKey, 'collateralFactor', configs[i].collateralFactor);
      vm.serializeUint(entryKey, 'maxLiquidationBonus', configs[i].maxLiquidationBonus);
      string memory entry = vm.serializeUint(entryKey, 'liquidationFee', configs[i].liquidationFee);
      result = vm.serializeString(bucket, vm.toString(configs[i].key), entry);
    }
    return result;
  }

  function _writeSpokeLiqConfigs(
    string memory path,
    Types.SpokeLiquidationSnapshot[] memory configs
  ) internal {
    string memory sectionKey = 'spokeLiqConfigs';
    vm.serializeJson(sectionKey, '{}');

    if (configs.length == 0) {
      vm.writeJson(vm.serializeString('root', 'spokeLiquidationConfigs', '{}'), path);
      vm.writeJson('{}', path, '$.spokeLiquidationConfigs');
      return;
    }

    string memory content;
    for (uint256 i; i < configs.length; i++) {
      string memory k = string.concat('liq_', vm.toString(configs[i].spokeAddress));
      vm.serializeJson(k, '{}');
      vm.serializeString(k, 'targetHealthFactor', vm.toString(configs[i].targetHealthFactor));
      vm.serializeString(
        k,
        'healthFactorForMaxBonus',
        vm.toString(configs[i].healthFactorForMaxBonus)
      );
      vm.serializeUint(k, 'liquidationBonusFactor', configs[i].liquidationBonusFactor);
      string memory obj = vm.serializeUint(
        k,
        'maxUserReservesLimit',
        configs[i].maxUserReservesLimit
      );
      content = vm.serializeString(sectionKey, vm.toString(configs[i].spokeAddress), obj);
    }
    vm.writeJson(vm.serializeString('root', 'spokeLiquidationConfigs', content), path);
  }

  function _writeHubAssets(string memory path, Types.HubAssetSnapshot[] memory assets) internal {
    string memory sectionKey = 'hubAssets';
    vm.serializeJson(sectionKey, '{}');

    if (assets.length == 0) {
      vm.writeJson(vm.serializeString('root', 'hubAssets', '{}'), path);
      vm.writeJson('{}', path, '$.hubAssets');
      return;
    }

    string memory content;
    for (uint256 i; i < assets.length; i++) {
      string memory obj = _serializeHubAsset(assets[i]);

      string memory hubKey = string.concat('hub_', vm.toString(assets[i].hubAddress));
      if (i == 0 || assets[i].hubAddress != assets[i - 1].hubAddress) {
        vm.serializeJson(hubKey, '{}');
      }
      string memory hubObj = vm.serializeString(hubKey, vm.toString(assets[i].assetId), obj);

      if (i + 1 == assets.length || assets[i + 1].hubAddress != assets[i].hubAddress) {
        content = vm.serializeString(sectionKey, vm.toString(assets[i].hubAddress), hubObj);
      }
    }
    vm.writeJson(vm.serializeString('root', 'hubAssets', content), path);
  }

  function _serializeHubAsset(Types.HubAssetSnapshot memory a) internal returns (string memory) {
    string memory k = string.concat(vm.toString(a.hubAddress), '_', vm.toString(a.assetId));
    vm.serializeJson(k, '{}');
    vm.serializeString(k, 'symbol', a.symbol);
    vm.serializeAddress(k, 'underlying', a.underlying);
    vm.serializeUint(k, 'decimals', a.decimals);
    vm.serializeUint(k, 'liquidityFee', a.liquidityFee);
    vm.serializeAddress(k, 'irStrategy', a.irStrategy);
    vm.serializeAddress(k, 'feeReceiver', a.feeReceiver);
    vm.serializeAddress(k, 'reinvestmentController', a.reinvestmentController);
    vm.serializeUint(k, 'optimalUsageRatio', a.optimalUsageRatio);
    vm.serializeUint(k, 'baseDrawnRate', a.baseDrawnRate);
    vm.serializeUint(k, 'rateGrowthBeforeOptimal', a.rateGrowthBeforeOptimal);
    vm.serializeUint(k, 'rateGrowthAfterOptimal', a.rateGrowthAfterOptimal);
    vm.serializeString(k, 'maxDrawnRate', vm.toString(a.maxDrawnRate));
    // Asset state
    vm.serializeString(k, 'deficitRay', vm.toString(uint256(a.deficitRay)));
    vm.serializeString(k, 'swept', vm.toString(uint256(a.swept)));
    vm.serializeString(k, 'premiumShares', vm.toString(uint256(a.premiumShares)));
    return vm.serializeString(k, 'premiumOffsetRay', vm.toString(a.premiumOffsetRay));
  }

  function _writeSpokeConfigs(
    string memory path,
    Types.SpokeConfigSnapshot[] memory caps
  ) internal {
    string memory sectionKey = 'spokeConfigs';
    vm.serializeJson(sectionKey, '{}');

    if (caps.length == 0) {
      vm.writeJson(vm.serializeString('root', 'spokeConfigs', '{}'), path);
      vm.writeJson('{}', path, '$.spokeConfigs');
      return;
    }

    string memory content;
    for (uint256 i; i < caps.length; i++) {
      string memory k = string.concat(
        vm.toString(caps[i].hubAddress),
        '_',
        vm.toString(caps[i].assetId),
        '_',
        vm.toString(caps[i].spokeAddress)
      );
      vm.serializeJson(k, '{}');
      vm.serializeString(k, 'assetSymbol', caps[i].assetSymbol);
      vm.serializeUint(k, 'addCap', uint256(caps[i].addCap));
      vm.serializeUint(k, 'drawCap', uint256(caps[i].drawCap));
      vm.serializeUint(k, 'riskPremiumThreshold', caps[i].riskPremiumThreshold);
      vm.serializeBool(k, 'active', caps[i].active);
      string memory obj = vm.serializeBool(k, 'halted', caps[i].halted);
      content = vm.serializeString(sectionKey, k, obj);
    }
    vm.writeJson(vm.serializeString('root', 'spokeConfigs', content), path);
  }

  function _writePositionManagers(
    string memory path,
    Types.PositionManagerSnapshot[] memory managers
  ) internal {
    string memory sectionKey = 'positionManagers';
    vm.serializeJson(sectionKey, '{}');

    if (managers.length == 0) {
      vm.writeJson(vm.serializeString('root', 'positionManagers', '{}'), path);
      vm.writeJson('{}', path, '$.positionManagers');
      return;
    }

    // Group by spoke address: each spoke is a sub-object keyed by manager addr.
    string memory content;
    for (uint256 i; i < managers.length; i++) {
      string memory spokeKey = string.concat('pm_', vm.toString(managers[i].spokeAddress));
      // Initialize the per-spoke bucket on first occurrence.
      bool firstForSpoke = true;
      for (uint256 j; j < i; j++) {
        if (managers[j].spokeAddress == managers[i].spokeAddress) {
          firstForSpoke = false;
          break;
        }
      }
      if (firstForSpoke) {
        vm.serializeJson(spokeKey, '{}');
      }
      string memory spokeObj = vm.serializeBool(
        spokeKey,
        vm.toString(managers[i].positionManager),
        managers[i].active
      );

      // Write the section entry when this is the last manager for the spoke.
      bool lastForSpoke = true;
      for (uint256 j = i + 1; j < managers.length; j++) {
        if (managers[j].spokeAddress == managers[i].spokeAddress) {
          lastForSpoke = false;
          break;
        }
      }
      if (lastForSpoke) {
        content = vm.serializeString(sectionKey, vm.toString(managers[i].spokeAddress), spokeObj);
      }
    }
    vm.writeJson(vm.serializeString('root', 'positionManagers', content), path);
  }

  function _writeAccessManagerRoles(
    string memory path,
    Types.AccessManagerRoleSnapshot[] memory roles
  ) internal {
    string memory sectionKey = 'accessManagerRoles';
    vm.serializeJson(sectionKey, '{}');

    if (roles.length == 0) {
      vm.writeJson(vm.serializeString('root', 'accessManagerRoles', '{}'), path);
      vm.writeJson('{}', path, '$.accessManagerRoles');
      return;
    }

    string memory content;
    for (uint256 i; i < roles.length; i++) {
      string memory amKey = string.concat('am_', vm.toString(roles[i].accessManager));
      bool firstForAm = true;
      for (uint256 j; j < i; j++) {
        if (roles[j].accessManager == roles[i].accessManager) {
          firstForAm = false;
          break;
        }
      }
      if (firstForAm) {
        vm.serializeJson(amKey, '{}');
      }
      string memory roleObj = _serializeRole(roles[i]);
      string memory amObj = vm.serializeString(amKey, vm.toString(roles[i].roleId), roleObj);

      bool lastForAm = true;
      for (uint256 j = i + 1; j < roles.length; j++) {
        if (roles[j].accessManager == roles[i].accessManager) {
          lastForAm = false;
          break;
        }
      }
      if (lastForAm) {
        content = vm.serializeString(sectionKey, vm.toString(roles[i].accessManager), amObj);
      }
    }
    vm.writeJson(vm.serializeString('root', 'accessManagerRoles', content), path);
  }

  function _serializeRole(
    Types.AccessManagerRoleSnapshot memory r
  ) private returns (string memory) {
    string memory k = string.concat(
      'role_',
      vm.toString(r.accessManager),
      '_',
      vm.toString(r.roleId)
    );
    vm.serializeJson(k, '{}');
    vm.serializeString(k, 'label', r.label);
    vm.serializeAddress(k, 'members', r.members);

    // Flatten targetSelectors into parallel arrays for readability/diffability.
    address[] memory targets = new address[](r.targetSelectors.length);
    string[] memory selectors = new string[](r.targetSelectors.length);
    for (uint256 i; i < r.targetSelectors.length; i++) {
      targets[i] = r.targetSelectors[i].target;
      selectors[i] = vm.toString(r.targetSelectors[i].selector);
    }
    vm.serializeAddress(k, 'targets', targets);
    return vm.serializeString(k, 'selectors', selectors);
  }
}
