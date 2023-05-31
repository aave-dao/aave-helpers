// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {AaveV3ConfigEngine as Engine} from '../AaveV3ConfigEngine.sol';
import {IAaveV3ConfigEngine as IEngine, IV3RateStrategyFactory, IAaveOracle} from '../IAaveV3ConfigEngine.sol';
import {IChainlinkAggregator} from '../../interfaces/IChainlinkAggregator.sol';

library PriceFeedEngine {
  function executePriceFeedsUpdate(
    Engine.EngineConstants calldata engineConstants,
    IEngine.PriceFeedUpdate[] memory updates
  ) external {
    require(updates.length != 0, 'AT_LEAST_ONE_UPDATE_REQUIRED');

    _setPriceFeeds(engineConstants.oracle, updates);
  }

  function _setPriceFeeds(IAaveOracle oracle, IEngine.PriceFeedUpdate[] memory updates) internal {
    address[] memory assets = new address[](updates.length);
    address[] memory sources = new address[](updates.length);

    for (uint256 i = 0; i < updates.length; i++) {
      require(updates[i].priceFeed != address(0), 'PRICE_FEED_ALWAYS_REQUIRED');
      require(
        IChainlinkAggregator(updates[i].priceFeed).latestAnswer() > 0,
        'FEED_SHOULD_RETURN_POSITIVE_PRICE'
      );
      assets[i] = updates[i].asset;
      sources[i] = updates[i].priceFeed;
    }

    oracle.setAssetSources(assets, sources);
  }
}
