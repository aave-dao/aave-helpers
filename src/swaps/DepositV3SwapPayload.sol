// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';

import {BaseSwapPayload} from './BaseSwapPayload.sol';

/**
 * @title DepositV3SwapPayload
 * @author Llama
 */
abstract contract DepositV3SwapPayload is BaseSwapPayload {
  using SafeERC20 for IERC20;

  event DepositedIntoV3(address indexed token, uint256 amount);

  function _deposit(address token, uint256 amount) internal override {
    IERC20(token).forceApprove(address(AaveV3Ethereum.POOL), amount);
    AaveV3Ethereum.POOL.deposit(token, amount, address(AaveV3Ethereum.COLLECTOR), 0);
    emit DepositedIntoV3(token, amount);
  }
}
