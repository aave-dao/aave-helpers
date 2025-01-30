// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {GovernanceV3Optimism} from 'aave-address-book/GovernanceV3Optimism.sol';
import {GovernanceV3Polygon} from 'aave-address-book/GovernanceV3Polygon.sol';
import {ArbitrumScript, EthereumScript, OptimismScript, PolygonScript} from 'solidity-utils/contracts/utils/ScriptUtils.sol';
import {AaveArbEthERC20Bridge} from 'src/bridges/arbitrum/AaveArbEthERC20Bridge.sol';
import {AavePolEthERC20Bridge} from 'src/bridges/polygon/AavePolEthERC20Bridge.sol';
import {AavePolEthPlasmaBridge} from 'src/bridges/polygon/AavePolEthPlasmaBridge.sol';
import {AaveOpEthERC20Bridge} from 'src/bridges/optimism/AaveOpEthERC20Bridge.sol';

contract DeployEthereum is EthereumScript {
  function run() external broadcast {
    bytes32 salt = 'Aave Treasury Bridge';
    new AavePolEthERC20Bridge{salt: salt}(GovernanceV3Ethereum.EXECUTOR_LVL_1);
  }
}

contract DeployPolygon is PolygonScript {
  function run() external broadcast {
    bytes32 salt = 'Aave Treasury Bridge';
    new AavePolEthERC20Bridge{salt: salt}(GovernanceV3Polygon.EXECUTOR_LVL_1);
  }
}

contract DeployPlasmaEthereum is EthereumScript {
  function run() external broadcast {
    bytes32 salt = 'Aave Treasury Plasma Bridge';
    new AavePolEthPlasmaBridge{salt: salt}(0x3765A685a401622C060E5D700D9ad89413363a91);
  }
}

contract DeployPlasmaPolygon is PolygonScript {
  function run() external broadcast {
    bytes32 salt = 'Aave Treasury Plasma Bridge';
    new AavePolEthPlasmaBridge{salt: salt}(0x3765A685a401622C060E5D700D9ad89413363a91);
  }
}

contract DeployOptimism is OptimismScript {
  function run() external broadcast {
    bytes32 salt = 'Aave Treasury Optimism Bridge';
    new AaveOpEthERC20Bridge{salt: salt}(0x3765A685a401622C060E5D700D9ad89413363a91);
  }
}

contract DeployArbBridgeEthereum is EthereumScript {
  function run() external broadcast {
    bytes32 salt = 'Aave Treasury Bridge';
    new AaveArbEthERC20Bridge{salt: salt}(0x3765A685a401622C060E5D700D9ad89413363a91);
  }
}

contract DeployArbBridgeArbitrum is ArbitrumScript {
  function run() external broadcast {
    bytes32 salt = 'Aave Treasury Bridge';
    new AaveArbEthERC20Bridge{salt: salt}(0x3765A685a401622C060E5D700D9ad89413363a91);
  }
}
