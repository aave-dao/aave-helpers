// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Minimal interface of the Base B20 factory precompile at 0xB20f000000000000000000000000000000000000.
interface IB20Factory {
  /// @notice Whether `token` was created by this factory, recovered from the address prefix. Never reverts.
  function isB20(address token) external view returns (bool);

  /// @notice Whether `createB20` has run to completion at `token`. Never reverts.
  function isB20Initialized(address token) external view returns (bool);
}
