// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';

import {IVeToken} from '../../src/asset-manager/interfaces/IVeToken.sol';
import {IWardenBoost} from '../../src/asset-manager/interfaces/IWardenBoost.sol';
import {StrategicAssetsManager} from '../../src/asset-manager/StrategicAssetsManager.sol';
import {VeTokenManager} from '../../src/asset-manager/VeTokenManager.sol';

interface ISmartWalletChecker {
  function allowlistAddress(address contractAddress) external;
}

contract VeTokenManagerTest is Test {
  event BuyBoost(address delegator, address receiver, uint256 amount, uint256 duration);
  event ClaimBoostRewards();
  event DelegateUpdate(address indexed oldDelegate, address indexed newDelegate);
  event LockVEBAL(uint256 cummulativeTokensLocked, uint256 lockHorizon);
  event RemoveBoostOffer();
  event SellBoost(
    uint256 pricePerVote,
    uint64 maxDurationWeeks,
    uint64 expiryTime,
    uint16 minPerc,
    uint16 maxPerc,
    bool useAdvicePrice
  );
  event SetLockDuration(uint256 newDuration);
  event SetSpaceId(bytes32 id);
  event UnlockVEBAL(uint256 tokensUnlocked);
  event VoteCast(uint256 voteData, bool support);
  event VotingContractUpdate(address indexed token, address voting);

  error NullClaimAmount();

  // Helpers
  address public constant SMART_WALLET_CHECKER = 0x7869296Efd0a76872fEE62A058C8fBca5c1c826C;

  // VeToken
  address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
  address public constant B_80BAL_20WETH = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
  address public constant VE_BAL = 0xC128a9954e6c874eA3d62ce62B468bA073093F25;
  address public constant WARDEN_VE_BAL = 0x42227bc7D65511a357c43993883c7cef53B25de9;
  address public constant VE_BOOST = 0x67F8DF125B796B05895a6dc8Ecf944b9556ecb0B;
  bytes32 public constant BALANCER_SPACE_ID = 'balancer.eth';

  uint256 public constant LOCK_DURATION_ONE_YEAR = 365 days;
  uint256 public constant WEEK = 7 days;

  address public immutable initialDelegate = makeAddr('initial-delegate');

  StrategicAssetsManager public strategicAssets;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 17523941);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets = new StrategicAssetsManager();
    vm.stopPrank();
  }
}

contract BuyBoostTest is VeTokenManagerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    strategicAssets.buyBoost(
      makeAddr('delegator'),
      makeAddr('receiver'),
      1e18,
      1,
      type(uint256).max
    );
  }

  function test_revertsIf_estimatedFeeExceedsMaxFee() public {
    address delegator = 0x20EADfcaf91BD98674FF8fc341D148E1731576A4;
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectRevert(VeTokenManager.MaxFeeExceeded.selector);
    strategicAssets.buyBoost(delegator, makeAddr('receiver'), 4000e18, 1, 1);
  }

  function test_successful() public {
    deal(BAL, address(strategicAssets), 100e18);
    address delegator = 0x20EADfcaf91BD98674FF8fc341D148E1731576A4;
    vm.expectEmit();
    emit BuyBoost(delegator, address(strategicAssets), 4000e18, 1);
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.buyBoost(delegator, address(strategicAssets), 4000e18, 1, type(uint256).max);
    vm.stopPrank();
  }
}

contract SellBoostTest is VeTokenManagerTest {
  function test_revertsIf_invalidCaller() public {
    uint64 expiration = uint64(block.timestamp + 10000);
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    strategicAssets.sellBoost(1000, 10, expiration, 1000, 10000, true);
  }

  function test_successful() public {
    vm.expectRevert();
    IWardenBoost(WARDEN_VE_BAL).offers(7); // ID 7 Doesn't exist yet

    uint64 expiration = uint64(block.timestamp + WEEK);
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectEmit();
    emit SellBoost(1000, 10, expiration, 1000, 10000, true);
    strategicAssets.sellBoost(1000, 10, expiration, 1000, 10000, true);
    vm.stopPrank();

    IWardenBoost.BoostOffer memory offer = IWardenBoost(WARDEN_VE_BAL).offers(7);

    assertEq(offer.pricePerVote, 1000);
    assertEq(offer.maxDuration, 10);
    assertEq(offer.expiryTime, expiration);
    assertEq(offer.minPerc, 1000);
    assertEq(offer.maxPerc, 10000);
  }
}

