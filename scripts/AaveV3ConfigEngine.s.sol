// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../src/ScriptUtils.sol';
import {AaveV3ConfigEngine as Engine} from '../src/v3-config-engine/AaveV3ConfigEngine.sol';
import {IAaveV3ConfigEngine as IEngine} from '../src/v3-config-engine/IAaveV3ConfigEngine.sol';
import {IV3RateStrategyFactory} from '../src/v3-config-engine/IV3RateStrategyFactory.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3BNB} from 'aave-address-book/AaveV3BNB.sol';
import {AaveV3Optimism} from 'aave-address-book/AaveV3Optimism.sol';
import {AaveV3Arbitrum} from 'aave-address-book/AaveV3Arbitrum.sol';
import {AaveV3Polygon} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveV3Avalanche} from 'aave-address-book/AaveV3Avalanche.sol';
import {AaveV3Metis} from 'aave-address-book/AaveV3Metis.sol';
import {AaveV3Gnosis} from 'aave-address-book/AaveV3Gnosis.sol';
import {AaveV3Base} from 'aave-address-book/AaveV3Base.sol';
import {CapsEngine} from '../src/v3-config-engine/libraries/CapsEngine.sol';
import {BorrowEngine} from '../src/v3-config-engine/libraries/BorrowEngine.sol';
import {CollateralEngine} from '../src/v3-config-engine/libraries/CollateralEngine.sol';
import {RateEngine} from '../src/v3-config-engine/libraries/RateEngine.sol';
import {PriceFeedEngine} from '../src/v3-config-engine/libraries/PriceFeedEngine.sol';
import {EModeEngine} from '../src/v3-config-engine/libraries/EModeEngine.sol';
import {ListingEngine} from '../src/v3-config-engine/libraries/ListingEngine.sol';

library DeployEngineEthLib {
  function deploy() internal returns (address) {
    IEngine.EngineLibraries memory engineLibraries = IEngine.EngineLibraries({
      listingEngine: Create2Utils.create2Deploy('v1', type(ListingEngine).creationCode),
      eModeEngine: Create2Utils.create2Deploy('v1', type(EModeEngine).creationCode),
      borrowEngine: Create2Utils.create2Deploy('v1', type(BorrowEngine).creationCode),
      collateralEngine: Create2Utils.create2Deploy('v1', type(CollateralEngine).creationCode),
      priceFeedEngine: Create2Utils.create2Deploy('v1', type(PriceFeedEngine).creationCode),
      rateEngine: Create2Utils.create2Deploy('v1', type(RateEngine).creationCode),
      capsEngine: Create2Utils.create2Deploy('v1', type(CapsEngine).creationCode)
    });
    IEngine.EngineConstants memory engineConstants = IEngine.EngineConstants({
      pool: AaveV3Ethereum.POOL,
      poolConfigurator: AaveV3Ethereum.POOL_CONFIGURATOR,
      ratesStrategyFactory: IV3RateStrategyFactory(AaveV3Ethereum.RATES_FACTORY),
      oracle: AaveV3Ethereum.ORACLE,
      rewardsController: AaveV3Ethereum.DEFAULT_INCENTIVES_CONTROLLER,
      collector: address(AaveV3Ethereum.COLLECTOR)
    });

    return
      address(
        new Engine(
          AaveV3Ethereum.DEFAULT_A_TOKEN_IMPL_REV_1,
          AaveV3Ethereum.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1,
          AaveV3Ethereum.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1,
          engineConstants,
          engineLibraries
        )
      );
  }
}

library DeployEngineOptLib {
  function deploy() internal returns (address) {
    IEngine.EngineLibraries memory engineLibraries = IEngine.EngineLibraries({
      listingEngine: Create2Utils.create2Deploy('v1', type(ListingEngine).creationCode),
      eModeEngine: Create2Utils.create2Deploy('v1', type(EModeEngine).creationCode),
      borrowEngine: Create2Utils.create2Deploy('v1', type(BorrowEngine).creationCode),
      collateralEngine: Create2Utils.create2Deploy('v1', type(CollateralEngine).creationCode),
      priceFeedEngine: Create2Utils.create2Deploy('v1', type(PriceFeedEngine).creationCode),
      rateEngine: Create2Utils.create2Deploy('v1', type(RateEngine).creationCode),
      capsEngine: Create2Utils.create2Deploy('v1', type(CapsEngine).creationCode)
    });
    IEngine.EngineConstants memory engineConstants = IEngine.EngineConstants({
      pool: AaveV3Optimism.POOL,
      poolConfigurator: AaveV3Optimism.POOL_CONFIGURATOR,
      ratesStrategyFactory: IV3RateStrategyFactory(AaveV3Optimism.RATES_FACTORY),
      oracle: AaveV3Optimism.ORACLE,
      rewardsController: AaveV3Optimism.DEFAULT_INCENTIVES_CONTROLLER,
      collector: address(AaveV3Optimism.COLLECTOR)
    });

    return
      address(
        new Engine(
          AaveV3Optimism.DEFAULT_A_TOKEN_IMPL_REV_2,
          AaveV3Optimism.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_2,
          AaveV3Optimism.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_3,
          engineConstants,
          engineLibraries
        )
      );
  }
}

