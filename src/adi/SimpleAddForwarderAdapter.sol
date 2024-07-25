// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import './BaseAdaptersUpdate.sol';

/**
 * @title SimpleAddForwarderAdapter
 * @author BGD Labs @bgdlabs
 * @dev this payload should be used when adding a new bridging path to adi
 */
contract SimpleAddForwarderAdapter is BaseAdaptersUpdate {
  address public immutable CURRENT_CHAIN_BRIDGE_ADAPTER;
  address public immutable DESTINATION_CHAIN_BRIDGE_ADAPTER;
  uint256 public immutable DESTINATION_CHAIN_ID;

  constructor(
    address crossChainController,
    address currentChainBridgeAdapter,
    address destinationChainBridgeAdapter,
    uint256 destinationChainId
  ) BaseAdaptersUpdate(crossChainController) {
  CURRENT_CHAIN_BRIDGE_ADAPTER = currentChainBridgeAdapter;
  DESTINATION_CHAIN_BRIDGE_ADAPTER = destinationChainBridgeAdapter;
  DESTINATION_CHAIN_ID = destinationChainId;
  }

  function getForwarderBridgeAdaptersToEnable()
  public
  view
  override
  returns (ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[] memory)
  {
    ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[]
    memory newForwarders = new ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[](1);

    newForwarders[0] = ICrossChainForwarder.ForwarderBridgeAdapterConfigInput({
      currentChainBridgeAdapter: CURRENT_CHAIN_BRIDGE_ADAPTER,
      destinationBridgeAdapter: DESTINATION_CHAIN_BRIDGE_ADAPTER,
      destinationChainId: DESTINATION_CHAIN_ID
    });

    return newForwarders;
  }
}