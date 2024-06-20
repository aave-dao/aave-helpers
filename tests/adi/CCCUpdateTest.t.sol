// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GovernanceV3Polygon} from 'aave-address-book/GovernanceV3Polygon.sol';
import {MiscPolygon} from 'aave-address-book/MiscPolygon.sol';
import {CCCUpdateArgs, BaseCCCUpdate} from '../../src/adi/BaseCCCUpdate.sol';
import '../../src/adi/test/ADITestBase.sol';
import {CCCMock} from './mocks/CCCMock.sol';

contract UpdateCCCPayload is BaseCCCUpdate {
  constructor(
    address newCCCImpl
  )
    BaseCCCUpdate(
      CCCUpdateArgs({
        crossChainController: GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER,
        proxyAdmin: MiscPolygon.PROXY_ADMIN,
        newCCCImpl: newCCCImpl
      })
    )
  {
    console.log('new ccc constructor', newCCCImpl);
  }

  function getInitializeSignature() public pure override returns (bytes memory) {
    return abi.encodeWithSignature('initializeRevision()');
  }
}

contract UpdateCCCImplTest is ADITestBase {
  UpdateCCCPayload public payload;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('polygon'), 58369335);
    address cccImpl = address(new CCCMock());
    console.log('impl', cccImpl);
    payload = new UpdateCCCPayload(cccImpl);
  }

  function test_defaultTest() public {
    defaultTest(
      'test_ccc_update_adi_diffs',
      GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER,
      address(payload),
      false
    );
  }
}
