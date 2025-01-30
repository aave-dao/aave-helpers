// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {ITransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/interfaces/ITransparentProxyFactory.sol';
import {AaveSwapper} from 'src/swaps/AaveSwapper.sol';

contract DeployAaveSwapper is Script {
  function run() external {
    vm.startBroadcast();

    address aaveSwapper = address(new AaveSwapper());
    ITransparentProxyFactory(MiscEthereum.TRANSPARENT_PROXY_FACTORY).create(
      aaveSwapper,
      GovernanceV3Ethereum.EXECUTOR_LVL_1,
      abi.encodeWithSelector(AaveSwapper.initialize.selector, GovernanceV3Ethereum.EXECUTOR_LVL_1)
    );

    vm.stopBroadcast();
  }
}
