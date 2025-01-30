// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

import {BaseSwapPayload} from '../../src/swaps/BaseSwapPayload.sol';
import {DepositV2SwapPayload} from '../../src/swaps/DepositV2SwapPayload.sol';

contract MyPayload is DepositV2SwapPayload {
  function execute() external {}

  function deposit(address token, uint256 amount) external {
    _deposit(token, amount);
  }
}

contract DepositV2SwapPayloadTest is Test {
  event DepositedIntoV2(address indexed token, uint256 amount);

  DepositV2SwapPayload public payload;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 17779177);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    payload = new MyPayload();
    vm.stopPrank();
  }

  function test_successful() public {
    uint256 amount = 1_000e18;

    deal(AaveV2EthereumAssets.AAVE_UNDERLYING, address(payload), amount);

    uint256 balanceCollectorBefore = IERC20(AaveV2EthereumAssets.AAVE_A_TOKEN).balanceOf(
      address(AaveV2Ethereum.COLLECTOR)
    );

    assertEq(IERC20(AaveV2EthereumAssets.AAVE_UNDERLYING).balanceOf(address(payload)), amount);

    vm.expectEmit();
    emit DepositedIntoV2(AaveV2EthereumAssets.AAVE_UNDERLYING, amount);
    payload.deposit(AaveV2EthereumAssets.AAVE_UNDERLYING, amount);

    assertEq(IERC20(AaveV2EthereumAssets.AAVE_UNDERLYING).balanceOf(address(payload)), 0);
    assertGt(
      IERC20(AaveV2EthereumAssets.AAVE_A_TOKEN).balanceOf(address(AaveV2Ethereum.COLLECTOR)),
      balanceCollectorBefore
    );
  }
}
