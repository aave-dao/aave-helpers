// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {CommonTestBase} from '../../src/CommonTestBase.sol';

import {BaseSwapPayload} from '../../src/swaps/BaseSwapPayload.sol';
import {DepositV3SwapPayload} from '../../src/swaps/DepositV3SwapPayload.sol';

contract MyPayload is DepositV3SwapPayload {
  function execute() external {}

  function deposit(address token, uint256 amount) external {
    _deposit(token, amount);
  }
}

contract DepositV3SwapPayloadTest is CommonTestBase {
  event DepositedIntoV3(address indexed token, uint256 amount);

  DepositV3SwapPayload public payload;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 19036383);

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    payload = new MyPayload();
    vm.stopPrank();
  }

  function test_successful() public {
    uint256 amount = 1_000e18;

    deal2(AaveV3EthereumAssets.AAVE_UNDERLYING, address(payload), amount);

    uint256 balanceCollectorBefore = IERC20(AaveV3EthereumAssets.AAVE_A_TOKEN).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    assertEq(IERC20(AaveV3EthereumAssets.AAVE_UNDERLYING).balanceOf(address(payload)), amount);

    vm.expectEmit();
    emit DepositedIntoV3(AaveV3EthereumAssets.AAVE_UNDERLYING, amount);
    payload.deposit(AaveV3EthereumAssets.AAVE_UNDERLYING, amount);

    assertEq(IERC20(AaveV3EthereumAssets.AAVE_UNDERLYING).balanceOf(address(payload)), 0);
    assertGt(
      IERC20(AaveV3EthereumAssets.AAVE_A_TOKEN).balanceOf(address(AaveV3Ethereum.COLLECTOR)),
      balanceCollectorBefore
    );
  }
}
