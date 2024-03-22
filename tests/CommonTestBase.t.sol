// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {CommonTestBase} from '../src/CommonTestBase.sol';
import {AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';

contract CommonTestBaseTest is CommonTestBase {
  function setUp() public {
    vm.createSelectFork('mainnet', 18572478);
  }

  function call() external view returns (address) {
    return msg.sender;
  }

  function test_deal2_shouldMaintainCurrentCaller() public {
    assertEq(this.call(), address(this));
    deal2(AaveV2EthereumAssets.USDC_UNDERLYING, address(this), 100e6);
    assertEq(this.call(), address(this));
  }
}
