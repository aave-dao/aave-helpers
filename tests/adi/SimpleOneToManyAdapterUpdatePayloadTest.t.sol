// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SimpleOneToManyAdapterUpdate} from '../../src/adi/SimpleOneToManyAdapterUpdate.sol';
import {GovernanceV3Polygon} from 'aave-address-book/GovernanceV3Polygon.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import 'forge-std/Test.sol';
import '../../src/adi/test/ADITestBase.sol';
import {LZAdapterDeploymentHelper, IBaseAdapter as IBaseAdapterMock} from './mocks/AdaptersByteCode.sol';

contract SimpleOneToManyAdapterUpdatePayload is
  SimpleOneToManyAdapterUpdate(
    SimpleOneToManyAdapterUpdate.ConstructorInput({
      ccc: GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER,
      adapterToRemove: address(0)
    })
  )
{
  function getChainsToReceive() public pure override returns (uint256[] memory) {
    uint256[] memory chains = new uint256[](1);
    chains[0] = ChainIds.MAINNET;
    return chains;
  }

  function getDestinationAdapters()
    public
    pure
    override
    returns (DestinationAdaptersInput[] memory)
  {
    DestinationAdaptersInput[] memory destinationAdapters = new DestinationAdaptersInput[](1);

    destinationAdapters[0].adapter = 0x8410d9BD353b420ebA8C48ff1B0518426C280FCC;
    destinationAdapters[0].chainId = ChainIds.MAINNET;

    return destinationAdapters;
  }

  function getNewAdapterCode() public pure override returns (bytes memory) {
    IBaseAdapterMock.TrustedRemotesConfig[]
      memory trustedRemotes = new IBaseAdapterMock.TrustedRemotesConfig[](1);
    trustedRemotes[0] = IBaseAdapterMock.TrustedRemotesConfig({
      originChainId: ChainIds.MAINNET,
      originForwarder: GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER
    });

    return
      LZAdapterDeploymentHelper.getAdapterCode(
        LZAdapterDeploymentHelper.BaseAdapterArgs({
          crossChainController: GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER,
          providerGasLimit: 0,
          trustedRemotes: trustedRemotes,
          isTestnet: false
        }),
        0x1a44076050125825900e736c501f859c50fE728c
      );
  }
}

contract SimpleOneToManyAdapterUpdateEthereumPayload is
  SimpleOneToManyAdapterUpdate(
    SimpleOneToManyAdapterUpdate.ConstructorInput({
      ccc: GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER,
      adapterToRemove: address(0)
    })
  )
{
  function getChainsToReceive() public pure override returns (uint256[] memory) {
    uint256[] memory chains = new uint256[](2);
    chains[0] = ChainIds.POLYGON;
    chains[0] = ChainIds.AVALANCHE;
    return chains;
  }

  function getNewAdapterCode() public pure override returns (bytes memory) {
    IBaseAdapterMock.TrustedRemotesConfig[]
      memory trustedRemotes = new IBaseAdapterMock.TrustedRemotesConfig[](2);
    trustedRemotes[0] = IBaseAdapterMock.TrustedRemotesConfig({
      originChainId: ChainIds.POLYGON,
      originForwarder: GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER
    });
    trustedRemotes[1] = IBaseAdapterMock.TrustedRemotesConfig({
      originChainId: ChainIds.AVALANCHE,
      originForwarder: GovernanceV3Avalanche.CROSS_CHAIN_CONTROLLER
    });

    return
      LZAdapterDeploymentHelper.getAdapterCode(
        LZAdapterDeploymentHelper.BaseAdapterArgs({
          crossChainController: GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER,
          providerGasLimit: 0,
          trustedRemotes: trustedRemotes,
          isTestnet: false
        }),
        0x1a44076050125825900e736c501f859c50fE728c
      );
  }
}

// provably here we should just define the blockNumber and network. And use base test that in theory could generate diffs
contract SimpleOneToManyAdapterUpdatePayloadTest is ADITestBase {
  SimpleOneToManyAdapterUpdatePayload public payload;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('polygon'), 56680671);

    // deploy payload
    payload = new SimpleOneToManyAdapterUpdatePayload();
    // deploy adapter
    GovV3Helpers.deployDeterministic(payload.getNewAdapterCode());
  }

  function getDestinationPayloadsByChain()
    public
    pure
    override
    returns (DestinationPayload[] memory)
  {
    DestinationPayload[] memory destinationPayload = new DestinationPayload[](1);
    destinationPayload[0] = DestinationPayload({
      chainId: ChainIds.MAINNET,
      payloadCode: type(SimpleOneToManyAdapterUpdateEthereumPayload).creationCode
    });

    return destinationPayload;
  }

  function test_defaultTest() public {
    defaultTest(
      'test_adi_diffs',
      GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER,
      address(payload),
      true
    );
  }
}
