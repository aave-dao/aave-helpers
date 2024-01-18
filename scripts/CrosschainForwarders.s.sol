// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../src/ScriptUtils.sol';
import {CrosschainForwarderPolygon} from '../src/crosschainforwarders/CrosschainForwarderPolygon.sol';
import {CrosschainForwarderOptimism} from '../src/crosschainforwarders/CrosschainForwarderOptimism.sol';
import {CrosschainForwarderArbitrum} from '../src/crosschainforwarders/CrosschainForwarderArbitrum.sol';
import {CrosschainForwarderMetis} from '../src/crosschainforwarders/CrosschainForwarderMetis.sol';

import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';

contract DeployPol is EthereumScript {
  function run() external broadcast {
    new CrosschainForwarderPolygon(AaveGovernanceV2.POLYGON_BRIDGE_EXECUTOR);
  }
}

contract DeployOpt is EthereumScript {
  function run() external broadcast {
    new CrosschainForwarderOptimism(AaveGovernanceV2.OPTIMISM_BRIDGE_EXECUTOR);
  }
}

contract DeployArb is EthereumScript {
  function run() external broadcast {
    new CrosschainForwarderArbitrum(AaveGovernanceV2.ARBITRUM_BRIDGE_EXECUTOR);
  }
}

contract DeployMet is EthereumScript {
  function run() external broadcast {
    new CrosschainForwarderMetis(AaveGovernanceV2.METIS_BRIDGE_EXECUTOR);
  }
}
