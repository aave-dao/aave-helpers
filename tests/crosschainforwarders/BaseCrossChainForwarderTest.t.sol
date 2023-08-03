// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {AaveMisc} from 'aave-address-book/AaveAddressBook.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {IL2CrossDomainMessenger} from 'governance-crosschain-bridges/contracts/dependencies/optimism/interfaces/IL2CrossDomainMessenger.sol';
import {AddressAliasHelper} from 'governance-crosschain-bridges/contracts/dependencies/arbitrum/AddressAliasHelper.sol';
import {GovHelpers} from '../../src/GovHelpers.sol';
import {ProtocolV3TestBase} from '../../src/ProtocolV3TestBase.sol';
import {CrosschainForwarderBase} from '../../src/crosschainforwarders/CrosschainForwarderBase.sol';
import {PayloadWithEmit} from '../mocks/PayloadWithEmit.sol';
import {ICrossDomainMessenger} from './ICrossDomainMessenger.sol';
/**
 * This test covers syncing between mainnet and metis.
 */
contract BaseCrossChainForwarderTest is ProtocolV3TestBase {
  event TestEvent();
  // the identifiers of the forks
  uint256 mainnetFork;
  uint256 baseFork;

  // TODO: replace with address-book
  address public constant BASE_BRIDGE_EXECUTOR = 0xA9F30e6ED4098e9439B2ac8aEA2d3fc26BcEbb45;

  ICrossDomainMessenger public OVM_L2_CROSS_DOMAIN_MESSENGER =
    ICrossDomainMessenger(0x4200000000000000000000000000000000000007);

  PayloadWithEmit public payloadWithEmit;

  CrosschainForwarderBase public forwarder;

  function setUp() public {
    mainnetFork = vm.createSelectFork(vm.rpcUrl('mainnet'), 17834369);
    forwarder = new CrosschainForwarderBase();
    baseFork = vm.createSelectFork(vm.rpcUrl('base'), 2137538);
    payloadWithEmit = new PayloadWithEmit();
  }

  function testProposalE2E() public {
    // 1. create l1 proposal
    vm.selectFork(mainnetFork);
    vm.startPrank(AaveMisc.ECOSYSTEM_RESERVE);
    GovHelpers.Payload[] memory payloads = new GovHelpers.Payload[](1);
    payloads[0] = GovHelpers.Payload({
      target: address(forwarder),
      value: 0,
      signature: 'execute(address)',
      callData: abi.encode(address(payloadWithEmit)),
      withDelegatecall: true
    });

    uint256 proposalId = GovHelpers.createProposal(payloads, 0x7ecafb3b0b7e418336cccb0c82b3e25944011bf11e41f8dc541841da073fe4f1);
    vm.stopPrank();

    // 2. execute proposal and record logs so we can extract the emitted StateSynced event
    vm.recordLogs();
    GovHelpers.passVoteAndExecute(vm, proposalId);
    Vm.Log[] memory entries = vm.getRecordedLogs();
    assertEq(keccak256('SentMessage(address,address,bytes,uint256,uint256)'), entries[3].topics[0]);
    assertEq(address(uint160(uint256(entries[3].topics[1]))), BASE_BRIDGE_EXECUTOR);
    (address sender, bytes memory message, uint256 nonce) = abi.decode(
      entries[3].data,
      (address, bytes, uint256)
    );


    // 3. mock the receive on l2 with the data emitted on StateSynced
    vm.selectFork(baseFork);
    address relayer = AddressAliasHelper.applyL1ToL2Alias(0x866E82a600A1414e583f7F13623F1aC5d58b0Afa);
    vm.startPrank(relayer); // AddressAliasHelper.applyL1ToL2Alias on L1_CROSS_DOMAIN_MESSENGER_ADDRESS
    OVM_L2_CROSS_DOMAIN_MESSENGER.relayMessage(nonce, sender, BASE_BRIDGE_EXECUTOR, 0, 2000000, message);
    vm.stopPrank();

    // 4. execute proposal on l2
    vm.expectEmit(true, true, true, true);
    emit TestEvent();
    GovHelpers.executeLatestActionSet(vm, BASE_BRIDGE_EXECUTOR);
  }
}
