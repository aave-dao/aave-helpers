// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../src/aDI/SimpleOneToManyAdapterUpdate.sol';
import {GovernanceV3Polygon} from 'aave-address-book/GovernanceV3Polygon.sol';
import {ChainIds} from '../../src/ChainIds.sol';
import 'forge-std/Test.sol';
import '../../src/adi/test/ADITestBase.sol';

contract SimpleOneToManyAdapterUpdatePayload is
  SimpleOneToManyAdapterUpdate(
    SimpleOneToManyAdapterUpdate.ConstructorInput({
      ccc: GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER,
      newAdapter: 0x853649f897383f89d8441346Cf26a9ed02720B02,
      adapterToRemove: 0xb13712De579E1f9943502FFCf72eab6ec348cF79
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

    destinationAdapters[0].adapter = 0x1562F1b2487F892BBA8Ef325aF054Fd157510a71;
    destinationAdapters[0].chainId = ChainIds.MAINNET;

    return destinationAdapters;
  }
}

// provably here we should just define the blockNumber and network. And use base test that in theory could generate diffs
contract SimpleOneToManyAdapterUpdatePayloadTest is ADITestBase {
  SimpleOneToManyAdapterUpdatePayload public payload;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('polygon'), 54954005);
    payload = new SimpleOneToManyAdapterUpdatePayload();
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
