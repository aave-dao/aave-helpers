// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IVotingMachineWithProofs, GovV3Helpers, PayloadsControllerUtils, IPayloadsControllerCore, GovV3StorageHelpers, IGovernanceCore} from '../src/GovV3Helpers.sol';
import {GovHelpers} from '../src/GovHelpers.sol';
import {ProtocolV3TestBase} from '../src/ProtocolV3TestBase.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';

import {PayloadWithEmit} from './mocks/PayloadWithEmit.sol';

interface Mock {
  function guardian() external view returns (address);
}

contract GovernanceV3Test is ProtocolV3TestBase {
  event TestEvent();

  PayloadWithEmit payload;

  uint256 public constant LONG_PROPOSAL_ID = 345;
  address public constant SHORT_PROPOSAL = 0xa59262276dB8F997948fdc4a10cBc1448A375636;

  function setUp() public {
    vm.createSelectFork('mainnet', 18363414);
    payload = new PayloadWithEmit();
    GovHelpers.passVoteAndExecute(vm, LONG_PROPOSAL_ID);
    GovHelpers.executePayload(vm, SHORT_PROPOSAL, AaveGovernanceV2.SHORT_EXECUTOR);
  }

  function test_injectProposalIntoGovernance() public {
    uint256 count = GovernanceV3Ethereum.GOVERNANCE.getProposalsCount();
    IPayloadsControllerCore payloadsController = GovV3Helpers.getPayloadsController(block.chainid);

    // 1. create action & register on payloadscontroller
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](1);
    actions[0] = GovV3Helpers.buildAction(address(payload));
    GovV3StorageHelpers.injectPayload(vm, payloadsController, actions);

    PayloadsControllerUtils.Payload[] memory payloads = new PayloadsControllerUtils.Payload[](1);
    payloads[0] = GovV3Helpers.buildMainnetPayload(vm, actions);
    uint256 proposalId = GovV3StorageHelpers.injectProposal(vm, payloads, address(0));
    uint256 countAfter = GovernanceV3Ethereum.GOVERNANCE.getProposalsCount();
    assertEq(countAfter, count + 1);
    IGovernanceCore.Proposal memory proposal = GovernanceV3Ethereum.GOVERNANCE.getProposal(
      proposalId
    );
    assertEq(proposal.payloads.length, payloads.length);

    GovV3StorageHelpers.readyProposal(vm, proposalId);
    IGovernanceCore.Proposal memory readiedProposal = GovernanceV3Ethereum.GOVERNANCE.getProposal(
      proposalId
    );
    assertEq(uint256(readiedProposal.state), uint256(IGovernanceCore.State.Queued));
    //GovernanceV3Ethereum.GOVERNANCE.executeProposal(proposalId);
  }

  function test_injectPayloadIntoPayloadsController() public {
    // 1. create action & register on payloadscontrolelr
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](2);
    actions[0] = GovV3Helpers.buildAction(address(payload));
    actions[1] = GovV3Helpers.buildAction(address(payload));

    IPayloadsControllerCore payloadsController = GovV3Helpers.getPayloadsController(block.chainid);

    uint40 countBefore = payloadsController.getPayloadsCount();
    GovV3StorageHelpers.injectPayload(vm, payloadsController, actions);
    uint40 countAfter = payloadsController.getPayloadsCount();
    // assure count is bumped by one
    assertEq(countAfter, countBefore + 1);

    IPayloadsControllerCore.Payload memory pl = payloadsController.getPayloadById(countBefore);
    assertEq(pl.actions.length, 2);
    assertEq(pl.actions[0].target, address(payload));
    assertEq(pl.actions[0].withDelegateCall, true);
    assertEq(pl.actions[1].target, address(payload));

    assertEq(pl.gracePeriod, payloadsController.GRACE_PERIOD());
    require(pl.state == IPayloadsControllerCore.PayloadState.Created, 'MUST_BE_IN_CREATED_STATE');
  }

  function test_readyPayloadId() public {
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](1);
    actions[0] = GovV3Helpers.buildAction(address(payload));
    uint40 payloadId = GovV3Helpers.createPayload(actions);

    IPayloadsControllerCore payloadsController = GovV3Helpers.getPayloadsController(block.chainid);

    GovV3StorageHelpers.readyPayloadId(vm, payloadsController, payloadId);
    IPayloadsControllerCore.Payload memory pl = payloadsController.getPayloadById(payloadId);
    assertEq(uint256(pl.state), uint256(IPayloadsControllerCore.PayloadState.Queued));
    assertEq(pl.queuedAt, 1697983463);
    assertEq(uint256(pl.maximumAccessLevelRequired), 1);
    assertEq(pl.createdAt, 1698069864);
    assertEq(pl.creator, address(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496));
  }

  /**
   * @dev this test covers the flow that one would usually need to follow within tests
   * it omits the actual governance by directly executing on the payloadController
   */
  function test_executePayloadViaId() public {
    // 1. create action & register on payloadscontroller
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](2);
    actions[0] = GovV3Helpers.buildAction(address(payload));
    actions[1] = GovV3Helpers.buildAction(address(payload));

    uint40 payloadId = GovV3Helpers.createPayload(actions);
    // 2. execute payload
    vm.expectEmit(true, true, true, true);
    emit TestEvent();
    GovV3Helpers.executePayload(vm, uint40(payloadId));
  }

  function test_executePayloadViaAddress() public {
    vm.expectEmit(true, true, true, true);
    emit TestEvent();
    GovV3Helpers.executePayload(vm, address(payload));
  }

  /**
   * Demo: this is more or less how a payload creation script could look like
   */
  function test_payloadCreation() public {
    // 1. deploy payloads
    PayloadWithEmit pl1 = new PayloadWithEmit();
    PayloadWithEmit pl2 = new PayloadWithEmit();

    // 2. create action & register action
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](2);
    actions[0] = GovV3Helpers.buildAction(address(pl1));
    actions[1] = GovV3Helpers.buildAction(address(pl2));
    GovV3Helpers.createPayload(actions);

    // 3. create the actual proposal
    PayloadsControllerUtils.Payload[] memory payloads = new PayloadsControllerUtils.Payload[](1);
    payloads[0] = GovV3Helpers.buildMainnetPayload(vm, actions);
    deal(MiscEthereum.ECOSYSTEM_RESERVE, 0.5e18);
    vm.startPrank(MiscEthereum.ECOSYSTEM_RESERVE);
    GovV3Helpers.createProposal(payloads, 'hash');
    vm.stopPrank();
  }

  function test_helpers() public {
    defaultTest('default', AaveV3Ethereum.POOL, address(payload));
  }
}
