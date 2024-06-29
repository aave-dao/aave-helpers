// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {AaveStethWithdrawer} from 'src/asset-manager/AaveStethWithdrawer.sol';

contract DeployAaveWithdrawer is Script {
  function run() external {
    vm.startBroadcast();

    new AaveStethWithdrawer(0x06610fdEFD2239C828e7114Fc1Ea7EfD9Ae90448);

    vm.stopBroadcast();
  }
}
