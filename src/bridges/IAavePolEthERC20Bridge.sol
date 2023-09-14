// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAavePolEthERC20Bridge {
  function bridge(address token, uint256 amount) external;

  function exit(bytes calldata burnProof) external;

  function withdrawToCollector(address token) external;
}