library DeployEngineArbLib {
  function deploy() internal returns (address) {
    IEngine.EngineLibraries memory engineLibraries = IEngine.EngineLibraries({
      listingEngine: Create2Utils.create2Deploy('v1', type(ListingEngine).creationCode),
      eModeEngine: Create2Utils.create2Deploy('v1', type(EModeEngine).creationCode),
      borrowEngine: Create2Utils.create2Deploy('v1', type(BorrowEngine).creationCode),
      collateralEngine: Create2Utils.create2Deploy('v1', type(CollateralEngine).creationCode),
      priceFeedEngine: Create2Utils.create2Deploy('v1', type(PriceFeedEngine).creationCode),
      rateEngine: Create2Utils.create2Deploy('v1', type(RateEngine).creationCode),
      capsEngine: Create2Utils.create2Deploy('v1', type(CapsEngine).creationCode)
    });
    IEngine.EngineConstants memory engineConstants = IEngine.EngineConstants({
      pool: AaveV3Arbitrum.POOL,
      poolConfigurator: AaveV3Arbitrum.POOL_CONFIGURATOR,
      ratesStrategyFactory: IV3RateStrategyFactory(AaveV3Arbitrum.RATES_FACTORY),
      oracle: AaveV3Arbitrum.ORACLE,
      rewardsController: AaveV3Arbitrum.DEFAULT_INCENTIVES_CONTROLLER,
      collector: address(AaveV3Arbitrum.COLLECTOR)
    });

    return
      address(
        new Engine(
          AaveV3Arbitrum.DEFAULT_A_TOKEN_IMPL_REV_2,
          AaveV3Arbitrum.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_2,
          AaveV3Arbitrum.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_3,
          engineConstants,
          engineLibraries
        )
      );
  }
}

library DeployEnginePolLib {
  function deploy() internal returns (address) {
    IEngine.EngineLibraries memory engineLibraries = IEngine.EngineLibraries({
      listingEngine: Create2Utils.create2Deploy('v1', type(ListingEngine).creationCode),
      eModeEngine: Create2Utils.create2Deploy('v1', type(EModeEngine).creationCode),
      borrowEngine: Create2Utils.create2Deploy('v1', type(BorrowEngine).creationCode),
      collateralEngine: Create2Utils.create2Deploy('v1', type(CollateralEngine).creationCode),
      priceFeedEngine: Create2Utils.create2Deploy('v1', type(PriceFeedEngine).creationCode),
      rateEngine: Create2Utils.create2Deploy('v1', type(RateEngine).creationCode),
      capsEngine: Create2Utils.create2Deploy('v1', type(CapsEngine).creationCode)
    });
    IEngine.EngineConstants memory engineConstants = IEngine.EngineConstants({
      pool: AaveV3Polygon.POOL,
      poolConfigurator: AaveV3Polygon.POOL_CONFIGURATOR,
      ratesStrategyFactory: IV3RateStrategyFactory(AaveV3Polygon.RATES_FACTORY),
      oracle: AaveV3Polygon.ORACLE,
      rewardsController: AaveV3Polygon.DEFAULT_INCENTIVES_CONTROLLER,
      collector: address(AaveV3Polygon.COLLECTOR)
    });

    return
      address(
        new Engine(
          AaveV3Polygon.DEFAULT_A_TOKEN_IMPL_REV_2,
          AaveV3Polygon.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_2,
          AaveV3Polygon.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_3,
          engineConstants,
          engineLibraries
        )
      );
  }
}

