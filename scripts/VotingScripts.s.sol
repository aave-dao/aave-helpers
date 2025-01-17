// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IVotingMachineWithProofs} from 'aave-address-book/governance-v3/IVotingMachineWithProofs.sol';
import {EthereumScript} from 'solidity-utils/contracts/utils/ScriptUtils.sol';
import {GovV3Helpers} from '../src/GovV3Helpers.sol';

contract VoteForProposal is EthereumScript {
  function run(uint256 proposalId, bool support) external broadcast {
    IVotingMachineWithProofs.VotingBalanceProof[] memory votingBalanceProofs = GovV3Helpers
      .getVotingProofs(vm, proposalId, msg.sender);
    GovV3Helpers.vote(vm, proposalId, votingBalanceProofs, support);
  }
}
