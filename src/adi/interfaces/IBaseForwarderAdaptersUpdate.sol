// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICrossChainForwarder} from 'aave-address-book/common/ICrossChainController.sol';

/**
 * @title Interface for base payload aDI and bridge adapters update
 * @author BGD Labs @bgdlabs
 */
interface IBaseForwarderAdaptersUpdate {
  function getForwarderBridgeAdaptersToRemove()
    external
    view
    virtual
    returns (ICrossChainForwarder.BridgeAdapterToDisable[] memory);

  function getForwarderBridgeAdaptersToEnable()
    external
    view
    virtual
    returns (ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[] memory);
}
