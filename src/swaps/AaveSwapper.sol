// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {Rescuable} from 'solidity-utils/contracts/utils/Rescuable.sol';
import {RescuableBase, IRescuableBase} from 'solidity-utils/contracts/utils/RescuableBase.sol';
import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';
import {Initializable} from 'solidity-utils/contracts/transparent-proxy/Initializable.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';

import {IPriceChecker} from './interfaces/IExpectedOutCalculator.sol';
import {IMilkman} from './interfaces/IMilkman.sol';

/**
 * @title AaveSwapper
 * @author Llama
 * @notice Helper contract to swap assets using milkman
 */
contract AaveSwapper is Initializable, OwnableWithGuardian, Rescuable {
  using SafeERC20 for IERC20;

  event SwapCanceled(address indexed fromToken, address indexed toToken, uint256 amount);
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

  error Invalid0xAddress();
  error InvalidAmount();
  error InvalidRecipient();
  error OracleNotSet();

  address public constant BAL80WETH20 = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;

  function initialize() external initializer {
    _transferOwnership(AaveGovernanceV2.SHORT_EXECUTOR);
    _updateGuardian(0xA519a7cE7B24333055781133B13532AEabfAC81b);
  }

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
  ) external onlyOwner {
    if (fromToken == address(0) || toToken == address(0)) revert Invalid0xAddress();
    if (recipient == address(0)) revert InvalidRecipient();
    if (amount == 0) revert InvalidAmount();

    IERC20(fromToken).forceApprove(milkman, amount);

    bytes memory data = _getPriceCheckerAndData(toToken, fromOracle, toOracle, slippage);

    IMilkman(milkman).requestSwapExactTokensForTokens(
      amount,
      IERC20(fromToken),
      IERC20(toToken),
      recipient,
      priceChecker,
      data
    );

    emit SwapRequested(
      milkman,
      fromToken,
      toToken,
      fromOracle,
      toOracle,
      amount,
      recipient,
      slippage
    );
  }

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
  ) external onlyOwnerOrGuardian {
    bytes memory data = _getPriceCheckerAndData(toToken, fromOracle, toOracle, slippage);

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

  function getExpectedOut(
    address priceChecker,
    uint256 amount,
    address fromToken,
    address toToken,
    address fromOracle,
    address toOracle
  ) public view returns (uint256) {
    bytes memory data = _getPriceCheckerAndData(toToken, fromOracle, toOracle, 0);

    (, bytes memory _data) = abi.decode(data, (uint256, bytes));

    return
      IPriceChecker(priceChecker).EXPECTED_OUT_CALCULATOR().getExpectedOut(
        amount,
        fromToken,
        toToken,
        _data
      );
  }

  function whoCanRescue() public view override returns (address) {
    return owner();
  }

  /// @inheritdoc IRescuableBase
  function maxRescue(
    address erc20Token
  ) public view override(RescuableBase, IRescuableBase) returns (uint256) {
    return type(uint256).max;
  }

  function _getPriceCheckerAndData(
    address toToken,
    address fromOracle,
    address toOracle,
    uint256 slippage
  ) internal pure returns (bytes memory) {
    if (toToken == BAL80WETH20) {
      return abi.encode(slippage, '');
    } else {
      return abi.encode(slippage, _getChainlinkCheckerData(fromOracle, toOracle));
    }
  }

  function _getChainlinkCheckerData(
    address fromOracle,
    address toOracle
  ) internal pure returns (bytes memory) {
    if (fromOracle == address(0) || toOracle == address(0)) revert OracleNotSet();

    address[] memory paths = new address[](2);
    paths[0] = fromOracle;
    paths[1] = toOracle;

    bool[] memory reverses = new bool[](2);
    reverses[1] = true;

    return abi.encode(paths, reverses);
  }
}
