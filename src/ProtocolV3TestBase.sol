// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5 <0.9.0;

import 'forge-std/Test.sol';
import {IAaveOracle, IPool, IPoolAddressesProvider, IPoolDataProvider, IReserveInterestRateStrategy, DataTypes, IPoolConfigurator} from 'aave-address-book/AaveV3.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {IERC20Metadata} from 'solidity-utils/contracts/oz-common/interfaces/IERC20Metadata.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {ReserveConfiguration} from 'aave-v3-origin/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {IDefaultInterestRateStrategyV2} from 'aave-v3-origin/contracts/interfaces/IDefaultInterestRateStrategyV2.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {DiffUtils} from 'aave-v3-origin-tests/utils/DiffUtils.sol';
import {ProtocolV3TestBase as RawProtocolV3TestBase, ReserveConfig} from 'aave-v3-origin-tests/utils/ProtocolV3TestBase.sol';
import {IInitializableAdminUpgradeabilityProxy} from './interfaces/IInitializableAdminUpgradeabilityProxy.sol';
import {ExtendedAggregatorV2V3Interface} from './interfaces/ExtendedAggregatorV2V3Interface.sol';
import {CommonTestBase, ReserveTokens} from './CommonTestBase.sol';
import {ILegacyDefaultInterestRateStrategy} from './dependencies/ILegacyDefaultInterestRateStrategy.sol';

