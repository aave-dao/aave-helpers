// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAaveArbEthERC20Bridge {
  /// @notice This function is not supported on this chain
  error InvalidChain();

  /// @notice Emitted when bridging a token from Arbitrum to Mainnet
  event Bridge(address indexed token, uint256 amount);

  /// @notice Emitted when finalizing the transfer on Mainnet
  /// @param l2sender The address sending the transaction from the L2
  /// @param to The address receiving the bridged funds
  /// @param l2block The block number of the transaction on the L2
  /// @param l1block The block number of the transaction on the L1
  /// @param value The value being bridged from the L2
  /// @param data Data being sent from the L2
  event Exit(
    address l2sender,
    address to,
    uint256 l2block,
    uint256 l1block,
    uint256 value,
    bytes data
  );

  /// @notice Returns the address of the Mainnet contract to exit the bridge from
  function MAINNET_OUTBOX() external view returns (address);

  /// This function withdraws an ERC20 token from Arbitrum to Mainnet. exit() needs
  /// to be called on mainnet with the corresponding burnProof in order to complete.
  /// @notice Arbitrum only. Function will revert if called from other network.
  /// @param token Arbitrum address of ERC20 token to withdraw.
  /// @param l1token Mainnet address of ERC20 token to withdraw.
  /// @param gateway The L2 gateway address to bridge through
  /// @param amount Amount of tokens to withdraw
  function bridge(address token, address l1token, address gateway, uint256 amount) external;

  /// This function completes the withdrawal process from Arbitrum to Mainnet.
  /// Burn proof is generated via API. Please see README.md
  /// @notice Mainnet only. Function will revert if called from other network.
  /// @param proof[] Burn proof generated via API.
  /// @param index The index of the burn transaction.
  /// @param l2sender The address sending the transaction from the L2
  /// @param destinationGateway The L1 gateway address receiving the bridged funds
  /// @param l2block The block number of the transaction on the L2
  /// @param l1block The block number of the transaction on the L1
  /// @param l2timestamp The timestamp of the transaction on the L2
  /// @param value The value being bridged from the L2
  /// @param data Data being sent from the L2
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
  ) external;
}
