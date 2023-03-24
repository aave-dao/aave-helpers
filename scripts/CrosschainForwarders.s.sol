// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Utils.s.sol';
import {CrosschainForwarderPolygon} from '../src/crosschainforwarders/CrosschainForwarderPolygon.sol';
import {CrosschainForwarderOptimism} from '../src/crosschainforwarders/CrosschainForwarderOptimism.sol';
import {CrosschainForwarderArbitrum} from '../src/crosschainforwarders/CrosschainForwarderArbitrum.sol';

contract DeployPol is EthereumScript {
  function run() external broadcast {
    new CrosschainForwarderPolygon();
  }
}

contract DeployOpt is EthereumScript {
  function run() external broadcast {
    new CrosschainForwarderOptimism();
  }
}

contract DeployArb is EthereumScript {
  function run() external broadcast {
    new CrosschainForwarderArbitrum();
  }
}
