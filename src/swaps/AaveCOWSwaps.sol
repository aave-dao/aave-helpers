// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';
import {Initializable} from 'solidity-utils/contracts/transparent-proxy/Initializable.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';

import {IPriceChecker} from './interfaces/IExpectedOutCalculator.sol';
import {IMilkman} from './interfaces/IMilkman.sol';

contract AaveCOWSwaps is Initializable, OwnableWithGuardian {
  using SafeERC20 for IERC20;

  event SwapCanceled(address fromToken, address toToken, uint256 amount);
  event SwapRequested(address fromToken, address toToken, address fromOracle, address toOracle, uint256 amount, address recipient);

  error Invalid0xAddress();
  error InvalidAmount();
  error InvalidRecipient();
  error OracleNotSet();

  address public constant BAL80WETH20 = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
  address public constant BPT_PRICE_CHECKER = 0xBeA6AAC5bDCe0206A9f909d80a467C93A7D6Da7c;

  address public chainlinkPriceChecker = 0xe80a1C615F75AFF7Ed8F08c9F21f9d00982D666c;
  address public milkman = 0x11C76AD590ABDFFCD980afEC9ad951B160F02797;

  /// @notice Chainlink Oracle address for given token (supports only USD bases)
  mapping(address tokenAddress => address) public tokenChainlinkOracle;

  function initialize() external initializer {
    _transferOwnership(_msgSender());
    _updateGuardian(_msgSender());
  }

  function swap(
    address fromToken,
    address toToken,
    address fromOracle,
    address toOracle,
    address recipient,
    uint256 amount,
    uint256 slippage
  ) external onlyOwner {
    if (fromToken == address(0) || toToken == address(0)) revert Invalid0xAddress();
    if (amount == 0) revert InvalidAmount();

    IERC20(fromToken).forceApprove(milkman, amount);

    (address priceChecker, bytes memory data) = _getPriceCheckerAndData(
        toToken,
      fromOracle,
      toOracle,
      slippage
    );

    IMilkman(milkman).requestSwapExactTokensForTokens(
      amount,
      IERC20(fromToken),
      IERC20(toToken),
      recipient,
      priceChecker,
      data
    );

    emit SwapRequested(fromToken, toToken, fromOracle, toOracle, amount, recipient);
  }

  function cancelSwap(
    address tradeMilkman,
    address fromToken,
    address toToken,
    address fromOracle,
    address toOracle,
    address recipient,
    uint256 amount,
    uint256 slippage
  ) external onlyOwnerOrGuardian {
    (address priceChecker, bytes memory data) = _getPriceCheckerAndData(
      toToken,
      fromOracle,
      toOracle,
      slippage
    );

    IMilkman(tradeMilkman).cancelSwap(
      amount,
      IERC20(fromToken),
      IERC20(toToken),
      recipient,
      priceChecker,
      data
    );

    IERC20(fromToken).safeTransfer(
      address(AaveV3Ethereum.COLLECTOR),
      IERC20(fromToken).balanceOf(address(this))
    );

    emit SwapCanceled(fromToken, toToken, amount);
  }

  function setMilkmanAddress(address _milkman) external onlyOwner {
    if (_milkman == address(0)) revert Invalid0xAddress();
    milkman = _milkman;
  }

  function setChainlinkPriceChecker(address _priceChecker) external onlyOwner {
    if (_priceChecker == address(0)) revert Invalid0xAddress();
    chainlinkPriceChecker = _priceChecker;
  }

  /// @notice Transfer any tokens on this contract to Aave V3 Collector
  /// @param tokens List of token addresses
  function withdrawToCollector(address[] calldata tokens) external onlyOwnerOrGuardian {
    for (uint256 i = 0; i < tokens.length; ++i) {
      IERC20(tokens[i]).safeTransfer(
        address(AaveV3Ethereum.COLLECTOR),
        IERC20(tokens[i]).balanceOf(address(this))
      );
    }
  }

  function getExpectedOut(
    uint256 amount,
    address fromToken,
    address toToken,
    address fromOracle,
    address toOracle
  ) public view returns (uint256) {
    (address priceChecker, bytes memory data) = _getPriceCheckerAndData(toToken, fromOracle, toOracle, 0);

    (, bytes memory _data) = abi.decode(data, (uint256, bytes));

    return
      IPriceChecker(priceChecker).EXPECTED_OUT_CALCULATOR().getExpectedOut(
        amount,
        fromToken,
        toToken,
        _data
      );
  }

  function _getPriceCheckerAndData(
    address toToken,
    address fromOracle,
    address toOracle,
    uint256 slippage
  ) internal view returns (address, bytes memory) {
    if (toToken == BAL80WETH20) {
      return (BPT_PRICE_CHECKER, abi.encode(slippage, ''));
    } else {
      return (
        chainlinkPriceChecker,
        abi.encode(slippage, _getChainlinkCheckerData(fromOracle, toOracle))
      );
    }
  }

  function _getChainlinkCheckerData(
    address fromOracle,
    address toOracle
  ) internal view returns (bytes memory) {
    if (fromOracle == address(0) || toOracle == address(0)) revert OracleNotSet();

    address[] memory paths = new address[](2);
    paths[0] = fromOracle;
    paths[1] = toOracle;

    bool[] memory reverses = new bool[](2);
    reverses[1] = true;

    return abi.encode(paths, reverses);
  }
}
