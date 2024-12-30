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
  AaveSwapper public immutable SWAPPER;

  /// @inheritdoc ISwapSteward
  ICollector public immutable COLLECTOR;

  /// @inheritdoc ISwapSteward
  address public MILKMAN;

  /// @inheritdoc ISwapSteward
  address public PRICE_CHECKER;

  /// @inheritdoc ISwapSteward
  mapping(address token => bool isApproved) public swapApprovedToken;

  /// @inheritdoc ISwapSteward
  mapping(address token => address oracle) public priceOracle;

  constructor(address _owner, address _guardian, address collector) {
    _transferOwnership(_owner);
    _updateGuardian(_guardian);

    COLLECTOR = ICollector(collector);
    SWAPPER = AaveSwapper(MiscEthereum.AAVE_SWAPPER);

    // https://etherscan.io/address/0x060373D064d0168931dE2AB8DDA7410923d06E88
    _setMilkman(0x060373D064d0168931dE2AB8DDA7410923d06E88);

    // https://etherscan.io/address/0xe80a1C615F75AFF7Ed8F08c9F21f9d00982D666c
    _setPriceChecker(0xe80a1C615F75AFF7Ed8F08c9F21f9d00982D666c);
  }

  /// @inheritdoc ISwapSteward
  function tokenSwap(
    address sellToken,
    uint256 amount,
    address buyToken,
    uint256 slippage
  ) external onlyOwnerOrGuardian {
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
    if (AggregatorInterface(priceFeedUSD).decimals() != 8) revert PriceFeedIncompatibility();
    if (AggregatorInterface(priceFeedUSD).latestAnswer() == 0) revert PriceFeedIncompatibility();

    emit SwapApprovedToken(token, priceFeedUSD);
  }

  /// @inheritdoc ISwapSteward
  function setPriceChecker(address newPriceChecker) external onlyOwner {
    _setPriceChecker(newPriceChecker);
  }

  /// @inheritdoc ISwapSteward
  function setMilkman(address newMilkman) external onlyOwner {
    _setMilkman(newMilkman);
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
