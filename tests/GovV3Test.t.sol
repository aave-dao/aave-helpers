// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {GovV3Helpers, PayloadsControllerUtils} from '../src/GovV3Helpers.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {PayloadWithEmit} from './mocks/PayloadWithEmit.sol';

contract GovernanceV3Test is Test {
  function setUp() public {
    vm.createSelectFork('sepolia', 4136682);
  }

  function testCreateProposal() public {
    GovV3Helpers.executePayload(vm, 1);
    // PayloadsControllerUtils.ExecutionAction[]
    //   memory actions = new PayloadsControllerUtils.ExecutionAction[](2);
    // actions[0] = GovV3Helpers.buildMainnet(1);
    // actions[1] = GovV3Helpers.buildPolygon(2);
    // vm.startPrank(AaveMisc.ECOSYSTEM_RESERVE);
    // GovHelpers.createProposal(payloads, bytes32('ipfs'));
    // vm.stopPrank();
  }
}
