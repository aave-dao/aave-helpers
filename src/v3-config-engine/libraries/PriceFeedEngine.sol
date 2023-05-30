// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {AaveV3ConfigEngine as Engine} from '../AaveV3ConfigEngine.sol';
import {IAaveV3ConfigEngine as IEngine, IV3RateStrategyFactory, IAaveOracle} from '../IAaveV3ConfigEngine.sol';
import {IChainlinkAggregator} from '../../interfaces/IChainlinkAggregator.sol';
import {EngineFlags} from '../EngineFlags.sol';

library PriceFeedEngine {
  function executePriceFeedsUpdate(
    IAaveOracle oracle,
    IEngine.PriceFeedUpdate[] memory updates
  ) external {
    require(updates.length != 0, 'AT_LEAST_ONE_UPDATE_REQUIRED');

    Engine.AssetsConfig memory configs = _repackPriceFeed(updates);

    setPriceFeeds(oracle, configs.ids, configs.basics);
  }

  function setPriceFeeds(
    IAaveOracle oracle,
    address[] memory ids,
    Engine.Basic[] memory basics
  ) public {
    address[] memory assets = new address[](ids.length);
    address[] memory sources = new address[](ids.length);

    for (uint256 i = 0; i < ids.length; i++) {
      require(basics[i].priceFeed != address(0), 'PRICE_FEED_ALWAYS_REQUIRED');
      require(
        IChainlinkAggregator(basics[i].priceFeed).latestAnswer() > 0,
        'FEED_SHOULD_RETURN_POSITIVE_PRICE'
      );
      assets[i] = ids[i];
      sources[i] = basics[i].priceFeed;
    }

    oracle.setAssetSources(assets, sources);
  }

  function _repackPriceFeed(
    IEngine.PriceFeedUpdate[] memory updates
  ) internal pure returns (Engine.AssetsConfig memory) {
    address[] memory ids = new address[](updates.length);
    Engine.Basic[] memory basics = new Engine.Basic[](updates.length);

    for (uint256 i = 0; i < updates.length; i++) {
      ids[i] = updates[i].asset;
      basics[i] = Engine.Basic({
        priceFeed: updates[i].priceFeed,
        assetSymbol: string(''), // unused for price feed update
        rateStrategyParams: IV3RateStrategyFactory.RateStrategyParams(0, 0, 0, 0, 0, 0, 0, 0, 0), // unused for price feed update
        implementations: IEngine.TokenImplementations(address(0), address(0), address(0)) // unused for price feed update
      });
    }

    return
      Engine.AssetsConfig({
        ids: ids,
        caps: new Engine.Caps[](0),
        basics: basics,
        borrows: new Engine.Borrow[](0),
        collaterals: new Engine.Collateral[](0),
        rates: new IV3RateStrategyFactory.RateStrategyParams[](0),
        eModeCategories: new Engine.EModeCategories[](0)
      });
  }
}
