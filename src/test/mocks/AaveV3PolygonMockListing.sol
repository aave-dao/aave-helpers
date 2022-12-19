// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Polygon} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveV3ListingPolygon, IGenericV3ListingEngine} from '../../v3-listing-engine/AaveV3ListingPolygon.sol';

/**
 * @dev Smart contract for a mock listing, to be able to test without having a v3 instance on Ethereum
 * IMPORTANT Parameters are pseudo-random, DON'T USE THIS ANYHOW IN PRODUCTION
 * @author BGD Labs
 */
contract AaveV3PolygonMockListing is AaveV3ListingPolygon {
  constructor(IGenericV3ListingEngine listingEngine) AaveV3ListingPolygon(listingEngine) {}

  function getAllConfigs() public pure override returns (IGenericV3ListingEngine.Listing[] memory) {
    IGenericV3ListingEngine.Listing[] memory listings = new IGenericV3ListingEngine.Listing[](1);

    listings[0] = IGenericV3ListingEngine.Listing({
      asset: 0x9c2C5fd7b07E95EE044DDeba0E97a665F142394f,
      assetSymbol: '1INCH',
      priceFeed: 0x443C5116CdF663Eb387e72C688D276e702135C87,
      rateStrategy: 0x03733F4E008d36f2e37F0080fF1c8DF756622E6F, // TODO
      enabledToBorrow: true,
      stableRateModeEnabled: false, // TODO
      borrowableInIsolation: false,
      flashloanable: false,
      ltv: 82_50,
      liqThreshold: 86_00,
      liqBonus: 5_00,
      reserveFactor: 10_00,
      supplyCap: 85_000,
      borrowCap: 60_000,
      debtCeiling: 0,
      liqProtocolFee: 10_00
    });

    return listings;
  }
}
