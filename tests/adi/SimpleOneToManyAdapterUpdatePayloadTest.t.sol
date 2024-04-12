// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SimpleOneToManyAdapterUpdate} from '../../src/adi/SimpleOneToManyAdapterUpdate.sol';
import {GovernanceV3Polygon} from 'aave-address-book/GovernanceV3Polygon.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {ChainIds} from '../../src/ChainIds.sol';
import 'forge-std/Test.sol';
import '../../src/adi/test/ADITestBase.sol';

contract SimpleOneToManyAdapterUpdatePayload is
  SimpleOneToManyAdapterUpdate(
    SimpleOneToManyAdapterUpdate.ConstructorInput({
      ccc: GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER,
      newAdapter: 0x7FAE7765abB4c8f778d57337bB720d0BC53057e3,
      adapterToRemove: 0xDA4B6024aA06f7565BBcAaD9B8bE24C3c229AAb5
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
}

contract SimpleOneToManyAdapterUpdateEthereumPayload is
  SimpleOneToManyAdapterUpdate(
    SimpleOneToManyAdapterUpdate.ConstructorInput({
      ccc: GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER,
      newAdapter: 0x8410d9BD353b420ebA8C48ff1B0518426C280FCC, // POLYGON native bridge adapter
      adapterToRemove: 0xb13712De579E1f9943502FFCf72eab6ec348cF79 // POLYGON
    })
  )
{
  function getChainsToReceive() public pure override returns (uint256[] memory) {
    uint256[] memory chains = new uint256[](1);
    chains[0] = ChainIds.POLYGON;
    return chains;
  }
}

// provably here we should just define the blockNumber and network. And use base test that in theory could generate diffs
contract SimpleOneToManyAdapterUpdatePayloadTest is ADITestBase {
  SimpleOneToManyAdapterUpdatePayload public payload;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('polygon'), 55428042);
    payload = new SimpleOneToManyAdapterUpdatePayload();
  }

  function getDestinationPayloadsByChain()
    public
    view
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