contract UpdateBoostOfferTest is VeTokenManagerTest {
  function test_revertsIf_invalidCaller() public {
    uint64 expiration = uint64(block.timestamp + 10000);
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    strategicAssets.updateBoostOffer(1000, 10, expiration, 1000, 10000, true);
  }

  function test_revertsIf_noOfferExists() public {
    uint64 expiration = uint64(block.timestamp + 10000);

    vm.expectRevert();
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.updateBoostOffer(1000, 10, expiration, 1000, 10000, true);
    vm.stopPrank();
  }

  function test_successful() public {
    vm.expectRevert();
    IWardenBoost(WARDEN_VE_BAL).offers(7); // ID 7 Doesn't exist yet

    uint64 expiration = uint64(block.timestamp + WEEK);
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.sellBoost(1000, 10, expiration, 1000, 10000, true);
    vm.stopPrank();

    IWardenBoost.BoostOffer memory offer = IWardenBoost(WARDEN_VE_BAL).offers(7);

    assertEq(offer.maxDuration, 10);
    assertEq(offer.expiryTime, expiration);
    assertEq(offer.minPerc, 1000);
    assertEq(offer.maxPerc, 10000);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectEmit();
    emit SellBoost(1000, 20, uint64(expiration + WEEK), 1000, 5000, true);
    strategicAssets.updateBoostOffer(1000, 20, uint64(expiration + WEEK), 1000, 5000, true);
    vm.stopPrank();

    IWardenBoost.BoostOffer memory offerUpdated = IWardenBoost(WARDEN_VE_BAL).offers(7);

    assertEq(offerUpdated.maxDuration, 20);
    assertEq(offerUpdated.expiryTime, uint64(expiration + WEEK));
    assertEq(offerUpdated.minPerc, 1000);
    assertEq(offerUpdated.maxPerc, 5000);
  }
}

contract RemoveBoostOfferTest is VeTokenManagerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    strategicAssets.removeBoostOffer();
  }

  function test_successful() public {
    vm.expectRevert();
    IWardenBoost(WARDEN_VE_BAL).offers(7); // ID 7 Doesn't exist yet

    uint64 expiration = uint64(block.timestamp + WEEK);
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.sellBoost(1000, 10, expiration, 1000, 10000, true);
    vm.stopPrank();

    IWardenBoost.BoostOffer memory offer = IWardenBoost(WARDEN_VE_BAL).offers(7);

    assertEq(
      IERC20(IWardenBoost(WARDEN_VE_BAL).delegationBoost()).allowance(
        address(strategicAssets),
        WARDEN_VE_BAL
      ),
      type(uint256).max
    );

    assertEq(offer.maxDuration, 10);
    assertEq(offer.expiryTime, expiration);
    assertEq(offer.minPerc, 1000);
    assertEq(offer.maxPerc, 10000);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectEmit();
    emit RemoveBoostOffer();
    strategicAssets.removeBoostOffer();
    vm.stopPrank();

    vm.expectRevert();
    IWardenBoost(WARDEN_VE_BAL).offers(7); // ID 7 Doesn't exist anymore

    assertEq(
      IERC20(IWardenBoost(WARDEN_VE_BAL).delegationBoost()).allowance(
        address(strategicAssets),
        WARDEN_VE_BAL
      ),
      0
    );
  }
}

