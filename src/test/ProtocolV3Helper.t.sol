// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {ProtocolV3TestBase} from '../ProtocolV3TestBase.sol';
import {AaveV3Polygon} from 'aave-address-book/AaveV3Polygon.sol';

contract ProxyHelpersTest is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('polygon', 32519994);
  }

  function testSnpashot() public {
    this.createConfigurationSnapshot('report', AaveV3Polygon.POOL);
  }

  function testE2E() public {
    this.e2eTest(AaveV3Polygon.POOL);
  }
}
