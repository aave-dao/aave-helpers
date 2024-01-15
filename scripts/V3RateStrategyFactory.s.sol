// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../src/ScriptUtils.sol';
import {IPoolAddressesProvider, IPool, IDefaultInterestRateStrategy} from 'aave-address-book/AaveV3.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {MiscPolygon} from 'aave-address-book/MiscPolygon.sol';
import {MiscAvalanche} from 'aave-address-book/MiscAvalanche.sol';
import {MiscMetis} from 'aave-address-book/MiscMetis.sol';
import {MiscBase} from 'aave-address-book/MiscBase.sol';
import {MiscGnosis} from 'aave-address-book/MiscGnosis.sol';
import {MiscBNB} from 'aave-address-book/MiscBNB.sol';
import {MiscArbitrum} from 'aave-address-book/MiscArbitrum.sol';
import {MiscOptimism} from 'aave-address-book/MiscOptimism.sol';
import {MiscScroll} from 'aave-address-book/MiscScroll.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {MiscPolygonZkEvm} from 'aave-address-book/MiscPolygonZkEvm.sol';
import {AaveV3Optimism} from 'aave-address-book/AaveV3Optimism.sol';
import {AaveV3Arbitrum} from 'aave-address-book/AaveV3Arbitrum.sol';
import {AaveV3Polygon} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveV3Avalanche} from 'aave-address-book/AaveV3Avalanche.sol';
import {AaveV3Metis} from 'aave-address-book/AaveV3Metis.sol';
import {AaveV3Base} from 'aave-address-book/AaveV3Base.sol';
import {AaveV3Gnosis} from 'aave-address-book/AaveV3Gnosis.sol';
import {AaveV3BNB} from 'aave-address-book/AaveV3BNB.sol';
import {AaveV3Scroll} from 'aave-address-book/AaveV3Scroll.sol';
import {AaveV3PolygonZkEvm} from 'aave-address-book/AaveV3PolygonZkEvm.sol';
import {ITransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/interfaces/ITransparentProxyFactory.sol';
import {V3RateStrategyFactory} from '../src/v3-config-engine/V3RateStrategyFactory.sol';

library DeployRatesFactoryLib {
  // TODO check also by param, potentially there could be different contracts, but with exactly same params
  function _getUniqueStrategiesOnPool(
    IPool pool
  ) internal view returns (IDefaultInterestRateStrategy[] memory) {
    address[] memory listedAssets = pool.getReservesList();
    IDefaultInterestRateStrategy[] memory uniqueRateStrategies = new IDefaultInterestRateStrategy[](
      listedAssets.length
    );
    uint256 uniqueRateStrategiesSize;
    for (uint256 i = 0; i < listedAssets.length; i++) {
      address strategy = pool.getReserveData(listedAssets[i]).interestRateStrategyAddress;

      bool found;
      for (uint256 j = 0; j < uniqueRateStrategiesSize; j++) {
        if (strategy == address(uniqueRateStrategies[j])) {
          found = true;
          break;
        }
      }

      if (!found) {
        uniqueRateStrategies[uniqueRateStrategiesSize] = IDefaultInterestRateStrategy(strategy);
        uniqueRateStrategiesSize++;
      }
    }

    // The famous one (modify dynamic array size)
    assembly {
      mstore(uniqueRateStrategies, uniqueRateStrategiesSize)
    }

    return uniqueRateStrategies;
  }

  function _createAndSetupRatesFactory(
    IPoolAddressesProvider addressesProvider,
    address transparentProxyFactory,
    address ownerForFactory
  ) internal returns (address, address[] memory) {
    IDefaultInterestRateStrategy[] memory uniqueStrategies = _getUniqueStrategiesOnPool(
      IPool(addressesProvider.getPool())
    );

    V3RateStrategyFactory ratesFactory = V3RateStrategyFactory(
      ITransparentProxyFactory(transparentProxyFactory).create(
        address(new V3RateStrategyFactory(addressesProvider)),
        ownerForFactory,
        abi.encodeWithSelector(V3RateStrategyFactory.initialize.selector, uniqueStrategies)
      )
    );

    address[] memory strategiesOnFactory = ratesFactory.getAllStrategies();

    return (address(ratesFactory), strategiesOnFactory);
  }
}

library DeployRatesFactoryEthLib {
  function deploy() internal returns (address, address[] memory) {
    return
      DeployRatesFactoryLib._createAndSetupRatesFactory(
        AaveV3Ethereum.POOL_ADDRESSES_PROVIDER,
        MiscEthereum.TRANSPARENT_PROXY_FACTORY,
        MiscEthereum.PROXY_ADMIN
      );
  }
}

library DeployRatesFactoryOptLib {
  function deploy() internal returns (address, address[] memory) {
    return
      DeployRatesFactoryLib._createAndSetupRatesFactory(
        AaveV3Optimism.POOL_ADDRESSES_PROVIDER,
        MiscOptimism.TRANSPARENT_PROXY_FACTORY,
        MiscOptimism.PROXY_ADMIN
      );
  }
}

library DeployRatesFactoryArbLib {
  function deploy() internal returns (address, address[] memory) {
    return
      DeployRatesFactoryLib._createAndSetupRatesFactory(
        AaveV3Arbitrum.POOL_ADDRESSES_PROVIDER,
        MiscArbitrum.TRANSPARENT_PROXY_FACTORY,
        MiscArbitrum.PROXY_ADMIN
      );
  }
}

library DeployRatesFactoryPolLib {
  function deploy() internal returns (address, address[] memory) {
    return
      DeployRatesFactoryLib._createAndSetupRatesFactory(
        AaveV3Polygon.POOL_ADDRESSES_PROVIDER,
        MiscPolygon.TRANSPARENT_PROXY_FACTORY,
        MiscPolygon.PROXY_ADMIN
      );
  }
}

library DeployRatesFactoryAvaLib {
  function deploy() internal returns (address, address[] memory) {
    return
      DeployRatesFactoryLib._createAndSetupRatesFactory(
        AaveV3Avalanche.POOL_ADDRESSES_PROVIDER,
        MiscAvalanche.TRANSPARENT_PROXY_FACTORY,
        MiscAvalanche.PROXY_ADMIN
      );
  }
}

library DeployRatesFactoryMetLib {
  function deploy() internal returns (address, address[] memory) {
    return
      DeployRatesFactoryLib._createAndSetupRatesFactory(
        AaveV3Metis.POOL_ADDRESSES_PROVIDER,
        MiscMetis.TRANSPARENT_PROXY_FACTORY,
        MiscMetis.PROXY_ADMIN
      );
  }
}

library DeployRatesFactoryBasLib {
  function deploy() internal returns (address, address[] memory) {
    return
      DeployRatesFactoryLib._createAndSetupRatesFactory(
        AaveV3Base.POOL_ADDRESSES_PROVIDER,
        MiscBase.TRANSPARENT_PROXY_FACTORY,
        MiscBase.PROXY_ADMIN
      );
  }
}

library DeployRatesFactoryGnoLib {
  function deploy() internal returns (address, address[] memory) {
    return
      DeployRatesFactoryLib._createAndSetupRatesFactory(
        AaveV3Gnosis.POOL_ADDRESSES_PROVIDER,
        MiscGnosis.TRANSPARENT_PROXY_FACTORY,
        MiscGnosis.PROXY_ADMIN
      );
  }
}

library DeployRatesFactoryBnbLib {
  function deploy() internal returns (address, address[] memory) {
    return
      DeployRatesFactoryLib._createAndSetupRatesFactory(
        AaveV3BNB.POOL_ADDRESSES_PROVIDER,
        MiscBNB.TRANSPARENT_PROXY_FACTORY,
        MiscBNB.PROXY_ADMIN
      );
  }
}

library DeployRatesFactoryScrollLib {
  function deploy() internal returns (address, address[] memory) {
    return
      DeployRatesFactoryLib._createAndSetupRatesFactory(
        AaveV3Scroll.POOL_ADDRESSES_PROVIDER,
        MiscScroll.TRANSPARENT_PROXY_FACTORY,
        MiscScroll.PROXY_ADMIN
      );
  }
}

library DeployRatesFactoryZkEvmLib {
  function deploy() internal returns (address, address[] memory) {
    return
      DeployRatesFactoryLib._createAndSetupRatesFactory(
        AaveV3PolygonZkEvm.POOL_ADDRESSES_PROVIDER,
        MiscPolygonZkEvm.TRANSPARENT_PROXY_FACTORY,
        MiscPolygonZkEvm.PROXY_ADMIN
      );
  }
}

contract DeployRatesFactoryEth is EthereumScript {
  function run() external broadcast {
    DeployRatesFactoryEthLib.deploy();
  }
}

contract DeployRatesFactoryOpt is OptimismScript {
  function run() external broadcast {
    DeployRatesFactoryOptLib.deploy();
  }
}

contract DeployRatesFactoryArb is ArbitrumScript {
  function run() external broadcast {
    DeployRatesFactoryArbLib.deploy();
  }
}

contract DeployRatesFactoryPol is PolygonScript {
  function run() external broadcast {
    DeployRatesFactoryPolLib.deploy();
  }
}

contract DeployRatesFactoryAva is AvalancheScript {
  function run() external broadcast {
    DeployRatesFactoryAvaLib.deploy();
  }
}

contract DeployRatesFactoryMet is MetisScript {
  function run() external broadcast {
    DeployRatesFactoryMetLib.deploy();
  }
}

contract DeployRatesFactoryBas is BaseScript {
  function run() external broadcast {
    DeployRatesFactoryBasLib.deploy();
  }
}

contract DeployRatesFactoryGno is GnosisScript {
  function run() external broadcast {
    DeployRatesFactoryGnoLib.deploy();
  }
}

contract DeployRatesFactoryBnb is BNBScript {
  function run() external broadcast {
    DeployRatesFactoryBnbLib.deploy();
  }
}

contract DeployRatesFactoryScroll is ScrollScript {
  function run() external broadcast {
    DeployRatesFactoryScrollLib.deploy();
  }
}

contract DeployRatesFactoryZkEvm is PolygonZkEvmScript {
  function run() external broadcast {
    DeployRatesFactoryZkEvmLib.deploy();
  }
}
