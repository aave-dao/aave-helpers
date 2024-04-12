// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseReceiverAdaptersUpdate, ICrossChainReceiver} from './interfaces/IBaseReceiverAdaptersUpdate.sol';

/**
 * @title Base payload aDI and bridge adapters update
 * @author BGD Labs @bgdlabs
 */
abstract contract BaseReceiverAdaptersUpdate is IBaseReceiverAdaptersUpdate {
  function getReceiverBridgeAdaptersToRemove()
    public
    view
    virtual
    returns (ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[] memory)
  {
    // remove old Receiver bridge adapter
    return new ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[](0);
  }

  function getReceiverBridgeAdaptersToAllow()
    public
    view
    virtual
    returns (ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[] memory)
  {
    return new ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[](0);
  }

  function executeReceiversUpdate(address crossChainController) public virtual {
    // remove old Receiver bridge adapter
    ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[]
      memory receiversToRemove = getReceiverBridgeAdaptersToRemove();
    if (receiversToRemove.length != 0) {
      ICrossChainReceiver(crossChainController).disallowReceiverBridgeAdapters(receiversToRemove);
    }

    // add receiver adapters
    ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[]
      memory receiversToAllow = getReceiverBridgeAdaptersToAllow();
    if (receiversToAllow.length != 0) {
      ICrossChainReceiver(crossChainController).allowReceiverBridgeAdapters(receiversToAllow);
    }
  }
}
