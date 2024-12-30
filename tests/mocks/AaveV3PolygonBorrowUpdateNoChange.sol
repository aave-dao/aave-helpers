// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'aave-v3-origin/contracts/extensions/v3-config-engine/AaveV3Payload.sol';
import {AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';

/**
 * @dev Inheriting directly from AaveV3Payload for being able to inject a custom engine
 * @author BGD Labs
 */
contract AaveV3PolygonBorrowUpdateNoChange is AaveV3Payload {
  constructor(IEngine customEngine) AaveV3Payload(customEngine) {}

  function borrowsUpdates() public pure override returns (IEngine.BorrowUpdate[] memory) {
    IEngine.BorrowUpdate[] memory borrowsUpdate = new IEngine.BorrowUpdate[](1);

    borrowsUpdate[0] = IEngine.BorrowUpdate({
      asset: AaveV3PolygonAssets.AAVE_UNDERLYING,
      enabledToBorrow: EngineFlags.KEEP_CURRENT,
      flashloanable: EngineFlags.KEEP_CURRENT,
      borrowableInIsolation: EngineFlags.KEEP_CURRENT,
      withSiloedBorrowing: EngineFlags.KEEP_CURRENT,
      reserveFactor: EngineFlags.KEEP_CURRENT
    });

    return borrowsUpdate;
  }

  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Polygon', networkAbbreviation: 'Pol'});
  }
}
