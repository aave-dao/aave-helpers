// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {AaveV3Optimism, AaveMisc} from 'aave-address-book/AaveAddressBook.sol';
import {AaveGovernanceV2, IExecutorWithTimelock} from 'aave-address-book/AaveGovernanceV2.sol';
import {AddressAliasHelper} from 'governance-crosschain-bridges/contracts/dependencies/arbitrum/AddressAliasHelper.sol';
import {IL2CrossDomainMessenger} from 'governance-crosschain-bridges/contracts/dependencies/optimism/interfaces/IL2CrossDomainMessenger.sol';
import {GovHelpers} from '../../GovHelpers.sol';
import {ProtocolV3TestBase, ReserveConfig, ReserveTokens, IERC20} from '../../ProtocolV3TestBase.sol';
import {CrosschainForwarderOptimism} from '../../crosschainforwarders/CrosschainForwarderOptimism.sol';
import {PayloadWithEmit} from '../mocks/PayloadWithEmit.sol';

/**
 * This test covers syncing between mainnet and optimism.
 */
contract OptimismCrossChainForwarderTest is ProtocolV3TestBase {
  event TestEvent();
  // the identifiers of the forks
  uint256 mainnetFork;
  uint256 optimismFork;

  address public constant OPTIMISM_BRIDGE_EXECUTOR = AaveGovernanceV2.OPTIMISM_BRIDGE_EXECUTOR;

  IL2CrossDomainMessenger public OVM_L2_CROSS_DOMAIN_MESSENGER =
    IL2CrossDomainMessenger(0x4200000000000000000000000000000000000007);

  PayloadWithEmit public payloadWithEmit;

  CrosschainForwarderOptimism public forwarder;

  function setUp() public {
    mainnetFork = vm.createSelectFork(vm.rpcUrl('mainnet'), 15783218);
    forwarder = new CrosschainForwarderOptimism();
    optimismFork = vm.createSelectFork(vm.rpcUrl('optimism'), 30264427);
    payloadWithEmit = new PayloadWithEmit();
  }

  function testProposalE2E() public {
    // 1. create l1 proposal
    vm.selectFork(mainnetFork);
    vm.startPrank(AaveMisc.ECOSYSTEM_RESERVE);
    GovHelpers.Payload[] memory payloads = new GovHelpers.Payload[](1);
    payloads[0] = GovHelpers.Payload({
      target: address(forwarder),
      signature: 'execute(address)',
      callData: abi.encode(address(payloadWithEmit))
    });

    uint256 proposalId = GovHelpers.createProposal(
      payloads,
      0x7ecafb3b0b7e418336cccb0c82b3e25944011bf11e41f8dc541841da073fe4f1
    );
    vm.stopPrank();

    // 2. execute proposal and record logs so we can extract the emitted StateSynced event
    vm.recordLogs();
    GovHelpers.passVoteAndExecute(vm, proposalId);
    Vm.Log[] memory entries = vm.getRecordedLogs();
    assertEq(keccak256('SentMessage(address,address,bytes,uint256,uint256)'), entries[3].topics[0]);
    assertEq(address(uint160(uint256(entries[3].topics[1]))), OPTIMISM_BRIDGE_EXECUTOR);
    (address sender, bytes memory message, uint256 nonce) = abi.decode(
      entries[3].data,
      (address, bytes, uint256)
    );

    // 3. mock the receive on l2 with the data emitted on StateSynced
    vm.selectFork(optimismFork);
    vm.startPrank(0x36BDE71C97B33Cc4729cf772aE268934f7AB70B2); // AddressAliasHelper.applyL1ToL2Alias on L1_CROSS_DOMAIN_MESSENGER_ADDRESS
    OVM_L2_CROSS_DOMAIN_MESSENGER.relayMessage(OPTIMISM_BRIDGE_EXECUTOR, sender, message, nonce);
    vm.stopPrank();

    // 4. execute proposal on l2
    vm.expectEmit(true, true, true, true);
    emit TestEvent();
    GovHelpers.executeLatestActionSet(vm);
  }
}
