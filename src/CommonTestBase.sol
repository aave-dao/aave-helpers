// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5 <0.9.0;

import 'forge-std/StdJson.sol';
import 'forge-std/Test.sol';
import {VmSafe} from 'forge-std/Vm.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV3OptimismAssets} from 'aave-address-book/AaveV3Optimism.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveV3AvalancheAssets} from 'aave-address-book/AaveV3Avalanche.sol';
import {AaveV3ArbitrumAssets} from 'aave-address-book/AaveV3Arbitrum.sol';
import {AaveV3GnosisAssets} from 'aave-address-book/AaveV3Gnosis.sol';
import {AaveV3BaseAssets} from 'aave-address-book/AaveV3Base.sol';
import {ChainIds} from 'solidity-utils/contracts/utils/ChainHelpers.sol';
import {GovV3Helpers} from './GovV3Helpers.sol';

struct ReserveTokens {
  address aToken;
  address stableDebtToken;
  address variableDebtToken;
}

contract CommonTestBase is Test {
  using stdJson for string;

  address public constant ETH_MOCK_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  address public constant EOA = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;

  function executePayload(Vm vm, address payload) internal {
    GovV3Helpers.executePayload(vm, payload);
  }

  /**
   * @notice deal doesn't support amounts stored in a script right now.
   * This function patches deal to mock and transfer funds instead.
   * @param asset the asset to deal
   * @param user the user to deal to
   * @param amount the amount to deal
   * @return bool true if the caller has changed due to prank usage
   */
  function _patchedDeal(address asset, address user, uint256 amount) internal returns (bool) {
    if (block.chainid == ChainIds.MAINNET) {
      // FXS
      if (asset == 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0) {
        vm.prank(0xF977814e90dA44bFA03b6295A0616a897441aceC);
        IERC20(asset).transfer(user, amount);
        return true;
      }
      // GUSD
      if (asset == AaveV2EthereumAssets.GUSD_UNDERLYING) {
        vm.prank(0x22FFDA6813f4F34C520bf36E5Ea01167bC9DF159);
        IERC20(asset).transfer(user, amount);
        return true;
      }
      // SNX
      if (asset == AaveV2EthereumAssets.SNX_UNDERLYING) {
        vm.prank(0x0D0452f487D1EDc869d1488ae984590ca2900D2F);
        IERC20(asset).transfer(user, amount);
        return true;
      }
      // sUSD
      if (asset == AaveV2EthereumAssets.sUSD_UNDERLYING) {
        vm.prank(0x99F4176EE457afedFfCB1839c7aB7A030a5e4A92);
        IERC20(asset).transfer(user, amount);
        return true;
      }
      // stETH
      if (asset == AaveV2EthereumAssets.stETH_UNDERLYING) {
        vm.prank(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
        IERC20(asset).transfer(user, amount);
        return true;
      }
      // LDO
      if (asset == AaveV3EthereumAssets.LDO_UNDERLYING) {
        vm.prank(0x3e40D73EB977Dc6a537aF587D48316feE66E9C8c);
        IERC20(asset).transfer(user, amount);
        return true;
      }
      // AAVE
      if (asset == AaveV3EthereumAssets.AAVE_UNDERLYING) {
        vm.prank(MiscEthereum.ECOSYSTEM_RESERVE);
        IERC20(asset).transfer(user, amount);
        return true;
      }
    }
    if (block.chainid == ChainIds.OPTIMISM) {
      // sUSD
      if (asset == AaveV3OptimismAssets.sUSD_UNDERLYING) {
        vm.prank(AaveV3OptimismAssets.sUSD_A_TOKEN);
        IERC20(asset).transfer(user, amount);
        return true;
      }
    }
    if (block.chainid == ChainIds.GNOSIS) {
      if (asset == AaveV3GnosisAssets.EURe_UNDERLYING) {
        vm.prank(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
        IERC20(asset).transfer(user, amount);
        return true;
      }
    }
    return false;
  }

  /**
   * Patched version of deal
   * @param asset to deal
   * @param user to deal to
   * @param amount to deal
   */
  function deal2(address asset, address user, uint256 amount) internal {
    (VmSafe.CallerMode mode, address oldSender, ) = vm.readCallers();
    if (mode != VmSafe.CallerMode.None) vm.stopPrank();
    bool patched = _patchedDeal(asset, user, amount);
    if (!patched) {
      deal(asset, user, amount);
    }
    if (mode != VmSafe.CallerMode.None) vm.startPrank(oldSender);
  }
}
