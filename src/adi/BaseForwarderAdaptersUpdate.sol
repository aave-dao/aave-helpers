// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseForwarderAdaptersUpdate, ICrossChainForwarder} from './interfaces/IBaseForwarderAdaptersUpdate.sol';

/**
 * @title Base forwarder payload. It has the methods to update the forwarder bridge adapters.
 * @author BGD Labs @bgdlabs
 */
abstract contract BaseForwarderAdaptersUpdate is IBaseForwarderAdaptersUpdate {
  /// @inheritdoc IBaseForwarderAdaptersUpdate
  function getForwarderBridgeAdaptersToRemove()
    public
    view
    virtual
    returns (ICrossChainForwarder.BridgeAdapterToDisable[] memory)
  {
    return new ICrossChainForwarder.BridgeAdapterToDisable[](0);
  }

  /// @inheritdoc IBaseForwarderAdaptersUpdate
  function getForwarderBridgeAdaptersToEnable()
    public
    view
    virtual
    returns (ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[] memory)
  {
    return new ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[](0);
  }

  /// @inheritdoc IBaseForwarderAdaptersUpdate
  function executeForwardersUpdate(address crossChainController) public virtual {
    // remove forwarding adapters
    ICrossChainForwarder.BridgeAdapterToDisable[]
      memory forwardersToRemove = getForwarderBridgeAdaptersToRemove();
    if (forwardersToRemove.length != 0) {
      ICrossChainForwarder(crossChainController).disableBridgeAdapters(forwardersToRemove);
    }

    // add forwarding adapters
    ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[]
      memory forwardersToEnable = getForwarderBridgeAdaptersToEnable();
    if (forwardersToEnable.length != 0) {
      ICrossChainForwarder(crossChainController).enableBridgeAdapters(forwardersToEnable);
    }
  }
}
