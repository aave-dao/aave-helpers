// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../src/ScriptUtils.sol';
import {AaveV3ConfigEngine} from '../src/v3-config-engine/AaveV3ConfigEngine.sol';
import {IV3RateStrategyFactory} from '../src/v3-config-engine/IV3RateStrategyFactory.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3Optimism} from 'aave-address-book/AaveV3Optimism.sol';
import {AaveV3Arbitrum} from 'aave-address-book/AaveV3Arbitrum.sol';
import {AaveV3Polygon} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveV3Avalanche} from 'aave-address-book/AaveV3Avalanche.sol';
import {AaveV3Metis} from 'aave-address-book/AaveV3Metis.sol';
import {IPool, IPoolConfigurator, IAaveOracle} from 'aave-address-book/AaveV3.sol';
import {CapsEngine} from '../src/v3-config-engine/libraries/CapsEngine.sol';
import {BorrowEngine} from '../src/v3-config-engine/libraries/BorrowEngine.sol';
import {CollateralEngine} from '../src/v3-config-engine/libraries/CollateralEngine.sol';
import {RateEngine} from '../src/v3-config-engine/libraries/RateEngine.sol';
import {PriceFeedEngine} from '../src/v3-config-engine/libraries/PriceFeedEngine.sol';
import {EModeEngine} from '../src/v3-config-engine/libraries/EModeEngine.sol';
import {ListingEngine} from '../src/v3-config-engine/libraries/ListingEngine.sol';

library DeployEngineEthLib {
  function deploy() internal returns (address) {
    AaveV3ConfigEngine.EngineLibraries memory engineLibraries = AaveV3ConfigEngine.EngineLibraries({
      listingEngine: Create2Utils._create2Deploy('v1', type(ListingEngine).creationCode),
      eModeEngine: Create2Utils._create2Deploy('v1', type(EModeEngine).creationCode),
      borrowEngine: Create2Utils._create2Deploy('v1', type(BorrowEngine).creationCode),
      collateralEngine: Create2Utils._create2Deploy('v1', type(CollateralEngine).creationCode),
      priceFeedEngine: Create2Utils._create2Deploy('v1', type(PriceFeedEngine).creationCode),
      rateEngine: Create2Utils._create2Deploy('v1', type(RateEngine).creationCode),
      capsEngine: Create2Utils._create2Deploy('v1', type(CapsEngine).creationCode)
    });
    AaveV3ConfigEngine.EngineConstants memory engineConstants = AaveV3ConfigEngine.EngineConstants({
      pool: AaveV3Ethereum.POOL,
      poolConfigurator: AaveV3Ethereum.POOL_CONFIGURATOR,
      ratesStrategyFactory: IV3RateStrategyFactory(AaveV3Ethereum.RATES_FACTORY),
      oracle: AaveV3Ethereum.ORACLE,
      aTokenImpl: AaveV3Ethereum.DEFAULT_A_TOKEN_IMPL_REV_1,
      vTokenImpl: AaveV3Ethereum.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1,
      sTokenImpl: AaveV3Ethereum.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1,
      rewardsController: AaveV3Ethereum.DEFAULT_INCENTIVES_CONTROLLER,
      collector: address(AaveV3Ethereum.COLLECTOR)
    });

    return
      address(
        new AaveV3ConfigEngine(
          engineConstants,
          engineLibraries
        )
      );
  }
}

library DeployEngineOptLib {
  function deploy() internal returns (address) {
    AaveV3ConfigEngine.EngineLibraries memory engineLibraries = AaveV3ConfigEngine.EngineLibraries({
      listingEngine: Create2Utils._create2Deploy('v1', type(ListingEngine).creationCode),
      eModeEngine: Create2Utils._create2Deploy('v1', type(EModeEngine).creationCode),
      borrowEngine: Create2Utils._create2Deploy('v1', type(BorrowEngine).creationCode),
      collateralEngine: Create2Utils._create2Deploy('v1', type(CollateralEngine).creationCode),
      priceFeedEngine: Create2Utils._create2Deploy('v1', type(PriceFeedEngine).creationCode),
      rateEngine: Create2Utils._create2Deploy('v1', type(RateEngine).creationCode),
      capsEngine: Create2Utils._create2Deploy('v1', type(CapsEngine).creationCode)
    });
    AaveV3ConfigEngine.EngineConstants memory engineConstants = AaveV3ConfigEngine.EngineConstants({
      pool: AaveV3Optimism.POOL,
      poolConfigurator: AaveV3Optimism.POOL_CONFIGURATOR,
      ratesStrategyFactory: IV3RateStrategyFactory(AaveV3Optimism.RATES_FACTORY),
      oracle: AaveV3Optimism.ORACLE,
      aTokenImpl: AaveV3Optimism.DEFAULT_A_TOKEN_IMPL_REV_2,
      vTokenImpl: AaveV3Optimism.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_2,
      sTokenImpl: AaveV3Optimism.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_2,
      rewardsController: AaveV3Optimism.DEFAULT_INCENTIVES_CONTROLLER,
      collector: address(AaveV3Optimism.COLLECTOR)
    });

    return
      address(
        new AaveV3ConfigEngine(
          engineConstants,
          engineLibraries
        )
      );
  }
}

