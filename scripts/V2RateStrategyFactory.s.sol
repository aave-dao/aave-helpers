// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ILendingPoolAddressesProvider, IDefaultInterestRateStrategy, ILendingPool} from 'aave-address-book/AaveV2.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {MiscPolygon} from 'aave-address-book/MiscPolygon.sol';
import {MiscAvalanche} from 'aave-address-book/MiscAvalanche.sol';
import {AaveV2Ethereum} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV2EthereumAMM} from 'aave-address-book/AaveV2EthereumAMM.sol';
import {AaveV2Polygon} from 'aave-address-book/AaveV2Polygon.sol';
import {AaveV2Avalanche} from 'aave-address-book/AaveV2Avalanche.sol';
import 'solidity-utils/contracts/utils/ScriptUtils.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {ITransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/interfaces/ITransparentProxyFactory.sol';
import {V2RateStrategyFactory} from '../src/v2-config-engine/V2RateStrategyFactory.sol';

library DeployV2RatesFactoryLib {
  function _getUniqueStrategiesOnPool(
    ILendingPool pool
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

      if (!found && _isStandardStrategy(strategy)) {
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
    ILendingPoolAddressesProvider addressesProvider,
    address transparentProxyFactory,
    address ownerForFactory
  ) internal returns (address, address[] memory) {
    IDefaultInterestRateStrategy[] memory uniqueStrategies = _getUniqueStrategiesOnPool(
      ILendingPool(addressesProvider.getLendingPool())
    );

    V2RateStrategyFactory ratesFactory = V2RateStrategyFactory(
      ITransparentProxyFactory(transparentProxyFactory).create(
        address(new V2RateStrategyFactory(addressesProvider)),
        ownerForFactory,
        abi.encodeWithSelector(V2RateStrategyFactory.initialize.selector, uniqueStrategies)
      )
    );

    address[] memory strategiesOnFactory = ratesFactory.getAllStrategies();

    return (address(ratesFactory), strategiesOnFactory);
  }

  // To make sure strategies initialised on the factory respect the standard code
  // We do so by checking if the strategy to initialise matches the standard deployed rates address codehash
  function _isStandardStrategy(address strategy) internal view returns (bool) {
    return (strategy.codehash ==
      0xd7aa7ce390578e74a5e48d4f530f22cbd75db8437fd6a1ae0a983e550483d972); // Current standard codehash deployed from factory
  }
}

library DeployV2RatesFactoryEthLib {
  function deploy() internal returns (address, address[] memory) {
    return
      DeployV2RatesFactoryLib._createAndSetupRatesFactory(
        AaveV2Ethereum.POOL_ADDRESSES_PROVIDER,
        MiscEthereum.TRANSPARENT_PROXY_FACTORY,
        MiscEthereum.PROXY_ADMIN
      );
  }
}

library DeployV2RatesFactoryEthAMMLib {
  function deploy() internal returns (address, address[] memory) {
    return
      DeployV2RatesFactoryLib._createAndSetupRatesFactory(
        AaveV2EthereumAMM.POOL_ADDRESSES_PROVIDER,
        MiscEthereum.TRANSPARENT_PROXY_FACTORY,
        MiscEthereum.PROXY_ADMIN
      );
  }
}

library DeployV2RatesFactoryPolLib {
  function deploy() internal returns (address, address[] memory) {
    return
      DeployV2RatesFactoryLib._createAndSetupRatesFactory(
        AaveV2Polygon.POOL_ADDRESSES_PROVIDER,
        MiscPolygon.TRANSPARENT_PROXY_FACTORY,
        MiscPolygon.PROXY_ADMIN
      );
  }
}

library DeployV2RatesFactoryAvaLib {
  function deploy() internal returns (address, address[] memory) {
    return
      DeployV2RatesFactoryLib._createAndSetupRatesFactory(
        AaveV2Avalanche.POOL_ADDRESSES_PROVIDER,
        MiscAvalanche.TRANSPARENT_PROXY_FACTORY,
        MiscAvalanche.PROXY_ADMIN
      );
  }
}

contract DeployV2RatesFactoryEth is EthereumScript {
  function run() external broadcast {
    DeployV2RatesFactoryEthLib.deploy();
  }
}

contract DeployV2RatesFactoryPol is PolygonScript {
  function run() external broadcast {
    DeployV2RatesFactoryPolLib.deploy();
  }
}

contract DeployV2RatesFactoryEthAMM is EthereumScript {
  function run() external broadcast {
    DeployV2RatesFactoryEthAMMLib.deploy();
  }
}

contract DeployV2RatesFactoryAva is AvalancheScript {
  function run() external broadcast {
    DeployV2RatesFactoryAvaLib.deploy();
  }
}
