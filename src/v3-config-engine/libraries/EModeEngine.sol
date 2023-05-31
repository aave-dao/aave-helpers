// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {EngineFlags} from '../EngineFlags.sol';
import {AaveV3ConfigEngine as Engine} from '../AaveV3ConfigEngine.sol';
import {DataTypes} from 'aave-address-book/AaveV3.sol';
import {SafeCast} from 'solidity-utils/contracts/oz-common/SafeCast.sol';
import {PercentageMath} from 'aave-v3-core/contracts/protocol/libraries/math/PercentageMath.sol';
import {IAaveV3ConfigEngine as IEngine, IPoolConfigurator, IV3RateStrategyFactory, IPool} from '../IAaveV3ConfigEngine.sol';

library EModeEngine {
  using PercentageMath for uint256;
  using SafeCast for uint256;

  function executeEModeAssetsUpdate(
    Engine.EngineConstants calldata engineConstants,
    IEngine.EModeAssetUpdate[] memory updates
  ) external {
    require(updates.length != 0, 'AT_LEAST_ONE_UPDATE_REQUIRED');

    _configEModeAssets(engineConstants.poolConfigurator, updates);
  }

  function executeEModeCategoriesUpdate(
    Engine.EngineConstants calldata engineConstants,
    IEngine.EModeCategoryUpdate[] memory updates
  ) external {
    require(updates.length != 0, 'AT_LEAST_ONE_UPDATE_REQUIRED');

    _configEModeCategories(engineConstants.poolConfigurator, engineConstants.pool, updates);
  }

  function _configEModeAssets(
    IPoolConfigurator poolConfigurator,
    IEngine.EModeAssetUpdate[] memory updates
  ) internal {
    for (uint256 i = 0; i < updates.length; i++) {
      if (updates[i].eModeCategory != EngineFlags.KEEP_CURRENT) {
        poolConfigurator.setAssetEModeCategory(updates[i].asset, updates[i].eModeCategory);
      }
    }
  }

  function _configEModeCategories(
    IPoolConfigurator poolConfigurator,
    IPool pool,
    IEngine.EModeCategoryUpdate[] memory updates
  ) internal {
    for (uint256 i = 0; i < updates.length; i++) {
      if (
        updates[i].ltv == EngineFlags.KEEP_CURRENT ||
        updates[i].liqThreshold == EngineFlags.KEEP_CURRENT ||
        updates[i].liqBonus == EngineFlags.KEEP_CURRENT ||
        updates[i].priceSource == EngineFlags.KEEP_CURRENT_ADDRESS ||
        keccak256(abi.encode(updates[i].label)) ==
        keccak256(abi.encode(EngineFlags.KEEP_CURRENT_STRING))
      ) {
        DataTypes.EModeCategory memory configuration = pool.getEModeCategoryData(
          updates[i].eModeCategory
        );
        uint256 currentLtv = configuration.ltv;
        uint256 currentLiqThreshold = configuration.liquidationThreshold;
        uint256 currentLiqBonus = configuration.liquidationBonus;
        address currentPriceSource = configuration.priceSource;
        string memory currentLabel = configuration.label;

        if (updates[i].ltv == EngineFlags.KEEP_CURRENT) {
          updates[i].ltv = currentLtv;
        }

        if (updates[i].liqThreshold == EngineFlags.KEEP_CURRENT) {
          updates[i].liqThreshold = currentLiqThreshold;
        }

        if (updates[i].liqBonus == EngineFlags.KEEP_CURRENT) {
          // Subtracting 100_00 to be consistent with the engine as 100_00 gets added while setting the liqBonus
          updates[i].liqBonus = currentLiqBonus - 100_00;
        }

        if (updates[i].priceSource == EngineFlags.KEEP_CURRENT_ADDRESS) {
          updates[i].priceSource = currentPriceSource;
        }

        if (
          keccak256(abi.encode(updates[i].label)) ==
          keccak256(abi.encode(EngineFlags.KEEP_CURRENT_STRING))
        ) {
          updates[i].label = currentLabel;
        }
      }

      // LT*LB (in %) should never be above 100%, because it means instant undercollateralization
      require(
        updates[i].liqThreshold.percentMul(100_00 + updates[i].liqBonus) <= 100_00,
        'INVALID_LT_LB_RATIO'
      );

      poolConfigurator.setEModeCategory(
        updates[i].eModeCategory,
        updates[i].ltv.toUint16(),
        updates[i].liqThreshold.toUint16(),
        // For reference, this is to simplify the interaction with the Aave protocol,
        // as there the definition is as e.g. 105% (5% bonus for liquidators)
        (100_00 + updates[i].liqBonus).toUint16(),
        updates[i].priceSource,
        updates[i].label
      );
    }
  }
}
