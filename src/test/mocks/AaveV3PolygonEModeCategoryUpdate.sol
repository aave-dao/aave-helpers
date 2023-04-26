// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../v3-config-engine/AaveV3PayloadBase.sol';
import {AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';

/**
 * @dev Smart contract for a mock update, to be able to test
 * IMPORTANT Parameters are pseudo-random, DON'T USE THIS ANYHOW IN PRODUCTION
 * @dev Inheriting directly from AaveV3PayloadBase for being able to inject a custom engine
 * @author BGD Labs
 */
contract AaveV3PolygonEModeCategoryUpdate is AaveV3PayloadBase {
  constructor(IEngine customEngine) AaveV3PayloadBase(customEngine) {}

  function eModeCategoryUpdates() public pure override returns (IEngine.EModeUpdate[] memory) {
    IEngine.EModeUpdate[] memory eModeUpdates = new IEngine.EModeUpdate[](1);

    eModeUpdates[0] = IEngine.EModeUpdate({
      eModeCategory: 1,
      ltv: 9740,
      liqThreshold: 9760,
      liqBonus: EngineFlags.KEEP_CURRENT,
      priceSource: EngineFlags.KEEP_CURRENT_ADDRESS,
      label: EngineFlags.KEEP_CURRENT_STRING
    });

    return eModeUpdates;
  }

  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Polygon', networkAbbreviation: 'Pol'});
  }
}
