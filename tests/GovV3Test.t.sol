// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {GovV3Helpers, PayloadsControllerUtils, IPayloadsControllerCore, GovV3StorageHelpers} from '../src/GovV3Helpers.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {PayloadWithEmit} from './mocks/PayloadWithEmit.sol';

interface Mock {
  function guardian() external view returns (address);
}

contract GovernanceV3Test is Test {
  event TestEvent();

  PayloadWithEmit payload;

  function setUp() public {
    vm.createSelectFork('mainnet', 18061912);
    payload = new PayloadWithEmit();
  }

  function test_injectPayloadIntoPayloadsController() public {
    // 1. create action & register on payloadscontrolelr
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](2);
    actions[0] = GovV3Helpers.buildAction(address(payload));
    actions[1] = GovV3Helpers.buildAction(address(payload));

    IPayloadsControllerCore payloadsController = IPayloadsControllerCore(
      GovV3Helpers._getPayloadsController(block.chainid)
    );

    uint40 countBefore = payloadsController.getPayloadsCount();
    GovV3StorageHelpers.injectPayload(vm, address(payloadsController), actions);
    uint40 countAfter = payloadsController.getPayloadsCount();
    // assure count is bumped by one
    assertEq(countAfter, countBefore + 1);

    IPayloadsControllerCore.Payload memory pl = payloadsController.getPayloadById(countBefore);
    assertEq(pl.actions.length, 2);
    assertEq(pl.actions[0].target, address(payload));
    assertEq(pl.actions[0].withDelegateCall, true);
    assertEq(pl.actions[1].target, address(payload));

    assertEq(pl.gracePeriod, payloadsController.GRACE_PERIOD());
  }

  function test_readyPayloadId() public {
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](1);
    actions[0] = GovV3Helpers.buildAction(address(payload));
    uint40 payloadId = GovV3Helpers.createPayload(actions);

    IPayloadsControllerCore payloadsController = IPayloadsControllerCore(
      GovV3Helpers._getPayloadsController(block.chainid)
    );

    GovV3StorageHelpers.readyPayloadId(vm, address(payloadsController), payloadId);
    IPayloadsControllerCore.Payload memory pl = payloadsController.getPayloadById(payloadId);
    assertEq(uint256(pl.state), uint256(IPayloadsControllerCore.PayloadState.Queued));
    assertEq(pl.queuedAt, 1693729594);
    assertEq(uint256(pl.maximumAccessLevelRequired), 1);
    assertEq(pl.createdAt, 1693815995);
    assertEq(pl.creator, address(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496));
  }

  /**
   * @dev this test covers the flow that one would usually need to follow within tests
   * it omits the actual governance by directly executing on the payloadController
   */
  function test_executePayloadViaId() public {
    // 1. create action & register on payloadscontrolelr
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
    uint40 payloadId = GovV3Helpers.createPayload(actions);
  }

  function test_mainnetProposalCreation() public {
    PayloadsControllerUtils.Payload[] memory payloads = new PayloadsControllerUtils.Payload[](1);
    /**
     * Upside:
     * - it's simple & analog to how it worked on gov v2
     * Downside:
     * - 0 chance to validate that `1` is the payload we want to execute
     */
    payloads[0] = buildMainnet(1);

    /**
     * Upside:
     * - we can at least validate the payload Id exists on the l2 and is in created state
     * - we could log the payloadAddresses with explorer links so people can easily double check
     * Downside:
     * - still no forced validation that payloadId is the correct one
     */
    payloads[0] = buildMainnet(vm, 1);

    /**
     * Upside:
     * - easier for the user
     * Downside:
     * - can be quite fragile as payloadAddress, must not be unique
     * - quite implicit
     */
    payloads[0] = buildMainnet(vm, payloadAddress);

    /**
     * Upside:
     * - like 2, but with some basic guarantee that payloadAddress is at least included in actions
     * Downside:
     * - a bit cumbersome as both id and address are needed
     */
    payloads[0] = buildMainnet(vm, 1, payloadAddress);

    /**
     * Upside:
     * - allows us to find the payloadId based on exact actions match. Therefore best assurance
     * Downside:
     * - quite verbose & cumbersome to use i guess?
     */
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](2);
    actions[0] = GovV3Helpers.buildAction(address(pl1));
    actions[1] = GovV3Helpers.buildAction(address(pl2));
    payloads[0] = buildMainnet(vm, actions);
  }
}