library DeployEngineArbLib {
  function deploy() internal returns (address) {
    AaveV3ConfigEngine.EngineLibraries memory engineLibraries = AaveV3ConfigEngine.EngineLibraries({
      listingEngine: Create2Utils._create2Deploy('v1', type(ListingEngine).creationCode),
      eModeEngine: Create2Utils._create2Deploy('v1', type(EModeEngine).creationCode),
      borrowEngine: Create2Utils._create2Deploy('v1', type(BorrowEngine).creationCode),
      collateralEngine: Create2Utils._create2Deploy('v1', type(CollateralEngine).creationCode),
      priceFeedEngine: Create2Utils._create2Deploy('v1', type(PriceFeedEngine).creationCode),
      rateEngine: Create2Utils._create2Deploy('v1', type(RateEngine).creationCode),
      capsEngine: Create2Utils._create2Deploy('v1', type(CapsEngine).creationCode)
    });
    AaveV3ConfigEngine.EngineConstants memory engineConstants = AaveV3ConfigEngine.EngineConstants({
      pool: AaveV3Arbitrum.POOL,
      poolConfigurator: AaveV3Arbitrum.POOL_CONFIGURATOR,
      ratesStrategyFactory: IV3RateStrategyFactory(AaveV3Arbitrum.RATES_FACTORY),
      oracle: AaveV3Arbitrum.ORACLE,
      aTokenImpl: AaveV3Arbitrum.DEFAULT_A_TOKEN_IMPL_REV_2,
      vTokenImpl: AaveV3Arbitrum.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_2,
      sTokenImpl: AaveV3Arbitrum.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_2,
      rewardsController: AaveV3Arbitrum.DEFAULT_INCENTIVES_CONTROLLER,
      collector: address(AaveV3Arbitrum.COLLECTOR)
    });

    return
      address(
        new AaveV3ConfigEngine(
          engineConstants,
          engineLibraries
        )
      );
  }
}

library DeployEnginePolLib {
  function deploy() internal returns (address) {
    AaveV3ConfigEngine.EngineLibraries memory engineLibraries = AaveV3ConfigEngine.EngineLibraries({
      listingEngine: Create2Utils._create2Deploy('v1', type(ListingEngine).creationCode),
      eModeEngine: Create2Utils._create2Deploy('v1', type(EModeEngine).creationCode),
      borrowEngine: Create2Utils._create2Deploy('v1', type(BorrowEngine).creationCode),
      collateralEngine: Create2Utils._create2Deploy('v1', type(CollateralEngine).creationCode),
      priceFeedEngine: Create2Utils._create2Deploy('v1', type(PriceFeedEngine).creationCode),
      rateEngine: Create2Utils._create2Deploy('v1', type(RateEngine).creationCode),
      capsEngine: Create2Utils._create2Deploy('v1', type(CapsEngine).creationCode)
    });
    AaveV3ConfigEngine.EngineConstants memory engineConstants = AaveV3ConfigEngine.EngineConstants({
      pool: AaveV3Polygon.POOL,
      poolConfigurator: AaveV3Polygon.POOL_CONFIGURATOR,
      ratesStrategyFactory: IV3RateStrategyFactory(AaveV3Polygon.RATES_FACTORY),
      oracle: AaveV3Polygon.ORACLE,
      aTokenImpl: AaveV3Polygon.DEFAULT_A_TOKEN_IMPL_REV_2,
      vTokenImpl: AaveV3Polygon.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_2,
      sTokenImpl: AaveV3Polygon.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_2,
      rewardsController: AaveV3Polygon.DEFAULT_INCENTIVES_CONTROLLER,
      collector: address(AaveV3Polygon.COLLECTOR)
    });

    return
      address(
        new AaveV3ConfigEngine(
          engineConstants,
          engineLibraries
        )
      );
  }
}

