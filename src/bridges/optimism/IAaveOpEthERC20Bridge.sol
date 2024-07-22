// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAaveOpEthERC20Bridge {
  /// @notice Returned when calling the contract from an invalid chain
  error InvalidChain();

  /// @notice Emitted when bridging a token from Optimism to Mainnet
  /// @param token Address of the OP token
  /// @param l1token Address of the equivalent Mainnet token
  /// @param amount Amount of tokens bridged
  /// @param to Address receiving token on Mainnet
  /// @param nonce Nonce of the bridge transaction
  event Bridge(
    address indexed token,
    address indexed l1token,
    uint256 amount,
    address indexed to,
    uint256 nonce
  );

  /// @notice Returns the Optimism Standard Bridge Address
  /// @return Address of bridge
  function L2_STANDARD_BRIDGE() external returns (address);

  /// @notice Bridges ERC20 token from Optimism to Ethereum Mainnet
  /// @param token The ERC20 address on Optimism
  /// @param l1Token The ERC20 address of the equivalent token on Mainnet
  /// @param amount The amount of ERC20 token to bridge
  function bridge(address token, address l1Token, uint256 amount) external;

  /// @notice Returns the current nonce
  /// @return Value of the current nonce
  function nonce() external view returns (uint256);
}
