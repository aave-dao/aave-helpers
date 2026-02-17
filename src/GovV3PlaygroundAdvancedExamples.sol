// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './GovV3PlaygroundAdvanced.sol';

contract LetMeJustHaveSome {
  string public name = 'some';
}

contract LetMeJustHaveAnother {
  string public name = 'another';
}

abstract contract MyPayloads is WithPayloads {
  function getActions() public pure override returns (ActionsPerChain[] memory) {
    ActionsPerChain[] memory payloads = new ActionsPerChain[](2);

    payloads[0].chainName = 'ethereum';
    payloads[0].actionCode = new bytes[](1);
    payloads[0].actionCode[0] = type(LetMeJustHaveSome).creationCode;

    payloads[1].chainName = 'polygon';
    payloads[1].actionCode = new bytes[](1);
    payloads[1].actionCode[0] = type(LetMeJustHaveAnother).creationCode;

    return payloads;
  }
}

contract DeploymentComplexEthereum is MyPayloads, DeployPayloadsEthereum {}

contract DeploymentComplexPolygon is MyPayloads, DeployPayloadsPolygon {}

// depends on what will be better for generator
contract DeploymentComplexPoly is MyPayloads, DeployPayloadsSingleChain('polygon') {

}

// I think it will look way better
// contract ProposalCreationComplex is
//   MyPayloads,
//   CreateProposal('20240121', 'UpdateStETHAndWETHRiskParamsOnAaveV3EthereumOptimismAndArbitrum')
// {}
contract ProposalCreationComplex is
  MyPayloads,
  CreateProposal(
    'src/20240121_Multi_UpdateStETHAndWETHRiskParamsOnAaveV3EthereumOptimismAndArbitrum/UpdateStETHAndWETHRiskParamsOnAaveV3EthereumOptimismAndArbitrum.md'
  )
{

}
