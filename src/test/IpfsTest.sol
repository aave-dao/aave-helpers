// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {ProtocolV3TestBase} from '../ProtocolV3TestBase.sol';
import {AaveV3Polygon} from 'aave-address-book/AaveV3Polygon.sol';

contract IpfsTest is ProtocolV3TestBase {
  /**
   * comparing the generated hash with the one previously generated for 1inch proposal
   */
  function test_validIpfsFile() public {
    bytes32 bs58Hash = ipfsHashFile('src/test/mocks/proposal.md');
    assertEq(
      bs58Hash,
      0x12f2d9c91e4e23ae4009ab9ef5862ee0ae79498937b66252213221f04a5d5b32,
      'HASH_MUST_MATCH'
    );
  }

  // /**
  //  * proposal is missing author and therefore should fail when generating the hash
  //  */
  // function test_invalidIpfsFile() public {
  // not sure how to properly test this as ffi level error on an internal function so i cannot try catch
  //   ipfsHashFile('src/test/mocks/proposal-invalid.md');
  // }
}
