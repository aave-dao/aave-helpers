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

  /// @dev Cannot deplete reserves to less than minimum allowed
  /// @param minimumBalance The minimum allowed balance to keep in the Collector
  error MinimumBalanceShield(uint256 minimumBalance);

  /// @dev Aave V3 Pool must have been previously approved
  error UnrecognizedV3Pool();

  /// @dev Could not identify V2 Pool
  error V2PoolNotFound();

  /// @notice Emitted when a new V3 Pool gets listed
  /// @param V3Pool The address of the new pool
  event AddedV3Pool(address indexed V3Pool);

  /// @notice Emitted when a new V2 Pool gets listed
  /// @param V2Pool The address of the new pool
  event AddedV2Pool(address indexed V2Pool);

  /// @notice Emitted when the minimum balance for a token is updated
  /// @param token The address of the token
  /// @param newAmount The new minimum balance for the token
  event MinimumTokenBalanceUpdated(address indexed token, uint newAmount);

  /// @notice Returns instance of Aave V3 Collector
  function COLLECTOR() external view returns (ICollector);

  /// @notice Returns instance of the Aave V2 Mainnet V2 Lending Pool
  function v2Pool() external view returns (ILendingPool);

  /// @notice Returns whether pool is approved to be used by PoolV3FinSteward
  /// @param pool Address of the Aave V3 Pool
  function v3Pools(address pool) external view returns (bool);

  /// @notice Returns minimum balance of token to keep in Aave Pools
  /// @param token Address of the token to check balance for
  function minTokenBalance(address token) external view returns (uint256);

  /// @notice Deposits a specified amount of a reserve token into Aave V3
  /// @param pool The address of the V3 Pool to deposit into
  /// @param reserve The address of the reserve token
  /// @param amount The amount of the reserve token to deposit
  function depositV3(address pool, address reserve, uint amount) external;

  /// @notice Migrates a specified amount of a reserve token from Aave V2 to Aave V3
  /// @param pool The address of the destination V3 Pool
  /// @param reserve The address of the reserve token
  /// @param amount The amount of the reserve token to migrate
  function migrateV2toV3(address pool, address reserve, uint amount) external;

  /// @notice Withdraws a specified amount of a reserve token from Aave V2
  /// @param reserve The address of the reserve token to withdraw
  /// @param amount The amount of the reserve token to withdraw
  function withdrawV2(address reserve, uint amount) external;

  /// @notice Withdraws a specified amount of a reserve token from Aave V3
  /// @param V3Pool The address of the V3 pool to withdraw from
  /// @param reserve The address of the reserve token to withdraw
  /// @param amount The amount of the reserve token to withdraw
  function withdrawV3(address V3Pool, address reserve, uint amount) external;

  /// @notice Checks whether aToken amount can be withdrawn from a reserve
  /// @param token Address of the Aave Token
  /// @param amount The amount to withdraw from the reserve
  function validateAmount(address token, uint256 amount) external view;

  /// @notice Checks whether a V3 pool instance is configured to be interacted with
  /// @param pool Address of the V3 pool to check
  function validateV3Pool(address pool) external view;

  /// @notice Sets the minimum balance shield for a specified token
  /// @param token The address of the token
  /// @param amount The minimum balance to shield
  function setMinimumBalanceShield(address token, uint amount) external;

  /// @notice Approves an Aave V3 Instance to be used by the PoolV3FinSteward
  /// @param newV3pool Address of the Aave V3 Pool
  function setV3Pool(address newV3pool) external;

  /// @notice Updates the Aave V2 Instance to be used by the PoolV3FinSteward
  /// @param newV2pool Address of the Aave V2 Pool
  function setV2Pool(address newV2pool) external;
}
