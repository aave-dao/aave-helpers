// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5 <0.9.0;
pragma abicoder v2;

import 'forge-std/Vm.sol';
import {AaveGovernanceV2, IAaveGovernanceV2, IExecutorWithTimelock} from 'aave-address-book/AaveGovernanceV2.sol';

library GovHelpers {
  struct SPropCreateParams {
    address executor;
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
    bytes32 ipfsHash;
  }

  IAaveGovernanceV2 internal constant GOV = IAaveGovernanceV2(0xEC568fffba86c094cf06b22134B23074DFE2252c);

  address public constant SHORT_EXECUTOR = 0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

  address public constant LONG_EXECUTOR = 0x79426A1c24B2978D90d7A5070a46C65B07bC4299;

  address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

  address internal constant AAVE_WHALE = address(0x25F2226B597E8F9514B3F68F00f494cF4f286491);

  /**
   * Impersonate the ecosystem reserve and created the proposal.
   */
  function createProposal(Vm vm, SPropCreateParams memory params) internal returns (uint256) {
    vm.deal(AAVE_WHALE, 1 ether);
    vm.startPrank(AAVE_WHALE);
    uint256 proposalId = GOV.create(
      IExecutorWithTimelock(params.executor),
      params.targets,
      params.values,
      params.signatures,
      params.calldatas,
      params.withDelegatecalls,
      params.ipfsHash
    );
    vm.stopPrank();
    return proposalId;
  }

  function _getProposalSlot(uint256 proposalId) private pure returns (bytes32 slot) {
    uint256 proposalsMapSlot = 0x4;
    return bytes32(uint256(keccak256(abi.encode(proposalId, proposalsMapSlot))) + 11);
  }

  /**
   * Alter storage slots so the proposal passes
   */
  function passVoteAndExecute(Vm vm, uint256 proposalId) internal {
    uint256 power = 5000000 ether;
    vm.roll(block.number + 1);
    vm.store(address(GOV), _getProposalSlot(proposalId), bytes32(power));
    uint256 endBlock = GOV.getProposalById(proposalId).endBlock;
    vm.roll(endBlock + 1);
    GOV.queue(proposalId);
    uint256 executionTime = GOV.getProposalById(proposalId).executionTime;
    vm.warp(executionTime + 1);
    GOV.execute(proposalId);
  }

  function getProposalById(uint256 proposalId)
    internal
    view
    returns (IAaveGovernanceV2.ProposalWithoutVotes memory)
  {
    return GOV.getProposalById(proposalId);
  }
}
