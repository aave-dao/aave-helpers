// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5 <0.9.0;

import 'forge-std/Test.sol';

struct ReserveTokens {
  address aToken;
  address stableDebtToken;
  address variableDebtToken;
}

contract CommonTestBase is Test {
  address public constant ETH_MOCK_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  address public constant EOA = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;

  /**
   * @dev generates the diff between two reports
   */
  function diffReports(string memory reportBefore, string memory reportAfter) internal {
    string memory outPath = string(
      abi.encodePacked('./diffs/', reportBefore, '_', reportAfter, '.md')
    );
    string memory beforePath = string(abi.encodePacked('./reports/', reportBefore, '.md'));
    string memory afterPath = string(abi.encodePacked('./reports/', reportAfter, '.md'));

    string[] memory inputs = new string[](3);
    inputs[0] = 'sh';
    inputs[1] = '-c';
    inputs[2] = string(
      abi.encodePacked(
        'printf ',
        "'```diff\n'",
        '"`git diff --no-index --diff-algorithm=patience --ignore-space-at-eol ',
        beforePath,
        ' ',
        afterPath,
        '`"',
        "'```' > ",
        outPath
      )
    );
    vm.ffi(inputs);
  }

  /**
   * @dev forwards time by x blocks
   */
  function _skipBlocks(uint128 blocks) internal {
    vm.roll(block.number + blocks);
    vm.warp(block.timestamp + blocks * 12); // assuming a block is around 12seconds
  }

  function _isInUint256Array(uint256[] memory haystack, uint256 needle)
    internal
    pure
    returns (bool)
  {
    for (uint256 i = 0; i < haystack.length; i++) {
      if (haystack[i] == needle) return true;
    }
    return false;
  }

  function _isInAddressArray(address[] memory haystack, address needle)
    internal
    pure
    returns (bool)
  {
    for (uint256 i = 0; i < haystack.length; i++) {
      if (haystack[i] == needle) return true;
    }
    return false;
  }
}