contract Claim is VeTokenManagerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    strategicAssets.claimBoostRewards();
  }

  function test_revertsIf_noRewardsWereEarned() public {
    uint64 expiration = uint64(block.timestamp + WEEK);
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.sellBoost(1000, 10, expiration, 1000, 10000, true);

    vm.expectRevert(NullClaimAmount.selector);
    strategicAssets.claimBoostRewards();
    vm.stopPrank();
  }

  function test_successful() public {
    vm.startPrank(0x10A19e7eE7d7F8a52822f6817de8ea18204F2e4f); // Authenticated Address
    ISmartWalletChecker(SMART_WALLET_CHECKER).allowlistAddress(address(strategicAssets));
    vm.stopPrank();

    deal(B_80BAL_20WETH, address(strategicAssets), 1_000e18);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.setLockDurationVEBAL(LOCK_DURATION_ONE_YEAR);
    strategicAssets.lockVEBAL();
    vm.stopPrank();

    deal(BAL, address(this), 1_000e18);

    uint64 expiration = uint64(block.timestamp + WEEK);
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.sellBoost(1000, 10, expiration, 1000, 10000, true);
    vm.stopPrank();

    IERC20(BAL).approve(WARDEN_VE_BAL, type(uint256).max);
    uint256 amount = 400e18;
    uint256 maxFee = IWardenBoost(WARDEN_VE_BAL).estimateFees(address(strategicAssets), amount, 1);
    IWardenBoost(WARDEN_VE_BAL).buyDelegationBoost(
      address(strategicAssets),
      address(this),
      amount,
      1,
      maxFee
    );

    vm.warp(WEEK);

    uint256 balanceBefore = IERC20(BAL).balanceOf(address(strategicAssets));

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectEmit();
    emit ClaimBoostRewards();
    strategicAssets.claimBoostRewards();
    vm.stopPrank();

    uint256 balanceAfter = IERC20(BAL).balanceOf(address(strategicAssets));

    assertGt(balanceAfter, balanceBefore);
  }
}

contract SetSpaceIdTest is VeTokenManagerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    strategicAssets.setSpaceIdVEBAL(BALANCER_SPACE_ID);
  }

  function test_successful() public {
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.setDelegateVEBAL(initialDelegate);
    vm.expectEmit();
    emit SetSpaceId(BALANCER_SPACE_ID);
    strategicAssets.setSpaceIdVEBAL(BALANCER_SPACE_ID);
    vm.stopPrank();

    assertEq(
      strategicAssets.DELEGATE_REGISTRY().delegation(address(strategicAssets), BALANCER_SPACE_ID),
      initialDelegate
    );
  }
}

contract SetDelegationSnapshot is VeTokenManagerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    strategicAssets.setDelegateVEBAL(makeAddr('another-delegate'));
  }

  function test_successful() public {
    address newDelegate = makeAddr('another-delegate');
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.setDelegateVEBAL(newDelegate);
    strategicAssets.setSpaceIdVEBAL(BALANCER_SPACE_ID);
    vm.stopPrank();

    assertEq(
      strategicAssets.DELEGATE_REGISTRY().delegation(address(strategicAssets), BALANCER_SPACE_ID),
      newDelegate
    );
  }
}

contract ClearDelegationSnapshot is VeTokenManagerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    strategicAssets.clearDelegateVEBAL();
  }

  function test_successful() public {
    address newDelegate = makeAddr('new-delegate');
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.setDelegateVEBAL(newDelegate);
    strategicAssets.setSpaceIdVEBAL(BALANCER_SPACE_ID);
    vm.stopPrank();

    assertEq(
      strategicAssets.DELEGATE_REGISTRY().delegation(address(strategicAssets), BALANCER_SPACE_ID),
      newDelegate
    );

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.clearDelegateVEBAL();
    vm.stopPrank();

    assertEq(
      strategicAssets.DELEGATE_REGISTRY().delegation(address(strategicAssets), BALANCER_SPACE_ID),
      address(0)
    );
  }
}

