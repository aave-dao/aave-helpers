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
    GovHelpers.DelegateCallProposal[] memory delegateCalls = new GovHelpers.DelegateCallProposal[](
      2
    );
    delegateCalls[0] = GovHelpers.createMainnetDelegateCall(address(1));
    delegateCalls[1] = GovHelpers.createPolygonDelegateCall(address(2));

    vm.startPrank(AaveMisc.ECOSYSTEM_RESERVE);
    GovHelpers.createDelegateCallProposal(delegateCalls, bytes32('ipfs'));
    vm.stopPrank();
  }
}
