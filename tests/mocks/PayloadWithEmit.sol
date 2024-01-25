// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IPoolConfigurator, ConfiguratorInputTypes} from 'aave-address-book/AaveV3.sol';
import {IProposalGenericExecutor} from '../../src/interfaces/IProposalGenericExecutor.sol';

/**
 * @dev This payload simply emits an event on execution
 */
contract PayloadWithEmit is IProposalGenericExecutor {
  event TestEvent();

  function execute() external {
    emit TestEvent();
  }
}
