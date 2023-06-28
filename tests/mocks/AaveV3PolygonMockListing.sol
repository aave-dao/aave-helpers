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
contract AaveV3PolygonMockListing is AaveV3PayloadBase {
  constructor(IEngine customEngine) AaveV3PayloadBase(customEngine) {}

  function newListings() public view override returns (IEngine.Listing[] memory) {
    IEngine.Listing[] memory listings = new IEngine.Listing[](1);

    listings[0] = IEngine.Listing({
      asset: 0x9c2C5fd7b07E95EE044DDeba0E97a665F142394f,
      assetSymbol: '1INCH',
      priceFeed: 0x443C5116CdF663Eb387e72C688D276e702135C87,
      rateStrategyParams: LISTING_ENGINE.RATE_STRATEGIES_FACTORY().getStrategyDataOfAsset(
        AaveV3PolygonAssets.AAVE_UNDERLYING
      ), // Quite common case, of setting the same rate strategy as an already listed asset
      enabledToBorrow: EngineFlags.ENABLED,
      stableRateModeEnabled: EngineFlags.DISABLED,
      borrowableInIsolation: EngineFlags.DISABLED,
      withSiloedBorrowing: EngineFlags.DISABLED,
      flashloanable: EngineFlags.DISABLED,
      ltv: 82_50,
      liqThreshold: 86_00,
      liqBonus: 5_00,
      reserveFactor: 10_00,
      supplyCap: 85_000,
      borrowCap: 60_000,
      debtCeiling: 0,
      liqProtocolFee: 10_00,
      eModeCategory: 0
    });

    return listings;
  }

  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Polygon', networkAbbreviation: 'Pol'});
  }
}
