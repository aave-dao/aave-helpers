// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {AaveMisc, AaveGovernanceV2} from 'aave-address-book/AaveAddressBook.sol';
import {GovHelpers} from '../../src/GovHelpers.sol';
import {ProtocolV3TestBase} from '../../src/ProtocolV3TestBase.sol';
import {PayloadWithEmit} from '../mocks/PayloadWithEmit.sol';
import {CrosschainForwarderPolygonZkEVM} from '../../src/crosschainforwarders/CrosschainForwarderPolygonZkEVM.sol';
import {ZkEVMBridgeExecutor} from 'governance-crosschain-bridges/contracts/bridges/ZkEVMBridgeExecutor.sol';

/**
 * This test covers syncing between mainnet and polygon.
 */
contract PolygonZkEVMCrossChainForwarderTest is ProtocolV3TestBase {
  event TestEvent();
  // the identifiers of the forks
  uint256 mainnetFork;
  uint256 zkevmFork;

  CrosschainForwarderPolygonZkEVM forwarder;
  ZkEVMBridgeExecutor executor;
  PayloadWithEmit public payloadWithEmit;

  address constant zkevmBridge = 0x2a3DD3EB832aF982ec71669E178424b10Dca2EDe;

  function setUp() public {
    mainnetFork = vm.createSelectFork(vm.rpcUrl('mainnet'), 17670229);
    zkevmFork = vm.createSelectFork(vm.rpcUrl('zkevm'), 2384958);

    // deploy executor on L2
    vm.selectFork(zkevmFork);
    executor = new ZkEVMBridgeExecutor(
      AaveGovernanceV2.SHORT_EXECUTOR,
      172800,
      259200,
      28800,
      604800,
      address(0)
    );
    payloadWithEmit = new PayloadWithEmit();

    // deploy forwarder on mainnet with linked executor
    vm.selectFork(mainnetFork);
    forwarder = new CrosschainForwarderPolygonZkEVM(address(executor));
  }

  // utility to transform memory to calldata so array range access is available
  function _cutBytes(bytes calldata input) public pure returns (bytes calldata) {
    return input[64:];
  }

  function testProposalE2E() public {
    // 1. create l1 proposal
    vm.selectFork(mainnetFork);
    vm.startPrank(AaveMisc.ECOSYSTEM_RESERVE);
    GovHelpers.Payload[] memory payloads = new GovHelpers.Payload[](1);
    payloads[0] = GovHelpers.Payload({
      value: 0,
      withDelegatecall: true,
      target: address(forwarder),
      signature: 'execute(address)',
      callData: abi.encode(address(payloadWithEmit))
    });

    uint256 proposalId = GovHelpers.createProposal(
      payloads,
      0xf6e50d5a3f824f5ab4ffa15fb79f4fa1871b8bf7af9e9b32c1aaaa9ea633006d
    );
    vm.stopPrank();

    // 2. execute proposal and record logs so we can extract the emitted StateSynced event
    vm.recordLogs();
    GovHelpers.passVoteAndExecute(vm, proposalId);

    Vm.Log[] memory entries = vm.getRecordedLogs();
    Vm.Log memory bridgeEventLog;
    bool bridgeEventFound = false;
    for (uint256 i = 0; i < entries.length; i++) {
      if (
        entries[i].topics.length > 0 &&
        entries[i].topics[0] == 0x501781209a1f8899323b96b4ef08b168df93e0a90c673d1e4cce39366cb62f9b
      ) {
        bridgeEventLog = entries[i];
        bridgeEventFound = true;
      }
    }
    assertTrue(bridgeEventFound, 'Bridge event not found');
    (, , address originAddress, , address destinationAddress, , bytes memory metadata, ) = abi
      .decode(bridgeEventLog.data, (uint8, uint32, address, uint32, address, uint, bytes, uint32));
    assertEq(destinationAddress, address(executor));
    assertEq(originAddress, address(AaveGovernanceV2.SHORT_EXECUTOR), 'Origin address mismatch');

    // 3. mock the receive on l2 with the data emitted on BridgeEvent
    emit log_bytes(metadata);
    vm.selectFork(zkevmFork);
    vm.prank(zkevmBridge);
    executor.onMessageReceived(originAddress, 0, metadata);

    // 4. Forward time & execute proposal
    vm.expectEmit(true, true, true, true);
    emit TestEvent();
    GovHelpers.executeLatestActionSet(vm, address(executor));
  }
}
