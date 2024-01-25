// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDelegateRegistry {
  /// @param id The string representation of the Snapshot spaceId
  /// @param delegate Address of the user to delegate to
  function setDelegate(bytes32 id, address delegate) external;

  /// @param id The string representation of the Snapshot spaceId
  function clearDelegate(bytes32 id) external;

  /// @param delegator Address of the user delegating tokens
  /// @param id The string representation of the Snapshot spaceId
  function delegation(address delegator, bytes32 id) external view returns (address delegatee);
}