struct LocalVars {
  IPoolDataProvider.TokenData[] reserves;
  ReserveConfig[] configs;
}

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
contract ProtocolV3TestBase is RawProtocolV3TestBase, CommonTestBase {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using SafeERC20 for IERC20;

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
    return defaultTest(reportName, pool, payload, true);
  }

  function defaultTest(
    string memory reportName,
    IPool pool,
    address payload,
    bool runE2E
  ) public returns (ReserveConfig[] memory, ReserveConfig[] memory) {
    string memory beforeString = string(abi.encodePacked(reportName, '_before'));
    ReserveConfig[] memory configBefore = createConfigurationSnapshot(beforeString, pool);

    uint256 startGas = gasleft();

    executePayload(vm, payload);

    uint256 gasUsed = startGas - gasleft();
    assertLt(gasUsed, (block.gaslimit * 95) / 100, 'BLOCK_GAS_LIMIT_EXCEEDED'); // 5% is kept as a buffer

    string memory afterString = string(abi.encodePacked(reportName, '_after'));
    ReserveConfig[] memory configAfter = createConfigurationSnapshot(afterString, pool);

    diffReports(beforeString, afterString);

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
    uint256 snapshot = vm.snapshot();
    for (uint256 i; i < configs.length; i++) {
      if (_includeInE2e(configs[i])) {
        e2eTestAsset(pool, collateralConfig, configs[i]);
        vm.revertTo(snapshot);
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
    uint256 collateralAssetAmount = _getTokenAmountByDollarValue(pool, collateralConfig, 100000);
    uint256 testAssetAmount = _getTokenAmountByDollarValue(pool, testAssetConfig, 1000);

    // remove caps as they should not prevent testing
    IPoolAddressesProvider addressesProvider = IPoolAddressesProvider(pool.ADDRESSES_PROVIDER());
    IPoolConfigurator poolConfigurator = IPoolConfigurator(addressesProvider.getPoolConfigurator());
    vm.startPrank(addressesProvider.getACLAdmin());
    if (collateralConfig.supplyCap != 0)
      poolConfigurator.setSupplyCap(collateralConfig.underlying, 0);
    if (testAssetConfig.supplyCap != 0)
      poolConfigurator.setSupplyCap(testAssetConfig.underlying, 0);
    if (testAssetConfig.borrowCap != 0)
      poolConfigurator.setBorrowCap(testAssetConfig.underlying, 0);
    vm.stopPrank();

    // GHO is a special case as it cannot be supplied
    if (testAssetConfig.underlying == AaveV3EthereumAssets.GHO_UNDERLYING) {
      _deposit(collateralConfig, pool, collateralSupplier, collateralAssetAmount);
      uint256 snapshot = vm.snapshot();
      // test variable borrowing
      if (testAssetConfig.borrowingEnabled) {
        _e2eTestBorrowRepay(pool, collateralSupplier, testAssetConfig, testAssetAmount);
        vm.revertTo(snapshot);
      }
    } else {
      _deposit(collateralConfig, pool, collateralSupplier, collateralAssetAmount);
      _deposit(testAssetConfig, pool, testAssetSupplier, testAssetAmount);
      uint256 snapshot = vm.snapshot();
      // test withdrawal
      _withdraw(testAssetConfig, pool, testAssetSupplier, testAssetAmount / 2);
      _withdraw(testAssetConfig, pool, testAssetSupplier, type(uint256).max);
      vm.revertTo(snapshot);
      // test variable borrowing
      if (testAssetConfig.borrowingEnabled) {
        if (
          (testAssetConfig.borrowCap * 10 ** testAssetConfig.decimals) <
          IERC20(testAssetConfig.variableDebtToken).totalSupply() + testAssetAmount
        ) {
          console.log('Skip Borrowing: %s, borrow cap fully utilized', testAssetConfig.symbol);
          return;
        }
        _e2eTestBorrowRepay(pool, collateralSupplier, testAssetConfig, testAssetAmount);
        vm.revertTo(snapshot);
      }
    }
  }

  /**
   * Reserves that are frozen or not active should not be included in e2e test suite
   */
  function _includeInE2e(ReserveConfig memory config) internal pure returns (bool) {
    return !config.isFrozen && config.isActive && !config.isPaused;
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

  function _e2eTestBorrowRepay(
    IPool pool,
    address borrower,
    ReserveConfig memory testAssetConfig,
    uint256 amount
  ) internal {
    this._borrow(testAssetConfig, pool, borrower, amount);
    _repay(testAssetConfig, pool, borrower, amount);
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
        _includeInE2e(configs[i]) &&
        // usable as collateral
        configs[i].usageAsCollateralEnabled &&
        // not isolated asset as we can only borrow stablecoins against it
        configs[i].debtCeiling == 0
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
    assertApproxEqAbs(aTokenAfter, aTokenBefore + amount, 1);
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
    uint256 amountOut = pool.withdraw(config.underlying, amount, user);
    console.log('WITHDRAW: %s, Amount: %s', config.symbol, amountOut);
    uint256 aTokenAfter = IERC20(config.aToken).balanceOf(user);
    if (aTokenBefore < amount) {
      require(aTokenAfter == 0, '_withdraw(): DUST_AFTER_WITHDRAW_ALL');
    } else {
      assertApproxEqAbs(aTokenAfter, aTokenBefore - amount, 1);
    }
    vm.stopPrank();
    return amountOut;
  }

  function _borrow(ReserveConfig memory config, IPool pool, address user, uint256 amount) external {
    vm.startPrank(user);
    address debtToken = config.variableDebtToken;
    uint256 debtBefore = IERC20(debtToken).balanceOf(user);
    console.log('BORROW: %s, Amount %s', config.symbol, amount);
    pool.borrow(config.underlying, amount, 2, 0, user);
    uint256 debtAfter = IERC20(debtToken).balanceOf(user);
    assertApproxEqAbs(debtAfter, debtBefore + amount, 1);
    vm.stopPrank();
  }

  function _repay(ReserveConfig memory config, IPool pool, address user, uint256 amount) internal {
    vm.startPrank(user);
    address debtToken = config.variableDebtToken;
    uint256 debtBefore = IERC20(debtToken).balanceOf(user);
    deal2(config.underlying, user, amount);
    IERC20(config.underlying).forceApprove(address(pool), amount);
    console.log('REPAY: %s, Amount: %s', config.symbol, amount);
    pool.repay(config.underlying, amount, 2, user);
    uint256 debtAfter = IERC20(debtToken).balanceOf(user);
    if (amount >= debtBefore) {
      assertEq(debtAfter, 0, '_repay() : ERROR MUST_BE_ZERO');
    } else {
      assertApproxEqAbs(debtAfter, debtBefore - amount, 1, '_repay() : ERROR MAX_ONE_OFF');
    }
    vm.stopPrank();
  }

  function getIsVirtualAccActive(
    DataTypes.ReserveConfigurationMap memory configuration
  ) external pure returns (bool) {
    return configuration.getIsVirtualAccActive();
  }

  function _writeEModeConfigs(string memory path, IPool pool) internal virtual override {
    // keys for json stringification
    string memory eModesKey = 'emodes';
    string memory content = '{}';
    vm.serializeJson(eModesKey, '{}');
    uint8 emptyCounter = 0;
    for (uint8 i = 0; i < 256; i++) {
      try pool.getEModeCategoryCollateralConfig(i) returns (DataTypes.CollateralConfig memory cfg) {
        if (cfg.liquidationThreshold == 0) {
          if (++emptyCounter > 2) break;
        } else {
          string memory key = vm.toString(i);
          vm.serializeJson(key, '{}');
          vm.serializeUint(key, 'eModeCategory', i);
          vm.serializeString(key, 'label', pool.getEModeCategoryLabel(i));
          vm.serializeUint(key, 'ltv', cfg.ltv);
          vm.serializeString(
            key,
            'collateralBitmap',
            vm.toString(pool.getEModeCategoryCollateralBitmap(i))
          );
          vm.serializeString(
            key,
            'borrowableBitmap',
            vm.toString(pool.getEModeCategoryBorrowableBitmap(i))
          );
          vm.serializeUint(key, 'liquidationThreshold', cfg.liquidationThreshold);
          string memory object = vm.serializeUint(key, 'liquidationBonus', cfg.liquidationBonus);
          content = vm.serializeString(eModesKey, key, object);
          emptyCounter = 0;
        }
      } catch {
        DataTypes.EModeCategoryLegacy memory category = pool.getEModeCategoryData(i);
        if (category.liquidationThreshold == 0) {
          if (++emptyCounter > 2) break;
        } else {
          string memory key = vm.toString(i);
          vm.serializeJson(key, '{}');
          vm.serializeUint(key, 'eModeCategory', i);
          vm.serializeString(key, 'label', category.label);
          vm.serializeUint(key, 'ltv', category.ltv);
          vm.serializeUint(key, 'liquidationThreshold', category.liquidationThreshold);
          vm.serializeUint(key, 'liquidationBonus', category.liquidationBonus);
          string memory object = vm.serializeAddress(key, 'priceSource', category.priceSource);
          content = vm.serializeString(eModesKey, key, object);
          emptyCounter = 0;
        }
      }
    }
    string memory output = vm.serializeString('root', 'eModes', content);
    vm.writeJson(output, path);
  }

  function _writeStrategyConfigs(
    string memory path,
    ReserveConfig[] memory configs
  ) internal virtual override {
    // keys for json stringification
    string memory strategiesKey = 'stategies';
    string memory content = '{}';
    vm.serializeJson(strategiesKey, '{}');

    for (uint256 i = 0; i < configs.length; i++) {
      IDefaultInterestRateStrategyV2 strategyV2 = IDefaultInterestRateStrategyV2(
        configs[i].interestRateStrategy
      );
      ILegacyDefaultInterestRateStrategy strategyV1 = ILegacyDefaultInterestRateStrategy(
        configs[i].interestRateStrategy
      );
      address asset = configs[i].underlying;
      string memory key = vm.toString(asset);
      vm.serializeJson(key, '{}');
      vm.serializeString(key, 'address', vm.toString(configs[i].interestRateStrategy));
      string memory object;
      try strategyV1.getVariableRateSlope1() {
        vm.serializeString(
          key,
          'baseStableBorrowRate',
          vm.toString(strategyV1.getBaseStableBorrowRate())
        );
        vm.serializeString(key, 'stableRateSlope1', vm.toString(strategyV1.getStableRateSlope1()));
        vm.serializeString(key, 'stableRateSlope2', vm.toString(strategyV1.getStableRateSlope2()));
        vm.serializeString(
          key,
          'baseVariableBorrowRate',
          vm.toString(strategyV1.getBaseVariableBorrowRate())
        );
        vm.serializeString(
          key,
          'variableRateSlope1',
          vm.toString(strategyV1.getVariableRateSlope1())
        );
        vm.serializeString(
          key,
          'variableRateSlope2',
          vm.toString(strategyV1.getVariableRateSlope2())
        );
        vm.serializeString(
          key,
          'optimalStableToTotalDebtRatio',
          vm.toString(strategyV1.OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO())
        );
        vm.serializeString(
          key,
          'maxExcessStableToTotalDebtRatio',
          vm.toString(strategyV1.MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO())
        );
        vm.serializeString(key, 'optimalUsageRatio', vm.toString(strategyV1.OPTIMAL_USAGE_RATIO()));
        object = vm.serializeString(
          key,
          'maxExcessUsageRatio',
          vm.toString(strategyV1.MAX_EXCESS_USAGE_RATIO())
        );
      } catch {
        vm.serializeString(
          key,
          'baseVariableBorrowRate',
          vm.toString(strategyV2.getBaseVariableBorrowRate(asset))
        );
        vm.serializeString(
          key,
          'variableRateSlope1',
          vm.toString(strategyV2.getVariableRateSlope1(asset))
        );
        vm.serializeString(
          key,
          'variableRateSlope2',
          vm.toString(strategyV2.getVariableRateSlope2(asset))
        );
        vm.serializeString(
          key,
          'maxVariableBorrowRate',
          vm.toString(strategyV2.getMaxVariableBorrowRate(asset))
        );
        object = vm.serializeString(
          key,
          'optimalUsageRatio',
          vm.toString(strategyV2.getOptimalUsageRatio(asset))
        );
      }
      content = vm.serializeString(strategiesKey, key, object);
    }
    string memory output = vm.serializeString('root', 'strategies', content);
    vm.writeJson(output, path);
  }

  // TODO: deprecated, remove it later
  function _validateInterestRateStrategy(
    address interestRateStrategyAddress,
    address expectedStrategy,
    InterestStrategyValues memory expectedStrategyValues
  ) internal view {
    ILegacyDefaultInterestRateStrategy strategy = ILegacyDefaultInterestRateStrategy(
      interestRateStrategyAddress
    );

    require(
      address(strategy) == expectedStrategy,
      '_validateInterestRateStrategy() : INVALID_STRATEGY_ADDRESS'
    );

    require(
      strategy.OPTIMAL_USAGE_RATIO() == expectedStrategyValues.optimalUsageRatio,
      '_validateInterestRateStrategy() : INVALID_OPTIMAL_RATIO'
    );
    require(
      strategy.OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO() ==
        expectedStrategyValues.optimalStableToTotalDebtRatio,
      '_validateInterestRateStrategy() : INVALID_OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO'
    );
    require(
      address(strategy.ADDRESSES_PROVIDER()) == expectedStrategyValues.addressesProvider,
      '_validateInterestRateStrategy() : INVALID_ADDRESSES_PROVIDER'
    );
    require(
      strategy.getBaseVariableBorrowRate() == expectedStrategyValues.baseVariableBorrowRate,
      '_validateInterestRateStrategy() : INVALID_BASE_VARIABLE_BORROW'
    );
    require(
      strategy.getBaseStableBorrowRate() == expectedStrategyValues.baseStableBorrowRate,
      '_validateInterestRateStrategy() : INVALID_BASE_STABLE_BORROW'
    );
    require(
      strategy.getStableRateSlope1() == expectedStrategyValues.stableRateSlope1,
      '_validateInterestRateStrategy() : INVALID_STABLE_SLOPE_1'
    );
    require(
      strategy.getStableRateSlope2() == expectedStrategyValues.stableRateSlope2,
      '_validateInterestRateStrategy() : INVALID_STABLE_SLOPE_2'
    );
    require(
      strategy.getVariableRateSlope1() == expectedStrategyValues.variableRateSlope1,
      '_validateInterestRateStrategy() : INVALID_VARIABLE_SLOPE_1'
    );
    require(
      strategy.getVariableRateSlope2() == expectedStrategyValues.variableRateSlope2,
      '_validateInterestRateStrategy() : INVALID_VARIABLE_SLOPE_2'
    );
  }
}
