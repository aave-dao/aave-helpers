// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenPool {
  /// @notice Mint an amount of tokens with no additional logic.
  function directMint(address to, uint256 amount) external;

  /// @notice Sets the bridge limit, the maximum amount of tokens that can be bridged out
  /// @param limit The new bridge limit
  function setBridgeLimit(uint256 limit) external;

  /// @notice Gets the bridge limit
  /// @return The maximum amount of tokens that can be transferred out to other chains
  function getBridgeLimit() external view returns (uint256);

  /// @notice Gets the current bridged amount to other chains
  /// @return The amount of tokens transferred out to other chains
  function getCurrentBridgedAmount() external view returns (uint256);

  /// @notice Gets the CCIP router used by the pool
  function getRouter() external view returns (address);

  /// @notice Gets the token bucket with its values for the block it was requested at.
  function getCurrentOutboundRateLimiterState(
    uint64 remoteChainSelector
  )
    external
    view
    returns (uint128 tokens, uint32 lastUpdated, bool isEnabled, uint128 capacity, uint128 rate);

  /// @notice Gets the token bucket with its values for the block it was requested at.
  function getCurrentInboundRateLimiterState(
    uint64 remoteChainSelector
  )
    external
    view
    returns (uint128 tokens, uint32 lastUpdated, bool isEnabled, uint128 capacity, uint128 rate);
}
