// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';

import {ILiquidityGaugeController} from '../../src/asset-manager/interfaces/ILiquidityGaugeController.sol';
import {LSDLiquidityGaugeManager} from '../../src/asset-manager/LSDLiquidityGaugeManager.sol';
import {StrategicAssetsManager} from '../../src/asset-manager/StrategicAssetsManager.sol';
import {Common} from '../../src/asset-manager/Common.sol';

interface ISmartWalletChecker {
  function allowlistAddress(address contractAddress) external;
}

contract LSDLiquidityGaugeManagerTest is Test {
  event GaugeControllerChanged(address indexed oldController, address indexed newController);
  event GaugeRewardsClaimed(address indexed gauge, address indexed token, uint256 amount);
  event GaugeStake(address indexed gauge, uint256 amount);
  event GaugeUnstake(address indexed gauge, uint256 amount);
  event GaugeVote(address indexed gauge, uint256 amount);

  // Helpers
  address public constant SMART_WALLET_CHECKER = 0x7869296Efd0a76872fEE62A058C8fBca5c1c826C;

  address public constant B_80BAL_20WETH = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
  address public constant VE_BAL = 0xC128a9954e6c874eA3d62ce62B468bA073093F25;
  address public constant VE_BAL_GAUGE = 0xe2b680A8d02fbf48C7D9465398C4225d7b7A7f87;
  address public constant WARDEN_VE_BAL = 0x42227bc7D65511a357c43993883c7cef53B25de9;
  address public constant BALANCER_GAUGE_CONTROLLER = 0xC128468b7Ce63eA702C1f104D55A2566b13D3ABD;

  StrategicAssetsManager public strategicAssets;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 17523941);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets = new StrategicAssetsManager();
    vm.stopPrank();
  }
}

contract SetGaugeController is LSDLiquidityGaugeManagerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    strategicAssets.setGaugeController(BALANCER_GAUGE_CONTROLLER);
  }

  function test_revertsIf_invalidZeroAddress() public {
    vm.expectRevert(Common.InvalidZeroAddress.selector);
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.setGaugeController(address(0));
    vm.stopPrank();
  }

  function test_revertsIf_settingToSameController() public {
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.setGaugeController(BALANCER_GAUGE_CONTROLLER);

    vm.expectRevert(LSDLiquidityGaugeManager.SameController.selector);
    strategicAssets.setGaugeController(BALANCER_GAUGE_CONTROLLER);
    vm.stopPrank();
  }

  function test_successful() public {
    address newController = makeAddr('new-controller');

    vm.expectEmit();
    emit GaugeControllerChanged(address(0), newController);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.setGaugeController(newController);
    vm.stopPrank();

    assertEq(strategicAssets.gaugeControllerBalancer(), newController);
  }
}

contract VoteForGaugeWeight is LSDLiquidityGaugeManagerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    strategicAssets.voteForGaugeWeight(VE_BAL_GAUGE, 100);
  }

  function test_revertsIf_gaugeIsZeroAddress() public {
    vm.expectRevert(Common.InvalidZeroAddress.selector);
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.voteForGaugeWeight(address(0), 100);
    vm.stopPrank();
  }

  function test_successful() public {
    vm.startPrank(0x10A19e7eE7d7F8a52822f6817de8ea18204F2e4f); // Authenticated Address
    ISmartWalletChecker(SMART_WALLET_CHECKER).allowlistAddress(address(strategicAssets));
    vm.stopPrank();

    deal(B_80BAL_20WETH, address(strategicAssets), 1_000e18);

    uint256 weightBefore = ILiquidityGaugeController(BALANCER_GAUGE_CONTROLLER).get_gauge_weight(
      VE_BAL_GAUGE
    );

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.setGaugeController(BALANCER_GAUGE_CONTROLLER);
    strategicAssets.setLockDurationVEBAL(365 days);
    strategicAssets.lockVEBAL();

    vm.expectEmit();
    emit GaugeVote(VE_BAL_GAUGE, 100);
    strategicAssets.voteForGaugeWeight(VE_BAL_GAUGE, 100);
    vm.stopPrank();

    assertGt(
      ILiquidityGaugeController(BALANCER_GAUGE_CONTROLLER).get_gauge_weight(VE_BAL_GAUGE),
      weightBefore
    );
  }
}
