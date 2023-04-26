// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';

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

abstract contract FantomScript is WithChainIdValidation {
  constructor() WithChainIdValidation(250) {}
}

abstract contract HarmonyScript is WithChainIdValidation {
  constructor() WithChainIdValidation(1666600000) {}
}

abstract contract MetisScript is WithChainIdValidation {
  constructor() WithChainIdValidation(1088) {}
}
