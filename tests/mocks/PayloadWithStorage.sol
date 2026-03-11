// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IProposalGenericExecutor} from '../../src/interfaces/IProposalGenericExecutor.sol';

/**
 * @dev Mock payload that incorrectly declares a state variable.
 * Used to test that _validateNoPayloadStorageSlots detects storage variables.
 */
contract PayloadWithStorage is IProposalGenericExecutor {
  uint256 internal _randomStorageVariable;

  function execute() external {
    // do nothing just relax
  }
}
