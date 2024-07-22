// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IProposalGenericExecutor} from '../interfaces/IProposalGenericExecutor.sol';

abstract contract BaseADIPayloadUpdate is IProposalGenericExecutor {
  address public immutable CROSS_CHAIN_CONTROLLER;

  /**
   * @param crossChainController address of the CCC of the network where payload will be deployed
   */
  constructor(address crossChainController) {
    CROSS_CHAIN_CONTROLLER = crossChainController;
  }
}
