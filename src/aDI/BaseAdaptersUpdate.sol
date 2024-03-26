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
    // remove old Receiver bridge adapter
    ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[]
      memory receiversToRemove = getReceiverBridgeAdaptersToRemove();
    if (receiversToRemove.length != 0) {
      ICrossChainReceiver(CROSS_CHAIN_CONTROLLER).disallowReceiverBridgeAdapters(receiversToRemove);
    }

    // remove forwarding adapters
    ICrossChainForwarder.BridgeAdapterToDisable[]
      memory forwardersToRemove = getForwarderBridgeAdaptersToRemove();
    if (forwardersToRemove.length != 0) {
      ICrossChainForwarder(CROSS_CHAIN_CONTROLLER).disableBridgeAdapters(forwardersToRemove);
    }

    ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[]
      memory receiversToAllow = getReceiverBridgeAdaptersToAllow();
    if (receiversToAllow.length != 0) {
      // add receiver adapters
      ICrossChainReceiver(CROSS_CHAIN_CONTROLLER).allowReceiverBridgeAdapters(receiversToAllow);
    }
    ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[]
      memory forwardersToEnable = getForwarderBridgeAdaptersToEnable();
    if (forwardersToEnable.length != 0) {
      // add forwarding adapters
      ICrossChainForwarder(CROSS_CHAIN_CONTROLLER).enableBridgeAdapters(forwardersToEnable);
    }
  }
}
