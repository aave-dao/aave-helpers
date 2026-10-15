// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPool, DataTypes, ICollector} from 'aave-address-book/AaveV3.sol';
import {ILendingPool, DataTypes as V2DataTypes} from 'aave-address-book/AaveV2.sol';
import {ITokenizationSpoke} from 'aave-address-book/AaveV4.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';

import {AaveSwapper} from './swaps/AaveSwapper.sol';
import {IChainlinkAggregator} from './interfaces/IChainlinkAggregator.sol';

/**
 * @title CollectorUtils
 * @author BGD Labs
 * @notice Wraps up routine operations of the AaveCollector
 */
library CollectorUtils {
  error InvalidZeroAmount();
  error PriceOracleDecimalsMismatch();

  /**
   * @notice Object with deposit or withdrawal params
   * @param pool The address of the Aave V3 or V2 (only in case of withdraw) pool
   * @param underlying The address of the ERC20 compatible asset, listed on the corresponding Aave pool
   * @param amount The amount to be withdrawn or deposited, type(uint256).max for the full collector balance
   */
  struct IOInput {
    address pool;
    address underlying;
    uint256 amount;
  }

  /**
   * @notice Object with stream parameters
   * @param underlying The address of the ERC20 compatible asset
   * @param receiver The address of the receiver of the stream
   * @param amount The streamed amount in wei
   * @param start The start timestamp of the stream in seconds
   * @param duration The duration of the stream in seconds
   */
  struct CreateStreamInput {
    address underlying;
    address receiver;
    uint256 amount;
    uint256 start;
    uint256 duration;
  }

  /**
   * @notice Object with swap parameters
   * @param milkman The address of the Milkman contract
   * @param priceChecker The address of the Milkman price checker
   * @param fromUnderlying The address of the input asset, ERC20 compatible
   * @param toUnderlying The address of the output asset, ERC20 compatible
   * @param fromUnderlyingPriceFeed The address of the price feed for the input asset
   * @param toUnderlyingPriceFeed The address of the price feed for the output asset
   * @param amount The amount of input asset to swap, in wei
   * @param slippage The maximal swap slippage, where 100_00 is equal to 100%
   */
  struct SwapInput {
    address milkman;
    address priceChecker;
    address fromUnderlying;
    address toUnderlying;
    address fromUnderlyingPriceFeed;
    address toUnderlyingPriceFeed;
    uint256 amount;
    uint256 slippage;
  }
  using SafeERC20 for IERC20;

  /**
   * @notice Deposit funds of the collector to the Aave v3
   * @param collector The address of the Aave collector
   * @param input The deposit parameters wrapped as IOInput
   */
  function depositToV3(ICollector collector, IOInput memory input) internal {
    if (input.amount == 0) {
      revert InvalidZeroAmount();
    }

    if (input.amount == type(uint256).max) {
      input.amount = IERC20(input.underlying).balanceOf(address(collector));
    }
    collector.transfer(IERC20(input.underlying), address(this), input.amount);
    IERC20(input.underlying).forceApprove(input.pool, input.amount);
    IPool(input.pool).supply(input.underlying, input.amount, address(collector), 0);
  }

  /**
   * @notice Deposit funds of the collector to an Aave v4 TokenizationSpoke
   * @dev The underlying is derived from the tokenization spoke, as each TokenizationSpoke tokenizes a single asset
   * @param collector The address of the Aave collector
   * @param tokenizationSpoke The address of the Aave V4 TokenizationSpoke
   * @param amount The amount of underlying to deposit, type(uint256).max for the full collector balance
   * @return The amount of tokenization spoke shares minted to the collector
   */
  function depositToV4(
    ICollector collector,
    address tokenizationSpoke,
    uint256 amount
  ) internal returns (uint256) {
    if (amount == 0) {
      revert InvalidZeroAmount();
    }

    address underlying = ITokenizationSpoke(tokenizationSpoke).asset();
    if (amount == type(uint256).max) {
      amount = IERC20(underlying).balanceOf(address(collector));
    }
    collector.transfer(IERC20(underlying), address(this), amount);
    IERC20(underlying).forceApprove(tokenizationSpoke, amount);
    return ITokenizationSpoke(tokenizationSpoke).deposit(amount, address(collector));
  }

  /**
   * @notice Withdraw funds of the collector from the Aave v3 to the receiver
   * @dev Due to imprecision may get 1-2 wei less than the specified amount
   * @param collector The address of the Aave collector
   * @param receiver The address of the receiver of the underlying
   * @param input The withdrawal parameters wrapped as IOInput, amount type(uint256).max for the full collector balance
   */
  function withdrawFromV3(
    ICollector collector,
    IOInput memory input,
    address receiver
  ) internal returns (uint256) {
    address aTokenAddress = IPool(input.pool).getReserveAToken(input.underlying);
    return __withdraw(collector, input, aTokenAddress, receiver);
  }

  /**
   * @notice Withdraw funds of the collector from an Aave v4 TokenizationSpoke to the receiver
   * @param collector The address of the Aave collector
   * @param tokenizationSpoke The address of the Aave V4 TokenizationSpoke
   * @param amount The amount of underlying to withdraw, type(uint256).max for the max withdrawable by the collector
   * @param receiver The address of the receiver of the underlying
   * @return The actual amount of underlying withdrawn
   */
  function withdrawFromV4(
    ICollector collector,
    address tokenizationSpoke,
    uint256 amount,
    address receiver
  ) internal returns (uint256) {
    if (amount == 0) {
      revert InvalidZeroAmount();
    }

    if (amount == type(uint256).max) {
      amount = ITokenizationSpoke(tokenizationSpoke).maxWithdraw(address(collector));
    }
    uint256 shares = ITokenizationSpoke(tokenizationSpoke).previewWithdraw(amount);
    collector.transfer(IERC20(tokenizationSpoke), address(this), shares);
    ITokenizationSpoke(tokenizationSpoke).withdraw(amount, receiver, address(this));
    return amount;
  }

  /**
   * @notice Withdraw funds of the collector from the Aave v2 to the receiver
   * @dev Due to imprecision may get 1-2 wei less than the specified amount
   * @param collector The address of the Aave collector
   * @param receiver The address of the receiver of the underlying
   * @param input The withdrawal parameters wrapped as IOInput, amount type(uint256).max for the full collector balance
   */
  function withdrawFromV2(
    ICollector collector,
    IOInput memory input,
    address receiver
  ) internal returns (uint256) {
    V2DataTypes.ReserveData memory reserveData = ILendingPool(input.pool).getReserveData(
      input.underlying
    );
    return __withdraw(collector, input, reserveData.aTokenAddress, receiver);
  }

  /**
   * @notice Open a funds stream to the receiver with exact amount after rounding
   * @param collector The address of the Aave collector
   * @param input The stream creation parameters wrapped as CreateStreamInput
   * @return The actual stream amount
   */
  function stream(ICollector collector, CreateStreamInput memory input) internal returns (uint256) {
    if (input.amount == 0) {
      revert InvalidZeroAmount();
    }

    uint256 actualAmount = (input.amount / input.duration) * input.duration;
    collector.createStream(
      input.receiver,
      actualAmount,
      input.underlying,
      input.start,
      input.start + input.duration
    );

    return actualAmount;
  }

  /**
   * @notice Open a swap order on AaveSwapper, to swap collector funds fromUnderlying to toUnderlying
   * @param collector The address of the Aave collector
   * @param swapper The address of the AaveSwapper
   * @param input The swap parameters wrapped as SwapInput
   */
  function swap(ICollector collector, address swapper, SwapInput memory input) internal {
    if (input.amount == 0) {
      revert InvalidZeroAmount();
    }
    if (
      IChainlinkAggregator(input.fromUnderlyingPriceFeed).decimals() !=
      IChainlinkAggregator(input.toUnderlyingPriceFeed).decimals()
    ) {
      revert PriceOracleDecimalsMismatch();
    }

    if (input.amount == type(uint256).max) {
      input.amount = IERC20(input.fromUnderlying).balanceOf(address(collector));
    }

    collector.transfer(IERC20(input.fromUnderlying), swapper, input.amount);
    uint256 swapperBalance = IERC20(input.fromUnderlying).balanceOf(swapper);

    // Some tokens, like stETH, can lose 1-2 wei on transfer
    if (swapperBalance < input.amount) {
      input.amount = swapperBalance;
    }

    AaveSwapper(swapper).swap(
      input.milkman,
      input.priceChecker,
      input.fromUnderlying,
      input.toUnderlying,
      input.fromUnderlyingPriceFeed,
      input.toUnderlyingPriceFeed,
      address(collector),
      input.amount,
      input.slippage
    );
  }

  /**
   * @notice Withdraw funds of the collector from Aave
   * @dev Internal template for both v2 and v3
   * @dev Due to imprecision may get 1-2 wei less than the specified amount
   * @param collector The address of the Aave collector
   * @param input The withdrawal parameters wrapped as IOInput
   * @param aTokenAddress The address of the aToken for the corresponding reserve in the pool
   * @param receiver The address of the receiver of the underlying
   * @return The actual amount of underlying withdrawn
   */
  function __withdraw(
    ICollector collector,
    IOInput memory input,
    address aTokenAddress,
    address receiver
  ) internal returns (uint256) {
    if (input.amount == 0) {
      revert InvalidZeroAmount();
    }

    if (input.amount == type(uint256).max) {
      input.amount = IERC20(aTokenAddress).balanceOf(address(collector));
    }
    uint256 balanceBeforeTransfer = IERC20(aTokenAddress).balanceOf(address(this));

    collector.transfer(IERC20(aTokenAddress), address(this), input.amount);

    uint256 balanceAfterTransfer = IERC20(aTokenAddress).balanceOf(address(this));
    input.amount = balanceAfterTransfer - balanceBeforeTransfer;

    // Withdrawal interfaces of v2 and v3 are the same, so we use either
    return IPool(input.pool).withdraw(input.underlying, input.amount, address(receiver));
  }
}
