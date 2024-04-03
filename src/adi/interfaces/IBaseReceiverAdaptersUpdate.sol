// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICrossChainReceiver} from 'aave-address-book/common/ICrossChainController.sol';

/**
 * @title Interface of the base payload aDI and bridge adapters update
 * @author BGD Labs @bgdlabs
 */
interface IBaseReceiverAdaptersUpdate {
  function getReceiverBridgeAdaptersToRemove()
    external
    view
    returns (ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[] memory);

  function getReceiverBridgeAdaptersToAllow()
    external
    view
    returns (ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[] memory);
}
