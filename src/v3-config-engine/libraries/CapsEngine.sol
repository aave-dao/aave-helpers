// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {EngineFlags} from '../EngineFlags.sol';
import {AaveV3ConfigEngine as Engine} from '../AaveV3ConfigEngine.sol';
import {IAaveV3ConfigEngine as IEngine, IPoolConfigurator, IV3RateStrategyFactory} from '../IAaveV3ConfigEngine.sol';

library CapsEngine {
  function executeCapsUpdate(
    Engine.EngineConstants calldata engineConstants,
    IEngine.CapsUpdate[] memory updates
  ) external {
    require(updates.length != 0, 'AT_LEAST_ONE_UPDATE_REQUIRED');

    Engine.AssetsConfig memory configs = _repackCapsUpdate(updates);

    configureCaps(engineConstants.poolConfigurator, configs.ids, configs.caps);
  }

  function configureCaps(
    IPoolConfigurator poolConfigurator,
    address[] memory ids,
    Engine.Caps[] memory caps
  ) public {
    for (uint256 i = 0; i < ids.length; i++) {
      if (caps[i].supplyCap != EngineFlags.KEEP_CURRENT) {
        poolConfigurator.setSupplyCap(ids[i], caps[i].supplyCap);
      }

      if (caps[i].borrowCap != EngineFlags.KEEP_CURRENT) {
        poolConfigurator.setBorrowCap(ids[i], caps[i].borrowCap);
      }
    }
  }

  function _repackCapsUpdate(
    IEngine.CapsUpdate[] memory updates
  ) internal pure returns (Engine.AssetsConfig memory) {
    address[] memory ids = new address[](updates.length);
    Engine.Caps[] memory caps = new Engine.Caps[](updates.length);

    for (uint256 i = 0; i < updates.length; i++) {
      ids[i] = updates[i].asset;
      caps[i] = Engine.Caps({supplyCap: updates[i].supplyCap, borrowCap: updates[i].borrowCap});
    }

    return
      Engine.AssetsConfig({
        ids: ids,
        caps: caps,
        basics: new Engine.Basic[](0),
        borrows: new Engine.Borrow[](0),
        collaterals: new Engine.Collateral[](0),
        rates: new IV3RateStrategyFactory.RateStrategyParams[](0),
        eModeCategories: new Engine.EModeCategories[](0)
      });
  }
}
