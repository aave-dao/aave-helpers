// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {SafeERC20, IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {CommonTestBase} from 'src/CommonTestBase.sol';
import {ISpoke, IAaveOracle} from 'aave-address-book/AaveV4.sol';
import {IHubBase} from 'aave-v4/hub/interfaces/IHubBase.sol';
import {WadRayMath} from 'aave-v4/libraries/math/WadRayMath.sol';
import {Types} from 'src/dependencies/v4/Types.sol';

/// @title Actions
/// @notice Low-level spoke actions with hub and spoke accounting assertions.
abstract contract Actions is CommonTestBase {
  using SafeERC20 for IERC20;
  using stdMath for uint256;

  uint256 constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18;
  uint256 constant MAX_DEAL_UNIT = 1e12; // whole units not accounting for token decimals

  function _getUserAccounting(
    ISpoke spoke,
    uint256 reserveId,
    address user
  ) internal view returns (Types.Accounting memory) {
    (uint256 drawnDebt, uint256 premiumDebt) = spoke.getUserDebt(reserveId, user);
    ISpoke.UserPosition memory position = spoke.getUserPosition(reserveId, user);
    return
      Types.Accounting({
        collateralShares: position.suppliedShares,
        collateralAssets: spoke.getUserSuppliedAssets(reserveId, user),
        drawnDebt: drawnDebt,
        premiumDebt: premiumDebt,
        totalDebt: spoke.getUserTotalDebt(reserveId, user),
        drawnShares: position.drawnShares,
        premiumShares: position.premiumShares,
        premiumOffsetRay: position.premiumOffsetRay
      });
  }

  function _getReserveAccounting(
    ISpoke spoke,
    Types.ReserveInfo memory reserveInfo
  ) internal view returns (Types.Accounting memory) {
    IHubBase hub = IHubBase(reserveInfo.hub);
    uint16 assetId = reserveInfo.assetId;
    (uint256 drawnDebt, uint256 premiumDebt) = hub.getSpokeOwed(assetId, address(spoke));
    (uint256 premiumShares, int256 premiumOffsetRay) = hub.getSpokePremiumData(
      assetId,
      address(spoke)
    );
    return
      Types.Accounting({
        collateralShares: spoke.getReserveSuppliedShares(reserveInfo.reserveId),
        collateralAssets: spoke.getReserveSuppliedAssets(reserveInfo.reserveId),
        drawnDebt: drawnDebt,
        premiumDebt: premiumDebt,
        totalDebt: spoke.getReserveTotalDebt(reserveInfo.reserveId),
        drawnShares: hub.getSpokeDrawnShares(assetId, address(spoke)),
        premiumShares: premiumShares,
        premiumOffsetRay: premiumOffsetRay
      });
  }

  function _getSpokeOnHubAccounting(
    ISpoke spoke,
    Types.ReserveInfo memory reserveInfo
  ) internal view returns (Types.Accounting memory) {
    IHubBase hub = IHubBase(reserveInfo.hub);
    uint16 assetId = reserveInfo.assetId;
    address spokeAddr = address(spoke);
    (uint256 spokeDrawnOwed, uint256 spokePremiumOwed) = hub.getSpokeOwed(assetId, spokeAddr);
    (uint256 premiumShares, int256 premiumOffsetRay) = hub.getSpokePremiumData(assetId, spokeAddr);
    return
      Types.Accounting({
        collateralShares: hub.getSpokeAddedShares(assetId, spokeAddr),
        collateralAssets: hub.getSpokeAddedAssets(assetId, spokeAddr),
        drawnDebt: spokeDrawnOwed,
        premiumDebt: spokePremiumOwed,
        totalDebt: hub.getSpokeTotalOwed(assetId, spokeAddr),
        drawnShares: hub.getSpokeDrawnShares(assetId, spokeAddr),
        premiumShares: premiumShares,
        premiumOffsetRay: premiumOffsetRay
      });
  }

  function _getPositionSnapshot(
    ISpoke spoke,
    Types.ReserveInfo memory reserveInfo,
    address user
  ) internal view returns (Types.PositionSnapshot memory) {
    return
      Types.PositionSnapshot({
        user: _getUserAccounting({spoke: spoke, reserveId: reserveInfo.reserveId, user: user}),
        reserve: _getReserveAccounting({spoke: spoke, reserveInfo: reserveInfo}),
        spokeOnHub: _getSpokeOnHubAccounting({spoke: spoke, reserveInfo: reserveInfo})
      });
  }

  /// @notice Skip time, assert debt accounting grew as expected, then revert.
  function _skipTimeAndCheckAccounting(
    ISpoke spoke,
    Types.ReserveInfo memory reserveInfo,
    address user,
    uint256 skipDays
  ) internal {
    uint256 snapshot = vm.snapshotState();

    Types.PositionSnapshot memory snapshotBefore = _getPositionSnapshot(spoke, reserveInfo, user);

    skip(skipDays * 1 days);

    Types.PositionSnapshot memory snapshotAfter = _getPositionSnapshot(spoke, reserveInfo, user);

    // User debt should not decrease over time
    assertGe(
      snapshotAfter.user.totalDebt,
      snapshotBefore.user.totalDebt,
      'TIME_SKIP: user total debt decreased'
    );
    assertGe(
      snapshotAfter.user.drawnDebt,
      snapshotBefore.user.drawnDebt,
      'TIME_SKIP: user drawn debt decreased'
    );

    // Reserve debt should not decrease over time
    assertGe(
      snapshotAfter.reserve.totalDebt,
      snapshotBefore.reserve.totalDebt,
      'TIME_SKIP: reserve total debt decreased'
    );
    assertGe(
      snapshotAfter.reserve.drawnDebt,
      snapshotBefore.reserve.drawnDebt,
      'TIME_SKIP: reserve drawn debt decreased'
    );

    // Hub spoke owed should not decrease over time
    assertGe(
      snapshotAfter.spokeOnHub.totalDebt,
      snapshotBefore.spokeOnHub.totalDebt,
      'TIME_SKIP: hub spoke owed decreased'
    );
    assertGe(
      snapshotAfter.spokeOnHub.drawnDebt,
      snapshotBefore.spokeOnHub.drawnDebt,
      'TIME_SKIP: hub spoke drawn decreased'
    );

    // Hub drawn index should have grown
    IHubBase hub = IHubBase(reserveInfo.hub);
    uint256 drawnIndexAfter = hub.getAssetDrawnIndex(reserveInfo.assetId);
    assertGt(
      drawnIndexAfter,
      WadRayMath.RAY,
      'TIME_SKIP: drawn index should be greater than default 1 RAY'
    );

    vm.revertToState(snapshot);
  }

  function _supply(
    ISpoke spoke,
    Types.ReserveInfo memory reserveInfo,
    address user,
    uint256 amount
  ) internal {
    require(!reserveInfo.paused, 'SUPPLY: PAUSED_RESERVE');
    require(!reserveInfo.frozen, 'SUPPLY: FROZEN_RESERVE');

    Types.PositionSnapshot memory snapshotBefore = _getPositionSnapshot(spoke, reserveInfo, user);

    _forceApprove({spoke: spoke, underlying: reserveInfo.underlying, user: user, amount: amount});

    _logAction('SUPPLY', reserveInfo.symbol, amount);
    vm.prank(user);
    (uint256 returnedShares, uint256 returnedAssets) = spoke.supply({
      reserveId: reserveInfo.reserveId,
      amount: amount,
      onBehalfOf: user
    });

    Types.PositionSnapshot memory snapshotAfter = _getPositionSnapshot(spoke, reserveInfo, user);

    assertEq(returnedAssets, amount, 'SUPPLY: returnedAssets mismatch');

    // User
    assertApproxEqAbs(
      snapshotAfter.user.collateralAssets,
      snapshotBefore.user.collateralAssets + amount,
      1,
      'SUPPLY: user assets mismatch'
    );
    assertEq(
      snapshotAfter.user.collateralShares,
      snapshotBefore.user.collateralShares + returnedShares,
      'SUPPLY: user shares mismatch'
    );
    // Spoke accounting on hub
    assertApproxEqAbs(
      snapshotAfter.spokeOnHub.collateralAssets,
      snapshotBefore.spokeOnHub.collateralAssets + amount,
      1,
      'SUPPLY: hub assets mismatch'
    );
    uint256 expectedAddedShares = IHubBase(reserveInfo.hub).previewAddByAssets(
      reserveInfo.assetId,
      amount
    );
    assertEq(returnedShares, expectedAddedShares, 'SUPPLY: returnedShares mismatch');
    assertEq(
      snapshotAfter.spokeOnHub.collateralShares,
      snapshotBefore.spokeOnHub.collateralShares + expectedAddedShares,
      'SUPPLY: hub shares mismatch'
    );
  }

  /// @notice Deal to the user and force approve the spoke to spend the amount of the underlying token for the user
  function _forceApprove(ISpoke spoke, address underlying, address user, uint256 amount) internal {
    deal2(underlying, user, amount);
    vm.prank(user);
    IERC20(underlying).forceApprove(address(spoke), amount);
  }

  function _withdraw(
    ISpoke spoke,
    Types.ReserveInfo memory reserveInfo,
    address user,
    uint256 amount
  ) internal {
    Types.PositionSnapshot memory snapshotBefore = _getPositionSnapshot(spoke, reserveInfo, user);

    vm.startPrank(user);
    _logAction('WITHDRAW', reserveInfo.symbol, amount);
    (uint256 returnedShares, uint256 withdrawnAmount) = spoke.withdraw({
      reserveId: reserveInfo.reserveId,
      amount: amount,
      onBehalfOf: user
    });
    vm.stopPrank();

    Types.PositionSnapshot memory snapshotAfter = _getPositionSnapshot(spoke, reserveInfo, user);

    if (amount >= snapshotBefore.user.collateralAssets) {
      assertEq(snapshotAfter.user.collateralAssets, 0, 'WITHDRAW: user assets should be zero');
      assertEq(snapshotAfter.user.collateralShares, 0, 'WITHDRAW: user shares should be zero');
    } else {
      assertApproxEqAbs(
        snapshotAfter.user.collateralAssets,
        snapshotBefore.user.collateralAssets - withdrawnAmount,
        1,
        'WITHDRAW: user assets mismatch'
      );
      assertEq(
        snapshotBefore.user.collateralShares - snapshotAfter.user.collateralShares,
        returnedShares,
        'WITHDRAW: user shares delta mismatch'
      );
    }
    // Hub spoke
    assertApproxEqAbs(
      snapshotBefore.spokeOnHub.collateralAssets - snapshotAfter.spokeOnHub.collateralAssets,
      withdrawnAmount,
      1,
      'WITHDRAW: hub assets mismatch'
    );
    assertEq(
      snapshotBefore.spokeOnHub.collateralShares - snapshotAfter.spokeOnHub.collateralShares,
      returnedShares,
      'WITHDRAW: hub shares mismatch'
    );
  }

  function _borrow(
    ISpoke spoke,
    Types.ReserveInfo memory reserveInfo,
    address user,
    uint256 amount
  ) internal {
    Types.PositionSnapshot memory snapshotBefore = _getPositionSnapshot(spoke, reserveInfo, user);
    uint256 expectedDrawnShares = IHubBase(reserveInfo.hub).previewDrawByAssets(
      reserveInfo.assetId,
      amount
    );

    _logAction('BORROW', reserveInfo.symbol, amount);
    vm.prank(user);
    (uint256 returnedShares, uint256 returnedAssets) = spoke.borrow({
      reserveId: reserveInfo.reserveId,
      amount: amount,
      onBehalfOf: user
    });

    Types.PositionSnapshot memory snapshotAfter = _getPositionSnapshot(spoke, reserveInfo, user);

    assertEq(returnedAssets, amount, 'BORROW: returnedAssets mismatch');
    assertEq(returnedShares, expectedDrawnShares, 'BORROW: returnedShares mismatch');

    // User debt - up to 2 wei diff due to premium/drawn debt
    assertApproxEqAbs(
      snapshotAfter.user.totalDebt,
      snapshotBefore.user.totalDebt + amount,
      2,
      'BORROW: user debt mismatch'
    );
    assertApproxEqAbs(
      snapshotAfter.user.drawnDebt,
      snapshotBefore.user.drawnDebt + returnedAssets,
      2,
      'BORROW: user drawn debt mismatch'
    );
    // Hub spoke - up to 2 wei diff due to premium/drawn debt
    assertApproxEqAbs(
      snapshotAfter.spokeOnHub.totalDebt,
      snapshotBefore.spokeOnHub.totalDebt + amount,
      2,
      'BORROW: hub debt mismatch'
    );
    assertEq(
      snapshotAfter.spokeOnHub.drawnShares,
      snapshotBefore.spokeOnHub.drawnShares + expectedDrawnShares,
      'BORROW: hub drawn shares mismatch'
    );

    // Health factor must remain above liquidation threshold after borrow
    uint256 healthFactor = spoke.getUserAccountData(user).healthFactor;
    assertGt(healthFactor, HEALTH_FACTOR_LIQUIDATION_THRESHOLD, 'BORROW: health factor below 1');
  }

  function _repay(
    ISpoke spoke,
    Types.ReserveInfo memory reserveInfo,
    address user,
    uint256 amount
  ) internal {
    Types.PositionSnapshot memory snapshotBefore = _getPositionSnapshot(spoke, reserveInfo, user);
    uint256 effectiveRepayAmount = amount >= snapshotBefore.user.totalDebt
      ? snapshotBefore.user.totalDebt
      : amount;
    uint256 drawnRepayAmount = effectiveRepayAmount > snapshotBefore.user.premiumDebt
      ? effectiveRepayAmount - snapshotBefore.user.premiumDebt
      : 0;
    uint256 expectedRestoredShares = IHubBase(reserveInfo.hub).previewRestoreByAssets(
      reserveInfo.assetId,
      drawnRepayAmount
    );

    _forceApprove({
      spoke: spoke,
      underlying: reserveInfo.underlying,
      user: user,
      amount: effectiveRepayAmount
    });

    _logAction('REPAY', reserveInfo.symbol, amount);
    vm.prank(user);
    (uint256 returnedShares, uint256 returnedAssets) = spoke.repay({
      reserveId: reserveInfo.reserveId,
      amount: amount,
      onBehalfOf: user
    });

    Types.PositionSnapshot memory snapshotAfter = _getPositionSnapshot(spoke, reserveInfo, user);

    assertEq(returnedAssets, effectiveRepayAmount, 'REPAY: returnedAssets mismatch');
    assertEq(returnedShares, expectedRestoredShares, 'REPAY: returnedShares mismatch');

    if (amount >= snapshotBefore.user.totalDebt) {
      assertEq(snapshotAfter.user.totalDebt, 0, 'REPAY: user debt should be zero');
    } else {
      assertApproxEqAbs(
        snapshotAfter.user.totalDebt.delta(snapshotBefore.user.totalDebt),
        amount,
        2,
        'REPAY: user debt mismatch'
      );
    }
    // Hub spoke - up to 2 wei diff due to premium/drawn debt
    assertApproxEqAbs(
      snapshotBefore.spokeOnHub.totalDebt.delta(snapshotAfter.spokeOnHub.totalDebt),
      effectiveRepayAmount,
      2,
      'REPAY: hub debt mismatch'
    );
    assertEq(
      snapshotBefore.spokeOnHub.drawnShares.delta(snapshotAfter.spokeOnHub.drawnShares),
      expectedRestoredShares,
      'REPAY: hub drawn shares mismatch'
    );
  }

  function _liquidationCall(
    ISpoke spoke,
    Types.ReserveInfo memory collateralInfo,
    Types.ReserveInfo memory debtInfo,
    address liquidator,
    address borrower,
    uint256 debtToCover,
    bool receiveShares
  ) internal {
    Types.PositionSnapshot memory collateralSnapshotBefore = _getPositionSnapshot(
      spoke,
      collateralInfo,
      borrower
    );
    Types.PositionSnapshot memory debtSnapshotBefore = _getPositionSnapshot(
      spoke,
      debtInfo,
      borrower
    );
    assertGt(debtSnapshotBefore.user.totalDebt, 0, 'LIQUIDATE: borrower has no debt');

    _forceApprove({
      spoke: spoke,
      underlying: debtInfo.underlying,
      user: liquidator,
      amount: debtSnapshotBefore.user.totalDebt
    });

    // Capture pre-liquidation totals (token balance + supplied assets) for profitability check
    uint256 liquidatorDebtTotalBefore = IERC20(debtInfo.underlying).balanceOf(liquidator) +
      spoke.getUserSuppliedAssets(debtInfo.reserveId, liquidator);
    uint256 liquidatorCollateralTotalBefore = IERC20(collateralInfo.underlying).balanceOf(
      liquidator
    ) + spoke.getUserSuppliedAssets(collateralInfo.reserveId, liquidator);

    ISpoke.UserAccountData memory borrowerAccountDataBefore = spoke.getUserAccountData(borrower);

    if (debtToCover == UINT256_MAX) {
      console.log(
        'LIQUIDATE: %s, DebtToCover: UINT256_MAX, TotalDebt: %e',
        debtInfo.symbol,
        debtSnapshotBefore.user.totalDebt
      );
    } else {
      console.log(
        'LIQUIDATE: %s, DebtToCover: %e, TotalDebt: %e',
        debtInfo.symbol,
        debtToCover,
        debtSnapshotBefore.user.totalDebt
      );
    }

    vm.prank(liquidator);
    spoke.liquidationCall({
      collateralReserveId: collateralInfo.reserveId,
      debtReserveId: debtInfo.reserveId,
      user: borrower,
      debtToCover: debtToCover,
      receiveShares: receiveShares
    });

    Types.PositionSnapshot memory collateralSnapshotAfter = _getPositionSnapshot(
      spoke,
      collateralInfo,
      borrower
    );
    Types.PositionSnapshot memory debtSnapshotAfter = _getPositionSnapshot(
      spoke,
      debtInfo,
      borrower
    );

    // Debt decreased
    assertLt(
      debtSnapshotAfter.user.totalDebt,
      debtSnapshotBefore.user.totalDebt,
      'LIQUIDATE: debt did not decrease'
    );
    assertLt(
      debtSnapshotAfter.spokeOnHub.totalDebt,
      debtSnapshotBefore.spokeOnHub.totalDebt,
      'LIQUIDATE: hub debt did not decrease'
    );
    // Collateral decreased
    assertLt(
      collateralSnapshotAfter.user.collateralAssets,
      collateralSnapshotBefore.user.collateralAssets,
      'LIQUIDATE: collateral did not decrease'
    );
    // hub collateral can remain unchanged if receiveShares is true
    assertLe(
      collateralSnapshotAfter.spokeOnHub.totalDebt,
      collateralSnapshotAfter.spokeOnHub.totalDebt,
      'LIQUIDATE: hub collateral did not decrease or stay the same'
    );
    assertLe(
      spoke.getUserAccountData(borrower).activeCollateralCount,
      borrowerAccountDataBefore.activeCollateralCount,
      'LIQUIDATE: borrower collateral count did not decrease or stay the same'
    );
    assertLe(
      spoke.getUserAccountData(borrower).borrowCount,
      borrowerAccountDataBefore.borrowCount,
      'LIQUIDATE: borrower borrow count did not decrease or stay the same'
    );
    assertLe(
      spoke.getUserAccountData(borrower).totalCollateralValue,
      borrowerAccountDataBefore.totalCollateralValue,
      'LIQUIDATE: borrower collateral value did not decrease or stay the same'
    );
    assertLe(
      spoke.getUserAccountData(borrower).totalDebtValueRay,
      borrowerAccountDataBefore.totalDebtValueRay,
      'LIQUIDATE: borrower debt value did not decrease or stay the same'
    );

    // Liquidation profitability: collateral value received > debt value paid
    _assertLiquidationProfitable({
      spoke: spoke,
      collateralInfo: collateralInfo,
      debtInfo: debtInfo,
      liquidator: liquidator,
      liquidatorDebtBefore: liquidatorDebtTotalBefore,
      liquidatorCollateralBefore: liquidatorCollateralTotalBefore
    });
  }

  /// @dev Totals = token balance + supplied share assets. Caller passes pre-computed before-totals.
  function _assertLiquidationProfitable(
    ISpoke spoke,
    Types.ReserveInfo memory collateralInfo,
    Types.ReserveInfo memory debtInfo,
    address liquidator,
    uint256 liquidatorDebtBefore,
    uint256 liquidatorCollateralBefore
  ) private view {
    uint256 liquidatorDebtAfter = IERC20(debtInfo.underlying).balanceOf(liquidator) +
      spoke.getUserSuppliedAssets(debtInfo.reserveId, liquidator);
    uint256 liquidatorCollateralAfter = IERC20(collateralInfo.underlying).balanceOf(liquidator) +
      spoke.getUserSuppliedAssets(collateralInfo.reserveId, liquidator);

    uint256 debtSpent = liquidatorDebtAfter.delta(liquidatorDebtBefore);
    uint256 collateralGained = liquidatorCollateralAfter.delta(liquidatorCollateralBefore);

    if (collateralInfo.underlying == debtInfo.underlying) {
      // Same underlying: collateral/debt assets are the same, so debtSpent should == collateralGained and be positive
      assertEq(debtSpent, collateralGained); // sanity check
      assertGt(
        collateralGained,
        0,
        'LIQUIDATE: not profitable (same underlying) - collateral gained <= debt spent'
      );
    } else {
      // Different underlyings: compare oracle-normalized $ values.
      // Cross-multiply to avoid precision loss from division with extreme mocked prices:
      // collGained * collPrice * 10^debtDecimals > debtSpent * debtPrice * 10^collDecimals
      IAaveOracle oracle = IAaveOracle(spoke.ORACLE());
      uint256 collPrice = oracle.getReservePrice(collateralInfo.reserveId);
      uint256 debtPrice = oracle.getReservePrice(debtInfo.reserveId);

      assertGt(
        collateralGained * collPrice * (10 ** debtInfo.decimals),
        debtSpent * debtPrice * (10 ** collateralInfo.decimals),
        'LIQUIDATE: not profitable - collateral $ value <= debt $ value'
      );
    }
  }

  /// @notice Convert a token amount to its oracle-denominated value.
  function _getOracleValue(
    IAaveOracle oracle,
    Types.ReserveInfo memory reserveInfo,
    uint256 amount
  ) internal view returns (uint256) {
    uint256 price = oracle.getReservePrice(reserveInfo.reserveId);
    return (amount * price) / (10 ** reserveInfo.decimals);
  }

  function _maxDealAmount(uint8 decimals) internal pure returns (uint256) {
    return MAX_DEAL_UNIT * 10 ** decimals;
  }

  function _logAction(string memory action, string memory symbol, uint256 amount) internal pure {
    if (amount == UINT256_MAX) {
      console.log('%s: %s, Amount: UINT256_MAX', action, symbol);
    } else {
      console.log('%s: %s, Amount: %e', action, symbol, amount);
    }
  }
}
