// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './BaseAdaptersUpdate.sol';

/**
 * @title Base payload aDI and bridge adapters update
 * @author BGD Labs @bgdlabs
 * @dev This payload should be used when wanting to substitute an adapter that receives and also forwards
 */
abstract contract SimpleOneToManyAdapterUpdate is BaseAdaptersUpdate {
  struct ConstructorInput {
    address ccc;
    address adapterToRemove;
    address newAdapter;
  }

  struct DestinationAdaptersInput {
    address adapter;
    uint256 chainId;
  }

  address public immutable ADAPTER_TO_REMOVE;
  address public immutable NEW_ADAPTER;

  constructor(ConstructorInput memory constructorInput) BaseAdaptersUpdate(constructorInput.ccc) {
    ADAPTER_TO_REMOVE = constructorInput.adapterToRemove;
    NEW_ADAPTER = constructorInput.newAdapter;
  }

  function getDestinationAdapters()
    public
    pure
    virtual
    returns (DestinationAdaptersInput[] memory)
  {
    return new DestinationAdaptersInput[](0);
  }

  function getChainsToReceive() public pure virtual returns (uint256[] memory);

  function getChainsToSend() public pure virtual returns (uint256[] memory) {
    DestinationAdaptersInput[] memory destinationAdapters = getDestinationAdapters();
    uint256[] memory chainsToSend = new uint256[](destinationAdapters.length);
    for (uint256 i = 0; i < destinationAdapters.length; i++) {
      chainsToSend[i] = destinationAdapters[i].chainId;
    }
    return chainsToSend;
  }

  function getReceiverBridgeAdaptersToRemove()
    public
    view
    virtual
    override
    returns (ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[] memory)
  {
    // remove old Receiver bridge adapter
    ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[]
      memory bridgeAdaptersToRemove = new ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[](1);

    bridgeAdaptersToRemove[0] = ICrossChainReceiver.ReceiverBridgeAdapterConfigInput({
      bridgeAdapter: ADAPTER_TO_REMOVE,
      chainIds: getChainsToReceive()
    });

    return bridgeAdaptersToRemove;
  }

  function getForwarderBridgeAdaptersToRemove()
    public
    view
    virtual
    override
    returns (ICrossChainForwarder.BridgeAdapterToDisable[] memory)
  {
    ICrossChainForwarder.BridgeAdapterToDisable[]
      memory forwarderAdaptersToRemove = new ICrossChainForwarder.BridgeAdapterToDisable[](1);

    forwarderAdaptersToRemove[0] = ICrossChainForwarder.BridgeAdapterToDisable({
      bridgeAdapter: ADAPTER_TO_REMOVE,
      chainIds: getChainsToSend()
    });

    return forwarderAdaptersToRemove;
  }

  function getReceiverBridgeAdaptersToAllow()
    public
    view
    virtual
    override
    returns (ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[] memory)
  {
    ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[]
      memory bridgeAdapterConfig = new ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[](1);

    bridgeAdapterConfig[0] = ICrossChainReceiver.ReceiverBridgeAdapterConfigInput({
      bridgeAdapter: NEW_ADAPTER,
      chainIds: getChainsToReceive()
    });

    return bridgeAdapterConfig;
  }

  function getForwarderBridgeAdaptersToEnable()
    public
    view
    virtual
    override
    returns (ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[] memory)
  {
    DestinationAdaptersInput[] memory destinationAdapters = getDestinationAdapters();

    ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[]
      memory bridgeAdaptersToEnable = new ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[](
        destinationAdapters.length
      );

    for (uint256 i = 0; i < destinationAdapters.length; i++) {
      bridgeAdaptersToEnable[i] = ICrossChainForwarder.ForwarderBridgeAdapterConfigInput({
        currentChainBridgeAdapter: NEW_ADAPTER,
        destinationBridgeAdapter: destinationAdapters[i].adapter,
        destinationChainId: destinationAdapters[i].chainId
      });
    }

    return bridgeAdaptersToEnable;
  }
}
