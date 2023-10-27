// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';

import {IVlToken} from '../../src/asset-manager/interfaces/IVlToken.sol';
import {StrategicAssetsManager} from '../../src/asset-manager/StrategicAssetsManager.sol';
import {VlTokenManager} from '../../src/asset-manager/VlTokenManager.sol';

contract VlTokenManagerTest is Test {
  event ClaimVLAURARewards();
  event DelegatedVLAURA(address newDelegate);
  event EmergencyWithdraw(uint256 tokensUnlocked);
  event LockVLAURA(uint256 cummulativeTokensLocked, uint256 lockHorizon);
  event RelockVLAURA(uint256 cumulativeTokensLocked);
  event UnlockVLAURA(uint256 tokensUnlocked);

  address public constant AURA = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;
  address public constant VL_AURA = 0x3Fa73f1E5d8A792C80F426fc8F84FBF7Ce9bBCAC;
  address public constant AURA_BAL = 0x616e8BfA43F920657B3497DBf40D6b1A02D4608d;
  address public constant VL_AURA_OWNER = 0x5feA4413E3Cc5Cf3A29a49dB41ac0c24850417a0;

  StrategicAssetsManager public strategicAssets;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 17523941);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets = new StrategicAssetsManager();
    vm.stopPrank();
  }
}

contract LockVLAURATest is VlTokenManagerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    strategicAssets.lockVLAURA(1_000e18);
  }

  function test_revertsIf_insufficientBalance() public {
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectRevert('ERC20: transfer amount exceeds balance');
    strategicAssets.lockVLAURA(1_000e18);
    vm.stopPrank();
  }

  function test_successful() public {
    deal(AURA, address(strategicAssets), 1_000e18);
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectEmit();
    emit LockVLAURA(1_000e18, 1697582531);
    strategicAssets.lockVLAURA(1_000e18);
    vm.stopPrank();

    (uint256 lockedBalance, , , ) = IVlToken(VL_AURA).lockedBalances(address(strategicAssets));
    assertEq(lockedBalance, 1_000e18);
  }
}

contract RelockVLAURATest is VlTokenManagerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    strategicAssets.relockVLAURA();
  }

  function test_revertsIf_noLocks() public {
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectRevert('no locks');
    strategicAssets.relockVLAURA();
    vm.stopPrank();
  }

  function test_revertsIf_noExpiredLocks() public {
    deal(AURA, address(strategicAssets), 1_000e18);
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectEmit();
    emit LockVLAURA(1_000e18, 1697582531);
    strategicAssets.lockVLAURA(1_000e18);

    vm.expectRevert('no exp locks');
    strategicAssets.relockVLAURA();
    vm.stopPrank();
  }

  function test_successful() public {
    uint256 amount = 1_000e18;
    deal(AURA, address(strategicAssets), amount);

    assertEq(IERC20(AURA).balanceOf(address(strategicAssets)), amount);
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectEmit();
    emit LockVLAURA(amount, 1697582531);
    strategicAssets.lockVLAURA(amount);

    vm.warp(block.timestamp + IVlToken(VL_AURA).lockDuration());

    strategicAssets.relockVLAURA();
    vm.stopPrank();

    // No AURA Unlocked
    assertEq(IERC20(AURA).balanceOf(address(strategicAssets)), 0);
  }
}

contract UnlockVLAURATest is VlTokenManagerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    strategicAssets.unlockVLAURA();
  }

  function test_revertsIf_noLocks() public {
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectRevert('no locks');
    strategicAssets.unlockVLAURA();
    vm.stopPrank();
  }

  function test_revertsIf_noExpiredLocks() public {
    deal(AURA, address(strategicAssets), 1_000e18);
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectEmit();
    emit LockVLAURA(1_000e18, 1697582531);
    strategicAssets.lockVLAURA(1_000e18);

    vm.expectRevert('no exp locks');
    strategicAssets.unlockVLAURA();
    vm.stopPrank();
  }

  function test_successful() public {
    uint256 amount = 1_000e18;
    deal(AURA, address(strategicAssets), amount);

    assertEq(IERC20(AURA).balanceOf(address(strategicAssets)), amount);
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectEmit();
    emit LockVLAURA(amount, 1697582531);
    strategicAssets.lockVLAURA(amount);

    // AURA Locked
    assertEq(IERC20(AURA).balanceOf(address(strategicAssets)), 0);

    vm.warp(block.timestamp + IVlToken(VL_AURA).lockDuration());

    strategicAssets.unlockVLAURA();
    vm.stopPrank();

    // AURA unlocked
    assertEq(IERC20(AURA).balanceOf(address(strategicAssets)), amount);
  }
}

contract DelegateVLAURATest is VlTokenManagerTest {
  function test_revertsIf_invalidCaller() public {
    address delegatee = makeAddr('delegatee');

    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    strategicAssets.delegateVLAURA(delegatee);
  }

  function test_revertsIf_nothingToDelegate() public {
    address delegatee = makeAddr('delegatee');

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectRevert('Nothing to delegate');
    strategicAssets.delegateVLAURA(delegatee);
    vm.stopPrank();
  }

  function test_revertsIf_successful() public {
    deal(AURA, address(strategicAssets), 1_000e18);
    address delegatee = makeAddr('delegatee');

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.lockVLAURA(1_000e18);

    vm.expectEmit();
    emit DelegatedVLAURA(delegatee);
    strategicAssets.delegateVLAURA(delegatee);
    vm.stopPrank();

    assertEq(delegatee, IVlToken(VL_AURA).delegates(address(strategicAssets)));
  }
}

contract ClaimVLAURARewardsTest is VlTokenManagerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    strategicAssets.claimVLAURARewards();
  }

  function test_successful() public {
    deal(AURA, address(strategicAssets), 1_000e18);

    assertEq(IERC20(AURA_BAL).balanceOf(address(strategicAssets)), 0);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.lockVLAURA(1_000e18);

    vm.warp(block.timestamp + IVlToken(VL_AURA).lockDuration());

    vm.expectEmit();
    emit ClaimVLAURARewards();
    strategicAssets.claimVLAURARewards();
    vm.stopPrank();

    assertGt(IERC20(AURA_BAL).balanceOf(address(strategicAssets)), 0);
  }
}

contract EmergencyWithdrawVLAURA is VlTokenManagerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    strategicAssets.emergencyWithdrawVLAURA();
  }

  function test_successful() public {
    uint256 amount = 1_000e18;
    deal(AURA, address(strategicAssets), amount);

    assertEq(IERC20(AURA).balanceOf(address(strategicAssets)), amount);
    assertEq(IERC20(VL_AURA).balanceOf(address(strategicAssets)), 0);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.lockVLAURA(amount);
    vm.stopPrank();

    assertEq(IERC20(AURA).balanceOf(address(strategicAssets)), 0);
    (uint256 lockedBalance, , , ) = IVlToken(VL_AURA).lockedBalances(address(strategicAssets));
    assertEq(lockedBalance, 1_000e18);

    vm.warp(block.timestamp + IVlToken(VL_AURA).lockDuration());

    vm.startPrank(VL_AURA_OWNER);
    IVlToken(VL_AURA).shutdown();
    vm.stopPrank();

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.emergencyWithdrawVLAURA();
    vm.stopPrank();

    assertEq(IERC20(AURA).balanceOf(address(strategicAssets)), amount);
    (uint256 lockedBalanceAfterWithdraw, , , ) = IVlToken(VL_AURA).lockedBalances(
      address(strategicAssets)
    );
    assertEq(lockedBalanceAfterWithdraw, 0);
  }
}
