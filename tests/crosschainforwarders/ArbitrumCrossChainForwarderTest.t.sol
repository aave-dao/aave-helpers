// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {AaveV3Arbitrum, AaveMisc} from 'aave-address-book/AaveAddressBook.sol';
import {AaveGovernanceV2, IExecutorWithTimelock} from 'aave-address-book/AaveGovernanceV2.sol';
import {AddressAliasHelper} from 'governance-crosschain-bridges/contracts/dependencies/arbitrum/AddressAliasHelper.sol';
import {IInbox} from 'governance-crosschain-bridges/contracts/dependencies/arbitrum/interfaces/IInbox.sol';
import {IL2BridgeExecutor} from 'governance-crosschain-bridges/contracts/interfaces/IL2BridgeExecutor.sol';
import {GovHelpers} from '../../src/GovHelpers.sol';
import {ProtocolV3TestBase, ReserveConfig, ReserveTokens, IERC20} from '../../src/ProtocolV3TestBase.sol';
import {ProtocolV3TestBase, ReserveConfig} from '../../src/ProtocolV3TestBase.sol';
import {CrosschainForwarderArbitrum} from '../../src/crosschainforwarders/CrosschainForwarderArbitrum.sol';
import {PayloadWithEmit} from '../mocks/PayloadWithEmit.sol';

/**
 * This test covers syncing between mainnet and arbitrum.
 */
contract ArbitrumCrossChainForwarderTest is ProtocolV3TestBase {
  event TestEvent();

  // the identifiers of the forks
  uint256 mainnetFork;
  uint256 arbitrumFork;

  PayloadWithEmit public payloadWithEmit;

  IInbox public constant INBOX = IInbox(0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f);

  address public constant ARBITRUM_BRIDGE_EXECUTOR = AaveGovernanceV2.ARBITRUM_BRIDGE_EXECUTOR;

  uint256 public constant MESSAGE_LENGTH = 580;

  CrosschainForwarderArbitrum public forwarder;

  function setUp() public {
    mainnetFork = vm.createSelectFork(vm.rpcUrl('mainnet'), 16128510);
    forwarder = new CrosschainForwarderArbitrum();
    arbitrumFork = vm.createSelectFork(vm.rpcUrl('arbitrum'), 76261612);
    payloadWithEmit = new PayloadWithEmit();
  }

  // utility to transform memory to calldata so array range access is available
  function _cutBytes(bytes calldata input) public pure returns (bytes calldata) {
    return input[64:];
  }

  function testHasSufficientGas() public {
    vm.selectFork(mainnetFork);
    assertEq(AaveGovernanceV2.SHORT_EXECUTOR.balance, 0);
    (bool hasEnoughGasBefore, ) = forwarder.hasSufficientGasForExecution(580);
    assertEq(hasEnoughGasBefore, false);
    deal(address(AaveGovernanceV2.SHORT_EXECUTOR), 0.001 ether);
    (bool hasEnoughGasAfter, ) = forwarder.hasSufficientGasForExecution(580);
    assertEq(hasEnoughGasAfter, true);
  }

  function testgetGetMaxSubmissionCost() public {
    vm.selectFork(mainnetFork);
    (uint256 maxSubmission, ) = forwarder.getRequiredGas(580);
    assertGt(maxSubmission, 0);
  }

  function testProposalE2E() public {
    // assumes the short exec will be topped up with some eth to pay for l2 fee
    vm.selectFork(mainnetFork);
    deal(address(AaveGovernanceV2.SHORT_EXECUTOR), 0.001 ether);

    // 1. create l1 proposal
    vm.startPrank(AaveMisc.ECOSYSTEM_RESERVE);
    GovHelpers.Payload[] memory payloads = new GovHelpers.Payload[](1);
    payloads[0] = GovHelpers.Payload({
      target: address(forwarder),
      value: 0,
      signature: 'execute(address)',
      callData: abi.encode(address(payloadWithEmit)),
      withDelegatecall: true
    });

    uint256 proposalId = GovHelpers.createProposal(
      payloads,
      0xec9d2289ab7db9bfbf2b0f2dd41ccdc0a4003e9e0d09e40dee09095145c63fb5
    );
    vm.stopPrank();

    // 2. execute proposal and record logs so we can extract the emitted StateSynced event
    vm.recordLogs();
    bytes memory payload = forwarder.getEncodedPayload(address(payloadWithEmit));

    (uint256 maxSubmission, ) = forwarder.getRequiredGas(580);
    // check ticket is created correctly
    vm.expectCall(
      address(INBOX),
      abi.encodeCall(
        IInbox.unsafeCreateRetryableTicket,
        (
          ARBITRUM_BRIDGE_EXECUTOR,
          0,
          maxSubmission,
          forwarder.ARBITRUM_BRIDGE_EXECUTOR(),
          forwarder.ARBITRUM_GUARDIAN(),
          forwarder.L2_GAS_LIMIT(),
          forwarder.L2_MAX_FEE_PER_GAS(),
          payload
        )
      )
    );
    GovHelpers.passVoteAndExecute(vm, proposalId);

    // check events are emitted correctly
    Vm.Log[] memory entries = vm.getRecordedLogs();
    assertEq(keccak256('InboxMessageDelivered(uint256,bytes)'), entries[3].topics[0]);
    // uint256 messageId = uint256(entries[3].topics[1]);
    (
      address to,
      uint256 callvalue,
      uint256 value,
      uint256 maxSubmissionCost,
      address excessFeeRefundAddress,
      address callValueRefundAddress,
      uint256 maxGas,
      uint256 gasPriceBid,
      uint256 length
    ) = abi.decode(
        this._cutBytes(entries[3].data),
        (address, uint256, uint256, uint256, address, address, uint256, uint256, uint256)
      );
    assertEq(callvalue, 0);
    assertEq(value > 0, true);
    assertEq(maxSubmissionCost > 0, true);
    assertEq(to, ARBITRUM_BRIDGE_EXECUTOR);
    assertEq(excessFeeRefundAddress, ARBITRUM_BRIDGE_EXECUTOR);
    assertEq(callValueRefundAddress, forwarder.ARBITRUM_GUARDIAN());
    assertEq(maxGas, forwarder.L2_GAS_LIMIT());
    assertEq(gasPriceBid, forwarder.L2_MAX_FEE_PER_GAS());
    assertEq(length, 580);

    // 3. mock the queuing on l2 with the data emitted on InboxMessageDelivered
    vm.selectFork(arbitrumFork);
    vm.startPrank(AddressAliasHelper.applyL1ToL2Alias(AaveGovernanceV2.SHORT_EXECUTOR));

    (bool success, ) = ARBITRUM_BRIDGE_EXECUTOR.call(payload);
    assertEq(success, true);
    vm.stopPrank();
    // 4. execute the proposal
    vm.expectEmit(true, true, true, true);
    emit TestEvent();
    GovHelpers.executeLatestActionSet(vm, ARBITRUM_BRIDGE_EXECUTOR);
  }
}
