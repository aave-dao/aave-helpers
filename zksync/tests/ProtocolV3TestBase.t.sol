// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {ProtocolV3TestBase} from '../src/ProtocolV3TestBase.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {AaveV3ZkSync} from 'aave-address-book/AaveV3ZkSync.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';

contract GovernanceV3TestZkSync is ProtocolV3TestBase {
  function setUp() public override {
    vm.createSelectFork('zksync', 42185953);
    super.setUp();
  }

  function test_helpers() public {
    defaultTest('zksync', AaveV3ZkSync.POOL, address(0xB8c88b80f3bd77fa0Ea7DC831549e9bdcC024DF3));
  }
}
