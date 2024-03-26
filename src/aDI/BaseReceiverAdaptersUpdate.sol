// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICrossChainReceiver} from 'aave-address-book/common/ICrossChainController.sol';

/**
 * @title Base payload aDI and bridge adapters update
 * @author BGD Labs @bgdlabs
 */
abstract contract BaseReceiverAdaptersUpdate {
  function getReceiverBridgeAdaptersToRemove()
    public
    pure
    virtual
    returns (ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[] memory)
  {
    // remove old Receiver bridge adapter
    return new ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[](0);
  }

  function getReceiverBridgeAdaptersToAllow()
    public
    pure
    virtual
    returns (ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[] memory)
  {
    return new ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[](0);
  }
}
