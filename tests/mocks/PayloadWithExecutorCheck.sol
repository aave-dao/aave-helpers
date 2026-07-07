// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IProposalGenericExecutor} from '../../src/interfaces/IProposalGenericExecutor.sol';

/**
 * @dev Mock payload that reverts unless delegatecalled by the expected executor.
 * As executors delegatecall payloads, `address(this)` during execution is the executor itself.
 */
contract PayloadWithExecutorCheck is IProposalGenericExecutor {
  address public immutable EXPECTED_EXECUTOR;

  constructor(address expectedExecutor) {
    EXPECTED_EXECUTOR = expectedExecutor;
  }

  function execute() external view {
    require(address(this) == EXPECTED_EXECUTOR, 'UNEXPECTED_EXECUTOR');
  }
}
