// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Minimal interface of a Base B20 token (node-native, code is the single byte 0xef).
interface IB20 {
  function MINT_ROLE() external view returns (bytes32);

  function hasRole(bytes32 role, address account) external view returns (bool);

  function mint(address to, uint256 amount) external;
}
