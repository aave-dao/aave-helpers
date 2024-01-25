// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {AaveV2Ethereum} from 'aave-address-book/AaveV2Ethereum.sol';

import {ISwapPayload} from './interfaces/ISwapPayload.sol';

/**
 * @title BaseSwapPayload
 * @author Llama
 */
abstract contract BaseSwapPayload is ISwapPayload {
  using SafeERC20 for IERC20;

  /*
   * When going through the governance flow, address(this) will be the Executor.
   * Setting a SELF variable in order to set the payload address as the receiver
   * in case funds are to be deposited later on.
   */
  address internal immutable SELF;

  constructor() {
    SELF = address(this);
  }

  function _deposit(address token, uint256 amount) internal virtual {
    IERC20(token).safeTransfer(address(AaveV2Ethereum.COLLECTOR), amount);
  }
}
