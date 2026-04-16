// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IPool, IPoolDataProvider} from 'aave-address-book/AaveV3.sol';
import {AaveV3MegaEth} from 'aave-address-book/AaveV3MegaEth.sol';

/**
 * @notice Quick smoke test to verify MegaETH fork works via Alchemy RPC.
 *  Run: forge test --mc MegaEthForkTest
 */
contract MegaEthForkTest is Test {
  function setUp() public {
    vm.createSelectFork('megaeth');
  }

  function test_forkBasics() public view {
    console.log('Chain ID:', block.chainid);
    console.log('Block number:', block.number);
    console.log('Block timestamp:', block.timestamp);
  }

  function test_poolReadCalls() public view {
    IPool pool = AaveV3MegaEth.POOL;
    console.log('Pool:', address(pool));

    address[] memory reserves = pool.getReservesList();
    console.log('Reserve count:', reserves.length);
    assertGt(reserves.length, 0, 'no reserves');

    for (uint256 i; i < reserves.length; i++) {
      console.log('  [%s] %s', i, reserves[i]);
    }
  }
}
