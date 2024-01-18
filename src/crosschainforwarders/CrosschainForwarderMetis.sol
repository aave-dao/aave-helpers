// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICrossDomainMessenger} from 'governance-crosschain-bridges/contracts/dependencies/optimism/interfaces/ICrossDomainMessenger.sol';
import {IL2BridgeExecutor} from 'governance-crosschain-bridges/contracts/interfaces/IL2BridgeExecutor.sol';

/**
 * @title A generic executor for proposals targeting the metis v3 pool
 * @author BGD Labs
 * @notice You can **only** use this executor when the metis payload has a `execute()` signature without parameters
 * @notice You can **only** use this executor when the metis payload is expected to be executed via `DELEGATECALL`
 * @notice The L2CrossDomainMessenger can **only** queue an action on metis with up to a max gas which is specified in `MAX_GAS_LIMIT`.
 * It encodes and sends via the L2CrossDomainMessenger a message to queue for execution an action on L2, in the Aave METIS_BRIDGE_EXECUTOR.
 */
contract CrosschainForwarderMetis {
  /**
   * @dev The L1 Cross Domain Messenger contract sends messages from L1 to L2, and relays messages
   * from L2 onto L1. In this contract it's used to send the encoded L2 queuing over the bridge.
   */
  address public constant L1_CROSS_DOMAIN_MESSENGER_ADDRESS =
    0x081D1101855bD523bA69A9794e0217F0DB6323ff;

  /**
   * @dev The metis bridge executor is a L2 governance execution contract.
   * This contract allows queuing of proposals by allow listed addresses.
   */
  address public immutable METIS_BRIDGE_EXECUTOR;

  /**
   * @dev The gas limit of the queue transaction by the L2CrossDomainMessenger on L2.
   * The limit seems reasonable considering the queue transaction, as all gas limits are prepaid.
   */
  uint32 public constant MAX_GAS_LIMIT = 5_000_000;

  /**
   * @param bridgeExecutor The L2 executor
   */
  constructor(address bridgeExecutor) {
    METIS_BRIDGE_EXECUTOR = bridgeExecutor;
  }

  /**
   * @dev this function will be executed once the proposal passes the mainnet vote.
   * @param l2PayloadContract the metis contract containing the `execute()` signature.
   */
  function execute(address l2PayloadContract) public {
    address[] memory targets = new address[](1);
    targets[0] = l2PayloadContract;
    uint256[] memory values = new uint256[](1);
    values[0] = 0;
    string[] memory signatures = new string[](1);
    signatures[0] = 'execute()';
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = '';
    bool[] memory withDelegatecalls = new bool[](1);
    withDelegatecalls[0] = true;

    bytes memory queue = abi.encodeWithSelector(
      IL2BridgeExecutor.queue.selector,
      targets,
      values,
      signatures,
      calldatas,
      withDelegatecalls
    );
    ICrossDomainMessenger(L1_CROSS_DOMAIN_MESSENGER_ADDRESS).sendMessage(
      METIS_BRIDGE_EXECUTOR,
      queue,
      MAX_GAS_LIMIT
    );
  }
}
