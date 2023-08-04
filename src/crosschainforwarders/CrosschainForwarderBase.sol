// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICrossDomainMessenger} from 'governance-crosschain-bridges/contracts/dependencies/optimism/interfaces/ICrossDomainMessenger.sol';
import {IL2BridgeExecutor} from 'governance-crosschain-bridges/contracts/interfaces/IL2BridgeExecutor.sol';

/**
 * @title A generic executor for proposals targeting the Base v3 pool
 * @author BGD Labs
 * @notice You can **only** use this executor when the Base payload has a `execute()` signature without parameters
 * @notice You can **only** use this executor when the Base payload is expected to be executed via `DELEGATECALL`
 * @notice You can **only** execute payloads on Base with up to prepayed gas.
 * Prepaid gas is the maximum gas covered by the bridge without additional payment.
 * @dev This executor is a generic wrapper to be used with Base CrossDomainMessenger (https://etherscan.io/address/0x866E82a600A1414e583f7F13623F1aC5d58b0Afa)
 * It encodes and sends via the L2CrossDomainMessenger a message to queue for execution an action on L2, in the Aave BASE_BRIDGE_EXECUTOR.
 */
contract CrosschainForwarderBase {
  /**
   * @dev The L1 Cross Domain Messenger contract sends messages from L1 to L2, and relays messages
   * from L2 onto L1. In this contract it's used by the governance SHORT_EXECUTOR to send the encoded L2 queuing over the bridge.
   */
  address public constant L1_CROSS_DOMAIN_MESSENGER_ADDRESS =
    0x866E82a600A1414e583f7F13623F1aC5d58b0Afa;

  /**
   * @dev The base bridge executor is a L2 governance execution contract.
   * This contract allows queuing of proposals by allow listed addresses (in this case the L1 short executor).
   * https://basescan.org/address/0xa9f30e6ed4098e9439b2ac8aea2d3fc26bcebb45
   */
  address public constant BASE_BRIDGE_EXECUTOR = 0xA9F30e6ED4098e9439B2ac8aEA2d3fc26BcEbb45;

  /**
   * @dev The gas limit of the queue transaction by the L2CrossDomainMessenger on L2.
   * The limit seems reasonable considering the queue transaction, as gas limits are prepaid.
   */
  uint32 public constant MAX_GAS_LIMIT = 1_900_000;

  /**
   * @dev this function will be executed once the proposal passes the mainnet vote.
   * @param l2PayloadContract the base contract containing the `execute()` signature.
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
      BASE_BRIDGE_EXECUTOR,
      queue,
      MAX_GAS_LIMIT
    );
  }
}
