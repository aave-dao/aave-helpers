// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {ProtocolV3TestBase} from '../ProtocolV3TestBase.sol';
import {AaveV3Polygon} from 'aave-address-book/AaveV3Polygon.sol';

contract ProtocolV3TestBaseTest is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('polygon', 36329200);
  }

  function testSnpashot() public {
    this.createConfigurationSnapshot('pre-x', AaveV3Polygon.POOL);
    // do sth
    // this.createConfigurationSnapshot('post-x', AaveV3Polygon.POOL);

    // requires --ffi
    // diffReports('pre-x', 'post-x');
  }

  // commented out as it is insanely slow with public rpcs
  // function testE2E() public {
  //   address user = address(3);
  //   this.e2eTest(AaveV3Polygon.POOL, user);
  // }
}
