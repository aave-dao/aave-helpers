// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {AaveV3Arbitrum} from 'aave-address-book/AaveV3Arbitrum.sol';
import {AaveV3Avalanche} from 'aave-address-book/AaveV3Avalanche.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3Plasma} from 'aave-address-book/AaveV3Plasma.sol';
import {AaveV3XLayer} from 'aave-address-book/AaveV3XLayer.sol';
import {GhoArbitrum} from 'aave-address-book/GhoArbitrum.sol';
import {GhoAvalanche} from 'aave-address-book/GhoAvalanche.sol';
import {GhoEthereum} from 'aave-address-book/GhoEthereum.sol';
import {GhoPlasma} from 'aave-address-book/GhoPlasma.sol';
import {GhoXLayer} from 'aave-address-book/GhoXLayer.sol';
import {GovernanceV3Arbitrum} from 'aave-address-book/GovernanceV3Arbitrum.sol';
import {GovernanceV3Avalanche} from 'aave-address-book/GovernanceV3Avalanche.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {GovernanceV3Plasma} from 'aave-address-book/GovernanceV3Plasma.sol';
import {GovernanceV3XLayer} from 'aave-address-book/GovernanceV3XLayer.sol';
import {ArbitrumScript, AvalancheScript, EthereumScript, PlasmaScript, XLayerScript} from 'solidity-utils/contracts/utils/ScriptUtils.sol';
import {ITokenPool} from 'src/dependencies/chainlink/interfaces/ITokenPool.sol';
import {AaveGhoCcipBridge} from 'src/bridges/ccip/AaveGhoCcipBridge.sol';

/**
 * @dev Deploys a new instance of the AaveGhoCcipBridge with the deployer as initial owner, sets Ethereum mainnet
 * as destination chain (pointing to the mainnet AaveGhoCcipBridge) and transfers the ownership to EXECUTOR_LVL_1.
 */
library CcipBridgeDeployerLib {
  uint32 internal constant GAS_LIMIT = 450_000;

  // https://docs.chain.link/ace/supported-networks#mainnet-networks
  uint64 internal constant MAINNET_CHAIN_SELECTOR = 5009297550715157269;

  // https://etherscan.io/address/0x7F2f96fcdC3A29Be75938d2aC3D92E7006919fe6
  address internal constant MAINNET_BRIDGE = 0x7F2f96fcdC3A29Be75938d2aC3D92E7006919fe6;

  function deploy(
    address router,
    address gho,
    address collector,
    address deployer,
    address executor
  ) internal returns (AaveGhoCcipBridge bridge) {
    bridge = new AaveGhoCcipBridge(router, gho, collector, deployer);

    bridge.setDestinationChain(MAINNET_CHAIN_SELECTOR, abi.encode(MAINNET_BRIDGE), '', GAS_LIMIT);

    bridge.transferOwnership(executor);
  }
}

/// @dev Mainnet can't target itself, so no destination is set here.
contract DeployEthereum is EthereumScript {
  function run() external broadcast {
    (, address deployer, ) = vm.readCallers();
    AaveGhoCcipBridge bridge = new AaveGhoCcipBridge(
      ITokenPool(GhoEthereum.GHO_CCIP_TOKEN_POOL).getRouter(),
      GhoEthereum.GHO_TOKEN,
      address(AaveV3Ethereum.COLLECTOR),
      deployer
    );
    bridge.transferOwnership(GovernanceV3Ethereum.EXECUTOR_LVL_1);
  }
}

contract DeployArbitrum is ArbitrumScript {
  function run() external broadcast {
    (, address deployer, ) = vm.readCallers();
    CcipBridgeDeployerLib.deploy(
      ITokenPool(GhoArbitrum.GHO_CCIP_TOKEN_POOL).getRouter(),
      GhoArbitrum.GHO_TOKEN,
      address(AaveV3Arbitrum.COLLECTOR),
      deployer,
      GovernanceV3Arbitrum.EXECUTOR_LVL_1
    );
  }
}

contract DeployAvalanche is AvalancheScript {
  function run() external broadcast {
    (, address deployer, ) = vm.readCallers();
    CcipBridgeDeployerLib.deploy(
      ITokenPool(GhoAvalanche.GHO_CCIP_TOKEN_POOL).getRouter(),
      GhoAvalanche.GHO_TOKEN,
      address(AaveV3Avalanche.COLLECTOR),
      deployer,
      GovernanceV3Avalanche.EXECUTOR_LVL_1
    );
  }
}

contract DeployPlasma is PlasmaScript {
  function run() external broadcast {
    (, address deployer, ) = vm.readCallers();
    CcipBridgeDeployerLib.deploy(
      ITokenPool(GhoPlasma.GHO_CCIP_TOKEN_POOL).getRouter(),
      GhoPlasma.GHO_TOKEN,
      address(AaveV3Plasma.COLLECTOR),
      deployer,
      GovernanceV3Plasma.EXECUTOR_LVL_1
    );
  }
}

contract DeployXLayer is XLayerScript {
  function run() external broadcast {
    (, address deployer, ) = vm.readCallers();
    CcipBridgeDeployerLib.deploy(
      ITokenPool(GhoXLayer.GHO_CCIP_TOKEN_POOL).getRouter(),
      GhoXLayer.GHO_TOKEN,
      address(AaveV3XLayer.COLLECTOR),
      deployer,
      GovernanceV3XLayer.EXECUTOR_LVL_1
    );
  }
}
