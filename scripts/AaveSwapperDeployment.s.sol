// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {ITransparentProxyFactory, ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/interfaces/ITransparentProxyFactory.sol';

import {AaveSwapper} from 'src/swaps/AaveSwapper.sol';

contract DeployAaveSwapper is Script {
  function run() external {
    vm.startBroadcast();

    address aaveSwapper = address(new AaveSwapper());
    ITransparentProxyFactory(MiscEthereum.TRANSPARENT_PROXY_FACTORY).create(
      aaveSwapper,
      ProxyAdmin(MiscEthereum.PROXY_ADMIN),
      abi.encodeWithSelector(AaveSwapper.initialize.selector)
    );

    vm.stopBroadcast();
  }
}
