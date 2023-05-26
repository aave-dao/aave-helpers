// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ConfiguratorInputTypes, DataTypes} from 'aave-address-book/AaveV3.sol';
import {ReserveConfiguration} from 'aave-v3-core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {CapsEngine} from './libraries/CapsEngine.sol';
import {BorrowEngine} from './libraries/BorrowEngine.sol';
import {CollateralEngine} from './libraries/CollateralEngine.sol';
import {RateEngine} from './libraries/RateEngine.sol';
import {PriceFeedEngine} from './libraries/PriceFeedEngine.sol';
import {EModeEngine} from './libraries/EModeEngine.sol';
import {ListingEngine} from './libraries/ListingEngine.sol';
import './IAaveV3ConfigEngine.sol';

/**
 * @dev Helper smart contract abstracting the complexity of changing configurations on Aave v3, simplifying
 * listing flow and parameters updates.
 * - It is planned to be used via delegatecall, by any contract having appropriate permissions to
 * do a listing, or any other granular config
 * Assumptions:
 * - Only one a/v/s token implementation for all assets
 * - Only one RewardsController for all assets
 * - Only one Collector for all assets
 * @author BGD Labs
 */
contract AaveV3ConfigEngine is IAaveV3ConfigEngine {

  struct AssetsConfig {
    address[] ids;
    Basic[] basics;
    Borrow[] borrows;
    Collateral[] collaterals;
    Caps[] caps;
    IV3RateStrategyFactory.RateStrategyParams[] rates;
    EModeCategories[] eModeCategories;
  }

  struct Basic {
    string assetSymbol;
    address priceFeed;
    IV3RateStrategyFactory.RateStrategyParams rateStrategyParams;
    TokenImplementations implementations;
  }

  struct Borrow {
    uint256 enabledToBorrow; // Main config flag, if EngineFlag.DISABLED, some of the other fields will not be considered
    uint256 flashloanable; // EngineFlag.ENABLED for true, EngineFlag.DISABLED for false otherwise EngineFlag.KEEP_CURRENT
    uint256 stableRateModeEnabled; // EngineFlag.ENABLED for true, EngineFlag.DISABLED for false otherwise EngineFlag.KEEP_CURRENT
    uint256 borrowableInIsolation; // EngineFlag.ENABLED for true, EngineFlag.DISABLED for false otherwise EngineFlag.KEEP_CURRENT
    uint256 withSiloedBorrowing; // EngineFlag.ENABLED for true, EngineFlag.DISABLED for false otherwise EngineFlag.KEEP_CURRENT
    uint256 reserveFactor; // With 2 digits precision, `10_00` for 10%. Should be positive and < 100_00
  }

  struct Collateral {
    uint256 ltv; // Only considered if liqThreshold > 0. With 2 digits precision, `10_00` for 10%. Should be lower than liquidationThreshold
    uint256 liqThreshold; // If `0`, the asset will not be enabled as collateral. Same format as ltv, and should be higher
    uint256 liqBonus; // Only considered if liqThreshold > 0. Same format as ltv
    uint256 debtCeiling; // Only considered if liqThreshold > 0. In USD and without decimals, so 100_000 for 100k USD debt ceiling
    uint256 liqProtocolFee; // Only considered if liqThreshold > 0. Same format as ltv
    uint256 eModeCategory; // If `0` eMode will be disabled for the asset, else the eMode category will be set.
  }

  struct Caps {
    uint256 supplyCap; // Always configured. In "big units" of the asset, and no decimals. 100 for 100 ETH supply cap
    uint256 borrowCap; // Always configured, no matter if enabled for borrowing or not. Same format as supply cap
  }

  struct EModeCategories {
    uint8 eModeCategory;
    uint256 ltv; // With 2 digits precision, `10_00` for 10%. Should be lower or equal to liquidationThreshold
    uint256 liqThreshold; // Same format as ltv, and should be higher or equal to ltv.
    uint256 liqBonus; // Same format as ltv
    address priceSource; // A custom price oracle for the eMode category
    string label; // The label for the eMode category
  }

  IPool internal immutable POOL;
  IPoolConfigurator internal immutable POOL_CONFIGURATOR;
  IAaveOracle internal immutable ORACLE;
  address internal immutable ATOKEN_IMPL;
  address internal immutable VTOKEN_IMPL;
  address internal immutable STOKEN_IMPL;
  address internal immutable REWARDS_CONTROLLER;
  address internal immutable COLLECTOR;
  IV3RateStrategyFactory internal immutable RATE_STRATEGIES_FACTORY;

  constructor(
    IPool pool,
    IPoolConfigurator configurator,
    IAaveOracle oracle,
    address aTokenImpl,
    address vTokenImpl,
    address sTokenImpl,
    address rewardsController,
    address collector,
    IV3RateStrategyFactory rateStrategiesFactory
  ) {
    require(address(pool) != address(0), 'ONLY_NONZERO_POOL');
    require(address(configurator) != address(0), 'ONLY_NONZERO_CONFIGURATOR');
    require(address(oracle) != address(0), 'ONLY_NONZERO_ORACLE');
    require(aTokenImpl != address(0), 'ONLY_NONZERO_ATOKEN');
    require(vTokenImpl != address(0), 'ONLY_NONZERO_VTOKEN');
    require(sTokenImpl != address(0), 'ONLY_NONZERO_STOKEN');
    require(rewardsController != address(0), 'ONLY_NONZERO_REWARDS_CONTROLLER');
    require(collector != address(0), 'ONLY_NONZERO_COLLECTOR');
    require(address(rateStrategiesFactory) != address(0), 'ONLY_NONZERO_RATES_FACTORY');

    POOL = pool;
    POOL_CONFIGURATOR = configurator;
    ORACLE = oracle;
    ATOKEN_IMPL = aTokenImpl;
    VTOKEN_IMPL = vTokenImpl;
    STOKEN_IMPL = sTokenImpl;
    REWARDS_CONTROLLER = rewardsController;
    COLLECTOR = collector;
    RATE_STRATEGIES_FACTORY = rateStrategiesFactory;
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function listAssets(PoolContext memory context, Listing[] memory listings) public {
    require(listings.length != 0, 'AT_LEAST_ONE_ASSET_REQUIRED');

    ListingWithCustomImpl[] memory customListings = new ListingWithCustomImpl[](listings.length);
    for (uint256 i = 0; i < listings.length; i++) {
      customListings[i] = ListingWithCustomImpl({
        base: listings[i],
        implementations: TokenImplementations({
          aToken: ATOKEN_IMPL,
          vToken: VTOKEN_IMPL,
          sToken: STOKEN_IMPL
        })
      });
    }

    listAssetsCustom(context, customListings);
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function listAssetsCustom(
    PoolContext memory context,
    ListingWithCustomImpl[] memory listings
  ) public {
    ListingEngine.executeCustomAssetListing(
      context,
      POOL_CONFIGURATOR,
      RATE_STRATEGIES_FACTORY,
      POOL,
      ORACLE,
      COLLECTOR,
      REWARDS_CONTROLLER,
      listings
    );
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updateCaps(CapsUpdate[] memory updates) public {
    CapsEngine.executeCapsUpdate(
      POOL_CONFIGURATOR,
      updates
    );
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updatePriceFeeds(PriceFeedUpdate[] memory updates) public {
    PriceFeedEngine.executePriceFeedsUpdate(
      ORACLE,
      updates
    );
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updateCollateralSide(CollateralUpdate[] memory updates) public {
    CollateralEngine.executeCollateralSide(
      POOL_CONFIGURATOR,
      POOL,
      updates
    );
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updateBorrowSide(BorrowUpdate[] memory updates) public {
    BorrowEngine.executeBorrowSide(
      POOL_CONFIGURATOR,
      POOL,
      updates
    );
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updateRateStrategies(RateStrategyUpdate[] memory updates) public {
    RateEngine.executeRateStrategiesUpdate(
      POOL_CONFIGURATOR,
      RATE_STRATEGIES_FACTORY,
      updates
    );
  }

  /// @inheritdoc IAaveV3ConfigEngine
  function updateEModeCategories(EModeUpdate[] memory updates) public {
    EModeEngine.executeEModeCategoriesUpdate(
      POOL_CONFIGURATOR,
      POOL,
      updates
    );
  }
}
