// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {Rescuable} from 'solidity-utils/contracts/utils/Rescuable.sol';
import {RescuableBase, IRescuableBase} from 'solidity-utils/contracts/utils/RescuableBase.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {ChainIds} from 'solidity-utils/contracts/utils/ChainHelpers.sol';

import {IAavePolEthPlasmaBridge} from './IAavePolEthPlasmaBridge.sol';

interface IERC20Polygon {
  /// @param account Address of the account to query
  function balanceOf(address account) external view returns (uint256);

  /// @param to The adress to send tokens to
  /// @param amount The amount of tokens to transfer
  function transfer(address to, uint256 amount) external returns (bool);

  /// @dev First step in bridging tokens
  /// @param amount The amount of tokens to withdraw (bridge)
  function withdraw(uint256 amount) external payable;
}

interface IERC20PredicateBurnOnly {
  /// @dev Function needs to be called in order to confirm a withdrawal
  /// @param data The generated proof to confirm a withdrawal transaction
  function startExitWithBurntTokens(bytes calldata data) external;
}

interface IWithdrawManager {
  /// @dev Last step in exiting a token bridge
  /// @param _token Address of the token being withdrawn
  function processExits(address _token) external;

  /// @dev Last step in exiting a multi-token bridge
  /// @param _tokens Array of token addresses being withdrawn
  function processExitsBatch(address[] calldata _tokens) external;
}

/// @title AavePolEthPlasmaBridge
/// @author efecarranza.eth
/// @notice Helper contract to bridge assets from Polygon to Ethereum
contract AavePolEthPlasmaBridge is Ownable, Rescuable, IAavePolEthPlasmaBridge {
  using SafeERC20 for IERC20;

  /// @inheritdoc IAavePolEthPlasmaBridge
  address public constant ERC20_PREDICATE_BURN = 0x158d5fa3Ef8e4dDA8a5367deCF76b94E7efFCe95;

  /// @inheritdoc IAavePolEthPlasmaBridge
  address public constant WITHDRAW_MANAGER = 0x2A88696e0fFA76bAA1338F2C74497cC013495922;

  /// @inheritdoc IAavePolEthPlasmaBridge
  address public constant MATIC_MAINNET = 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0;

  /// @inheritdoc IAavePolEthPlasmaBridge
  address public constant MATIC_POLYGON = 0x0000000000000000000000000000000000001010;

  /// @param _owner The owner of the contract upon deployment
  constructor(address _owner) {
    _transferOwnership(_owner);
  }

  /// @inheritdoc IAavePolEthPlasmaBridge
  function bridge(uint256 amount) external onlyOwner {
    if (block.chainid != ChainIds.POLYGON) revert InvalidChain();

    IERC20Polygon(MATIC_POLYGON).withdraw{value: amount}(amount);
    emit Bridge(MATIC_POLYGON, amount);
  }

  /// @inheritdoc IAavePolEthPlasmaBridge
  function confirmExit(bytes calldata burnProof) external {
    if (block.chainid != ChainIds.MAINNET) revert InvalidChain();

    IERC20PredicateBurnOnly(ERC20_PREDICATE_BURN).startExitWithBurntTokens(burnProof);
    emit ConfirmExit(burnProof);
  }

  /// @inheritdoc IAavePolEthPlasmaBridge
  function exit() external {
    if (block.chainid != ChainIds.MAINNET) revert InvalidChain();

    IWithdrawManager(WITHDRAW_MANAGER).processExits(MATIC_MAINNET);
    emit Exit(MATIC_MAINNET);
  }

  /// @inheritdoc IAavePolEthPlasmaBridge
  function withdrawToCollector() external {
    if (block.chainid != ChainIds.MAINNET) revert InvalidChain();

    uint256 balance = IERC20(MATIC_MAINNET).balanceOf(address(this));

    IERC20(MATIC_MAINNET).safeTransfer(address(AaveV3Ethereum.COLLECTOR), balance);
    emit WithdrawToCollector(MATIC_MAINNET, balance);
  }

  /// @inheritdoc Rescuable
  function whoCanRescue() public view override returns (address) {
    return owner();
  }

  /// @inheritdoc IRescuableBase
  function maxRescue(
    address erc20Token
  ) public view override(RescuableBase, IRescuableBase) returns (uint256) {
    return type(uint256).max;
  }

  /// @dev Allows the contract to receive Matic on Polygon
  receive() external payable {
    if (block.chainid != ChainIds.POLYGON) revert InvalidChain();
  }
}
