// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
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
