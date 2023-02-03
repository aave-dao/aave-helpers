// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {ProtocolV2TestBase} from '../ProtocolV2TestBase.sol';
import {AaveV2Ethereum} from 'aave-address-book/AaveV2Ethereum.sol';

contract ProtocolV2TestBaseTest is ProtocolV2TestBase {
  function setUp() public {
    vm.createSelectFork('mainnet', 16526807);
  }

  function testSnpashot() public {
    this.createConfigurationSnapshot('v2-report', AaveV2Ethereum.POOL);
  }

  // commented out as it is insanely slow with public rpcs
  // function testE2E() public {
  //   address user = address(3);
  //   this.e2eTest(AaveV3Polygon.POOL, user);
  // }
}
