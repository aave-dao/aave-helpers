// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {Rescuable} from 'solidity-utils/contracts/utils/Rescuable.sol';
import {RescuableBase, IRescuableBase} from 'solidity-utils/contracts/utils/RescuableBase.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {ChainIds} from 'solidity-utils/contracts/utils/ChainHelpers.sol';

import {IAaveArbEthERC20Bridge} from './IAaveArbEthERC20Bridge.sol';

/// @notice The L1 Outbox to exit a bridge transaction on Mainnet
interface IL1Outbox {
  /// @notice Executes a transaction by providing a generated proof
  /// @param proof The proof to exit with
  /// @param index The index of the transaction in the block
  /// @param l2sender The executor of the L2 transaction
  /// @param to The L1 gateway address that the L2 transaction was sent to
  /// @param l2block The L2 block where the transaction took place
  /// @param l1block The L1 block where the transaction took place
  /// @param l2timestamp The L2 timestamp when the transaction took place
  /// @param value The value sent with the transaction
  /// @param data Any extra data sent with the transaction
  function executeTransaction(
    bytes32[] calldata proof,
    uint256 index,
    address l2sender,
    address to,
    uint256 l2block,
    uint256 l1block,
    uint256 l2timestamp,
    uint256 value,
    bytes calldata data
  ) external;
}

/// @notice L2 Gateway to initiate bridge
interface IL2Gateway {
  /// @notice Executes a burn transaction to initiate a bridge
  /// @param tokenAddress The L11 address of the token to burn
  /// @param recipient Receiver of the bridged tokens
  /// @param amount The amount of tokens to bridge
  /// @param data Any extra data to include in the burn transaction
  function outboundTransfer(
    address tokenAddress,
    address recipient,
    uint256 amount,
    bytes calldata data
  ) external;
}

/// @author efecarranza.eth
/// @notice Contract to bridge ERC20 tokens from Arbitrum to Mainnet
contract AaveArbEthERC20Bridge is Ownable, Rescuable, IAaveArbEthERC20Bridge {
  using SafeERC20 for IERC20;

  /// @inheritdoc IAaveArbEthERC20Bridge
  address public constant MAINNET_OUTBOX = 0x0B9857ae2D4A3DBe74ffE1d7DF045bb7F96E4840;

  /// @param _owner The owner of the contract upon deployment
  constructor(address _owner) {
    _transferOwnership(_owner);
  }

  /// @inheritdoc IAaveArbEthERC20Bridge
  function bridge(
    address token,
    address l1Token,
    address gateway,
    uint256 amount
  ) external onlyOwner {
    if (block.chainid != ChainIds.ARBITRUM) revert InvalidChain();

    IERC20(token).forceApprove(gateway, amount);

    IL2Gateway(gateway).outboundTransfer(l1Token, address(AaveV3Ethereum.COLLECTOR), amount, '');

    emit Bridge(token, amount);
  }

  /// @inheritdoc IAaveArbEthERC20Bridge
  function exit(
    bytes32[] calldata proof,
    uint256 index,
    address l2sender,
    address destinationGateway,
    uint256 l2block,
    uint256 l1block,
    uint256 l2timestamp,
    uint256 value,
    bytes calldata data
  ) external {
    if (block.chainid != ChainIds.MAINNET) revert InvalidChain();

    IL1Outbox(MAINNET_OUTBOX).executeTransaction(
      proof,
      index,
      l2sender,
      destinationGateway,
      l2block,
      l1block,
      l2timestamp,
      value,
      data
    );

    emit Exit(l2sender, destinationGateway, l2block, l1block, value, data);
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
}
