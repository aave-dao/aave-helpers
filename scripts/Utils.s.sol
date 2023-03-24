// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3Optimism} from 'aave-address-book/AaveV3Optimism.sol';
import {AaveV3Arbitrum} from 'aave-address-book/AaveV3Arbitrum.sol';
import {AaveV3Polygon} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveV3Avalanche} from 'aave-address-book/AaveV3Avalanche.sol';

/**
 * Helper contract to enforce correct chain selection in scripts
 */
abstract contract WithChainIdValidation is Script {
  constructor(uint256 chainId) {
    require(block.chainid == chainId, 'CHAIN_ID_MISMATCH');
  }

  modifier broadcast() {
    vm.startBroadcast();
    _;
    vm.stopBroadcast();
  }
}

abstract contract EthereumScript is WithChainIdValidation {
  constructor() WithChainIdValidation(1) {}
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
