// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';

import {AaveSwapper} from 'src/swaps/AaveSwapper.sol';

contract DeployAaveSwapper is Script {
  function run() external {
    vm.startBroadcast();

    address aaveSwapper = address(new AaveSwapper());
    TransparentProxyFactory(MiscEthereum.TRANSPARENT_PROXY_FACTORY).create(
      aaveSwapper,
      MiscEthereum.PROXY_ADMIN,
      abi.encodeWithSelector(AaveSwapper.initialize.selector)
    );

    vm.stopBroadcast();
  }
}
