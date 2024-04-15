// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICrossChainForwarder} from 'aave-address-book/common/ICrossChainController.sol';

/**
 * @title Interface for base forwarder payload.
 * @author BGD Labs @bgdlabs
 */
interface IBaseForwarderAdaptersUpdate {
  /**
   * @notice method to get the forwarder adapters to remove
   * @return object array with the adapter to remove and an array of chain ids to remove it from
   */
  function getForwarderBridgeAdaptersToRemove()
    external
    view
    returns (ICrossChainForwarder.BridgeAdapterToDisable[] memory);

  /**
   * @notice method to get the forwarder adapters to enable
   * @return object array with the current and destination pair of adapters to enable and the chainId
             to communicate with
   */
  function getForwarderBridgeAdaptersToEnable()
    external
    view
    returns (ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[] memory);

  /**
   * @notice method to add and remove forwarder adapters
   * @param crossChainController address of the CCC on the networks where the adapters are going to be updated
   */
  function executeForwardersUpdate(address crossChainController) external;
}
