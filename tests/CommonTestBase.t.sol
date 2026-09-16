// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {CommonTestBase} from '../src/CommonTestBase.sol';
import {AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV3GnosisAssets} from 'aave-address-book/AaveV3Gnosis.sol';

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

contract CommonTestBaseGnosisTest is CommonTestBase {
  function setUp() public {
    vm.createSelectFork('gnosis');
  }

  function test_deal2_EURe() public {
    deal2(AaveV3GnosisAssets.EURe_UNDERLYING, address(this), 100e18);
    assertEq(IERC20(AaveV3GnosisAssets.EURe_UNDERLYING).balanceOf(address(this)), 100e18);
  }
}
