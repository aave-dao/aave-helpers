// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVeToken {
  /// @param owner Address of user to check balance of
  function balanceOf(address owner) external view returns (uint256);

  /// @param owner Address of user to check locked balance of
  function locked(address owner) external view returns (uint256);

  /// @param value Amount of tokens to lock
  /// @param unlock_time Time when tokens can be unlocked
  function create_lock(uint256 value, uint256 unlock_time) external;

  /// @param value Amount of tokens to lock for existing balance
  function increase_amount(uint256 value) external;

  /// @param unlock_time New unlock time for locked position
  function increase_unlock_time(uint256 unlock_time) external;

  /// @notice Withdraw locked tokens (reverts if locked period has not passed)
  function withdraw() external;

  /// @param owner Address of user who has locked balance
  function locked__end(address owner) external view returns (uint256);
}
