// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {AaveV3ZkSync} from 'aave-address-book/AaveV3ZkSync.sol';
import {ProtocolV3TestBase} from '../src/ProtocolV3TestBase.sol';
import {PayloadWithEmit} from '../../tests/mocks/PayloadWithEmit.sol';

contract ProtocolV3TestBaseTest is ProtocolV3TestBase {
  PayloadWithEmit payload;

  function setUp() public override {
    vm.createSelectFork('zksync', 50675012);
    payload = new PayloadWithEmit();

    super.setUp();
  }

  function test_helpers() public {
    defaultTest('zksync', AaveV3ZkSync.POOL, address(payload));
  }
}
