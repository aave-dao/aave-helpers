// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Script} from 'forge-std/Script.sol';
import {AaveV3Optimism} from 'aave-address-book/AaveV3Optimism.sol';
import {AaveV3Arbitrum} from 'aave-address-book/AaveV3Arbitrum.sol';
import {AaveV3Polygon} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveV3Avalanche} from 'aave-address-book/AaveV3Avalanche.sol';
import {GenericV3ListingEngine} from '../src/v3-listing-engine/GenericV3ListingEngine.sol';

/**
 * Helper contract to enforce correct chain selection in scripts
 */
abstract contract WithChainIdValidation is Script {
  constructor(uint256 chainId) {
    require(block.chainid == chainId, 'CHAIN_ID_MISMATCH');
  }
}

abstract contract OptimismScript is WithChainIdValidation {
  constructor() WithChainIdValidation(10) {}
}

abstract contract ArbitrumScript is WithChainIdValidation {
  constructor() WithChainIdValidation(42161) {}
}

abstract contract PolygonScript is WithChainIdValidation {
  constructor() WithChainIdValidation(137) {}
}

abstract contract AvalancheScript is WithChainIdValidation {
  constructor() WithChainIdValidation(43114) {}
}

contract DeployListingEngineOpt is OptimismScript {
  function run() external {
    vm.startBroadcast();
    new GenericV3ListingEngine(
      AaveV3Optimism.POOL_CONFIGURATOR,
      AaveV3Optimism.ORACLE,
      AaveV3Optimism.DEFAULT_A_TOKEN_IMPL_REV_1,
      AaveV3Optimism.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1,
      AaveV3Optimism.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1,
      AaveV3Optimism.DEFAULT_INCENTIVES_CONTROLLER,
      AaveV3Optimism.COLLECTOR
    );
    vm.stopBroadcast();
  }
}

contract DeployListingEngineArb is ArbitrumScript {
  function run() external {
    vm.startBroadcast();
    new GenericV3ListingEngine(
      AaveV3Arbitrum.POOL_CONFIGURATOR,
      AaveV3Arbitrum.ORACLE,
      AaveV3Arbitrum.DEFAULT_A_TOKEN_IMPL_REV_1,
      AaveV3Arbitrum.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1,
      AaveV3Arbitrum.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1,
      AaveV3Arbitrum.DEFAULT_INCENTIVES_CONTROLLER,
      AaveV3Arbitrum.COLLECTOR
    );
    vm.stopBroadcast();
  }
}

contract DeployListingEnginePol is PolygonScript {
  function run() external {
    vm.startBroadcast();
    new GenericV3ListingEngine(
      AaveV3Polygon.POOL_CONFIGURATOR,
      AaveV3Polygon.ORACLE,
      AaveV3Polygon.DEFAULT_A_TOKEN_IMPL_REV_1,
      AaveV3Polygon.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1,
      AaveV3Polygon.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1,
      AaveV3Polygon.DEFAULT_INCENTIVES_CONTROLLER,
      AaveV3Polygon.COLLECTOR
    );
    vm.stopBroadcast();
  }
}

contract DeployListingEngineAva is AvalancheScript {
  function run() external {
    vm.startBroadcast();
    new GenericV3ListingEngine(
      AaveV3Avalanche.POOL_CONFIGURATOR,
      AaveV3Avalanche.ORACLE,
      AaveV3Avalanche.DEFAULT_A_TOKEN_IMPL_REV_1,
      AaveV3Avalanche.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1,
      AaveV3Avalanche.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1,
      AaveV3Avalanche.DEFAULT_INCENTIVES_CONTROLLER,
      AaveV3Avalanche.COLLECTOR
    );
    vm.stopBroadcast();
  }
}
