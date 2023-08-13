// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../src/ScriptUtils.sol';
import {IPoolAddressesProvider, IPool, IDefaultInterestRateStrategy} from 'aave-address-book/AaveV3.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3Optimism} from 'aave-address-book/AaveV3Optimism.sol';
import {AaveV3Arbitrum} from 'aave-address-book/AaveV3Arbitrum.sol';
import {AaveV3Polygon} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveV3Avalanche} from 'aave-address-book/AaveV3Avalanche.sol';
import {AaveV3Metis} from 'aave-address-book/AaveV3Metis.sol';
import {AaveV3Base} from 'aave-address-book/AaveV3Base.sol';
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
        AaveMisc.TRANSPARENT_PROXY_FACTORY_ETHEREUM,
        AaveMisc.PROXY_ADMIN_ETHEREUM
      );
  }
}

library DeployRatesFactoryOptLib {
  function deploy() internal returns (address, address[] memory) {
    return
      DeployRatesFactoryLib._createAndSetupRatesFactory(
        AaveV3Optimism.POOL_ADDRESSES_PROVIDER,
        AaveMisc.TRANSPARENT_PROXY_FACTORY_OPTIMISM,
        AaveMisc.PROXY_ADMIN_OPTIMISM
      );
  }
}

library DeployRatesFactoryArbLib {
  function deploy() internal returns (address, address[] memory) {
    return
      DeployRatesFactoryLib._createAndSetupRatesFactory(
        AaveV3Arbitrum.POOL_ADDRESSES_PROVIDER,
        AaveMisc.TRANSPARENT_PROXY_FACTORY_ARBITRUM,
        AaveMisc.PROXY_ADMIN_ARBITRUM
      );
  }
}

library DeployRatesFactoryPolLib {
  function deploy() internal returns (address, address[] memory) {
    return
      DeployRatesFactoryLib._createAndSetupRatesFactory(
        AaveV3Polygon.POOL_ADDRESSES_PROVIDER,
        AaveMisc.TRANSPARENT_PROXY_FACTORY_POLYGON,
        AaveMisc.PROXY_ADMIN_POLYGON
      );
  }
}

library DeployRatesFactoryAvaLib {
  function deploy() internal returns (address, address[] memory) {
    return
      DeployRatesFactoryLib._createAndSetupRatesFactory(
        AaveV3Avalanche.POOL_ADDRESSES_PROVIDER,
        AaveMisc.TRANSPARENT_PROXY_FACTORY_AVALANCHE,
        AaveMisc.PROXY_ADMIN_AVALANCHE
      );
  }
}

library DeployRatesFactoryMetLib {
  function deploy() internal returns (address, address[] memory) {
    return
      DeployRatesFactoryLib._createAndSetupRatesFactory(
        AaveV3Metis.POOL_ADDRESSES_PROVIDER,
        AaveMisc.TRANSPARENT_PROXY_FACTORY_METIS,
        AaveMisc.PROXY_ADMIN_METIS
      );
  }
}

library DeployRatesFactoryBasLib {
  function deploy() internal returns (address, address[] memory) {
    return
      DeployRatesFactoryLib._createAndSetupRatesFactory(
        AaveV3Base.POOL_ADDRESSES_PROVIDER,
        AaveMisc.TRANSPARENT_PROXY_FACTORY_BASE,
        AaveMisc.PROXY_ADMIN_BASE
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
