// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './BaseReceiverAdaptersUpdate.sol';
import './BaseForwarderAdaptersUpdate.sol';
import './BaseADIPayloadUpdate.sol';

/**
 * @title Base payload aDI and bridge adapters update
 * @author BGD Labs @bgdlabs
 */
abstract contract BaseAdaptersUpdate is
  BaseReceiverAdaptersUpdate,
  BaseForwarderAdaptersUpdate,
  BaseADIPayloadUpdate
{
  /**
   * @param crossChainController address of the CCC of the network where payload will be deployed
   */
  constructor(address crossChainController) BaseADIPayloadUpdate(crossChainController) {}

  function execute() public virtual {
    executeReceiversUpdate(CROSS_CHAIN_CONTROLLER);

    executeForwardersUpdate(CROSS_CHAIN_CONTROLLER);
  }
}
