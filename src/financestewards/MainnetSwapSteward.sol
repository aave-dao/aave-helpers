// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {IPool, DataTypes as DataTypesV3} from 'aave-address-book/AaveV3.sol';
import {ILendingPool, DataTypes as DataTypesV2} from 'aave-address-book/AaveV2.sol';

import {AaveSwapper} from 'src/swaps/AaveSwapper.sol';
import {AggregatorInterface} from 'src/financestewards/AggregatorInterface.sol';
import {ICollector, CollectorUtils as CU} from 'src/CollectorUtils.sol';
import {IPoolV3FinSteward} from 'src/financestewards/interfaces/IPoolV3FinSteward.sol';
import {ISwapSteward} from 'src/financestewards/interfaces/ISwapSteward.sol';

contract MainnetSwapSteward is OwnableWithGuardian, ISwapSteward {
  using DataTypesV2 for DataTypesV2.ReserveData;
  using DataTypesV3 for DataTypesV3.ReserveDataLegacy;
  using CU for CU.SwapInput;

  /// @inheritdoc ISwapSteward
  uint256 public constant MAX_SLIPPAGE = 1000; // 10%

  /// @inheritdoc ISwapSteward
  AaveSwapper public immutable SWAPPER = AaveSwapper(MiscEthereum.AAVE_SWAPPER);

  /// @inheritdoc ISwapSteward
  ICollector public immutable COLLECTOR = AaveV3Ethereum.COLLECTOR;

  /// @inheritdoc ISwapSteward
  IPoolV3FinSteward public POOLV3STEWARD;

  /// @inheritdoc ISwapSteward
  address public MILKMAN;

  /// @inheritdoc ISwapSteward
  address public PRICE_CHECKER;

  /// @inheritdoc ISwapSteward
  mapping(address token => bool isApproved) public swapApprovedToken;

  /// @inheritdoc ISwapSteward
  mapping(address token => address oracle) public priceOracle;

  constructor(address _owner, address _guardian, address _poolV3Steward) {
    _transferOwnership(_owner);
    _updateGuardian(_guardian);

    // https://etherscan.io/address/0x060373D064d0168931dE2AB8DDA7410923d06E88
    _setMilkman(0x060373D064d0168931dE2AB8DDA7410923d06E88);

    // https://etherscan.io/address/0xe80a1C615F75AFF7Ed8F08c9F21f9d00982D666c
    _setPriceChecker(0xe80a1C615F75AFF7Ed8F08c9F21f9d00982D666c);
    _setPoolV3Steward(_poolV3Steward);
  }

  /// @inheritdoc ISwapSteward
  function withdrawV2andSwap(
    address reserve,
    uint256 amount,
    address buyToken,
    uint256 slippage
  ) external onlyOwnerOrGuardian {
    DataTypesV2.ReserveData memory reserveData = POOLV3STEWARD.v2Pool().getReserveData(reserve);

    POOLV3STEWARD.validateAmount(reserveData.aTokenAddress, amount);
    _validateSwap(reserve, amount, buyToken, slippage);

    CU.IOInput memory withdrawData = CU.IOInput(address(POOLV3STEWARD.v2Pool()), reserve, amount);

    uint256 withdrawAmount = CU.withdrawFromV2(COLLECTOR, withdrawData, address(this));

    CU.SwapInput memory swapData = CU.SwapInput(
      MILKMAN,
      PRICE_CHECKER,
      reserve,
      buyToken,
      priceOracle[reserve],
      priceOracle[buyToken],
      withdrawAmount,
      slippage
    );

    CU.swap(COLLECTOR, address(SWAPPER), swapData);
  }

  /// @inheritdoc ISwapSteward
  function withdrawV3andSwap(
    address pool,
    address reserve,
    uint256 amount,
    address buyToken,
    uint256 slippage
  ) external onlyOwnerOrGuardian {
    POOLV3STEWARD.validateV3Pool(pool);

    DataTypesV3.ReserveDataLegacy memory reserveData = IPool(pool).getReserveData(reserve);

    POOLV3STEWARD.validateAmount(reserveData.aTokenAddress, amount);
    _validateSwap(reserve, amount, buyToken, slippage);

    CU.IOInput memory withdrawData = CU.IOInput(pool, reserve, amount);

    uint256 withdrawAmount = CU.withdrawFromV3(COLLECTOR, withdrawData, address(this));

    CU.SwapInput memory swapData = CU.SwapInput(
      MILKMAN,
      PRICE_CHECKER,
      reserve,
      buyToken,
      priceOracle[reserve],
      priceOracle[buyToken],
      withdrawAmount,
      slippage
    );

    CU.swap(COLLECTOR, address(SWAPPER), swapData);
  }

  /// @inheritdoc ISwapSteward
  function tokenSwap(
    address sellToken,
    uint256 amount,
    address buyToken,
    uint256 slippage
  ) external onlyOwnerOrGuardian {
    POOLV3STEWARD.validateAmount(sellToken, amount);
    _validateSwap(sellToken, amount, buyToken, slippage);

    CU.SwapInput memory swapData = CU.SwapInput(
      MILKMAN,
      PRICE_CHECKER,
      sellToken,
      buyToken,
      priceOracle[sellToken],
      priceOracle[buyToken],
      amount,
      slippage
    );

    CU.swap(COLLECTOR, address(SWAPPER), swapData);
  }

  /// @inheritdoc ISwapSteward
  function setSwappableToken(address token, address priceFeedUSD) external onlyOwner {
    if (priceFeedUSD == address(0)) revert MissingPriceFeed();

    swapApprovedToken[token] = true;
    priceOracle[token] = priceFeedUSD;

    // Validate oracle has necessary functions
    AggregatorInterface(priceFeedUSD).decimals();
    AggregatorInterface(priceFeedUSD).latestAnswer();

    emit SwapApprovedToken(token, priceFeedUSD);
  }

  function setPoolV3Steward(address newPoolV3Steward) external onlyOwner {
    _setPoolV3Steward(newPoolV3Steward);
  }

  /// @inheritdoc ISwapSteward
  function setPriceChecker(address newPriceChecker) external onlyOwner {
    _setPriceChecker(newPriceChecker);
  }

  /// @inheritdoc ISwapSteward
  function setMilkman(address newMilkman) external onlyOwner {
    _setMilkman(newMilkman);
  }

  /// @dev Internal function to set the PoolV3FinSteward
  function _setPoolV3Steward(address poolV3Steward) internal {
    if (poolV3Steward == address(0)) revert InvalidZeroAddress();
    address old = address(POOLV3STEWARD);
    POOLV3STEWARD = IPoolV3FinSteward(poolV3Steward);

    emit PoolV3StewardUpdated(old, poolV3Steward);
  }

  /// @dev Internal function to set the price checker
  function _setPriceChecker(address newPriceChecker) internal {
    if (newPriceChecker == address(0)) revert InvalidZeroAddress();
    address old = PRICE_CHECKER;
    PRICE_CHECKER = newPriceChecker;

    emit PriceCheckerUpdated(old, newPriceChecker);
  }

  /// @dev Internal function to set the Milkman instance address
  function _setMilkman(address newMilkman) internal {
    if (newMilkman == address(0)) revert InvalidZeroAddress();
    address old = MILKMAN;
    MILKMAN = newMilkman;

    emit MilkmanAddressUpdated(old, newMilkman);
  }

  /// @dev Internal function to validate a swap's parameters
  function _validateSwap(
    address sellToken,
    uint256 amountIn,
    address buyToken,
    uint256 slippage
  ) internal view {
    if (amountIn == 0) revert InvalidZeroAmount();

    if (!swapApprovedToken[sellToken] || !swapApprovedToken[buyToken]) {
      revert UnrecognizedToken();
    }

    if (slippage > MAX_SLIPPAGE) revert InvalidSlippage();

    if (
      AggregatorInterface(priceOracle[buyToken]).latestAnswer() == 0 ||
      AggregatorInterface(priceOracle[sellToken]).latestAnswer() == 0
    ) {
      revert PriceFeedFailure();
    }
  }
}
