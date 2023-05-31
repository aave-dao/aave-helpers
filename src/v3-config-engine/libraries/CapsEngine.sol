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

    _configureCaps(engineConstants.poolConfigurator, updates);
  }

  function _configureCaps(
    IPoolConfigurator poolConfigurator,
    IEngine.CapsUpdate[] memory caps
  ) internal {
    for (uint256 i = 0; i < caps.length; i++) {
      if (caps[i].supplyCap != EngineFlags.KEEP_CURRENT) {
        poolConfigurator.setSupplyCap(caps[i].asset, caps[i].supplyCap);
      }

      if (caps[i].borrowCap != EngineFlags.KEEP_CURRENT) {
        poolConfigurator.setBorrowCap(caps[i].asset, caps[i].borrowCap);
      }
    }
  }
}
