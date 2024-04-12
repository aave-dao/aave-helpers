// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IProposalGenericExecutor} from '../interfaces/IProposalGenericExecutor.sol';
import './BaseReceiverAdaptersUpdate.sol';
import './BaseForwarderAdaptersUpdate.sol';

/**
 * @title Base payload aDI and bridge adapters update
 * @author BGD Labs @bgdlabs
 */
abstract contract BaseAdaptersUpdate is
  BaseReceiverAdaptersUpdate,
  BaseForwarderAdaptersUpdate,
  IProposalGenericExecutor
{
  address public immutable CROSS_CHAIN_CONTROLLER;

  constructor(address crossChainController) {
    CROSS_CHAIN_CONTROLLER = crossChainController;
  }

  function execute() public override {
    executeReceiversUpdate(CROSS_CHAIN_CONTROLLER);

    executeForwardersUpdate(CROSS_CHAIN_CONTROLLER);
  }
}
