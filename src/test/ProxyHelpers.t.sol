// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {ProxyHelpers} from '../ProxyHelpers.sol';
import {GovHelpers} from '../GovHelpers.sol';

contract ProxyHelpersTest is Test {
  function setUp() public {
    vm.createSelectFork('ethereum', 15446410);
  }

  function testAdmin() public {
    address admin = ProxyHelpers.getInitializableAdminUpgradeabilityProxyAdmin(
      vm,
      0x41A08648C3766F9F9d85598fF102a08f4ef84F84
    );
    assertEq(admin, GovHelpers.LONG_EXECUTOR);
  }
}
