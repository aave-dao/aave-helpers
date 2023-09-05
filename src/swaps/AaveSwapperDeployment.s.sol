// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from 'forge-std/Script.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';

import {AaveSwapper} from './AaveSwapper.sol';

contract DeplyAaveSwapper is Script {
  function run() external {
    vm.startBroadcast();

    address aaveSwapper = address(new AaveSwapper());
    TransparentProxyFactory(AaveMisc.TRANSPARENT_PROXY_FACTORY_ETHEREUM).create(
      aaveSwapper,
      AaveMisc.PROXY_ADMIN_ETHEREUM,
      abi.encodeWithSelector(AaveSwapper.initialize.selector)
    );

    vm.stopBroadcast();
  }
}
