// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICollector} from '../../CollectorUtils.sol';
import {IPool} from 'aave-address-book/AaveV3.sol';
import {ILendingPool} from 'aave-address-book/AaveV2.sol';

interface IPoolV3FinSteward {
  /// @dev Provided address cannot be the zero-address
  error InvalidZeroAddress();

  /// @dev Amount cannot be zero
  error InvalidZeroAmount();

  /// @dev Aave Pool must have been previously approved
  error UnrecognizedPool();

  /// @dev Could not identify V2 Pool
  error V2PoolNotFound();

  /// @notice Emitted when a new Pool gets listed
  /// @param pool The address of the new pool
  event ApprovedPool(address indexed pool);

  /// @notice Emitted when a Pool gets removed
  /// @param pool The address of the revoked pool
  event RevokedPool(address indexed pool);

  /// @notice Returns instance of Aave V3 Collector
  function COLLECTOR() external view returns (ICollector);

  /// @notice Returns whether pool is approved to be used
  /// @param poolV2 Address of the Aave V3 Pool
  function poolsV2(address poolV2) external view returns (bool);

  /// @notice Returns whether pool is approved to be used
  /// @param poolV3 Address of the Aave V3 Pool
  function poolsV3(address poolV3) external view returns (bool);

  /// @notice Deposits a specified amount of a reserve token into Aave V3
  /// @param pool The address of the V3 Pool to deposit into
  /// @param reserve The address of the reserve token
  /// @param amount The amount of the reserve token to deposit
  function depositV3(address pool, address reserve, uint256 amount) external;

  /// @notice Withdraws a specified amount of a reserve token from Aave V2
  /// @param pool The address of the V2 Pool to withdraw from
  /// @param reserve The address of the reserve token to withdraw
  /// @param amount The amount of the reserve token to withdraw
  function withdrawV2(address pool, address reserve, uint256 amount) external;

  /// @notice Withdraws a specified amount of a reserve token from Aave V3
  /// @param V3Pool The address of the V3 pool to withdraw from
  /// @param reserve The address of the reserve token to withdraw
  /// @param amount The amount of the reserve token to withdraw
  function withdrawV3(address V3Pool, address reserve, uint256 amount) external;

  /// @notice Migrates a specified amount of a reserve token from Aave V2 to Aave V3
  /// @param poolV2 The address of the origin V2 Pool
  /// @param poolV3 The address of the destination V3 Pool
  /// @param reserve The address of the reserve token
  /// @param amount The amount of the reserve token to migrate
  function migrateV2toV3(address poolV2, address poolV3, address reserve, uint256 amount) external;

  /// @notice Migrates a specified amount of a reserve token from an Aave V3 instance to another
  /// @param fromPool The address of the origin V3 Pool
  /// @param toPool The address of the destination V3 Pool
  /// @param reserve The address of the reserve token
  /// @param amount The amount of the reserve token to migrate
  function migrateBetweenV3(
    address fromPool,
    address toPool,
    address reserve,
    uint256 amount
  ) external;

  /// @notice Checks whether a V3 pool instance is configured to be interacted with
  /// @param pool Address of the V3 pool to check
  function validateV3Pool(address pool) external view;

  /// @notice Checks whether a V2 pool instance is configured to be interacted with
  /// @param pool Address of the V2 pool to check
  function validateV2Pool(address pool) external view;

  /// @notice Approves the permission to use a new pool
  /// @param pool Address of the new Pool
  /// @param version3 True if new pool is a V3 isntance
  function approvePool(address pool, bool version3) external;

  /// @notice Revokes the permission to use a pool
  /// @param pool Address of the Pool to remove
  /// @param version3 True if new pool is a V3 isntance
  function revokePool(address pool, bool version3) external;
}
