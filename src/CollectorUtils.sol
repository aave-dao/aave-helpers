// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPool, DataTypes} from 'aave-address-book/AaveV3.sol';
import {ICollector} from 'aave-address-book/common/ICollector.sol';
import {ILendingPool, DataTypes as V2DataTypes} from 'aave-address-book/AaveV2.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';

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

  /* @notice Object with deposit or withdrawal params
   * @param pool Aave V3 or V2 (only in case of withdraw) pool
   * @param underlying ERC20 compatible asset, listed on the corresponding Aave v3 pool
   * @param amount to be withdrawn/deposited
   */
  struct IOInput {
    address pool;
    address underlying;
    uint256 amount;
  }

  /**
   * @notice object with stream parameters
   * @param underlying ERC20 compatible asset
   * @param receiver receiver of the stream
   * @param amount streamed amount in wei
   * @param start of the stream in seconds
   * @param duration duration of the stream in seconds
   */
  struct CreateStreamInput {
    address underlying;
    address receiver;
    uint256 amount;
    uint256 start;
    uint256 duration;
  }

  /**
   * @notice object with stream parameters
   * @param fromUnderlying input asset, ERC20 compatible
   * @param toUnderlying output asset, ERC20 compatible
   * @param fromUnderlyingPriceFeed price feed for the input asset
   * @param toUnderlyingPriceFeed price feed for the output asset
   * @param amount amount of input asset to swap, in wei
   * @param slippage maximal swap slippage, where 100_00 is equal to 100%
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
   * @param collector aave collector
   * @param input deposit parameters wrapped as IOInput
   */
  function depositToV3(ICollector collector, IOInput memory input) internal {
    if (input.amount == 0) {
      revert InvalidZeroAmount();
    }

    if (input.amount == type(uint256).max) {
      input.amount = IERC20(input.underlying).balanceOf(address(collector));
    }
    collector.transfer(input.underlying, address(this), input.amount);
    IERC20(input.underlying).forceApprove(input.pool, input.amount);
    IPool(input.pool).supply(input.underlying, input.amount, address(collector), 0);
  }

  /**
   * @notice Withdraw funds of the collector from the Aave v3 to the receiver
   * @dev due to imprecision may get 1-2 wei less then specified amount
   * @param collector aave collector
   * @param receiver receiver of the underlying
   * @param input withdraw parameters wrapped as IOInput
   */
  function withdrawFromV3(
    ICollector collector,
    IOInput memory input,
    address receiver
  ) internal returns (uint256) {
    DataTypes.ReserveDataLegacy memory reserveData = IPool(input.pool).getReserveData(
      input.underlying
    );
    return __withdraw(collector, input, reserveData.aTokenAddress, receiver);
  }

  /**
   * @notice Withdraw funds of the collector from the Aave v2 to the receiver
   * @dev due to imprecision may get 1-2 wei less then specified amount
   * @param collector aave collector
   * @param receiver receiver of the underlying
   * @param input withdraw parameters wrapped as IOInput
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
   * @param collector aave collector
   * @param input stream creation parameters wrapped as CreateStreamInput
   * @return the actual stream amount
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
   * @param collector aave collector
   * @param swapper AaveSwapper
   * @param input swap parameters wrapped as SwapInput
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

    collector.transfer(input.fromUnderlying, swapper, input.amount);
    uint256 swapperBalance = IERC20(input.fromUnderlying).balanceOf(swapper);

    // some tokens, like stETH, can loose 1-2wei on transfer
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
   * @dev internal template for both v2 and v3
   * @dev due to imprecision may get 1-2 wei less then specified amount
   * @param collector aave collector
   * @param input withdraw parameters wrapped as IOInput
   * @param aTokenAddress aToken address for the corresponding reserve in the pool
   * @param receiver receiver of the underlying
   * @return the actual amount of underlying withdrawn
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

    collector.transfer(aTokenAddress, address(this), input.amount);

    // in case of imprecision during the aTokenTransfer withdraw a bit less
    uint256 balanceAfterTransfer = IERC20(aTokenAddress).balanceOf(address(this));
    input.amount = balanceAfterTransfer >= input.amount ? input.amount : balanceAfterTransfer;

    // @dev withdrawal interfaces of v2 and v3 is the same, so we use any
    return IPool(input.pool).withdraw(input.underlying, input.amount, address(receiver));
  }
}