contract SetLockDurationTest is VeTokenManagerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    strategicAssets.setLockDurationVEBAL(LOCK_DURATION_ONE_YEAR);
  }

  function test_successful() public {
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectEmit();
    emit SetLockDuration(LOCK_DURATION_ONE_YEAR + 1);
    strategicAssets.setLockDurationVEBAL(LOCK_DURATION_ONE_YEAR + 1);
    vm.stopPrank();
  }
}

contract LockTest is VeTokenManagerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    strategicAssets.lockVEBAL();
  }

  function test_successful_locksFirstTime() public {
    vm.startPrank(0x10A19e7eE7d7F8a52822f6817de8ea18204F2e4f); // Authenticated Address
    ISmartWalletChecker(SMART_WALLET_CHECKER).allowlistAddress(address(strategicAssets));
    vm.stopPrank();

    deal(B_80BAL_20WETH, address(strategicAssets), 1_000e18);

    assertEq(IERC20(B_80BAL_20WETH).balanceOf(address(strategicAssets)), 1_000e18);
    assertEq(IERC20(VE_BAL).balanceOf(address(strategicAssets)), 0);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.setLockDurationVEBAL(LOCK_DURATION_ONE_YEAR);

    vm.expectEmit();
    emit LockVEBAL(1_000e18, ((block.timestamp + LOCK_DURATION_ONE_YEAR) / WEEK) * WEEK);
    strategicAssets.lockVEBAL();
    vm.stopPrank();

    assertEq(IERC20(B_80BAL_20WETH).balanceOf(address(strategicAssets)), 0);
    assertEq(IERC20(VE_BAL).balanceOf(address(strategicAssets)), 980969970826973230916);
    assertEq(IVeToken(VE_BAL).locked(address(strategicAssets)), 1_000e18);
  }

  function test_successful_increaseBalance() public {
    vm.startPrank(0x10A19e7eE7d7F8a52822f6817de8ea18204F2e4f); // Authenticated Address
    ISmartWalletChecker(SMART_WALLET_CHECKER).allowlistAddress(address(strategicAssets));
    vm.stopPrank();

    deal(B_80BAL_20WETH, address(strategicAssets), 1_000e18);

    assertEq(IERC20(B_80BAL_20WETH).balanceOf(address(strategicAssets)), 1_000e18);
    assertEq(IERC20(VE_BAL).balanceOf(address(strategicAssets)), 0);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.setLockDurationVEBAL(LOCK_DURATION_ONE_YEAR);

    vm.expectEmit();
    emit LockVEBAL(1_000e18, ((block.timestamp + LOCK_DURATION_ONE_YEAR) / WEEK) * WEEK);
    strategicAssets.lockVEBAL();
    vm.stopPrank();

    assertEq(IERC20(B_80BAL_20WETH).balanceOf(address(strategicAssets)), 0);
    assertEq(IERC20(VE_BAL).balanceOf(address(strategicAssets)), 980969970826973230916);
    assertEq(IVeToken(VE_BAL).locked(address(strategicAssets)), 1_000e18);

    uint256 initialLockEnd = IVeToken(VE_BAL).locked__end(address(strategicAssets));

    deal(B_80BAL_20WETH, address(strategicAssets), 500e18);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.lockVEBAL();
    vm.stopPrank();

    assertEq(IERC20(B_80BAL_20WETH).balanceOf(address(strategicAssets)), 0);
    assertEq(IERC20(VE_BAL).balanceOf(address(strategicAssets)), 1471454956240459846374);
    assertEq(IVeToken(VE_BAL).locked(address(strategicAssets)), 1_500e18);
    assertEq(IVeToken(VE_BAL).locked__end(address(strategicAssets)), initialLockEnd);
  }

  function test_successful_increaseUnlockTime() public {
    vm.startPrank(0x10A19e7eE7d7F8a52822f6817de8ea18204F2e4f); // Authenticated Address
    ISmartWalletChecker(SMART_WALLET_CHECKER).allowlistAddress(address(strategicAssets));
    vm.stopPrank();

    deal(B_80BAL_20WETH, address(strategicAssets), 1_000e18);

    assertEq(IERC20(B_80BAL_20WETH).balanceOf(address(strategicAssets)), 1_000e18);
    assertEq(IERC20(VE_BAL).balanceOf(address(strategicAssets)), 0);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.setLockDurationVEBAL(LOCK_DURATION_ONE_YEAR);

    vm.expectEmit();
    emit LockVEBAL(1_000e18, ((block.timestamp + LOCK_DURATION_ONE_YEAR) / WEEK) * WEEK);
    strategicAssets.lockVEBAL();
    vm.stopPrank();

    assertEq(IERC20(B_80BAL_20WETH).balanceOf(address(strategicAssets)), 0);
    assertEq(IERC20(VE_BAL).balanceOf(address(strategicAssets)), 980969970826973230916);
    assertEq(IVeToken(VE_BAL).locked(address(strategicAssets)), 1_000e18);

    uint256 initialLockEnd = IVeToken(VE_BAL).locked__end(address(strategicAssets));

    vm.warp(block.timestamp + WEEK);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.lockVEBAL();
    vm.stopPrank();

    uint256 newLockEnd = IVeToken(VE_BAL).locked__end(address(strategicAssets));

    assertEq(IERC20(B_80BAL_20WETH).balanceOf(address(strategicAssets)), 0);
    assertEq(IERC20(VE_BAL).balanceOf(address(strategicAssets)), 980969970826973230916);
    assertEq(IVeToken(VE_BAL).locked(address(strategicAssets)), 1_000e18);
    assertEq(initialLockEnd + WEEK, newLockEnd);
  }

  function test_revertsIf_nothingToLockOrRelock() public {
    vm.startPrank(0x10A19e7eE7d7F8a52822f6817de8ea18204F2e4f); // Authenticated Address
    ISmartWalletChecker(SMART_WALLET_CHECKER).allowlistAddress(address(strategicAssets));
    vm.stopPrank();

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.setLockDurationVEBAL(LOCK_DURATION_ONE_YEAR);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectRevert(VeTokenManager.NoTokensToLockOrRelock.selector);
    strategicAssets.lockVEBAL();
    vm.stopPrank();
  }
}

