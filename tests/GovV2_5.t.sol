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

contract GovernanceV2_5Test is ProtocolV3TestBase {
  event TestEvent();

  PayloadWithEmit payload;

  function setUp() public {
    vm.createSelectFork('mainnet', 18470099);
    payload = new PayloadWithEmit();
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
    vm.startPrank(MiscEthereum.ECOSYSTEM_RESERVE);
    uint256 proposalId = GovV3Helpers.createProposal2_5(vm, payloads, 'hash');
    vm.stopPrank();

    // 4. execute the proposal
    GovHelpers.passVoteAndExecute(vm, proposalId);

    // 5. expect queueing on payloads controller
    IPayloadsControllerCore.Payload memory payloadsControllerPayload = GovernanceV3Ethereum
      .PAYLOADS_CONTROLLER
      .getPayloadById(0);
    require(
      payloadsControllerPayload.state == IPayloadsControllerCore.PayloadState.Queued,
      'SHOULD_BE_QUEUED'
    );
    vm.warp(block.timestamp + payloadsControllerPayload.delay + 1);
    vm.expectEmit(true, true, true, true);
    emit TestEvent();
    GovernanceV3Ethereum.PAYLOADS_CONTROLLER.executePayload(0);
  }

  function test_helpers() public {
    defaultTest('default', AaveV3Ethereum.POOL, address(payload));
  }
}
