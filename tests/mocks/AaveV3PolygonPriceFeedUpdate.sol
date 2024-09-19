// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'aave-v3-origin/contracts/extensions/v3-config-engine/AaveV3Payload.sol';
import {AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';

/**
 * @dev Smart contract for a mock listing, to be able to test without having a v3 instance on Ethereum
 * IMPORTANT Parameters are pseudo-random, DON'T USE THIS ANYHOW IN PRODUCTION
 * @dev Inheriting directly from AaveV3Payload for being able to inject a custom engine
 * @author BGD Labs
 */
contract AaveV3PolygonPriceFeedUpdate is AaveV3Payload {
  constructor(IEngine customEngine) AaveV3Payload(customEngine) {}

  function priceFeedsUpdates() public pure override returns (IEngine.PriceFeedUpdate[] memory) {
    IEngine.PriceFeedUpdate[] memory priceFeedsUpdate = new IEngine.PriceFeedUpdate[](1);

    priceFeedsUpdate[0] = IEngine.PriceFeedUpdate({
      asset: AaveV3PolygonAssets.AAVE_UNDERLYING,
      priceFeed: AaveV3PolygonAssets.USDC_ORACLE
    });

    return priceFeedsUpdate;
  }

  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Polygon', networkAbbreviation: 'Pol'});
  }
}
