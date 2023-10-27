// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';

/// @author Llama
abstract contract Common is OwnableWithGuardian {
  /// @notice Provided address is zero address
  error InvalidZeroAddress();

  /// @notice One week, in seconds. Vote-locking is rounded down to weeks.
  uint256 internal constant WEEK = 7 days;
}
