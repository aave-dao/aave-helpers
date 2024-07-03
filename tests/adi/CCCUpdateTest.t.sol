// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {CCCUpdateArgs, BaseCCCUpdate} from '../../src/adi/BaseCCCUpdate.sol';
import '../../src/adi/test/ADITestBase.sol';
import {CCCMock} from './mocks/CCCMock.sol';

contract UpdateCCCPayload is BaseCCCUpdate {
  constructor(
    address newCCCImpl
  )
    BaseCCCUpdate(
      CCCUpdateArgs({
        crossChainController: GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER,
        proxyAdmin: MiscEthereum.PROXY_ADMIN,
        crossChainControllerImpl: newCCCImpl
      })
    )
  {}

  function getInitializeSignature() public pure override returns (bytes memory) {
    return abi.encodeWithSignature('initializeRevision()');
  }
}

contract UpdateCCCImplTest is ADITestBase {
  UpdateCCCPayload public payload;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 20130837);
    address cccImpl = address(new CCCMock());
    payload = new UpdateCCCPayload(cccImpl);
  }

  function test_defaultTest() public {
    //    defaultTest(
    //      'test_ccc_update_adi_diffs',
    //      GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER,
    //      address(payload),
    //      false,
    //      vm
    //    );
  }
}
