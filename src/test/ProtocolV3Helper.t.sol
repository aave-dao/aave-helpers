// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {ProtocolV3Helper} from '../ProtocolV3Helper.sol';

contract ProxyHelpersTest is ProtocolV3Helper {
  function setUp() public {
    vm.createSelectFork('polygon', 32519994);
  }

  function testSnpashot() public {
    this.createConfigurationSnapshot('bla', 0x794a61358D6845594F94dc1DB02A252b5b4814aD);
  }
}
