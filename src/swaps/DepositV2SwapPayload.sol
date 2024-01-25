// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {AaveV2Ethereum} from 'aave-address-book/AaveV2Ethereum.sol';

import {BaseSwapPayload} from './BaseSwapPayload.sol';

/**
 * @title DepositV2SwapPayload
 * @author Llama
 */
abstract contract DepositV2SwapPayload is BaseSwapPayload {
  using SafeERC20 for IERC20;

  event DepositedIntoV2(address indexed token, uint256 amount);

  function _deposit(address token, uint256 amount) internal override {
    IERC20(token).forceApprove(address(AaveV2Ethereum.POOL), amount);
    AaveV2Ethereum.POOL.deposit(token, amount, address(AaveV2Ethereum.COLLECTOR), 0);
    emit DepositedIntoV2(token, amount);
  }
}
