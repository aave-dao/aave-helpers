// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {ProxyHelpers} from '../ProxyHelpers.sol';

contract ProxyHelpersTest is Test {
  function setUp() public {
    vm.createSelectFork('mainnet', 15816947);
  }

  function testAdmin() public {
    address admin = ProxyHelpers.getInitializableAdminUpgradeabilityProxyAdmin(
      vm,
      0x41A08648C3766F9F9d85598fF102a08f4ef84F84
    );
    assertEq(admin, AaveGovernanceV2.SHORT_EXECUTOR);
  }

  function testImplementation() public {
    address implementation = ProxyHelpers.getInitializableAdminUpgradeabilityProxyImplementation(
      vm,
      0x41A08648C3766F9F9d85598fF102a08f4ef84F84
    );
    assertEq(implementation, 0xadC74A134082eA85105258407159FBB428a73782);
  }
}