contract UnlockTest is VeTokenManagerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    strategicAssets.unlockVEBAL();
  }

  function test_revertsIf_unlockTimeHasNotPassed() public {
    vm.startPrank(0x10A19e7eE7d7F8a52822f6817de8ea18204F2e4f); // Authenticated Address
    ISmartWalletChecker(SMART_WALLET_CHECKER).allowlistAddress(address(strategicAssets));
    vm.stopPrank();

    deal(B_80BAL_20WETH, address(strategicAssets), 1_000e18);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.setLockDurationVEBAL(LOCK_DURATION_ONE_YEAR);
    strategicAssets.lockVEBAL();

    vm.expectRevert("The lock didn't expire");
    strategicAssets.unlockVEBAL();
    vm.stopPrank();
  }

  function test_successful_unlock() public {
    vm.startPrank(0x10A19e7eE7d7F8a52822f6817de8ea18204F2e4f); // Authenticated Address
    ISmartWalletChecker(SMART_WALLET_CHECKER).allowlistAddress(address(strategicAssets));
    vm.stopPrank();

    deal(B_80BAL_20WETH, address(strategicAssets), 1_000e18);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.setLockDurationVEBAL(LOCK_DURATION_ONE_YEAR);
    strategicAssets.lockVEBAL();
    vm.stopPrank();

    vm.warp(block.timestamp + LOCK_DURATION_ONE_YEAR + 1);

    vm.expectEmit();
    emit UnlockVEBAL(1_000e18);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.unlockVEBAL();
    vm.stopPrank();
  }
}
