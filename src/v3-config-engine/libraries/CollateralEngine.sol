// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {AaveV3ConfigEngine as Engine} from '../AaveV3ConfigEngine.sol';
import {ConfiguratorInputTypes, DataTypes} from 'aave-address-book/AaveV3.sol';
import {ReserveConfiguration} from 'aave-v3-core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {IAaveV3ConfigEngine as IEngine, IV3RateStrategyFactory, IPoolConfigurator, IPool} from '../IAaveV3ConfigEngine.sol';
import {SafeCast} from 'solidity-utils/contracts/oz-common/SafeCast.sol';
import {PercentageMath} from 'aave-v3-core/contracts/protocol/libraries/math/PercentageMath.sol';
import {EngineFlags} from '../EngineFlags.sol';

library CollateralEngine {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using PercentageMath for uint256;
  using SafeCast for uint256;

  function executeCollateralSide(IPoolConfigurator poolConfigurator, IPool pool, IEngine.CollateralUpdate[] memory updates) external {
    require(updates.length != 0, 'AT_LEAST_ONE_UPDATE_REQUIRED');

    Engine.AssetsConfig memory configs = _repackCollateralUpdate(updates);

    configCollateralSide(poolConfigurator, pool, configs.ids, configs.collaterals);
  }

  function configCollateralSide(IPoolConfigurator poolConfigurator, IPool pool, address[] memory ids, Engine.Collateral[] memory collaterals) public {
    for (uint256 i = 0; i < ids.length; i++) {
      if (collaterals[i].liqThreshold != 0) {
        bool notAllKeepCurrent = collaterals[i].ltv != EngineFlags.KEEP_CURRENT ||
          collaterals[i].liqThreshold != EngineFlags.KEEP_CURRENT ||
          collaterals[i].liqBonus != EngineFlags.KEEP_CURRENT;

        bool atLeastOneKeepCurrent = collaterals[i].ltv == EngineFlags.KEEP_CURRENT ||
          collaterals[i].liqThreshold == EngineFlags.KEEP_CURRENT ||
          collaterals[i].liqBonus == EngineFlags.KEEP_CURRENT;

        if (notAllKeepCurrent && atLeastOneKeepCurrent) {
          DataTypes.ReserveConfigurationMap memory configuration = pool.getConfiguration(ids[i]);
          (
            uint256 currentLtv,
            uint256 currentLiqThreshold,
            uint256 currentLiqBonus,
            ,
            ,

          ) = configuration.getParams();

          if (collaterals[i].ltv == EngineFlags.KEEP_CURRENT) {
            collaterals[i].ltv = currentLtv;
          }

          if (collaterals[i].liqThreshold == EngineFlags.KEEP_CURRENT) {
            collaterals[i].liqThreshold = currentLiqThreshold;
          }

          if (collaterals[i].liqBonus == EngineFlags.KEEP_CURRENT) {
            // Subtracting 100_00 to be consistent with the engine as 100_00 gets added while setting the liqBonus
            collaterals[i].liqBonus = currentLiqBonus - 100_00;
          }
        }

        if (notAllKeepCurrent) {
          // LT*LB (in %) should never be above 100%, because it means instant undercollateralization
          require(
            collaterals[i].liqThreshold.percentMul(100_00 + collaterals[i].liqBonus) <= 100_00,
            'INVALID_LT_LB_RATIO'
          );

          poolConfigurator.configureReserveAsCollateral(
            ids[i],
            collaterals[i].ltv,
            collaterals[i].liqThreshold,
            // For reference, this is to simplify the interaction with the Aave protocol,
            // as there the definition is as e.g. 105% (5% bonus for liquidators)
            100_00 + collaterals[i].liqBonus
          );
        }

        if (collaterals[i].liqProtocolFee != EngineFlags.KEEP_CURRENT) {
          require(collaterals[i].liqProtocolFee < 100_00, 'INVALID_LIQ_PROTOCOL_FEE');
          poolConfigurator.setLiquidationProtocolFee(ids[i], collaterals[i].liqProtocolFee);
        }

        if (collaterals[i].debtCeiling != EngineFlags.KEEP_CURRENT) {
          // For reference, this is to simplify the interactions with the Aave protocol,
          // as there the definition is with 2 decimals. We don't see any reason to set
          // a debt ceiling involving .something USD, so we simply don't allow to do it
          poolConfigurator.setDebtCeiling(ids[i], collaterals[i].debtCeiling * 100);
        }
      }

      if (collaterals[i].eModeCategory != EngineFlags.KEEP_CURRENT) {
        poolConfigurator.setAssetEModeCategory(ids[i], collaterals[i].eModeCategory.toUint8());
      }
    }
  }

  function _repackCollateralUpdate(
    IEngine.CollateralUpdate[] memory updates
  ) internal pure returns (Engine.AssetsConfig memory) {
    address[] memory ids = new address[](updates.length);
    Engine.Collateral[] memory collaterals = new Engine.Collateral[](updates.length);

    for (uint256 i = 0; i < updates.length; i++) {
      ids[i] = updates[i].asset;
      collaterals[i] = Engine.Collateral({
        ltv: updates[i].ltv,
        liqThreshold: updates[i].liqThreshold,
        liqBonus: updates[i].liqBonus,
        debtCeiling: updates[i].debtCeiling,
        liqProtocolFee: updates[i].liqProtocolFee,
        eModeCategory: updates[i].eModeCategory
      });
    }

    return
      Engine.AssetsConfig({
        ids: ids,
        caps: new Engine.Caps[](0),
        basics: new Engine.Basic[](0),
        borrows: new Engine.Borrow[](0),
        collaterals: collaterals,
        rates: new IV3RateStrategyFactory.RateStrategyParams[](0),
        eModeCategories: new Engine.EModeCategories[](0)
      });
  }
}