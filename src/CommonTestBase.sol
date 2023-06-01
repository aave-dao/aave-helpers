// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5 <0.9.0;

import 'forge-std/StdJson.sol';
import 'forge-std/Test.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {ChainIds} from './ChainIds.sol';

struct ReserveTokens {
  address aToken;
  address stableDebtToken;
  address variableDebtToken;
}

/**
 * https://github.com/foundry-rs/foundry/issues/2655#issuecomment-1208383099
 */
interface PatchedIERC20 {
  function approve(address spender, uint256 amount) external;

  function transferFrom(address from, address to, uint256 value) external;

  function balanceOf(address account) external view returns (uint256);
}

contract CommonTestBase is Test {
  using stdJson for string;

  address public constant ETH_MOCK_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  address public constant EOA = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;

  /**
   * @notice deal doesn't support amounts stored in a script right now.
   * This function patches deal to mock and transfer funds instead.
   * @param asset the asset to deal
   * @param user the user to deal to
   * @param amount the amount to deal
   */
  function _patchedDeal(address asset, address user, uint256 amount) internal {
    // TODO: once https://github.com/foundry-rs/foundry/pull/4884 merged scripts need to be adjusted
    if (block.chainid == ChainIds.MAINNET) {
      // GUSD
      if (asset == AaveV2EthereumAssets.GUSD_UNDERLYING) {
        vm.prank(0x22FFDA6813f4F34C520bf36E5Ea01167bC9DF159);
        IERC20(asset).transfer(user, amount);
        return;
      }
      // SNX
      if (asset == AaveV2EthereumAssets.SNX_UNDERLYING) {
        vm.prank(0xAc86855865CbF31c8f9FBB68C749AD5Bd72802e3);
        IERC20(asset).transfer(user, amount);
        return;
      }
      // sUSD
      if (asset == AaveV2EthereumAssets.sUSD_UNDERLYING) {
        vm.prank(0x99F4176EE457afedFfCB1839c7aB7A030a5e4A92);
        IERC20(asset).transfer(user, amount);
        return;
      }
      // stETH
      if (asset == AaveV2EthereumAssets.stETH_UNDERLYING) {
        vm.prank(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
        IERC20(asset).transfer(user, amount);
        return;
      }
    }
    deal(asset, user, amount);
  }

  /**
   * Some ERC20 are not perfectly spec compatible.
   * This method patches the approve for them
   * @notice for now only patching assets used on aave pools (for a more complete list check https://github.com/d-xo/weird-erc20)
   * @param asset the asset to approve
   * @param spender the spender to approve
   * @param amount the amount to approve
   */
  function _patchedApprove(address asset, address spender, uint256 amount) internal {
    if (block.chainid == ChainIds.MAINNET) {
      // USDT
      if (asset == AaveV2EthereumAssets.USDT_UNDERLYING) {
        PatchedIERC20(asset).approve(spender, amount);
        return;
      }
    }
    IERC20(asset).approve(spender, amount);
  }

  /**
   * @dev generates the diff between two reports
   */
  function diffReports(string memory reportBefore, string memory reportAfter) internal {
    string memory outPath = string(
      abi.encodePacked('./diffs/', reportBefore, '_', reportAfter, '.md')
    );
    string memory beforePath = string(abi.encodePacked('./reports/', reportBefore, '.json'));
    string memory afterPath = string(abi.encodePacked('./reports/', reportAfter, '.json'));

    string[] memory inputs = new string[](7);
    inputs[0] = 'npx';
    inputs[1] = 'aave-cli';
    inputs[2] = 'diff-snapshot';
    inputs[3] = beforePath;
    inputs[4] = afterPath;
    inputs[5] = '-o';
    inputs[6] = outPath;
    vm.ffi(inputs);
  }

  /**
   * @dev forwards time by x blocks
   */
  function _skipBlocks(uint128 blocks) internal {
    vm.roll(block.number + blocks);
    vm.warp(block.timestamp + blocks * 12); // assuming a block is around 12seconds
  }

  function _isInUint256Array(
    uint256[] memory haystack,
    uint256 needle
  ) internal pure returns (bool) {
    for (uint256 i = 0; i < haystack.length; i++) {
      if (haystack[i] == needle) return true;
    }
    return false;
  }

  function _isInAddressArray(
    address[] memory haystack,
    address needle
  ) internal pure returns (bool) {
    for (uint256 i = 0; i < haystack.length; i++) {
      if (haystack[i] == needle) return true;
    }
    return false;
  }
}
