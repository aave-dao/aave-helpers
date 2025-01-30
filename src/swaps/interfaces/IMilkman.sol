// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

interface IMilkman {
  /// @notice Asynchronously swap an exact amount of tokenIn for a market-determined amount of tokenOut.
  /// @dev Swaps are usually completed in ~2 minutes.
  /// @param amountIn The number of tokens to sell.
  /// @param fromToken The token that the user wishes to sell.
  /// @param toToken The token that the user wishes to receive.
  /// @param to Who should receive the tokens.
  /// @param appData The app data to be used in the CoW Protocol order.
  /// @param priceChecker A contract that verifies an order (mainly its minOut and fee) before Milkman signs it.
  /// @param priceCheckerData Data that gets passed to the price checker.
  function requestSwapExactTokensForTokens(
    uint256 amountIn,
    IERC20 fromToken,
    IERC20 toToken,
    address to,
    bytes32 appData,
    address priceChecker,
    bytes calldata priceCheckerData
  ) external;

  /// @notice Cancel a requested swap, sending the tokens back to the order creator.
  /// @dev `msg.sender` must be the original order creator. The other parameters are required to verify that this is the case (kind of like a merkle proof).
  function cancelSwap(
    uint256 amountIn,
    IERC20 fromToken,
    IERC20 toToken,
    address to,
    bytes32 appData,
    address priceChecker,
    bytes calldata priceCheckerData
  ) external;
}
