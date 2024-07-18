// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {AaveStethWithdrawer} from 'src/asset-manager/AaveStethWithdrawer.sol';

contract DeployAaveWithdrawer is Script {
  function run() external {
    vm.startBroadcast();

    address aaveWithdrawer = address(new AaveStethWithdrawer());
    TransparentProxyFactory(MiscEthereum.TRANSPARENT_PROXY_FACTORY).create(
      aaveWithdrawer,
      MiscEthereum.PROXY_ADMIN,
      abi.encodeWithSelector(AaveStethWithdrawer.initialize.selector)
    );
    
    vm.stopBroadcast();
  }
}
