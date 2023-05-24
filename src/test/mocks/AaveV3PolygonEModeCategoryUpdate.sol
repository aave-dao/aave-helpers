// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../v3-config-engine/AaveV3PayloadBase.sol';

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
      ltv: 97_40,
      liqThreshold: 97_60,
      liqBonus: 1_50,
      priceSource: EngineFlags.KEEP_CURRENT_ADDRESS,
      label: EngineFlags.KEEP_CURRENT_STRING
    });

    return eModeUpdates;
  }

  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Polygon', networkAbbreviation: 'Pol'});
  }
}

/**
 * @dev Smart contract for a mock update, to be able to test
 * IMPORTANT Parameters are pseudo-random, DON'T USE THIS ANYHOW IN PRODUCTION
 * @dev Inheriting directly from AaveV3PayloadBase for being able to inject a custom engine
 * @author BGD Labs
 */
contract AaveV3AvalancheEModeCategoryUpdateEdgeBonus is AaveV3PayloadBase {
  constructor(IEngine customEngine) AaveV3PayloadBase(customEngine) {}

  function eModeCategoryUpdates() public pure override returns (IEngine.EModeUpdate[] memory) {
    IEngine.EModeUpdate[] memory eModeUpdates = new IEngine.EModeUpdate[](1);

    eModeUpdates[0] = IEngine.EModeUpdate({
      eModeCategory: 1,
      ltv: 97_40,
      liqThreshold: 97_60,
      liqBonus: 2_50,
      priceSource: EngineFlags.KEEP_CURRENT_ADDRESS,
      label: EngineFlags.KEEP_CURRENT_STRING
    });

    return eModeUpdates;
  }

  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Avalanche', networkAbbreviation: 'Ava'});
  }
}
