// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {GovHelpers} from '../GovHelpers.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';

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
