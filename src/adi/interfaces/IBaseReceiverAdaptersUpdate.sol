// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICrossChainReceiver} from 'aave-address-book/common/ICrossChainController.sol';

/**
 * @title Interface of the base payload aDI and bridge adapters update
 * @author BGD Labs @bgdlabs
 */
interface IBaseReceiverAdaptersUpdate {
  /**
   * @notice method to get the receiver adapters to remove
   * @return object array with the adapter to remove and an array of chain ids to remove it from
   */
  function getReceiverBridgeAdaptersToRemove()
    external
    view
    returns (ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[] memory);

  /**
   * @notice method to get the receiver adapters to allow
   * @return object array with the adapter to allow and an array of chain ids to allow it to receive messages from
   */
  function getReceiverBridgeAdaptersToAllow()
    external
    view
    returns (ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[] memory);

  /**
   * @notice method to add and remove receiver adapters
   * @param crossChainController address of the CCC on the networks where the adapters are going to be updated
   */
  function executeReceiversUpdate(address crossChainController) external;
}