library DeployEngineAvaLib {
  function deploy() internal returns (address) {
    AaveV3ConfigEngine.EngineLibraries memory engineLibraries = AaveV3ConfigEngine.EngineLibraries({
      listingEngine: Create2Utils._create2Deploy('v1', type(ListingEngine).creationCode),
      eModeEngine: Create2Utils._create2Deploy('v1', type(EModeEngine).creationCode),
      borrowEngine: Create2Utils._create2Deploy('v1', type(BorrowEngine).creationCode),
      collateralEngine: Create2Utils._create2Deploy('v1', type(CollateralEngine).creationCode),
      priceFeedEngine: Create2Utils._create2Deploy('v1', type(PriceFeedEngine).creationCode),
      rateEngine: Create2Utils._create2Deploy('v1', type(RateEngine).creationCode),
      capsEngine: Create2Utils._create2Deploy('v1', type(CapsEngine).creationCode)
    });
    AaveV3ConfigEngine.EngineConstants memory engineConstants = AaveV3ConfigEngine.EngineConstants({
      pool: AaveV3Avalanche.POOL,
      poolConfigurator: AaveV3Avalanche.POOL_CONFIGURATOR,
      ratesStrategyFactory: IV3RateStrategyFactory(AaveV3Avalanche.RATES_FACTORY),
      oracle: AaveV3Avalanche.ORACLE,
      aTokenImpl: AaveV3Avalanche.DEFAULT_A_TOKEN_IMPL_REV_2,
      vTokenImpl: AaveV3Avalanche.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_2,
      sTokenImpl: AaveV3Avalanche.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_2,
      rewardsController: AaveV3Avalanche.DEFAULT_INCENTIVES_CONTROLLER,
      collector: address(AaveV3Avalanche.COLLECTOR)
    });

    return
      address(
        new AaveV3ConfigEngine(
          engineConstants,
          engineLibraries
        )
      );
  }
}

library DeployEngineMetLib {
  function deploy() internal returns (address) {
    AaveV3ConfigEngine.EngineLibraries memory engineLibraries = AaveV3ConfigEngine.EngineLibraries({
      listingEngine: Create2Utils._create2Deploy('v1', type(ListingEngine).creationCode),
      eModeEngine: Create2Utils._create2Deploy('v1', type(EModeEngine).creationCode),
      borrowEngine: Create2Utils._create2Deploy('v1', type(BorrowEngine).creationCode),
      collateralEngine: Create2Utils._create2Deploy('v1', type(CollateralEngine).creationCode),
      priceFeedEngine: Create2Utils._create2Deploy('v1', type(PriceFeedEngine).creationCode),
      rateEngine: Create2Utils._create2Deploy('v1', type(RateEngine).creationCode),
      capsEngine: Create2Utils._create2Deploy('v1', type(CapsEngine).creationCode)
    });
    AaveV3ConfigEngine.EngineConstants memory engineConstants = AaveV3ConfigEngine.EngineConstants({
      pool: AaveV3Metis.POOL,
      poolConfigurator: AaveV3Metis.POOL_CONFIGURATOR,
      ratesStrategyFactory: IV3RateStrategyFactory(AaveV3Metis.RATES_FACTORY),
      oracle: AaveV3Metis.ORACLE,
      aTokenImpl: AaveV3Metis.DEFAULT_A_TOKEN_IMPL_REV_1,
      vTokenImpl: AaveV3Metis.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1,
      sTokenImpl: AaveV3Metis.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1,
      rewardsController: AaveV3Metis.DEFAULT_INCENTIVES_CONTROLLER,
      collector: address(AaveV3Metis.COLLECTOR)
    });

    return
      address(
        new AaveV3ConfigEngine(
          engineConstants,
          engineLibraries
        )
      );
  }
}

contract DeployEngineEth is EthereumScript {
  function run() external broadcast {
    DeployEngineEthLib.deploy();
  }
}

contract DeployEngineOpt is OptimismScript {
  function run() external broadcast {
    DeployEngineOptLib.deploy();
  }
}

contract DeployEngineArb is ArbitrumScript {
  function run() external broadcast {
    DeployEngineArbLib.deploy();
  }
}

contract DeployEnginePol is PolygonScript {
  function run() external broadcast {
    DeployEnginePolLib.deploy();
  }
}

contract DeployEngineAva is AvalancheScript {
  function run() external broadcast {
    DeployEngineAvaLib.deploy();
  }
}

contract DeployEngineMet is MetisScript {
  function run() external broadcast {
    DeployEngineMetLib.deploy();
  }
}