library DeployEngineAvaLib {
  function deploy() internal returns (address) {
    IEngine.EngineLibraries memory engineLibraries = IEngine.EngineLibraries({
      listingEngine: Create2Utils.create2Deploy('v1', type(ListingEngine).creationCode),
      eModeEngine: Create2Utils.create2Deploy('v1', type(EModeEngine).creationCode),
      borrowEngine: Create2Utils.create2Deploy('v1', type(BorrowEngine).creationCode),
      collateralEngine: Create2Utils.create2Deploy('v1', type(CollateralEngine).creationCode),
      priceFeedEngine: Create2Utils.create2Deploy('v1', type(PriceFeedEngine).creationCode),
      rateEngine: Create2Utils.create2Deploy('v1', type(RateEngine).creationCode),
      capsEngine: Create2Utils.create2Deploy('v1', type(CapsEngine).creationCode)
    });
    IEngine.EngineConstants memory engineConstants = IEngine.EngineConstants({
      pool: AaveV3Avalanche.POOL,
      poolConfigurator: AaveV3Avalanche.POOL_CONFIGURATOR,
      ratesStrategyFactory: IV3RateStrategyFactory(AaveV3Avalanche.RATES_FACTORY),
      oracle: AaveV3Avalanche.ORACLE,
      rewardsController: AaveV3Avalanche.DEFAULT_INCENTIVES_CONTROLLER,
      collector: address(AaveV3Avalanche.COLLECTOR)
    });

    return
      address(
        new Engine(
          AaveV3Avalanche.DEFAULT_A_TOKEN_IMPL_REV_2,
          AaveV3Avalanche.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_2,
          AaveV3Avalanche.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_3,
          engineConstants,
          engineLibraries
        )
      );
  }
}

library DeployEngineMetLib {
  function deploy() internal returns (address) {
    IEngine.EngineLibraries memory engineLibraries = IEngine.EngineLibraries({
      listingEngine: Create2Utils.create2Deploy('v1', type(ListingEngine).creationCode),
      eModeEngine: Create2Utils.create2Deploy('v1', type(EModeEngine).creationCode),
      borrowEngine: Create2Utils.create2Deploy('v1', type(BorrowEngine).creationCode),
      collateralEngine: Create2Utils.create2Deploy('v1', type(CollateralEngine).creationCode),
      priceFeedEngine: Create2Utils.create2Deploy('v1', type(PriceFeedEngine).creationCode),
      rateEngine: Create2Utils.create2Deploy('v1', type(RateEngine).creationCode),
      capsEngine: Create2Utils.create2Deploy('v1', type(CapsEngine).creationCode)
    });
    IEngine.EngineConstants memory engineConstants = IEngine.EngineConstants({
      pool: AaveV3Metis.POOL,
      poolConfigurator: AaveV3Metis.POOL_CONFIGURATOR,
      ratesStrategyFactory: IV3RateStrategyFactory(AaveV3Metis.RATES_FACTORY),
      oracle: AaveV3Metis.ORACLE,
      rewardsController: AaveV3Metis.DEFAULT_INCENTIVES_CONTROLLER,
      collector: address(AaveV3Metis.COLLECTOR)
    });

    return
      address(
        new Engine(
          AaveV3Metis.DEFAULT_A_TOKEN_IMPL_REV_1,
          AaveV3Metis.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1,
          AaveV3Metis.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1,
          engineConstants,
          engineLibraries
        )
      );
  }
}

library DeployEngineBaseLib {
  function deploy() internal returns (address) {
    IEngine.EngineLibraries memory engineLibraries = IEngine.EngineLibraries({
      listingEngine: Create2Utils.create2Deploy('v1', type(ListingEngine).creationCode),
      eModeEngine: Create2Utils.create2Deploy('v1', type(EModeEngine).creationCode),
      borrowEngine: Create2Utils.create2Deploy('v1', type(BorrowEngine).creationCode),
      collateralEngine: Create2Utils.create2Deploy('v1', type(CollateralEngine).creationCode),
      priceFeedEngine: Create2Utils.create2Deploy('v1', type(PriceFeedEngine).creationCode),
      rateEngine: Create2Utils.create2Deploy('v1', type(RateEngine).creationCode),
      capsEngine: Create2Utils.create2Deploy('v1', type(CapsEngine).creationCode)
    });
    IEngine.EngineConstants memory engineConstants = IEngine.EngineConstants({
      pool: AaveV3Base.POOL,
      poolConfigurator: AaveV3Base.POOL_CONFIGURATOR,
      ratesStrategyFactory: IV3RateStrategyFactory(AaveV3Base.RATES_FACTORY),
      oracle: AaveV3Base.ORACLE,
      rewardsController: AaveV3Base.DEFAULT_INCENTIVES_CONTROLLER,
      collector: address(AaveV3Base.COLLECTOR)
    });

    return
      address(
        new Engine(
          AaveV3Base.DEFAULT_A_TOKEN_IMPL_REV_1,
          AaveV3Base.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1,
          AaveV3Base.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1,
          engineConstants,
          engineLibraries
        )
      );
  }
}

