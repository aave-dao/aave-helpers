// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICrossChainForwarder} from 'aave-address-book/common/ICrossChainController.sol';

/**
 * @title Base payload aDI and bridge adapters update
 * @author BGD Labs @bgdlabs
 */
abstract contract BaseForwarderAdaptersUpdate {
  function getForwarderBridgeAdaptersToRemove()
    public
    view
    virtual
    returns (ICrossChainForwarder.BridgeAdapterToDisable[] memory)
  {
    return new ICrossChainForwarder.BridgeAdapterToDisable[](0);
  }

  function getForwarderBridgeAdaptersToEnable()
    public
    view
    virtual
    returns (ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[] memory)
  {
    return new ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[](0);
  }
}
