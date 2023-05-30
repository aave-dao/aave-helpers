// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {ProtocolV2TestBase, ReserveConfig} from '../ProtocolV2TestBase.sol';
import {AaveV2Ethereum} from 'aave-address-book/AaveV2Ethereum.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';

contract ProtocolV2TestBaseTest is ProtocolV2TestBase {
  function setUp() public {
    vm.createSelectFork('mainnet', 17293676);
  }

  function testSnpashot() public {
    this.createConfigurationSnapshot('v2-report', AaveV2Ethereum.POOL);
  }

  function testE2E() public {
    address user = vm.addr(3);
    this.e2eTest(AaveV2Ethereum.POOL, user);
  }
}
