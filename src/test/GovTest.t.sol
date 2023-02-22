// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {GovHelpers, TestWithExecutor} from '../GovHelpers.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';

contract GovernanceTest is Test {
  function setUp() public {
    vm.createSelectFork('mainnet', 16526807);
  }

  function testCreateProposal() public {
    GovHelpers.Payload[] memory payloads = new GovHelpers.Payload[](2);
    payloads[0] = GovHelpers.buildMainnet(address(1));
    payloads[1] = GovHelpers.buildPolygon(address(2));

    vm.startPrank(AaveMisc.ECOSYSTEM_RESERVE);
    GovHelpers.createProposal(payloads, bytes32('ipfs'));
    vm.stopPrank();
  }
}

contract GovernanceExistingProposalTest is TestWithExecutor {
  function setUp() public {
    vm.createSelectFork('polygon', 39582255);
    _selectPayloadExecutor(AaveGovernanceV2.POLYGON_BRIDGE_EXECUTOR);
  }

  function testCreateProposal() public {
    _executor.execute(15);
  }
}