library DeployEngineGnoLib {
  function deploy() internal returns (address) {
    IEngine.EngineLibraries memory engineLibraries = IEngine.EngineLibraries({
      listingEngine: Create2Utils.create2Deploy('v1', type(ListingEngine).creationCode),
      eModeEngine: Create2Utils.create2Deploy('v1', type(EModeEngine).creationCode),
      borrowEngine: Create2Utils.create2Deploy('v1', type(BorrowEngine).creationCode),
      collateralEngine: Create2Utils.create2Deploy('v1', type(CollateralEngine).creationCode),
      priceFeedEngine: Create2Utils.create2Deploy('v1', type(PriceFeedEngine).creationCode),
      rateEngine: Create2Utils.create2Deploy('v1', type(RateEngine).creationCode),
      capsEngine: Create2Utils.create2Deploy('v1', type(CapsEngine).creationCode)
    });
    IEngine.EngineConstants memory engineConstants = IEngine.EngineConstants({
      pool: AaveV3Gnosis.POOL,
      poolConfigurator: AaveV3Gnosis.POOL_CONFIGURATOR,
      ratesStrategyFactory: IV3RateStrategyFactory(AaveV3Gnosis.RATES_FACTORY),
      oracle: AaveV3Gnosis.ORACLE,
      rewardsController: AaveV3Gnosis.DEFAULT_INCENTIVES_CONTROLLER,
      collector: address(AaveV3Gnosis.COLLECTOR)
    });

    return
      address(
        new Engine(
          AaveV3Gnosis.DEFAULT_A_TOKEN_IMPL_REV_1,
          AaveV3Gnosis.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1,
          AaveV3Gnosis.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1,
          engineConstants,
          engineLibraries
        )
      );
  }
}

library DeployEngineBnbLib {
  function deploy() internal returns (address) {
    IEngine.EngineLibraries memory engineLibraries = IEngine.EngineLibraries({
      listingEngine: Create2Utils.create2Deploy('v1', type(ListingEngine).creationCode),
      eModeEngine: Create2Utils.create2Deploy('v1', type(EModeEngine).creationCode),
      borrowEngine: Create2Utils.create2Deploy('v1', type(BorrowEngine).creationCode),
      collateralEngine: Create2Utils.create2Deploy('v1', type(CollateralEngine).creationCode),
      priceFeedEngine: Create2Utils.create2Deploy('v1', type(PriceFeedEngine).creationCode),
      rateEngine: Create2Utils.create2Deploy('v1', type(RateEngine).creationCode),
      capsEngine: Create2Utils.create2Deploy('v1', type(CapsEngine).creationCode)
    });
    IEngine.EngineConstants memory engineConstants = IEngine.EngineConstants({
      pool: AaveV3BNB.POOL,
      poolConfigurator: AaveV3BNB.POOL_CONFIGURATOR,
      ratesStrategyFactory: IV3RateStrategyFactory(AaveV3BNB.RATES_FACTORY),
      oracle: AaveV3BNB.ORACLE,
      rewardsController: AaveV3BNB.DEFAULT_INCENTIVES_CONTROLLER,
      collector: address(AaveV3BNB.COLLECTOR)
    });

    return
      address(
        new Engine(
          AaveV3BNB.DEFAULT_A_TOKEN_IMPL_REV_1,
          AaveV3BNB.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1,
          AaveV3BNB.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1,
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

contract DeployEngineBas is BaseScript {
  function run() external broadcast {
    DeployEngineBaseLib.deploy();
  }
}

contract DeployEngineGno is GnosisScript {
  function run() external broadcast {
    DeployEngineGnoLib.deploy();
  }
}

contract DeployEngineBnb is BNBScript {
  function run() external broadcast {
    DeployEngineBnbLib.deploy();
  }
}
