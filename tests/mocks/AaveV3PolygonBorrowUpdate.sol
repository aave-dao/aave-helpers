// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../src/v3-config-engine/AaveV3PayloadBase.sol';
import {AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';

/**
 * @dev Smart contract for a mock listing, to be able to test without having a v3 instance on Ethereum
 * IMPORTANT Parameters are pseudo-random, DON'T USE THIS ANYHOW IN PRODUCTION
 * @dev Inheriting directly from AaveV3PayloadBase for being able to inject a custom engine
 * @author BGD Labs
 */
contract AaveV3PolygonBorrowUpdate is AaveV3PayloadBase {
  constructor(IEngine customEngine) AaveV3PayloadBase(customEngine) {}

  function borrowsUpdates() public pure override returns (IEngine.BorrowUpdate[] memory) {
    IEngine.BorrowUpdate[] memory borrowsUpdate = new IEngine.BorrowUpdate[](1);

    borrowsUpdate[0] = IEngine.BorrowUpdate({
      asset: AaveV3PolygonAssets.AAVE_UNDERLYING,
      enabledToBorrow: EngineFlags.ENABLED,
      flashloanable: EngineFlags.DISABLED,
      stableRateModeEnabled: EngineFlags.KEEP_CURRENT,
      borrowableInIsolation: EngineFlags.KEEP_CURRENT,
      withSiloedBorrowing: EngineFlags.KEEP_CURRENT,
      reserveFactor: 15_00
    });

    return borrowsUpdate;
  }

  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Polygon', networkAbbreviation: 'Pol'});
  }
}
