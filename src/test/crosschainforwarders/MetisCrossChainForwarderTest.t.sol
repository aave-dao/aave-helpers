// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {AaveMisc} from 'aave-address-book/AaveAddressBook.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {IL2CrossDomainMessenger} from 'governance-crosschain-bridges/contracts/dependencies/optimism/interfaces/IL2CrossDomainMessenger.sol';
import {GovHelpers} from '../../GovHelpers.sol';
import {ProtocolV3TestBase} from '../../ProtocolV3TestBase.sol';
import {CrosschainForwarderMetis} from '../../crosschainforwarders/CrosschainForwarderMetis.sol';
import {PayloadWithEmit} from '../mocks/PayloadWithEmit.sol';

/**
 * This test covers syncing between mainnet and metis.
 */
contract MetisCrossChainForwarderTest is ProtocolV3TestBase {
  event TestEvent();
  // the identifiers of the forks
  uint256 mainnetFork;
  uint256 metisFork;

  address public constant METIS_BRIDGE_EXECUTOR = AaveGovernanceV2.METIS_BRIDGE_EXECUTOR;

  IL2CrossDomainMessenger public OVM_L2_CROSS_DOMAIN_MESSENGER =
    IL2CrossDomainMessenger(0x4200000000000000000000000000000000000007);

  PayloadWithEmit public payloadWithEmit;

  CrosschainForwarderMetis public forwarder;

  function setUp() public {
    mainnetFork = vm.createSelectFork(vm.rpcUrl('mainnet'), 17093477);
    forwarder = new CrosschainForwarderMetis();
    metisFork = vm.createSelectFork(vm.rpcUrl('metis'), 5428548);
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

    uint256 proposalId = GovHelpers.createProposal(payloads, 'ipfs');
    vm.stopPrank();

    // 2. execute proposal and record logs so we can extract the emitted StateSynced event
    vm.recordLogs();
    GovHelpers.passVoteAndExecute(vm, proposalId);
    Vm.Log[] memory entries = vm.getRecordedLogs();
    assertEq(
      keccak256('SentMessage(address,address,bytes,uint256,uint256,uint256)'),
      entries[3].topics[0]
    );
    assertEq(address(uint160(uint256(entries[3].topics[1]))), METIS_BRIDGE_EXECUTOR);
    (address sender, bytes memory message, uint256 nonce) = abi.decode(
      entries[3].data,
      (address, bytes, uint256)
    );

    // 3. mock the receive on l2 with the data emitted on StateSynced
    vm.selectFork(metisFork);
    vm.startPrank(0x192E1101855bD523Ba69a9794e0217f0Db633510); // AddressAliasHelper.applyL1ToL2Alias on L1_CROSS_DOMAIN_MESSENGER_ADDRESS
    OVM_L2_CROSS_DOMAIN_MESSENGER.relayMessage(METIS_BRIDGE_EXECUTOR, sender, message, nonce);
    vm.stopPrank();

    // 4. execute proposal on l2
    vm.expectEmit(true, true, true, true);
    emit TestEvent();
    GovHelpers.executeLatestActionSet(vm);
  }
}
