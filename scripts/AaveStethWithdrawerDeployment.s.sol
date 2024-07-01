// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {AaveStethWithdrawer} from 'src/asset-manager/AaveStethWithdrawer.sol';

contract DeployAaveWithdrawer is Script {
  function run() external {
    vm.startBroadcast();

    new AaveStethWithdrawer(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    
    vm.stopBroadcast();
  }
}
