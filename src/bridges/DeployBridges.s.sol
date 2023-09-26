// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EthereumScript, PolygonScript} from 'src/ScriptUtils.sol';
import {AavePolEthERC20Bridge} from './AavePolEthERC20Bridge.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';

contract DeployEthereum is EthereumScript {
  function run() external broadcast {
    bytes32 salt = 'Aave Treasury Bridge';
    new AavePolEthERC20Bridge{salt: salt}(AaveGovernanceV2.SHORT_EXECUTOR);
  }
}

contract DeployPolygon is PolygonScript {
  function run() external broadcast {
    bytes32 salt = 'Aave Treasury Bridge';
    new AavePolEthERC20Bridge{salt: salt}(AaveGovernanceV2.POLYGON_BRIDGE_EXECUTOR);
  }
}
