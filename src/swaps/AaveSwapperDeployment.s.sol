// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from 'forge-std/Script.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';

import {AaveSwapper} from './AaveSwapper.sol';

contract StrategicAssetsManagerPayload is Script {
    address public constant NEW_OWNER = AaveGovernanceV2.SHORT_EXECUTOR;
    address public constant NEW_GUARDIAN = 0xA519a7cE7B24333055781133B13532AEabfAC81b;
  function run() external {
    vm.startBroadcast();

    address aaveSwapper = address(new AaveSwapper());
    address newProxy = TransparentProxyFactory(AaveMisc.TRANSPARENT_PROXY_FACTORY_ETHEREUM).create(
      aaveSwapper,
      AaveMisc.PROXY_ADMIN_ETHEREUM,
      abi.encodeWithSelector(AaveSwapper.initialize.selector)
    );

    AaveSwapper(newProxy).updateGuardian(NEW_GUARDIAN);
    AaveSwapper(newProxy).transferOwnership(NEW_OWNER);

    vm.stopBroadcast();
  }
}
