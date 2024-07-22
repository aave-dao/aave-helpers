// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {AaveWstethWithdrawer} from 'src/asset-manager/AaveWstethWithdrawer.sol';

contract DeployAaveWithdrawer is Script {
  function run() external {
    vm.startBroadcast();

    address aaveWithdrawer = address(new AaveWstethWithdrawer());
    TransparentProxyFactory(MiscEthereum.TRANSPARENT_PROXY_FACTORY).create(
      aaveWithdrawer,
      MiscEthereum.PROXY_ADMIN,
      abi.encodeWithSelector(AaveWstethWithdrawer.initialize.selector)
    );
    
    vm.stopBroadcast();
  }
}
