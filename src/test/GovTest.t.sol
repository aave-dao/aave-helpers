// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {DelegatecallProposalCreationHelper, GovHelpers} from '../GovHelpers.sol';

contract GovernanceTest is Test {
  function setUp() public {
    vm.createSelectFork('mainnet', 16526807);
  }

  function testCreateProposal() public {
    DelegatecallProposalCreationHelper.DelegateCallProposal[]
      memory delegateCalls = new DelegatecallProposalCreationHelper.DelegateCallProposal[](2);
    delegateCalls[0] = DelegatecallProposalCreationHelper.createMainnetDelegateCall(address(1));
    delegateCalls[1] = DelegatecallProposalCreationHelper.createPolygonDelegateCall(address(2));

    vm.startPrank(GovHelpers.AAVE_WHALE);
    DelegatecallProposalCreationHelper.createProposal(delegateCalls, bytes32('ipfs'));
    vm.stopPrank();
  }
}
