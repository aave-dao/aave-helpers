// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV2Ethereum} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV2EthereumAMM} from 'aave-address-book/AaveV2EthereumAMM.sol';
import {AaveV2Polygon} from 'aave-address-book/AaveV2Polygon.sol';
import {AaveV2Avalanche} from 'aave-address-book/AaveV2Avalanche.sol';
import {AaveV3Optimism} from 'aave-address-book/AaveV3Optimism.sol';
import {AaveV3Arbitrum} from 'aave-address-book/AaveV3Arbitrum.sol';
import {AaveV3Polygon} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveV3Avalanche} from 'aave-address-book/AaveV3Avalanche.sol';
import {ChainIds} from './ChainIds.sol';

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
  constructor() WithChainIdValidation(ChainIds.MAINNET) {}
}

abstract contract OptimismScript is WithChainIdValidation {
  constructor() WithChainIdValidation(ChainIds.OPTIMISM) {}
}

abstract contract ArbitrumScript is WithChainIdValidation {
  constructor() WithChainIdValidation(ChainIds.ARBITRUM) {}
}

abstract contract PolygonScript is WithChainIdValidation {
  constructor() WithChainIdValidation(ChainIds.POLYGON) {}
}

abstract contract AvalancheScript is WithChainIdValidation {
  constructor() WithChainIdValidation(ChainIds.AVALANCHE) {}
}

abstract contract FantomScript is WithChainIdValidation {
  constructor() WithChainIdValidation(ChainIds.FANTOM) {}
}

abstract contract HarmonyScript is WithChainIdValidation {
  constructor() WithChainIdValidation(ChainIds.HARMONY) {}
}

abstract contract MetisScript is WithChainIdValidation {
  constructor() WithChainIdValidation(ChainIds.METIS) {}
}
