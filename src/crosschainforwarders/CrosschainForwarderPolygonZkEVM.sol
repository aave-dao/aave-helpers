// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {L2BridgeExecutor} from 'governance-crosschain-bridges/contracts/bridges/ZkEVMBridgeExecutor.sol';

interface IPolygonZkEVMBridge {
  function bridgeMessage(
    uint32 destinationNetwork,
    address destinationAddress,
    bool forceUpdateGlobalExitRoot,
    bytes calldata metadata
  ) external payable;
}

/**
 * @title A generic executor for proposals targeting the polygon zkEVM v3 pool
 * @author BGD Labs
 * @notice You can **only** use this executor when the polygon payload has a `execute()` signature without parameters
 * @notice You can **only** use this executor when the polygon payload is expected to be executed via `DELEGATECALL`
 * @dev This executor is a generic wrapper to be used with the Polygon ZkEVM Bridge (https://github.com/0xPolygonHermez/zkevm-contracts/blob/main/contracts/PolygonZkEVMBridge.sol)
 * It encodes a parameterless `execute()` with delegate calls and a specified target.
 * This encoded abi is then sent to the PolygonZkEVMBridge L1 to be synced to the PolygonZkEVMBridge L2 on the polygon zkevm network.
 * Once synced the POLYGON_ZKEVM_BRIDGE_EXECUTOR will queue the execution of the payload.
 */
contract CrosschainForwarderPolygonZkEVM {
  IPolygonZkEVMBridge public constant POLYGON_ZKEVM_BRIDGE =
    IPolygonZkEVMBridge(0x2a3DD3EB832aF982ec71669E178424b10Dca2EDe);
  address public immutable POLYGON_ZKEVM_BRIDGE_EXECUTOR;
  uint32 internal constant ZKEVM_NETWORK_ID = 1;

  constructor(address zkEvmExecutor) {
    POLYGON_ZKEVM_BRIDGE_EXECUTOR = zkEvmExecutor;
  }

  /**
   * @dev this function will be executed once the proposal passes the mainnet vote.
   * @param l2PayloadContract the polygon contract containing the `execute()` signature.
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

    bytes memory actions = abi.encodeCall(
      L2BridgeExecutor.queue,
      (targets, values, signatures, calldatas, withDelegatecalls)
    );
    POLYGON_ZKEVM_BRIDGE.bridgeMessage(
      ZKEVM_NETWORK_ID,
      POLYGON_ZKEVM_BRIDGE_EXECUTOR,
      true,
      actions
    );
  }
}
