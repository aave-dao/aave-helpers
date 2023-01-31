// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IInitializableAdminUpgradeabilityProxy {
  function upgradeTo(address newImplementation) external;

  function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;

  function admin() external returns (address);

  function implementation() external returns (address);
}
