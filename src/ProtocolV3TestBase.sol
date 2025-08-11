// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5 <0.9.0;

import 'forge-std/Test.sol';
import {IAaveOracle, IPool, IPoolAddressesProvider, IPoolDataProvider, IReserveInterestRateStrategy, DataTypes, IPoolConfigurator, Errors} from 'aave-address-book/AaveV3.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {ReserveConfiguration} from 'aave-v3-origin/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {PercentageMath} from 'aave-v3-origin/contracts/protocol/libraries/math/PercentageMath.sol';
import {WadRayMath} from 'aave-v3-origin/contracts/protocol/libraries/math/WadRayMath.sol';
import {IDefaultInterestRateStrategyV2} from 'aave-v3-origin/contracts/interfaces/IDefaultInterestRateStrategyV2.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {DiffUtils} from 'aave-v3-origin-tests/utils/DiffUtils.sol';
import {ProtocolV3TestBase as RawProtocolV3TestBase, ReserveConfig} from 'aave-v3-origin-tests/utils/ProtocolV3TestBase.sol';
import {MockAggregator} from 'aave-v3-origin/contracts/mocks/oracle/CLAggregators/MockAggregator.sol';
import {IInitializableAdminUpgradeabilityProxy} from './interfaces/IInitializableAdminUpgradeabilityProxy.sol';
import {ExtendedAggregatorV2V3Interface} from './interfaces/ExtendedAggregatorV2V3Interface.sol';
import {CommonTestBase, ReserveTokens, ChainIds} from './CommonTestBase.sol';
import {ILegacyDefaultInterestRateStrategy} from './dependencies/ILegacyDefaultInterestRateStrategy.sol';
import {Strings} from 'openzeppelin-contracts/contracts/utils/Strings.sol';
import {SeatbeltUtils} from './SeatbeltUtils.sol';
import {GovV3Helpers} from './GovV3Helpers.sol';

struct InterestStrategyValues {
  address addressesProvider;
  uint256 optimalUsageRatio;
  uint256 optimalStableToTotalDebtRatio;
  uint256 baseStableBorrowRate;
  uint256 stableRateSlope1;
  uint256 stableRateSlope2;
  uint256 baseVariableBorrowRate;
  uint256 variableRateSlope1;
  uint256 variableRateSlope2;
}

/**
 * only applicable to harmony at this point
 */
