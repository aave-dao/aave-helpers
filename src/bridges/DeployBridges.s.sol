// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EthereumScript, PolygonScript} from 'src/ScriptUtils.sol';
import {AavePolEthERC20Bridge} from './AavePolEthERC20Bridge.sol';

contract DeployEthereum is EthereumScript {
  function run() external broadcast {
    bytes32 salt = keccak256(abi.encode(tx.origin, uint256(0)));
    new AavePolEthERC20Bridge{salt: salt}();
  }
}

contract DeployPolygon is PolygonScript {
  function run() external broadcast {
    bytes32 salt = keccak256(abi.encode(tx.origin, uint256(0)));
    new AavePolEthERC20Bridge{salt: salt}();
  }
}
