// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5 <0.9.0;

import 'forge-std/Test.sol';
import {IAaveOracle, IPool, IPoolAddressesProvider, IPoolDataProvider, IReserveInterestRateStrategy, DataTypes, IPoolConfigurator, Errors} from 'aave-address-book/AaveV3.sol';
import {ReserveConfig} from 'aave-v3-origin-tests/utils/ProtocolV3TestBase.sol';
import {PercentageMath} from 'aave-v3-origin/contracts/protocol/libraries/math/PercentageMath.sol';
import {WadRayMath} from 'aave-v3-origin/contracts/protocol/libraries/math/WadRayMath.sol';
import {SnapshotHelpersV3} from './SnapshotHelpersV3.sol';
import {ProtocolV3TestBase as BaseProtocolV3TestBase} from '../../src/ProtocolV3TestBase.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

contract MockFlashReceiver {
  using SafeERC20 for IERC20;

  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address,
    bytes calldata
  ) external returns (bool) {
    for (uint256 i; i < assets.length; ++i) {
      IERC20(assets[i]).forceApprove(msg.sender, amounts[i] + premiums[i]);
    }
    return true;
  }
}

/**
 * only applicable to harmony at this point
 */
contract ProtocolV3TestBase is BaseProtocolV3TestBase {
  SnapshotHelpersV3 public snapshotHelper;
  using PercentageMath for uint256;
  using WadRayMath for uint256;

  function setUp() public virtual {
    snapshotHelper = new SnapshotHelpersV3();
    vm.makePersistent(address(snapshotHelper));
    vm.allowCheatcodes(address(snapshotHelper));
  }

  // workaround for https://github.com/matter-labs/foundry-zksync/issues/1073#issuecomment-2982866755
  function _flashLoan(
    ReserveConfig memory config,
    IPool pool,
    address user,
    address receiverAddress,
    uint256 amount,
    uint256 interestRateMode
  ) internal override {
    FlashLoanVars memory vars;

    vm.startPrank(user);

    DataTypes.ReserveDataLegacy memory reserveDataBefore = pool.getReserveData(config.underlying);

    vars.underlyingTokenBalanceOfATokenBefore = IERC20(config.underlying).balanceOf(config.aToken);
    vars.debtTokenBalanceOfUserBefore = IERC20(config.variableDebtToken).balanceOf(user);

    // @dev lazy way to initialize `FlashReceiver` address
    address receiverAddress2 = address(new MockFlashReceiver());

    if (interestRateMode == 0) {
      vars.flashLoanPremiumTotal = pool.FLASHLOAN_PREMIUM_TOTAL();

      vars.flashLoanPremiumTotal = amount.percentMulCeil(vars.flashLoanPremiumTotal);
      // @dev funds the FlashReceiver address
      deal2(config.underlying, receiverAddress2, vars.flashLoanPremiumTotal);
    }

    console.log('FLASH LOAN: %s, Amount: %s', config.symbol, amount);

    vars.assets = new address[](1);
    vars.assets[0] = config.underlying;

    vars.amounts = new uint256[](1);
    vars.amounts[0] = amount;

    vars.interestRateModes = new uint256[](1);
    vars.interestRateModes[0] = interestRateMode;

    console.log('fails next call');
    pool.flashLoan({
      receiverAddress: receiverAddress2, // @dev FlashReceiver address initialized above
      assets: vars.assets,
      amounts: vars.amounts,
      interestRateModes: vars.interestRateModes,
      onBehalfOf: user,
      params: '',
      referralCode: 0
    });

    vars.underlyingTokenBalanceOfATokenAfter = IERC20(config.underlying).balanceOf(config.aToken);
    vars.debtTokenBalanceOfUserAfter = IERC20(config.variableDebtToken).balanceOf(user);
    DataTypes.ReserveDataLegacy memory reserveDataAfter = pool.getReserveData(config.underlying);

    if (interestRateMode == 0) {
      assertEq(
        vars.underlyingTokenBalanceOfATokenBefore + vars.flashLoanPremiumTotal,
        vars.underlyingTokenBalanceOfATokenAfter,
        '11'
      );
      assertEq(
        reserveDataBefore.accruedToTreasury +
          vars.flashLoanPremiumTotal.rayDivFloor(reserveDataAfter.liquidityIndex),
        reserveDataAfter.accruedToTreasury,
        '12'
      );

      assertEq(vars.debtTokenBalanceOfUserAfter, vars.debtTokenBalanceOfUserBefore, '2');
    } else {
      assertGt(
        vars.underlyingTokenBalanceOfATokenBefore,
        vars.underlyingTokenBalanceOfATokenAfter,
        '3'
      );
      assertEq(
        vars.underlyingTokenBalanceOfATokenBefore - amount,
        vars.underlyingTokenBalanceOfATokenAfter,
        '4'
      );

      assertGt(vars.debtTokenBalanceOfUserAfter, vars.debtTokenBalanceOfUserBefore, '5');
      assertApproxEqAbs(
        vars.debtTokenBalanceOfUserAfter,
        vars.debtTokenBalanceOfUserBefore + amount,
        2,
        '6'
      );
    }

    vm.stopPrank();
  }

  /**
   * @dev Generates a markdown compatible snapshot of the whole pool configuration into `/reports`.
   * @param reportName filename suffix for the generated reports.
   * @param pool the pool to be snapshot
   * @return ReserveConfig[] list of configs
   */
  function createConfigurationSnapshot(
    string memory reportName,
    IPool pool
  ) public override returns (ReserveConfig[] memory) {
    return createConfigurationSnapshot(reportName, pool, true, true, true, true);
  }

  function createConfigurationSnapshot(
    string memory reportName,
    IPool pool,
    bool reserveConfigs,
    bool strategyConfigs,
    bool eModeConigs,
    bool poolConfigs
  ) public override returns (ReserveConfig[] memory) {
    ReserveConfig[] memory configs = _getReservesConfigs(pool);
    _switchOffZkVm();
    return
      snapshotHelper.createConfigurationSnapshot(
        reportName,
        pool,
        reserveConfigs,
        strategyConfigs,
        eModeConigs,
        poolConfigs,
        configs
      );
  }

  function _writeEModeConfigs(string memory path, IPool pool) internal override {
    _switchOffZkVm();
    return snapshotHelper.writeEModeConfigs(path, pool);
  }

  function _writeStrategyConfigs(
    string memory path,
    ReserveConfig[] memory configs
  ) internal override {
    _switchOffZkVm();
    return snapshotHelper.writeStrategyConfigs(path, configs);
  }

  function _writeReserveConfigs(
    string memory path,
    ReserveConfig[] memory configs,
    IPool pool
  ) internal override {
    _switchOffZkVm();
    return snapshotHelper.writeReserveConfigs(path, configs, pool);
  }

  function _writePoolConfiguration(string memory path, IPool pool) internal override {
    _switchOffZkVm();
    return snapshotHelper.writePoolConfiguration(path, pool);
  }

  function _switchOffZkVm() internal {
    (bool success, ) = address(vm).call(abi.encodeWithSignature('zkVm(bool)', false));
    require(success, 'ERROR SWITCHING OFF ZKVM');
  }
}
