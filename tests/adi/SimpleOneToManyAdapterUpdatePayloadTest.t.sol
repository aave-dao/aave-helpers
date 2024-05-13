// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SimpleOneToManyAdapterUpdate} from '../../src/adi/SimpleOneToManyAdapterUpdate.sol';
import {GovernanceV3Polygon} from 'aave-address-book/GovernanceV3Polygon.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import 'forge-std/Test.sol';
import '../../src/adi/test/ADITestBase.sol';
import {MockAdapterDeploymentHelper} from './mocks/AdaptersByteCode.sol';

contract SimpleOneToManyAdapterUpdatePayload is SimpleOneToManyAdapterUpdate {
  constructor(
    address crossChainController,
    address newAdapter
  )
    SimpleOneToManyAdapterUpdate(
      SimpleOneToManyAdapterUpdate.ConstructorInput({
        ccc: crossChainController,
        adapterToRemove: address(0),
        newAdapter: newAdapter
      })
    )
  {}

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
}

contract SimpleOneToManyAdapterUpdateEthereumPayload is SimpleOneToManyAdapterUpdate {
  constructor(
    address crossChainController,
    address newAdapter
  )
    SimpleOneToManyAdapterUpdate(
      SimpleOneToManyAdapterUpdate.ConstructorInput({
        ccc: crossChainController,
        adapterToRemove: address(0),
        newAdapter: newAdapter
      })
    )
  {}

  function getChainsToReceive() public pure override returns (uint256[] memory) {
    uint256[] memory chains = new uint256[](2);
    chains[0] = ChainIds.POLYGON;
    chains[1] = ChainIds.AVALANCHE;
    return chains;
  }
}

// provably here we should just define the blockNumber and network. And use base test that in theory could generate diffs
contract SimpleOneToManyAdapterUpdatePayloadTest is ADITestBase {
  SimpleOneToManyAdapterUpdatePayload public payload;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('polygon'), 56680671);
    // create payload constructor args
    IBaseAdapter.TrustedRemotesConfig[]
      memory trustedRemotes = new IBaseAdapter.TrustedRemotesConfig[](1);
    trustedRemotes[0] = IBaseAdapter.TrustedRemotesConfig({
      originChainId: ChainIds.MAINNET,
      originForwarder: GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER
    });

    MockAdapterDeploymentHelper.MockAdapterArgs memory args = MockAdapterDeploymentHelper
      .MockAdapterArgs({
        baseArgs: MockAdapterDeploymentHelper.BaseAdapterArgs({
          crossChainController: GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER,
          providerGasLimit: 0,
          trustedRemotes: trustedRemotes,
          isTestnet: false
        }),
        mockEndpoint: 0x1a44076050125825900e736c501f859c50fE728c
      });

    // deploy adapter
    address newAdapter = GovV3Helpers.deployDeterministic(
      MockAdapterDeploymentHelper.getAdapterCode(args)
    );
    // deploy payload
    payload = new SimpleOneToManyAdapterUpdatePayload(
      GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER,
      newAdapter
    );
  }

  function getDestinationPayloadsByChain()
    public
    pure
    override
    returns (DestinationPayload[] memory)
  {
    DestinationPayload[] memory destinationPayload = new DestinationPayload[](1);

    IBaseAdapter.TrustedRemotesConfig[]
      memory trustedRemotes = new IBaseAdapter.TrustedRemotesConfig[](2);
    trustedRemotes[0] = IBaseAdapter.TrustedRemotesConfig({
      originChainId: ChainIds.POLYGON,
      originForwarder: GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER
    });
    trustedRemotes[1] = IBaseAdapter.TrustedRemotesConfig({
      originChainId: ChainIds.AVALANCHE,
      originForwarder: GovernanceV3Avalanche.CROSS_CHAIN_CONTROLLER
    });

    MockAdapterDeploymentHelper.MockAdapterArgs memory args = MockAdapterDeploymentHelper
      .MockAdapterArgs({
        baseArgs: MockAdapterDeploymentHelper.BaseAdapterArgs({
          crossChainController: GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER,
          providerGasLimit: 0,
          trustedRemotes: trustedRemotes,
          isTestnet: false
        }),
        mockEndpoint: 0x1a44076050125825900e736c501f859c50fE728c
      });

    bytes memory adapterCode = MockAdapterDeploymentHelper.getAdapterCode(args);

    address newAdapter = GovV3Helpers.predictDeterministicAddress(adapterCode);

    destinationPayload[0] = DestinationPayload({
      chainId: ChainIds.MAINNET,
      payloadCode: abi.encodePacked(
        type(SimpleOneToManyAdapterUpdateEthereumPayload).creationCode,
        abi.encode(GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER, newAdapter)
      )
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