contract ProtocolV3TestBase is RawProtocolV3TestBase, SeatbeltUtils, CommonTestBase {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using PercentageMath for uint256;
  using WadRayMath for uint256;
  using SafeERC20 for IERC20;
  using Strings for string;

  // mock receiver for flashloans
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address /* initiator */,
    bytes calldata /* params */
  ) external virtual returns (bool) {
    for (uint256 i = 0; i < assets.length; i++) {
      IERC20(assets[i]).forceApprove(msg.sender, amounts[i] + premiums[i]);
    }

    return true;
  }

  /**
   * @dev runs the default test suite that should run on any proposal touching the aave protocol which includes:
   * - diffing the config
   * - checking if the changes are plausible (no conflicting config changes etc)
   * - running an e2e testsuite over all assets
   */
  function defaultTest(
    string memory reportName,
    IPool pool,
    address payload
  ) public returns (ReserveConfig[] memory, ReserveConfig[] memory) {
    return defaultTest(reportName, pool, payload, true, false);
  }

  function defaultTest(
    string memory reportName,
    IPool pool,
    address payload,
    bool runE2E,
    bool runSeatbelt
  ) public returns (ReserveConfig[] memory, ReserveConfig[] memory) {
    string memory beforeString = string(abi.encodePacked(reportName, '_before'));
    ReserveConfig[] memory configBefore = createConfigurationSnapshot(beforeString, pool);

    uint256 startGas = gasleft();

    vm.startStateDiffRecording();
    executePayload(vm, payload, pool);
    string memory rawDiff = vm.getStateDiffJson();

    uint256 gasUsed = startGas - gasleft();
    assertLt(gasUsed, (block.gaslimit * 95) / 100, 'BLOCK_GAS_LIMIT_EXCEEDED'); // 5% is kept as a buffer

    string memory afterString = string(abi.encodePacked(reportName, '_after'));
    ReserveConfig[] memory configAfter = createConfigurationSnapshot(afterString, pool);
    vm.writeJson(
      vm.serializeString('root', 'raw', rawDiff), // output
      string(abi.encodePacked('./reports/', afterString, '.json'))
    );

    diffReports(beforeString, afterString);
    if (runSeatbelt) {
      generateSeatbeltReport(
        reportName,
        address(GovV3Helpers.getPayloadsController(pool, block.chainid)),
        payload.code
      );
    }

    configChangePlausibilityTest(configBefore, configAfter);

    if (runE2E) e2eTest(pool);
    return (configBefore, configAfter);
  }

  function configChangePlausibilityTest(
    ReserveConfig[] memory configBefore,
    ReserveConfig[] memory configAfter
  ) public view {
    uint256 configsBeforeLength = configBefore.length;
    for (uint256 i = 0; i < configAfter.length; i++) {
      // assets are usually not permanently unlisted, so the expectation is there will only be addition
      // if config existed before
      if (i < configsBeforeLength) {
        // borrow increase should only happen on assets with borrowing enabled
        // unless it is setting a borrow cap for the first time
        if (
          configBefore[i].borrowCap < configAfter[i].borrowCap && configBefore[i].borrowCap != 0
        ) {
          require(configAfter[i].borrowingEnabled, 'PL_BORROW_CAP_BORROW_DISABLED');
        }
      } else {
        // at least newly listed assets should never have a supply cap exceeding total supply
        uint256 totalSupply = IERC20(configAfter[i].underlying).totalSupply();
        require(
          configAfter[i].supplyCap / 1e2 <=
            totalSupply / IERC20Metadata(configAfter[i].underlying).decimals(),
          'PL_SUPPLY_CAP_GT_TOTAL_SUPPLY'
        );
      }
      // borrow cap should never exceed supply cap
      if (
        configAfter[i].borrowCap != 0 &&
        configAfter[i].underlying != AaveV3EthereumAssets.GHO_UNDERLYING // GHO is the exclusion from the rule
      ) {
        console.log(configAfter[i].underlying);
        require(configAfter[i].borrowCap <= configAfter[i].supplyCap, 'PL_SUPPLY_LT_BORROW');
      }
    }
  }

  /**
   * @dev Makes a e2e test including withdrawals/borrows and supplies to various reserves.
   * @param pool the pool that should be tested
   */
  function e2eTest(IPool pool) public {
    ReserveConfig[] memory configs = _getReservesConfigs(pool);
    ReserveConfig memory collateralConfig = _getGoodCollateral(configs);
    uint256 snapshot = vm.snapshotState();
    for (uint256 i; i < configs.length; i++) {
      if (_includeInE2e(configs[i])) {
        e2eTestAsset(pool, collateralConfig, configs[i]);
        vm.revertToState(snapshot);
      } else {
        console.log('E2E: TestAsset %s SKIPPED', configs[i].symbol);
      }
    }
  }

  function e2eTestAsset(
    IPool pool,
    ReserveConfig memory collateralConfig,
    ReserveConfig memory testAssetConfig
  ) public {
    console.log(
      'E2E: Collateral %s, TestAsset %s',
      collateralConfig.symbol,
      testAssetConfig.symbol
    );
    address collateralSupplier = vm.addr(3);
    address testAssetSupplier = vm.addr(4);
    require(collateralConfig.usageAsCollateralEnabled, 'COLLATERAL_CONFIG_MUST_BE_COLLATERAL');
    uint256 collateralAssetAmount = _getTokenAmountByDollarValue(pool, collateralConfig, 100_000);
    uint256 testAssetAmount = _getTokenAmountByDollarValue(pool, testAssetConfig, 10_000);

    // remove caps as they should not prevent testing
    IPoolAddressesProvider addressesProvider = IPoolAddressesProvider(pool.ADDRESSES_PROVIDER());
    IPoolConfigurator poolConfigurator = IPoolConfigurator(addressesProvider.getPoolConfigurator());
    vm.startPrank(addressesProvider.getACLAdmin());
    if (collateralConfig.supplyCap != 0) {
      poolConfigurator.setSupplyCap(collateralConfig.underlying, 0);
    }
    if (testAssetConfig.supplyCap != 0) {
      poolConfigurator.setSupplyCap(testAssetConfig.underlying, 0);
    }
    if (testAssetConfig.borrowCap != 0) {
      poolConfigurator.setBorrowCap(testAssetConfig.underlying, 0);
    }
    vm.stopPrank();

    _deposit(collateralConfig, pool, collateralSupplier, collateralAssetAmount);
    _deposit(testAssetConfig, pool, testAssetSupplier, testAssetAmount);

    uint256 snapshotAfterDeposits = vm.snapshotState();

    // test deposits and withdrawals
    {
      uint256 aTokenTotalSupply = IERC20(testAssetConfig.aToken).totalSupply();
      uint256 variableDebtTokenTotalSupply = IERC20(testAssetConfig.variableDebtToken)
        .totalSupply();

      vm.prank(addressesProvider.getACLAdmin());
      poolConfigurator.setSupplyCap(
        testAssetConfig.underlying,
        aTokenTotalSupply / 10 ** testAssetConfig.decimals + 1
      );
      vm.prank(addressesProvider.getACLAdmin());
      poolConfigurator.setBorrowCap(
        testAssetConfig.underlying,
        variableDebtTokenTotalSupply / 10 ** testAssetConfig.decimals + 1
      );

      // caps should revert when supplying slightly more
      vm.expectRevert(Errors.SupplyCapExceeded.selector);
      vm.prank(testAssetSupplier);
      pool.deposit({
        asset: testAssetConfig.underlying,
        amount: 11 ** testAssetConfig.decimals,
        onBehalfOf: testAssetSupplier,
        referralCode: 0
      });
      if (testAssetConfig.borrowingEnabled) {
        uint256 borrowAmount = 11 ** testAssetConfig.decimals;

        if (aTokenTotalSupply < borrowAmount) {
          vm.prank(addressesProvider.getACLAdmin());
          poolConfigurator.setSupplyCap(testAssetConfig.underlying, 0);

          // aTokenTotalSupply == 10'000$
          // borrowAmount > 10'000$
          // need to add more test asset in order to be able to borrow it
          // right now there is not enough underlying tokens in the aToken
          _deposit(testAssetConfig, pool, testAssetSupplier, borrowAmount - aTokenTotalSupply);

          // need to add more collateral in order to be able to borrow
          // collateralAssetAmount == 100'000$
          _deposit(
            collateralConfig,
            pool,
            collateralSupplier,
            (collateralAssetAmount * borrowAmount) / aTokenTotalSupply
          );
        }

        vm.expectRevert(Errors.BorrowCapExceeded.selector);
        vm.prank(collateralSupplier);
        pool.borrow({
          asset: testAssetConfig.underlying,
          amount: borrowAmount,
          interestRateMode: 2,
          referralCode: 0,
          onBehalfOf: collateralSupplier
        });
      }

      vm.revertToState(snapshotAfterDeposits);

      _withdraw(testAssetConfig, pool, testAssetSupplier, testAssetAmount / 2);
      _withdraw(testAssetConfig, pool, testAssetSupplier, type(uint256).max);

      vm.revertToState(snapshotAfterDeposits);
    }

    // test borrows, repayments and liquidations
    if (testAssetConfig.borrowingEnabled) {
      // test borrowing and repayment
      _borrow({
        config: testAssetConfig,
        pool: pool,
        user: collateralSupplier,
        amount: testAssetAmount
      });

      uint256 snapshotBeforeRepay = vm.snapshotState();

      {
        // @note `actualBorrowAmount` can be bigger than `testAssetAmount` because of rounding
        uint256 actualBorrowAmount = IERC20(testAssetConfig.variableDebtToken).balanceOf(
          collateralSupplier
        );

        _repay({
          config: testAssetConfig,
          pool: pool,
          user: collateralSupplier,
          amount: actualBorrowAmount,
          withATokens: false
        });

        vm.revertToState(snapshotBeforeRepay);

        _repay({
          config: testAssetConfig,
          pool: pool,
          user: collateralSupplier,
          amount: actualBorrowAmount,
          withATokens: true
        });

        vm.revertToState(snapshotBeforeRepay);
      }

      if (testAssetConfig.underlying != collateralConfig.underlying) {
        _changeAssetPrice(pool, testAssetConfig, 1000_00); // price increases to 1'000%
      } else {
        _setAssetLtvAndLiquidationThreshold({
          pool: pool,
          config: testAssetConfig,
          newLtv: 5_00,
          newLiquidationThreshold: 5_00
        });
      }

      address liquidator = vm.addr(5);

      uint256 snapshotBeforeLiquidation = vm.snapshotState();

      // receive underlying tokens
      _liquidationCall({
        collateralConfig: collateralConfig,
        debtConfig: testAssetConfig,
        pool: pool,
        liquidator: liquidator,
        borrower: collateralSupplier,
        debtToCover: type(uint256).max,
        receiveAToken: false
      });

      vm.revertToState(snapshotBeforeLiquidation);

      // receive ATokens
      _liquidationCall({
        collateralConfig: collateralConfig,
        debtConfig: testAssetConfig,
        pool: pool,
        liquidator: liquidator,
        borrower: collateralSupplier,
        debtToCover: type(uint256).max,
        receiveAToken: true
      });

      vm.revertToState(snapshotAfterDeposits);
    }

    // test flashloans
    if (testAssetConfig.isFlashloanable) {
      _flashLoan({
        config: testAssetConfig,
        pool: pool,
        user: collateralSupplier,
        receiverAddress: address(this),
        amount: testAssetAmount,
        interestRateMode: 0
      });

      if (testAssetConfig.borrowingEnabled) {
        _flashLoan({
          config: testAssetConfig,
          pool: pool,
          user: collateralSupplier,
          receiverAddress: address(this),
          amount: testAssetAmount,
          interestRateMode: 2
        });
      }
    }
  }

  /**
   * Reserves that are frozen or not active should not be included in e2e test suite
   */
  function _includeInE2e(ReserveConfig memory config) internal pure returns (bool) {
    return !config.isFrozen && config.isActive && !config.isPaused && !config.symbol.equal('CELO');
  }

  function _getTokenAmountByDollarValue(
    IPool pool,
    ReserveConfig memory config,
    uint256 dollarValue
  ) internal view returns (uint256) {
    IPoolAddressesProvider addressesProvider = IPoolAddressesProvider(pool.ADDRESSES_PROVIDER());
    IAaveOracle oracle = IAaveOracle(addressesProvider.getPriceOracle());
    uint256 latestAnswer = oracle.getAssetPrice(config.underlying);
    return (dollarValue * 10 ** (8 + config.decimals)) / latestAnswer;
  }

  function _changeAssetPrice(
    IPool pool,
    ReserveConfig memory config,
    uint256 assetPriceChangePercentage
  ) internal {
    IPoolAddressesProvider addressesProvider = IPoolAddressesProvider(pool.ADDRESSES_PROVIDER());
    IAaveOracle priceOracle = IAaveOracle(addressesProvider.getPriceOracle());

    uint256 oldAssetPrice = priceOracle.getAssetPrice(config.underlying);
    uint256 newAssetPrice = (oldAssetPrice * assetPriceChangePercentage) / 100_00;

    MockAggregator assetPriceOracle = new MockAggregator(int256(newAssetPrice));

    address[] memory assets = new address[](1);
    assets[0] = config.underlying;
    address[] memory sources = new address[](1);
    sources[0] = address(assetPriceOracle);

    vm.prank(addressesProvider.getACLAdmin());
    priceOracle.setAssetSources(assets, sources);
  }

  function _setAssetLtvAndLiquidationThreshold(
    IPool pool,
    ReserveConfig memory config,
    uint256 newLtv,
    uint256 newLiquidationThreshold
  ) internal {
    IPoolAddressesProvider addressesProvider = IPoolAddressesProvider(pool.ADDRESSES_PROVIDER());
    IPoolConfigurator poolConfigurator = IPoolConfigurator(addressesProvider.getPoolConfigurator());

    vm.prank(addressesProvider.getACLAdmin());
    poolConfigurator.configureReserveAsCollateral(
      config.underlying,
      newLtv,
      newLiquidationThreshold,
      105_00
    );
  }

  /**
   * @dev returns a "good" collateral in the list
   */
  function _getGoodCollateral(
    ReserveConfig[] memory configs
  ) private pure returns (ReserveConfig memory config) {
    for (uint256 i = 0; i < configs.length; i++) {
      if (
        // not frozen etc
        // usable as collateral
        // not isolated asset as we can only borrow stablecoins against it
        // ltv is not 0
        _includeInE2e(configs[i]) &&
        configs[i].usageAsCollateralEnabled &&
        configs[i].debtCeiling == 0 &&
        configs[i].ltv != 0
      ) return configs[i];
    }
    revert('ERROR: No usable collateral found');
  }

  function _deposit(
    ReserveConfig memory config,
    IPool pool,
    address user,
    uint256 amount
  ) internal {
    require(!config.isFrozen, 'DEPOSIT(): FROZEN_RESERVE');
    require(config.isActive, 'DEPOSIT(): INACTIVE_RESERVE');
    require(!config.isPaused, 'DEPOSIT(): PAUSED_RESERVE');

    vm.startPrank(user);

    uint256 aTokenBefore = IERC20(config.aToken).balanceOf(user);

    deal2(config.underlying, user, amount);
    IERC20(config.underlying).forceApprove(address(pool), amount);

    console.log('SUPPLY: %s, Amount: %s', config.symbol, amount);

    pool.deposit(config.underlying, amount, user, 0);

    uint256 aTokenAfter = IERC20(config.aToken).balanceOf(user);

    // @note supply/borrow and other operations with a/v tokens
    // can generate +-2 wei roundings
    assertApproxEqAbs(aTokenAfter, aTokenBefore + amount, 2);

    vm.stopPrank();
  }

  function _withdraw(
    ReserveConfig memory config,
    IPool pool,
    address user,
    uint256 amount
  ) internal returns (uint256) {
    vm.startPrank(user);
    uint256 aTokenBefore = IERC20(config.aToken).balanceOf(user);
    if (
      block.chainid == ChainIds.CELO &&
      config.underlying == 0x471EcE3750Da237f93B8E339c536989b8978a438
    ) {
      vm.deal(config.aToken, aTokenBefore);
    }

    uint256 amountOut = pool.withdraw(config.underlying, amount, user);
    console.log('WITHDRAW: %s, Amount: %s', config.symbol, amountOut);
    uint256 aTokenAfter = IERC20(config.aToken).balanceOf(user);
    if (aTokenBefore < amount) {
      require(aTokenAfter == 0, '_withdraw(): DUST_AFTER_WITHDRAW_ALL');
    } else {
      // @note supply/borrow and other operations with a/v tokens
      // can generate +-2 wei roundings
      assertApproxEqAbs(aTokenAfter, aTokenBefore - amount, 2);
    }
    vm.stopPrank();
    return amountOut;
  }

  function _borrow(ReserveConfig memory config, IPool pool, address user, uint256 amount) internal {
    vm.startPrank(user);
    address debtToken = config.variableDebtToken;
    uint256 debtBefore = IERC20(debtToken).balanceOf(user);
    console.log('BORROW: %s, Amount %s', config.symbol, amount);
    pool.borrow(config.underlying, amount, 2, 0, user);
    uint256 debtAfter = IERC20(debtToken).balanceOf(user);
    // @note supply/borrow and other operations with a/v tokens
    // can generate +-2 wei roundings
    assertApproxEqAbs(debtAfter, debtBefore + amount, 2);
    vm.stopPrank();
  }

  function _repay(
    ReserveConfig memory config,
    IPool pool,
    address user,
    uint256 amount,
    bool withATokens
  ) internal {
    vm.startPrank(user);

    uint256 debtBefore = IERC20(config.variableDebtToken).balanceOf(user);

    deal2(config.underlying, user, amount + 2);
    IERC20(config.underlying).forceApprove(address(pool), amount + 2);

    console.log('REPAY: %s, Amount: %s', config.symbol, amount);

    if (withATokens) {
      // @note `+ 2` is required because the user's balance can be lower
      // than `amount` because of rounding .
      pool.supply({
        asset: config.underlying,
        amount: amount + 2,
        onBehalfOf: user,
        referralCode: 0
      });

      pool.repayWithATokens({asset: config.underlying, amount: amount, interestRateMode: 2});
    } else {
      pool.repay({asset: config.underlying, amount: amount, interestRateMode: 2, onBehalfOf: user});
    }

    uint256 debtAfter = IERC20(config.variableDebtToken).balanceOf(user);

    if (amount >= debtBefore) {
      assertEq(debtAfter, 0, '_repay() : ERROR MUST_BE_ZERO');
    } else {
      assertApproxEqAbs(debtAfter, debtBefore - amount, 1, '_repay() : ERROR MAX_ONE_OFF');
    }

    vm.stopPrank();
  }

  function _liquidationCall(
    ReserveConfig memory collateralConfig,
    ReserveConfig memory debtConfig,
    IPool pool,
    address liquidator,
    address borrower,
    uint256 debtToCover,
    bool receiveAToken
  ) internal {
    vm.startPrank(liquidator);

    uint256 debtBefore = IERC20(debtConfig.variableDebtToken).balanceOf(borrower);
    assertGt(debtBefore, 0);

    deal2(debtConfig.underlying, liquidator, debtToCover > debtBefore ? debtBefore : debtToCover);
    IERC20(debtConfig.underlying).forceApprove(address(pool), debtToCover);

    console.log(
      'LIQUIDATE: %s, Amount: %s, Debt Amount: %s',
      debtConfig.symbol,
      debtToCover,
      debtBefore
    );

    pool.liquidationCall({
      collateralAsset: collateralConfig.underlying,
      debtAsset: debtConfig.underlying,
      borrower: borrower,
      debtToCover: debtToCover,
      receiveAToken: receiveAToken
    });

    uint256 debtAfter = IERC20(debtConfig.variableDebtToken).balanceOf(borrower);

    assertLt(debtAfter, debtBefore);

    vm.stopPrank();
  }

  struct FlashLoanVars {
    uint256 underlyingTokenBalanceOfATokenBefore;
    uint256 debtTokenBalanceOfUserBefore;
    uint256 flashLoanPremiumTotal;
    uint256 underlyingTokenBalanceOfATokenAfter;
    uint256 debtTokenBalanceOfUserAfter;
    uint256[] interestRateModes;
    uint256[] amounts;
    address[] assets;
  }

  function _flashLoan(
    ReserveConfig memory config,
    IPool pool,
    address user,
    address receiverAddress,
    uint256 amount,
    uint256 interestRateMode
  ) internal virtual {
    FlashLoanVars memory vars;

    vm.startPrank(user);

    DataTypes.ReserveDataLegacy memory reserveDataBefore = pool.getReserveData(config.underlying);

    vars.underlyingTokenBalanceOfATokenBefore = IERC20(config.underlying).balanceOf(config.aToken);
    vars.debtTokenBalanceOfUserBefore = IERC20(config.variableDebtToken).balanceOf(user);

    if (interestRateMode == 0) {
      vars.flashLoanPremiumTotal = pool.FLASHLOAN_PREMIUM_TOTAL();

      vars.flashLoanPremiumTotal = amount.percentMulCeil(vars.flashLoanPremiumTotal);

      deal2(config.underlying, receiverAddress, vars.flashLoanPremiumTotal);
    }

    console.log('FLASH LOAN: %s, Amount: %s', config.symbol, amount);

    vars.assets = new address[](1);
    vars.assets[0] = config.underlying;

    vars.amounts = new uint256[](1);
    vars.amounts[0] = amount;

    vars.interestRateModes = new uint256[](1);
    vars.interestRateModes[0] = interestRateMode;

    pool.flashLoan({
      receiverAddress: receiverAddress,
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
      assertApproxEqAbs(
        vars.underlyingTokenBalanceOfATokenBefore + vars.flashLoanPremiumTotal,
        vars.underlyingTokenBalanceOfATokenAfter,
        2,
        '11'
      );
      assertApproxEqAbs(
        reserveDataBefore.accruedToTreasury +
          vars.flashLoanPremiumTotal.rayDivFloor(reserveDataAfter.liquidityIndex),
        reserveDataAfter.accruedToTreasury,
        2,
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
      // @note supply/borrow and other operations with a/v tokens
      // can generate +-2 wei roundings
      assertApproxEqAbs(
        vars.debtTokenBalanceOfUserAfter,
        vars.debtTokenBalanceOfUserBefore + amount,
        2,
        '6'
      );
    }

    vm.stopPrank();
  }
}
