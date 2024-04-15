// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './BaseAdaptersUpdate.sol';

/**
 * @title Base payload aDI and bridge adapters update
 * @author BGD Labs @bgdlabs
 * @dev This payload should be used when wanting to add or remove (or both) a receiver adapter. If one of the
        addresses is left as 0, the addition or removal will not be done
 */
abstract contract SimpleReceiverAdapterUpdate is BaseAdaptersUpdate {
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

  /**
   * @notice method to get the chains that a new adapter will receive messages from
   * @return an array of chain ids
   */
  function getChainsToReceive() public pure virtual returns (uint256[] memory);

  /// @inheritdoc IBaseReceiverAdaptersUpdate
  function getReceiverBridgeAdaptersToRemove()
    public
    view
    virtual
    override
    returns (ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[] memory)
  {
    if (ADAPTER_TO_REMOVE != address(0)) {
      // remove old Receiver bridge adapter
      ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[]
        memory bridgeAdaptersToRemove = new ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[](
          1
        );

      bridgeAdaptersToRemove[0] = ICrossChainReceiver.ReceiverBridgeAdapterConfigInput({
        bridgeAdapter: ADAPTER_TO_REMOVE,
        chainIds: getChainsToReceive()
      });

      return bridgeAdaptersToRemove;
    } else {
      return new ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[](0);
    }
  }

  /// @inheritdoc IBaseReceiverAdaptersUpdate
  function getReceiverBridgeAdaptersToAllow()
    public
    view
    virtual
    override
    returns (ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[] memory)
  {
    if (NEW_ADAPTER != address(0)) {
      ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[]
        memory bridgeAdapterConfig = new ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[](1);

      bridgeAdapterConfig[0] = ICrossChainReceiver.ReceiverBridgeAdapterConfigInput({
        bridgeAdapter: NEW_ADAPTER,
        chainIds: getChainsToReceive()
      });

      return bridgeAdapterConfig;
    } else {
      return new ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[](0);
    }
  }
}
