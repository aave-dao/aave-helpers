// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {CommonTestBase, StdDealPatch} from '../src/CommonTestBase.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';

contract CommonTestBaseTest is CommonTestBase {
  function setUp() public {
    vm.createSelectFork('mainnet', 18572478);
  }

  function call() external view returns (address) {
    return msg.sender;
  }

  function test_deal2_shouldMaintainCurrentCaller() public {
    assertEq(this.call(), address(this));
    deal2(AaveV3EthereumAssets.USDC_UNDERLYING, address(this), 100e6);
    assertEq(this.call(), address(this));
  }
}

contract DealMainnetTest is Test {
  function setUp() public {
    vm.createSelectFork('mainnet', 19467834);
  }

  function test_fxs() public {
    StdDealPatch.deal(vm, AaveV3EthereumAssets.FXS_UNDERLYING, address(this), 1e18);
  }

  function test_ldo() public {
    StdDealPatch.deal(vm, AaveV3EthereumAssets.LDO_UNDERLYING, address(this), 1e18);
  }
}
