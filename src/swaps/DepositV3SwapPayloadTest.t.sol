// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test} from 'forge-std/Test.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';

import {BaseSwapPayload} from './BaseSwapPayload.sol';
import {DepositV3SwapPayload} from './DepositV3SwapPayload.sol';

contract MyPayload is DepositV3SwapPayload {
  function execute() external {}

  function deposit(address token, uint256 amount) external {
    _deposit(token, amount);
  }
}

contract DepositV3SwapPayloadTest is Test {
  event DepositedIntoV3(address indexed token, uint256 amount);

  DepositV3SwapPayload public payload;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 17779177);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    payload = new MyPayload();
    vm.stopPrank();
  }

  function test_successful() public {
    uint256 amount = 1_000e18;

    deal(AaveV3EthereumAssets.AAVE_UNDERLYING, address(payload), amount);

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
