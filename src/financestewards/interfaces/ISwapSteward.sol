// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICollector} from '../../CollectorUtils.sol';
import {IPoolV3FinSteward} from './IPoolV3FinSteward.sol';
import {AaveSwapper} from 'src/swaps/AaveSwapper.sol';

interface ISwapSteward {
  /// @dev Slippage is too high
  error InvalidSlippage();

  /// @dev Provided address cannot be the zero-address
  error InvalidZeroAddress();

  /// @dev Amount cannot be zero
  error InvalidZeroAmount();

  /// @dev Oracle cannot be the zero-address
  error MissingPriceFeed();

  /// @dev Oracle did not return a valid value
  error PriceFeedFailure();

  /// @dev Token has not been previously approved for swapping
  error UnrecognizedToken();

  /// @notice Emitted when the Milkman contract address is updated
  /// @param oldAddress The old Milkman instance address
  /// @param newAddress The new Milkman instance address
  event MilkmanAddressUpdated(address oldAddress, address newAddress);

  /// @notice Emitted when the PoolV3Steward contract address is updated
  /// @param oldAddress The old PoolV3Steward instance address
  /// @param newAddress The new PoolV3Steward instance address
  event PoolV3StewardUpdated(address oldAddress, address newAddress);

  /// @notice Emitted when the Chainlink Price Checker contract address is updated
  /// @param oldAddress The old Price Checker instance address
  /// @param newAddress The new Price Checker instance address
  event PriceCheckerUpdated(address oldAddress, address newAddress);

  /// @notice Emitted when a token is approved for swapping with its corresponding USD oracle
  /// @param token The address of the token approved for swapping
  /// @param oracleUSD The address of the oracle providing the USD price feed for the token
  event SwapApprovedToken(address indexed token, address indexed oracleUSD);

  /// @notice Returns instance of Aave V3 Collector
  function COLLECTOR() external view returns (ICollector);

  /// @notice Returns instance of PoolV3FinSteward
  function POOLV3STEWARD() external view returns (IPoolV3FinSteward);

  /// @notice Returns the maximum allowed slippage for swaps (in BPS)
  function MAX_SLIPPAGE() external view returns (uint256);

  /// @notice Returns instance of the AaveSwapper contract
  function SWAPPER() external view returns (AaveSwapper);

  /// @notice Returns the address of the Milkman contract
  function MILKMAN() external view returns (address);

  /// @notice Returns address of the price checker used for swaps
  function PRICE_CHECKER() external view returns (address);

  /// @notice Returns whether token is approved to be swapped from/to
  /// @param token Address of the token to swap from/to
  function swapApprovedToken(address token) external view returns (bool);

  /// @notice Returns address of the Oracle to use for token swaps
  /// @param token Address of the token to swap
  function priceOracle(address token) external view returns (address);

  /// @notice Withdraws a specified amount of a reserve token from Aave V2 and swaps it for another token
  /// @param reserve The address of the reserve token to withdraw
  /// @param amount The amount of the reserve token to withdraw
  /// @param buyToken The address of the token to buy with the withdrawn reserve token
  /// @param slippage The slippage allowed in the swap
  function withdrawV2andSwap(
    address reserve,
    uint amount,
    address buyToken,
    uint256 slippage
  ) external;

  /// @notice Withdraws a specified amount of a reserve token from Aave V3 and swaps it for another token
  /// @param V3Pool The address of the V3 Pool to withdraw from
  /// @param reserve The address of the reserve token to withdraw
  /// @param amount The amount of the reserve token to withdraw
  /// @param buyToken The address of the token to buy with the withdrawn reserve token
  /// @param slippage The slippage allowed in the swap
  function withdrawV3andSwap(
    address V3Pool,
    address reserve,
    uint amount,
    address buyToken,
    uint256 slippage
  ) external;

  /// @notice Swaps a specified amount of a sell token for a buy token
  /// @param sellToken The address of the token to sell
  /// @param amount The amount of the sell token to swap
  /// @param buyToken The address of the token to buy
  /// @param slippage The slippage allowed in the swap
  function tokenSwap(
    address sellToken,
    uint256 amount,
    address buyToken,
    uint256 slippage
  ) external;

  /// @notice Sets the address for the MILKMAN used in swaps
  /// @param to The address of MILKMAN
  function setMilkman(address to) external;

  /// @notice Sets the address for the Price checker used in swaps
  /// @param to The address of PRICE_CHECKER
  function setPriceChecker(address to) external;

  /// @notice Sets a token as swappable and provides its price feed address
  /// @param token The address of the token to set as swappable
  /// @param priceFeedUSD The address of the price feed for the token
  function setSwappableToken(address token, address priceFeedUSD) external;
}
