// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {IAccessManaged} from 'aave-v4/dependencies/openzeppelin/IAccessManaged.sol';
import {HubConfigurator} from 'aave-v4/hub/HubConfigurator.sol';
import {ISpoke, IHub, IHubConfigurator, IAaveOracle} from 'aave-address-book/AaveV4.sol';
import {Types} from 'src/dependencies/v4/Types.sol';
import {Actions} from 'src/dependencies/v4/Actions.sol';

/// @title Helpers
/// @notice Query and utility functions for V4 e2e tests.
abstract contract Helpers is Actions {
  /// @notice Build ReserveInfo[] for all reserves on a spoke.
  function _getReserveInfo(ISpoke spoke) internal view returns (Types.ReserveInfo[] memory) {
    uint256 count = spoke.getReserveCount();
    Types.ReserveInfo[] memory info = new Types.ReserveInfo[](count);

    for (uint256 reserveId; reserveId < count; reserveId++) {
      ISpoke.Reserve memory reserve = spoke.getReserve(reserveId);
      ISpoke.ReserveConfig memory config = spoke.getReserveConfig(reserveId);
      ISpoke.DynamicReserveConfig memory dynamicConfig = spoke.getDynamicReserveConfig(
        reserveId,
        reserve.dynamicConfigKey
      );

      info[reserveId] = Types.ReserveInfo({
        reserveId: reserveId,
        underlying: reserve.underlying,
        hub: address(reserve.hub),
        assetId: reserve.assetId,
        symbol: _safeSymbol(reserve.underlying),
        decimals: reserve.decimals,
        paused: config.paused,
        frozen: config.frozen,
        borrowable: config.borrowable,
        collateralEnabled: dynamicConfig.collateralFactor > 0,
        collateralFactor: dynamicConfig.collateralFactor,
        maxLiquidationBonus: dynamicConfig.maxLiquidationBonus,
        liquidationFee: dynamicConfig.liquidationFee
      });
    }
    return info;
  }

  /// @notice Return all usable collaterals: not paused, not frozen, collateralFactor > 0.
  function _getAllUsableCollaterals(
    Types.ReserveInfo[] memory infos
  ) internal pure returns (Types.ReserveInfo[] memory) {
    uint256 count;
    for (uint256 i; i < infos.length; i++) {
      if (!infos[i].paused && !infos[i].frozen && infos[i].collateralEnabled) {
        count++;
      }
    }
    Types.ReserveInfo[] memory result = new Types.ReserveInfo[](count);
    uint256 index;
    for (uint256 i; i < infos.length; i++) {
      if (!infos[i].paused && !infos[i].frozen && infos[i].collateralEnabled) {
        result[index] = infos[i];
        index++;
      }
    }
    return result;
  }

  /// @notice Return all usable debt reserves: not paused, not frozen, borrowable.
  function _getAllUsableDebtReserves(
    Types.ReserveInfo[] memory infos
  ) internal pure returns (Types.ReserveInfo[] memory) {
    uint256 count;
    for (uint256 i; i < infos.length; i++) {
      if (!infos[i].paused && !infos[i].frozen && infos[i].borrowable) {
        count++;
      }
    }
    Types.ReserveInfo[] memory result = new Types.ReserveInfo[](count);
    uint256 index;
    for (uint256 i; i < infos.length; i++) {
      if (!infos[i].paused && !infos[i].frozen && infos[i].borrowable) {
        result[index] = infos[i];
        index++;
      }
    }
    return result;
  }

  /// @notice Ensure the hub has enough liquidity for a borrow by supplying on the given spoke.
  ///         Assumes addCaps have been set to max via _setCapsToMax before calling.
  function _ensureLiquidity(
    ISpoke spoke,
    Types.ReserveInfo memory reserveInfo,
    uint256 amount
  ) internal {
    _supply({spoke: spoke, reserveInfo: reserveInfo, user: vm.randomAddress(), amount: amount});
  }

  /// @notice Supply collateral to borrower on the same spoke, then enable as collateral.
  ///         Assumes addCaps have been set to max via _setCapsToMax before calling.
  function _ensureCollateral(
    ISpoke spoke,
    Types.ReserveInfo memory reserveInfo,
    address borrower,
    uint256 amount
  ) internal {
    _supply(spoke, reserveInfo, borrower, amount);
    vm.prank(borrower);
    spoke.setUsingAsCollateral({
      reserveId: reserveInfo.reserveId,
      usingAsCollateral: true,
      onBehalfOf: borrower
    });
  }

  /// @notice Ensure borrower has enough collateral to borrow a given dollar amount.
  ///         Loops over all collateral-enabled reserves, supplying until capacity is sufficient.
  ///         Compares against CF-adjusted totalCollateralValue, so it may use multiple reserves.
  function _ensureBorrowCapacity(
    ISpoke spoke,
    address borrower,
    uint256 borrowAmountInDollars
  ) internal {
    Types.ReserveInfo[] memory goodCollaterals = _getAllUsableCollaterals(_getReserveInfo(spoke));
    address oracleAddr = spoke.ORACLE();
    uint8 oracleDecimals = IAaveOracle(oracleAddr).decimals();
    uint256 targetCollateralDollarAmount = borrowAmountInDollars * 3;
    uint256 targetCollateralValue = targetCollateralDollarAmount * 10 ** oracleDecimals;

    for (uint256 i; i < goodCollaterals.length; i++) {
      uint256 supplyAmount = _getTokenAmountByDollarValue({
        oracleAddr: oracleAddr,
        reserveInfo: goodCollaterals[i],
        dollarValue: targetCollateralDollarAmount
      });

      _ensureCollateral({
        spoke: spoke,
        reserveInfo: goodCollaterals[i],
        borrower: borrower,
        amount: supplyAmount
      });

      // Check after supplying — totalCollateralValue is CF-adjusted, so we may need
      // multiple reserves to reach the target raw collateral value.
      ISpoke.UserAccountData memory account = spoke.getUserAccountData(borrower);
      if (account.totalCollateralValue > targetCollateralValue) {
        break;
      }
    }
  }

  /// @notice Convert a dollar value to token amount using the spoke oracle.
  function _getTokenAmountByDollarValue(
    address oracleAddr,
    Types.ReserveInfo memory reserveInfo,
    uint256 dollarValue
  ) internal view returns (uint256) {
    IAaveOracle oracle = IAaveOracle(oracleAddr);
    uint256 price = oracle.getReservePrice(reserveInfo.reserveId);
    uint8 oracleDecimals = oracle.decimals();
    return (dollarValue * 10 ** (oracleDecimals + reserveInfo.decimals)) / price;
  }

  /// @notice Supply up to `extraCount` of additional collaterals for the user, up to `maxUserReserves`.
  function _supplyRandomExtraCollaterals(
    ISpoke spoke,
    Types.ReserveInfo[] memory goodCollaterals,
    uint256 primaryIndex,
    uint256 testAssetReserveId,
    address oracleAddr,
    address user,
    uint256 extraCount
  ) internal {
    if (goodCollaterals.length <= 1 || extraCount == 0) {
      return;
    }

    uint16 maxUserReserves = spoke.MAX_USER_RESERVES_LIMIT();

    // Track collateral count before starting
    ISpoke.UserAccountData memory accountBefore = spoke.getUserAccountData(user);
    uint256 expectedCollateralCount = accountBefore.activeCollateralCount;

    uint256 supplied;
    for (uint256 index; index < goodCollaterals.length && supplied < extraCount; index++) {
      // skip the primary collateral and the test asset
      if (index == primaryIndex || goodCollaterals[index].reserveId == testAssetReserveId) {
        continue;
      }

      // When at the limit, assert the next collateral enable reverts, then restore state
      if (expectedCollateralCount + 1 > maxUserReserves) {
        _assertMaxUserReservesReverts({
          spoke: spoke,
          reserveInfo: goodCollaterals[index],
          oracleAddr: oracleAddr,
          user: user,
          isCollateral: true
        });
        break;
      }

      // adding too much collateral will mean user's HF is too high to make liquidatable easily
      uint256 extraDollars = vm.randomUint(1_000, 10_000);
      uint256 extraAmount = _getTokenAmountByDollarValue({
        oracleAddr: oracleAddr,
        reserveInfo: goodCollaterals[index],
        dollarValue: extraDollars
      });

      _supply({spoke: spoke, reserveInfo: goodCollaterals[index], user: user, amount: extraAmount});
      vm.prank(user);
      spoke.setUsingAsCollateral({
        reserveId: goodCollaterals[index].reserveId,
        usingAsCollateral: true,
        onBehalfOf: user
      });

      supplied++;
      expectedCollateralCount++;

      // Verify activeCollateralCount matches expected
      ISpoke.UserAccountData memory accountAfter = spoke.getUserAccountData(user);
      assertEq(
        accountAfter.activeCollateralCount,
        expectedCollateralCount,
        'EXTRA_COLLATERAL: activeCollateralCount mismatch'
      );
      assertLe(
        accountAfter.activeCollateralCount,
        maxUserReserves,
        'EXTRA_COLLATERAL: exceeds MAX_USER_RESERVES_LIMIT'
      );
    }
  }

  /// @notice Borrow from a random number of extra debt reserves for the user.
  ///         Supplies liquidity from a separate provider before each borrow.
  function _borrowRandomExtraReserves(
    ISpoke spoke,
    Types.ReserveInfo[] memory usableDebtReserves,
    uint256 primaryReserveId,
    address oracleAddr,
    address user,
    uint256 extraCount
  ) internal {
    if (usableDebtReserves.length <= 1 || extraCount == 0) {
      return;
    }

    uint16 maxUserReserves = spoke.MAX_USER_RESERVES_LIMIT();

    ISpoke.UserAccountData memory accountBefore = spoke.getUserAccountData(user);
    uint256 expectedBorrowCount = accountBefore.borrowCount;

    uint256 borrowed;
    for (uint256 index; index < usableDebtReserves.length && borrowed < extraCount; index++) {
      Types.ReserveInfo memory debtReserve = usableDebtReserves[index];

      if (debtReserve.reserveId == primaryReserveId) {
        continue;
      }

      // When at the limit, assert the next borrow reverts, then restore state
      if (expectedBorrowCount + 1 > maxUserReserves) {
        _assertMaxUserReservesReverts({
          spoke: spoke,
          reserveInfo: debtReserve,
          oracleAddr: oracleAddr,
          user: user,
          isCollateral: false
        });
        break;
      }

      uint256 extraDollars = vm.randomUint(100, 1_000);
      uint256 extraAmount = _getTokenAmountByDollarValue({
        oracleAddr: oracleAddr,
        reserveInfo: debtReserve,
        dollarValue: extraDollars
      });

      _ensureLiquidity({spoke: spoke, reserveInfo: debtReserve, amount: extraAmount});
      _borrow({spoke: spoke, reserveInfo: debtReserve, user: user, amount: extraAmount});

      borrowed++;
      expectedBorrowCount++;

      // Verify borrowCount within limit
      ISpoke.UserAccountData memory accountAfter = spoke.getUserAccountData(user);
      assertLe(
        accountAfter.borrowCount,
        maxUserReserves,
        'EXTRA_BORROW: exceeds MAX_USER_RESERVES_LIMIT'
      );
      assertEq(accountAfter.borrowCount, expectedBorrowCount, 'EXTRA_BORROW: borrowCount mismatch');
    }
  }

  /// @notice Assert that exceeding MAX_USER_RESERVES_LIMIT reverts, then restore state.
  function _assertMaxUserReservesReverts(
    ISpoke spoke,
    Types.ReserveInfo memory reserveInfo,
    address oracleAddr,
    address user,
    bool isCollateral
  ) internal {
    uint256 snapshot = vm.snapshotState();

    uint256 dollarValue = vm.randomUint(1_000, 50_000);
    uint256 amount = _getTokenAmountByDollarValue({
      oracleAddr: oracleAddr,
      reserveInfo: reserveInfo,
      dollarValue: dollarValue
    });

    if (isCollateral) {
      _supply({spoke: spoke, reserveInfo: reserveInfo, user: user, amount: amount});
      vm.prank(user);
      vm.expectRevert(ISpoke.MaximumUserReservesExceeded.selector);
      spoke.setUsingAsCollateral({
        reserveId: reserveInfo.reserveId,
        usingAsCollateral: true,
        onBehalfOf: user
      });
    } else {
      _ensureLiquidity({spoke: spoke, reserveInfo: reserveInfo, amount: amount});
      vm.prank(user);
      vm.expectRevert(ISpoke.MaximumUserReservesExceeded.selector);
      spoke.borrow({reserveId: reserveInfo.reserveId, amount: amount, onBehalfOf: user});
    }

    vm.revertToState(snapshot);
  }

  /// @notice Set all addCap/drawCap to max for every reserve on the spoke.
  function _setCapsToMax(ISpoke spoke) internal {
    _setSpokeCapsToMaxForAllReserves({spoke: spoke, maxAddCap: true, maxDrawCap: true});
  }

  /// @notice Set all addCap to max for every reserve on the spoke (leaves drawCap unchanged).
  function _setAddCapsToMax(ISpoke spoke) internal {
    _setSpokeCapsToMaxForAllReserves({spoke: spoke, maxAddCap: true, maxDrawCap: false});
  }

  /// @notice Set caps to max for a single hub-asset-spoke combination.
  /// @param maxAddCap If true, set addCap to max.
  /// @param maxDrawCap If true, set drawCap to max.
  function _setSpokeCapsToMax(
    IHub hub,
    uint256 assetId,
    address spoke,
    bool maxAddCap,
    bool maxDrawCap
  ) internal {
    IHubConfigurator configurator = _deployMockedHubConfigurator(hub);
    IHub.SpokeConfig memory config = hub.getSpokeConfig(assetId, spoke);
    if (maxAddCap) {
      config.addCap = hub.MAX_ALLOWED_SPOKE_CAP();
    }
    if (maxDrawCap) {
      config.drawCap = hub.MAX_ALLOWED_SPOKE_CAP();
    }
    configurator.updateSpokeCaps({
      hub: address(hub),
      assetId: assetId,
      spoke: spoke,
      addCap: config.addCap,
      drawCap: config.drawCap
    });
  }

  function _setSpokeCapsToMaxForAllReserves(ISpoke spoke, bool maxAddCap, bool maxDrawCap) private {
    Types.ReserveInfo[] memory infos = _getReserveInfo(spoke);
    for (uint256 i; i < infos.length; i++) {
      _setSpokeCapsToMax({
        hub: IHub(infos[i].hub),
        assetId: infos[i].assetId,
        spoke: address(spoke),
        maxAddCap: maxAddCap,
        maxDrawCap: maxDrawCap
      });
    }
    vm.clearMockedCalls();
  }

  /// @notice Deploy a temporary HubConfigurator with the hub's access manager, mocked to allow all calls.
  function _deployMockedHubConfigurator(IHub hub) internal returns (IHubConfigurator) {
    address accessManager = IAccessManaged(address(hub)).authority();
    vm.mockCall(
      accessManager,
      abi.encodeWithSelector(bytes4(keccak256('canCall(address,address,bytes4)'))),
      abi.encode(true, uint32(0))
    );
    return IHubConfigurator(address(new HubConfigurator(accessManager)));
  }

  function _safeSymbol(address token) internal view returns (string memory) {
    return IERC20Metadata(token).symbol();
  }
}
