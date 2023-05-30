// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {EngineFlags} from '../EngineFlags.sol';
import {AaveV3ConfigEngine as Engine} from '../AaveV3ConfigEngine.sol';
import {ConfiguratorInputTypes, DataTypes} from 'aave-address-book/AaveV3.sol';
import {ReserveConfiguration} from 'aave-v3-core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {IAaveV3ConfigEngine as IEngine, IV3RateStrategyFactory, IPoolConfigurator, IPool} from '../IAaveV3ConfigEngine.sol';

library BorrowEngine {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  function executeBorrowSide(
    IPoolConfigurator poolConfigurator,
    IPool pool,
    IEngine.BorrowUpdate[] memory updates
  ) external {
    require(updates.length != 0, 'AT_LEAST_ONE_UPDATE_REQUIRED');

    Engine.AssetsConfig memory configs = _repackBorrowUpdate(updates);

    configBorrowSide(poolConfigurator, pool, configs.ids, configs.borrows);
  }

  function configBorrowSide(
    IPoolConfigurator poolConfigurator,
    IPool pool,
    address[] memory ids,
    Engine.Borrow[] memory borrows
  ) public {
    for (uint256 i = 0; i < ids.length; i++) {
      if (borrows[i].enabledToBorrow != EngineFlags.KEEP_CURRENT) {
        poolConfigurator.setReserveBorrowing(
          ids[i],
          EngineFlags.toBool(borrows[i].enabledToBorrow)
        );
      } else {
        (, , bool borrowingEnabled, , ) = pool.getConfiguration(ids[i]).getFlags();
        borrows[i].enabledToBorrow = EngineFlags.fromBool(borrowingEnabled);
      }

      if (borrows[i].enabledToBorrow == EngineFlags.ENABLED) {
        if (borrows[i].stableRateModeEnabled != EngineFlags.KEEP_CURRENT) {
          poolConfigurator.setReserveStableRateBorrowing(
            ids[i],
            EngineFlags.toBool(borrows[i].stableRateModeEnabled)
          );
        }
      }

      if (borrows[i].borrowableInIsolation != EngineFlags.KEEP_CURRENT) {
        poolConfigurator.setBorrowableInIsolation(
          ids[i],
          EngineFlags.toBool(borrows[i].borrowableInIsolation)
        );
      }

      if (borrows[i].withSiloedBorrowing != EngineFlags.KEEP_CURRENT) {
        poolConfigurator.setSiloedBorrowing(
          ids[i],
          EngineFlags.toBool(borrows[i].withSiloedBorrowing)
        );
      }

      // The reserve factor should always be > 0
      require(
        (borrows[i].reserveFactor > 0 && borrows[i].reserveFactor <= 100_00) ||
          borrows[i].reserveFactor == EngineFlags.KEEP_CURRENT,
        'INVALID_RESERVE_FACTOR'
      );

      if (borrows[i].reserveFactor != EngineFlags.KEEP_CURRENT) {
        poolConfigurator.setReserveFactor(ids[i], borrows[i].reserveFactor);
      }

      if (borrows[i].flashloanable != EngineFlags.KEEP_CURRENT) {
        poolConfigurator.setReserveFlashLoaning(
          ids[i],
          EngineFlags.toBool(borrows[i].flashloanable)
        );
      }
    }
  }

  function _repackBorrowUpdate(
    IEngine.BorrowUpdate[] memory updates
  ) internal pure returns (Engine.AssetsConfig memory) {
    address[] memory ids = new address[](updates.length);
    Engine.Borrow[] memory borrows = new Engine.Borrow[](updates.length);

    for (uint256 i = 0; i < updates.length; i++) {
      ids[i] = updates[i].asset;
      borrows[i] = Engine.Borrow({
        enabledToBorrow: updates[i].enabledToBorrow,
        flashloanable: updates[i].flashloanable,
        stableRateModeEnabled: updates[i].stableRateModeEnabled,
        borrowableInIsolation: updates[i].borrowableInIsolation,
        withSiloedBorrowing: updates[i].withSiloedBorrowing,
        reserveFactor: updates[i].reserveFactor
      });
    }

    return
      Engine.AssetsConfig({
        ids: ids,
        caps: new Engine.Caps[](0),
        basics: new Engine.Basic[](0),
        borrows: borrows,
        collaterals: new Engine.Collateral[](0),
        rates: new IV3RateStrategyFactory.RateStrategyParams[](0),
        eModeCategories: new Engine.EModeCategories[](0)
      });
  }
}
