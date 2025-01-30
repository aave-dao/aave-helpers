// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAaveSwapper {
  /// @dev Emitted when a swap is canceled
  /// @param fromToken The token to swap from
  /// @param toToken The token to swap to
  /// @param amount Amount of fromToken to swap
  event SwapCanceled(address indexed fromToken, address indexed toToken, uint256 amount);

  /// @dev Emitted when a swap is submitted to Cow Swap
  /// @param milkman Address of Milkman (Cow Swap) contract
  /// @param fromToken Address of the token to swap from
  /// @param toToken Address of the token to swap to
  /// @param fromOracle Oracle to use for price validation for fromToken
  /// @param toOracle Oracle to use for price validation for toToken
  /// @param recipient Address receiving the swap
  /// @param amount Amount of fromToken to swap
  /// @param slippage The allowed slippage for the swap
  event SwapRequested(
    address milkman,
    address indexed fromToken,
    address indexed toToken,
    address fromOracle,
    address toOracle,
    uint256 amount,
    address indexed recipient,
    uint256 slippage
  );

  /// @dev Provided address cannot be the zero-address
  error Invalid0xAddress();

  /// @dev Amount has to be greater than zero
  error InvalidAmount();

  /// @dev Recipient cannot be the zero-address
  error InvalidRecipient();

  /// @dev Oracle has not be set
  error OracleNotSet();

  /// @notice Returns the address of the 80-BAL-20-WETH Balancer LP
  function BAL80WETH20() external view returns (address);

  /// @notice Performs a swap via Cow Swap
  /// @param milkman Address of Milkman (Cow Swap) contract
  /// @param priceChecker Address of price checker to use for swap
  /// @param fromToken Address of the token to swap from
  /// @param toToken Address of the token to swap to
  /// @param fromOracle Oracle to use for price validation for fromToken
  /// @param toOracle Oracle to use for price validation for toToken
  /// @param recipient Address receiving the swap
  /// @param amount Amount of fromToken to swap
  /// @param slippage The allowed slippage for the swap
  function swap(
    address milkman,
    address priceChecker,
    address fromToken,
    address toToken,
    address fromOracle,
    address toOracle,
    address recipient,
    uint256 amount,
    uint256 slippage
  ) external;

  /// @notice Canceels a pending swap via Cow Swap
  /// @param tradeMilkman Address of Milkman instance that holds funds in escrow
  /// @param priceChecker Address of price checker to use for swap
  /// @param fromToken Address of the token to swap from
  /// @param toToken Address of the token to swap to
  /// @param fromOracle Oracle to use for price validation for fromToken
  /// @param toOracle Oracle to use for price validation for toToken
  /// @param recipient Address receiving the swap
  /// @param amount Amount of fromToken to swap
  /// @param slippage The allowed slippage for the swap
  function cancelSwap(
    address tradeMilkman,
    address priceChecker,
    address fromToken,
    address toToken,
    address fromOracle,
    address toOracle,
    address recipient,
    uint256 amount,
    uint256 slippage
  ) external;

  /// @notice Returns the expected amount out in token to swap to
  /// @param priceChecker Address of price checker to use for swap
  /// @param amount Amount of fromToken to swap
  /// @param fromToken Address of the token to swap from
  /// @param toToken Address of the token to swap to
  /// @param fromOracle Oracle to use for price validation for fromToken
  /// @param toOracle Oracle to use for price validation for toToken
  function getExpectedOut(
    address priceChecker,
    uint256 amount,
    address fromToken,
    address toToken,
    address fromOracle,
    address toOracle
  ) external view returns (uint256);
}
