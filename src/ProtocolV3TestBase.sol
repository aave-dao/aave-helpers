// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5 <0.9.0;

import 'forge-std/Test.sol';
import {IAaveOracle, IPool, IPoolAddressesProvider, IPoolDataProvider, IDefaultInterestRateStrategy, DataTypes, IPoolConfigurator} from 'aave-address-book/AaveV3.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {IInitializableAdminUpgradeabilityProxy} from './interfaces/IInitializableAdminUpgradeabilityProxy.sol';
import {ExtendedAggregatorV2V3Interface} from './interfaces/ExtendedAggregatorV2V3Interface.sol';
import {ProxyHelpers} from './ProxyHelpers.sol';
import {CommonTestBase, ReserveTokens} from './CommonTestBase.sol';
import {ReserveConfiguration} from 'aave-v3-core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';

interface IERC20Detailed is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

struct ReserveConfig {
  string symbol;
  address underlying;
  address aToken;
  address stableDebtToken;
  address variableDebtToken;
  uint256 decimals;
  uint256 ltv;
  uint256 liquidationThreshold;
  uint256 liquidationBonus;
  uint256 liquidationProtocolFee;
  uint256 reserveFactor;
  bool usageAsCollateralEnabled;
  bool borrowingEnabled;
  address interestRateStrategy;
  bool stableBorrowRateEnabled;
  bool isPaused;
  bool isActive;
  bool isFrozen;
  bool isSiloed;
  bool isBorrowableInIsolation;
  bool isFlashloanable;
  uint256 supplyCap;
  uint256 borrowCap;
  uint256 debtCeiling;
  uint256 eModeCategory;
}

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
contract ProtocolV3TestBase is CommonTestBase {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using SafeERC20 for IERC20;

  /**
   * @dev Generates a markdown compatible snapshot of the whole pool configuration into `/reports`.
   * @param reportName filename suffix for the generated reports.
   * @param pool the pool to be snapshotted
   * @return ReserveConfig[] list of configs
   */
  function createConfigurationSnapshot(
    string memory reportName,
    IPool pool
  ) public returns (ReserveConfig[] memory) {
    return createConfigurationSnapshot(reportName, pool, true, true, true, true);
  }

  function createConfigurationSnapshot(
    string memory reportName,
    IPool pool,
    bool reserveConfigs,
    bool strategyConfigs,
    bool eModeConigs,
    bool poolConfigs
  ) public returns (ReserveConfig[] memory) {
    string memory path = string(abi.encodePacked('./reports/', reportName, '.json'));
    // overwrite with empty json to later be extended
    vm.writeFile(
      path,
      '{ "eModes": {}, "reserves": {}, "strategies": {}, "poolConfiguration": {} }'
    );
    vm.serializeUint('root', 'chainId', block.chainid);
    ReserveConfig[] memory configs = _getReservesConfigs(pool);
    if (reserveConfigs) _writeReserveConfigs(path, configs, pool);
    if (strategyConfigs) _writeStrategyConfigs(path, configs);
    if (eModeConigs) _writeEModeConfigs(path, configs, pool);
    if (poolConfigs) _writePoolConfiguration(path, pool);

    return configs;
  }

  /**
   * @dev Makes a e2e test including withdrawals/borrows and supplies to various reserves.
   * @param pool the pool that should be tested
   */
  function e2eTest(IPool pool) public {
    ReserveConfig[] memory configs = _getReservesConfigs(pool);
    ReserveConfig memory collateralConfig = _getGoodCollateral(pool, configs, 1000);
    uint256 snapshot = vm.snapshot();
    for (uint256 i; i < configs.length; i++) {
      if (_includeInE2e(configs[i])) {
        e2eTestAsset(pool, collateralConfig, configs[i]);
        vm.revertTo(snapshot);
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
    uint256 testAssetAmount = _getTokenAmountByDollarValue(pool, testAssetConfig, 100);
    if (
      (testAssetConfig.supplyCap * 10 ** testAssetConfig.decimals) <
      IERC20(testAssetConfig.aToken).totalSupply() + testAssetAmount
    ) {
      console.log('Skip: %s, supply cap fully utilized', testAssetConfig.symbol);
      return;
    }
    _deposit(
      collateralConfig,
      pool,
      collateralSupplier,
      _getTokenAmountByDollarValue(pool, collateralConfig, 10000)
    );
    _deposit(testAssetConfig, pool, testAssetSupplier, testAssetAmount);
    uint256 snapshot = vm.snapshot();
    // test withdrawal
    _withdraw(testAssetConfig, pool, testAssetSupplier, testAssetAmount / 2);
    _withdraw(testAssetConfig, pool, testAssetSupplier, type(uint256).max);
    vm.revertTo(snapshot);
    // test variable borrowing
    if (testAssetConfig.borrowingEnabled) {
      _e2eTestBorrowRepay(pool, collateralSupplier, testAssetConfig, testAssetAmount, false);
      vm.revertTo(snapshot);
      // test stable borrowing
      if (testAssetConfig.stableBorrowRateEnabled) {
        _e2eTestBorrowRepay(pool, collateralSupplier, testAssetConfig, testAssetAmount, true);
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
    uint256 amount,
    bool stable
  ) internal {
    this._borrow(testAssetConfig, pool, borrower, amount, stable);
    _repay(testAssetConfig, pool, borrower, amount, stable);
  }

  /**
   * @dev returns a "good" collateral in the list that cannot be borrowed in stable mode
   */
  function _getGoodCollateral(
    IPool pool,
    ReserveConfig[] memory configs,
    uint256 minSupplyCapDollarMargin
  ) private view returns (ReserveConfig memory config) {
    for (uint256 i = 0; i < configs.length; i++) {
      if (
        // not frozen etc
        _includeInE2e(configs[i]) &&
        // usable as collateral
        configs[i].usageAsCollateralEnabled &&
        // not stable borrowable as this makes testing stable borrowing unnecessary hard to reason about
        !configs[i].stableBorrowRateEnabled &&
        // supply cap not yet reached
        ((configs[i].supplyCap * 10 ** configs[i].decimals) >
          IERC20(configs[i].aToken).totalSupply()) &&
        (// supply cap margin big enough
        (configs[i].supplyCap * 10 ** configs[i].decimals) -
          IERC20(configs[i].aToken).totalSupply() >
          _getTokenAmountByDollarValue(pool, configs[i], minSupplyCapDollarMargin))
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
    IERC20(config.underlying).safeApprove(address(pool), amount);
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

  function _borrow(
    ReserveConfig memory config,
    IPool pool,
    address user,
    uint256 amount,
    bool stable
  ) external {
    vm.startPrank(user);
    address debtToken = stable ? config.stableDebtToken : config.variableDebtToken;
    uint256 debtBefore = IERC20(debtToken).balanceOf(user);
    console.log('BORROW: %s, Amount %s, Stable: %s', config.symbol, amount, stable);
    pool.borrow(config.underlying, amount, stable ? 1 : 2, 0, user);
    uint256 debtAfter = IERC20(debtToken).balanceOf(user);
    assertApproxEqAbs(debtAfter, debtBefore + amount, 1);
    vm.stopPrank();
  }

  function _repay(
    ReserveConfig memory config,
    IPool pool,
    address user,
    uint256 amount,
    bool stable
  ) internal {
    vm.startPrank(user);
    address debtToken = stable ? config.stableDebtToken : config.variableDebtToken;
    uint256 debtBefore = IERC20(debtToken).balanceOf(user);
    deal2(config.underlying, user, amount);
    IERC20(config.underlying).safeApprove(address(pool), amount);
    console.log('REPAY: %s, Amount: %s', config.symbol, amount);
    pool.repay(config.underlying, amount, stable ? 1 : 2, user);
    uint256 debtAfter = IERC20(debtToken).balanceOf(user);
    require(debtAfter == ((debtBefore > amount) ? debtBefore - amount : 0), '_repay() : ERROR');
    vm.stopPrank();
  }

  function _writeEModeConfigs(
    string memory path,
    ReserveConfig[] memory configs,
    IPool pool
  ) internal {
    // keys for json stringification
    string memory eModesKey = 'emodes';
    string memory content = '{}';

    uint256[] memory usedCategories = new uint256[](configs.length);
    for (uint256 i = 0; i < configs.length; i++) {
      if (!_isInUint256Array(usedCategories, configs[i].eModeCategory)) {
        usedCategories[i] = configs[i].eModeCategory;
        DataTypes.EModeCategory memory category = pool.getEModeCategoryData(
          uint8(configs[i].eModeCategory)
        );
        string memory key = vm.toString(configs[i].eModeCategory);
        vm.serializeUint(key, 'eModeCategory', configs[i].eModeCategory);
        vm.serializeString(key, 'label', category.label);
        vm.serializeUint(key, 'ltv', category.ltv);
        vm.serializeUint(key, 'liquidationThreshold', category.liquidationThreshold);
        vm.serializeUint(key, 'liquidationBonus', category.liquidationBonus);
        string memory object = vm.serializeAddress(key, 'priceSource', category.priceSource);
        content = vm.serializeString(eModesKey, key, object);
      }
    }
    string memory output = vm.serializeString('root', 'eModes', content);
    vm.writeJson(output, path);
  }

  function _writeStrategyConfigs(string memory path, ReserveConfig[] memory configs) internal {
    // keys for json stringification
    string memory strategiesKey = 'stategies';
    string memory content = '{}';

    address[] memory usedStrategies = new address[](configs.length);
    for (uint256 i = 0; i < configs.length; i++) {
      if (!_isInAddressArray(usedStrategies, configs[i].interestRateStrategy)) {
        usedStrategies[i] = configs[i].interestRateStrategy;
        IDefaultInterestRateStrategy strategy = IDefaultInterestRateStrategy(
          configs[i].interestRateStrategy
        );
        string memory key = vm.toString(address(strategy));
        vm.serializeString(
          key,
          'baseStableBorrowRate',
          vm.toString(strategy.getBaseStableBorrowRate())
        );
        vm.serializeString(key, 'stableRateSlope1', vm.toString(strategy.getStableRateSlope1()));
        vm.serializeString(key, 'stableRateSlope2', vm.toString(strategy.getStableRateSlope2()));
        vm.serializeString(
          key,
          'baseVariableBorrowRate',
          vm.toString(strategy.getBaseVariableBorrowRate())
        );
        vm.serializeString(
          key,
          'variableRateSlope1',
          vm.toString(strategy.getVariableRateSlope1())
        );
        vm.serializeString(
          key,
          'variableRateSlope2',
          vm.toString(strategy.getVariableRateSlope2())
        );
        vm.serializeString(
          key,
          'optimalStableToTotalDebtRatio',
          vm.toString(strategy.OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO())
        );
        vm.serializeString(
          key,
          'maxExcessStableToTotalDebtRatio',
          vm.toString(strategy.MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO())
        );
        vm.serializeString(key, 'optimalUsageRatio', vm.toString(strategy.OPTIMAL_USAGE_RATIO()));
        string memory object = vm.serializeString(
          key,
          'maxExcessUsageRatio',
          vm.toString(strategy.MAX_EXCESS_USAGE_RATIO())
        );
        content = vm.serializeString(strategiesKey, key, object);
      }
    }
    string memory output = vm.serializeString('root', 'strategies', content);
    vm.writeJson(output, path);
  }

  function _writeReserveConfigs(
    string memory path,
    ReserveConfig[] memory configs,
    IPool pool
  ) internal {
    // keys for json stringification
    string memory reservesKey = 'reserves';
    string memory content = '{}';

    IPoolAddressesProvider addressesProvider = IPoolAddressesProvider(pool.ADDRESSES_PROVIDER());
    IAaveOracle oracle = IAaveOracle(addressesProvider.getPriceOracle());
    for (uint256 i = 0; i < configs.length; i++) {
      ReserveConfig memory config = configs[i];
      ExtendedAggregatorV2V3Interface assetOracle = ExtendedAggregatorV2V3Interface(
        oracle.getSourceOfAsset(config.underlying)
      );

      string memory key = vm.toString(config.underlying);
      vm.serializeString(key, 'symbol', config.symbol);
      vm.serializeUint(key, 'ltv', config.ltv);
      vm.serializeUint(key, 'liquidationThreshold', config.liquidationThreshold);
      vm.serializeUint(key, 'liquidationBonus', config.liquidationBonus);
      vm.serializeUint(key, 'liquidationProtocolFee', config.liquidationProtocolFee);
      vm.serializeUint(key, 'reserveFactor', config.reserveFactor);
      vm.serializeUint(key, 'decimals', config.decimals);
      vm.serializeUint(key, 'borrowCap', config.borrowCap);
      vm.serializeUint(key, 'supplyCap', config.supplyCap);
      vm.serializeUint(key, 'debtCeiling', config.debtCeiling);
      vm.serializeUint(key, 'eModeCategory', config.eModeCategory);
      vm.serializeBool(key, 'usageAsCollateralEnabled', config.usageAsCollateralEnabled);
      vm.serializeBool(key, 'borrowingEnabled', config.borrowingEnabled);
      vm.serializeBool(key, 'stableBorrowRateEnabled', config.stableBorrowRateEnabled);
      vm.serializeBool(key, 'isPaused', config.isPaused);
      vm.serializeBool(key, 'isActive', config.isActive);
      vm.serializeBool(key, 'isFrozen', config.isFrozen);
      vm.serializeBool(key, 'isSiloed', config.isSiloed);
      vm.serializeBool(key, 'isBorrowableInIsolation', config.isBorrowableInIsolation);
      vm.serializeBool(key, 'isFlashloanable', config.isFlashloanable);
      vm.serializeAddress(key, 'interestRateStrategy', config.interestRateStrategy);
      vm.serializeAddress(key, 'underlying', config.underlying);
      vm.serializeAddress(key, 'aToken', config.aToken);
      vm.serializeAddress(key, 'stableDebtToken', config.stableDebtToken);
      vm.serializeAddress(key, 'variableDebtToken', config.variableDebtToken);
      vm.serializeAddress(
        key,
        'aTokenImpl',
        ProxyHelpers.getInitializableAdminUpgradeabilityProxyImplementation(vm, config.aToken)
      );
      vm.serializeString(key, 'aTokenSymbol', IERC20Detailed(config.aToken).symbol());
      vm.serializeString(key, 'aTokenName', IERC20Detailed(config.aToken).name());
      vm.serializeAddress(
        key,
        'stableDebtTokenImpl',
        ProxyHelpers.getInitializableAdminUpgradeabilityProxyImplementation(
          vm,
          config.stableDebtToken
        )
      );
      vm.serializeString(
        key,
        'stableDebtTokenSymbol',
        IERC20Detailed(config.stableDebtToken).symbol()
      );
      vm.serializeString(key, 'stableDebtTokenName', IERC20Detailed(config.stableDebtToken).name());
      vm.serializeAddress(
        key,
        'variableDebtTokenImpl',
        ProxyHelpers.getInitializableAdminUpgradeabilityProxyImplementation(
          vm,
          config.variableDebtToken
        )
      );
      vm.serializeString(
        key,
        'variableDebtTokenSymbol',
        IERC20Detailed(config.variableDebtToken).symbol()
      );
      vm.serializeString(
        key,
        'variableDebtTokenName',
        IERC20Detailed(config.variableDebtToken).name()
      );
      vm.serializeAddress(key, 'oracle', address(assetOracle));
      if (address(assetOracle) != address(0)) {
        try assetOracle.description() returns (string memory name) {
          vm.serializeString(key, 'oracleDescription', name);
        } catch {
          try assetOracle.name() returns (string memory name) {
            vm.serializeString(key, 'oracleName', name);
          } catch {}
        }
        try assetOracle.decimals() returns (uint8 decimals) {
          vm.serializeUint(key, 'oracleDecimals', decimals);
        } catch {
          try assetOracle.DECIMALS() returns (uint8 decimals) {
            vm.serializeUint(key, 'oracleDecimals', decimals);
          } catch {}
        }
      }
      string memory out = vm.serializeUint(
        key,
        'oracleLatestAnswer',
        uint256(oracle.getAssetPrice(config.underlying))
      );
      content = vm.serializeString(reservesKey, key, out);
    }
    string memory output = vm.serializeString('root', 'reserves', content);
    vm.writeJson(output, path);
  }

  function _writePoolConfiguration(string memory path, IPool pool) internal {
    // keys for json stringification
    string memory poolConfigKey = 'poolConfig';

    // addresses provider
    IPoolAddressesProvider addressesProvider = IPoolAddressesProvider(pool.ADDRESSES_PROVIDER());
    vm.serializeAddress(poolConfigKey, 'poolAddressesProvider', address(addressesProvider));

    // oracles
    vm.serializeAddress(poolConfigKey, 'oracle', addressesProvider.getPriceOracle());
    vm.serializeAddress(
      poolConfigKey,
      'priceOracleSentinel',
      addressesProvider.getPriceOracleSentinel()
    );

    // pool configurator
    IPoolConfigurator configurator = IPoolConfigurator(addressesProvider.getPoolConfigurator());
    vm.serializeAddress(poolConfigKey, 'poolConfigurator', address(configurator));
    vm.serializeAddress(
      poolConfigKey,
      'poolConfiguratorImpl',
      ProxyHelpers.getInitializableAdminUpgradeabilityProxyImplementation(vm, address(configurator))
    );

    // PoolDataProvider
    IPoolDataProvider pdp = IPoolDataProvider(addressesProvider.getPoolDataProvider());
    vm.serializeAddress(poolConfigKey, 'protocolDataProvider', address(pdp));

    // pool
    vm.serializeAddress(
      poolConfigKey,
      'poolImpl',
      ProxyHelpers.getInitializableAdminUpgradeabilityProxyImplementation(vm, address(pool))
    );
    string memory content = vm.serializeAddress(poolConfigKey, 'pool', address(pool));

    string memory output = vm.serializeString('root', 'poolConfig', content);
    vm.writeJson(output, path);
  }

  function _getReservesConfigs(IPool pool) internal view returns (ReserveConfig[] memory) {
    IPoolAddressesProvider addressesProvider = IPoolAddressesProvider(pool.ADDRESSES_PROVIDER());
    IPoolDataProvider poolDataProvider = IPoolDataProvider(addressesProvider.getPoolDataProvider());
    LocalVars memory vars;

    vars.reserves = poolDataProvider.getAllReservesTokens();

    vars.configs = new ReserveConfig[](vars.reserves.length);

    for (uint256 i = 0; i < vars.reserves.length; i++) {
      vars.configs[i] = _getStructReserveConfig(pool, vars.reserves[i]);
      ReserveTokens memory reserveTokens = _getStructReserveTokens(
        poolDataProvider,
        vars.configs[i].underlying
      );
      vars.configs[i].aToken = reserveTokens.aToken;
      vars.configs[i].variableDebtToken = reserveTokens.variableDebtToken;
      vars.configs[i].stableDebtToken = reserveTokens.stableDebtToken;
    }

    return vars.configs;
  }

  function _getStructReserveTokens(
    IPoolDataProvider pdp,
    address underlyingAddress
  ) internal view returns (ReserveTokens memory) {
    ReserveTokens memory reserveTokens;
    (reserveTokens.aToken, reserveTokens.stableDebtToken, reserveTokens.variableDebtToken) = pdp
      .getReserveTokensAddresses(underlyingAddress);

    return reserveTokens;
  }

  function _getStructReserveConfig(
    IPool pool,
    IPoolDataProvider.TokenData memory reserve
  ) internal view virtual returns (ReserveConfig memory) {
    ReserveConfig memory localConfig;
    DataTypes.ReserveConfigurationMap memory configuration = pool.getConfiguration(
      reserve.tokenAddress
    );
    localConfig.interestRateStrategy = pool
      .getReserveData(reserve.tokenAddress)
      .interestRateStrategyAddress;
    (
      localConfig.ltv,
      localConfig.liquidationThreshold,
      localConfig.liquidationBonus,
      localConfig.decimals,
      localConfig.reserveFactor,
      localConfig.eModeCategory
    ) = configuration.getParams();
    (
      localConfig.isActive,
      localConfig.isFrozen,
      localConfig.borrowingEnabled,
      localConfig.stableBorrowRateEnabled,
      localConfig.isPaused
    ) = configuration.getFlags();
    localConfig.symbol = reserve.symbol;
    localConfig.underlying = reserve.tokenAddress;
    localConfig.usageAsCollateralEnabled = localConfig.liquidationThreshold != 0;
    localConfig.isSiloed = configuration.getSiloedBorrowing();
    (localConfig.borrowCap, localConfig.supplyCap) = configuration.getCaps();
    localConfig.debtCeiling = configuration.getDebtCeiling();
    localConfig.liquidationProtocolFee = configuration.getLiquidationProtocolFee();
    localConfig.isBorrowableInIsolation = configuration.getBorrowableInIsolation();

    localConfig.isFlashloanable = configuration.getFlashLoanEnabled();

    return localConfig;
  }

  // TODO This should probably be simplified with assembly, too much boilerplate
  function _clone(ReserveConfig memory config) internal pure returns (ReserveConfig memory) {
    return
      ReserveConfig({
        symbol: config.symbol,
        underlying: config.underlying,
        aToken: config.aToken,
        stableDebtToken: config.stableDebtToken,
        variableDebtToken: config.variableDebtToken,
        decimals: config.decimals,
        ltv: config.ltv,
        liquidationThreshold: config.liquidationThreshold,
        liquidationBonus: config.liquidationBonus,
        liquidationProtocolFee: config.liquidationProtocolFee,
        reserveFactor: config.reserveFactor,
        usageAsCollateralEnabled: config.usageAsCollateralEnabled,
        borrowingEnabled: config.borrowingEnabled,
        interestRateStrategy: config.interestRateStrategy,
        stableBorrowRateEnabled: config.stableBorrowRateEnabled,
        isPaused: config.isPaused,
        isActive: config.isActive,
        isFrozen: config.isFrozen,
        isSiloed: config.isSiloed,
        isBorrowableInIsolation: config.isBorrowableInIsolation,
        isFlashloanable: config.isFlashloanable,
        supplyCap: config.supplyCap,
        borrowCap: config.borrowCap,
        debtCeiling: config.debtCeiling,
        eModeCategory: config.eModeCategory
      });
  }

  function _findReserveConfig(
    ReserveConfig[] memory configs,
    address underlying
  ) internal pure returns (ReserveConfig memory) {
    for (uint256 i = 0; i < configs.length; i++) {
      if (configs[i].underlying == underlying) {
        // Important to clone the struct, to avoid unexpected side effect if modifying the returned config
        return _clone(configs[i]);
      }
    }
    revert('RESERVE_CONFIG_NOT_FOUND');
  }

  function _findReserveConfigBySymbol(
    ReserveConfig[] memory configs,
    string memory symbolOfUnderlying
  ) internal pure returns (ReserveConfig memory) {
    for (uint256 i = 0; i < configs.length; i++) {
      if (
        keccak256(abi.encodePacked(configs[i].symbol)) ==
        keccak256(abi.encodePacked(symbolOfUnderlying))
      ) {
        return _clone(configs[i]);
      }
    }
    revert('RESERVE_CONFIG_NOT_FOUND');
  }

  function _logReserveConfig(ReserveConfig memory config) internal view {
    console.log('Symbol ', config.symbol);
    console.log('Underlying address ', config.underlying);
    console.log('AToken address ', config.aToken);
    console.log('Stable debt token address ', config.stableDebtToken);
    console.log('Variable debt token address ', config.variableDebtToken);
    console.log('Decimals ', config.decimals);
    console.log('LTV ', config.ltv);
    console.log('Liquidation Threshold ', config.liquidationThreshold);
    console.log('Liquidation Bonus ', config.liquidationBonus);
    console.log('Liquidation protocol fee ', config.liquidationProtocolFee);
    console.log('Reserve Factor ', config.reserveFactor);
    console.log('Usage as collateral enabled ', (config.usageAsCollateralEnabled) ? 'Yes' : 'No');
    console.log('Borrowing enabled ', (config.borrowingEnabled) ? 'Yes' : 'No');
    console.log('Stable borrow rate enabled ', (config.stableBorrowRateEnabled) ? 'Yes' : 'No');
    console.log('Supply cap ', config.supplyCap);
    console.log('Borrow cap ', config.borrowCap);
    console.log('Debt ceiling ', config.debtCeiling);
    console.log('eMode category ', config.eModeCategory);
    console.log('Interest rate strategy ', config.interestRateStrategy);
    console.log('Is active ', (config.isActive) ? 'Yes' : 'No');
    console.log('Is frozen ', (config.isFrozen) ? 'Yes' : 'No');
    console.log('Is siloed ', (config.isSiloed) ? 'Yes' : 'No');
    console.log('Is borrowable in isolation ', (config.isBorrowableInIsolation) ? 'Yes' : 'No');
    console.log('Is flashloanable ', (config.isFlashloanable) ? 'Yes' : 'No');
    console.log('-----');
    console.log('-----');
  }

  function _validateReserveConfig(
    ReserveConfig memory expectedConfig,
    ReserveConfig[] memory allConfigs
  ) internal pure {
    ReserveConfig memory config = _findReserveConfig(allConfigs, expectedConfig.underlying);
    require(
      keccak256(bytes(config.symbol)) == keccak256(bytes(expectedConfig.symbol)),
      '_validateConfigsInAave() : INVALID_SYMBOL'
    );
    require(
      config.underlying == expectedConfig.underlying,
      '_validateConfigsInAave() : INVALID_UNDERLYING'
    );
    require(config.decimals == expectedConfig.decimals, '_validateConfigsInAave: INVALID_DECIMALS');
    require(config.ltv == expectedConfig.ltv, '_validateConfigsInAave: INVALID_LTV');
    require(
      config.liquidationThreshold == expectedConfig.liquidationThreshold,
      '_validateConfigsInAave: INVALID_LIQ_THRESHOLD'
    );
    require(
      config.liquidationBonus == expectedConfig.liquidationBonus,
      '_validateConfigsInAave: INVALID_LIQ_BONUS'
    );
    require(
      config.liquidationProtocolFee == expectedConfig.liquidationProtocolFee,
      '_validateConfigsInAave: INVALID_LIQUIDATION_PROTOCOL_FEE'
    );
    require(
      config.reserveFactor == expectedConfig.reserveFactor,
      '_validateConfigsInAave: INVALID_RESERVE_FACTOR'
    );

    require(
      config.usageAsCollateralEnabled == expectedConfig.usageAsCollateralEnabled,
      '_validateConfigsInAave: INVALID_USAGE_AS_COLLATERAL'
    );
    require(
      config.borrowingEnabled == expectedConfig.borrowingEnabled,
      '_validateConfigsInAave: INVALID_BORROWING_ENABLED'
    );
    require(
      config.stableBorrowRateEnabled == expectedConfig.stableBorrowRateEnabled,
      '_validateConfigsInAave: INVALID_STABLE_BORROW_ENABLED'
    );
    require(
      config.isActive == expectedConfig.isActive,
      '_validateConfigsInAave: INVALID_IS_ACTIVE'
    );
    require(
      config.isFrozen == expectedConfig.isFrozen,
      '_validateConfigsInAave: INVALID_IS_FROZEN'
    );
    require(
      config.isSiloed == expectedConfig.isSiloed,
      '_validateConfigsInAave: INVALID_IS_SILOED'
    );
    require(
      config.isBorrowableInIsolation == expectedConfig.isBorrowableInIsolation,
      '_validateConfigsInAave: INVALID_IS_BORROWABLE_IN_ISOLATION'
    );
    require(
      config.isFlashloanable == expectedConfig.isFlashloanable,
      '_validateConfigsInAave: INVALID_IS_FLASHLOANABLE'
    );
    require(
      config.supplyCap == expectedConfig.supplyCap,
      '_validateConfigsInAave: INVALID_SUPPLY_CAP'
    );
    require(
      config.borrowCap == expectedConfig.borrowCap,
      '_validateConfigsInAave: INVALID_BORROW_CAP'
    );
    require(
      config.debtCeiling == expectedConfig.debtCeiling,
      '_validateConfigsInAave: INVALID_DEBT_CEILING'
    );
    require(
      config.eModeCategory == expectedConfig.eModeCategory,
      '_validateConfigsInAave: INVALID_EMODE_CATEGORY'
    );
    require(
      config.interestRateStrategy == expectedConfig.interestRateStrategy,
      '_validateConfigsInAave: INVALID_INTEREST_RATE_STRATEGY'
    );
  }

  function _validateInterestRateStrategy(
    address interestRateStrategyAddress,
    address expectedStrategy,
    InterestStrategyValues memory expectedStrategyValues
  ) internal view {
    IDefaultInterestRateStrategy strategy = IDefaultInterestRateStrategy(
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

  function _noReservesConfigsChangesApartNewListings(
    ReserveConfig[] memory allConfigsBefore,
    ReserveConfig[] memory allConfigsAfter
  ) internal pure {
    for (uint256 i = 0; i < allConfigsBefore.length; i++) {
      _requireNoChangeInConfigs(allConfigsBefore[i], allConfigsAfter[i]);
    }
  }

  function _noReservesConfigsChangesApartFrom(
    ReserveConfig[] memory allConfigsBefore,
    ReserveConfig[] memory allConfigsAfter,
    address assetChangedUnderlying
  ) internal pure {
    require(allConfigsBefore.length == allConfigsAfter.length, 'A_UNEXPECTED_NEW_LISTING_HAPPENED');

    for (uint256 i = 0; i < allConfigsBefore.length; i++) {
      if (assetChangedUnderlying != allConfigsBefore[i].underlying) {
        _requireNoChangeInConfigs(allConfigsBefore[i], allConfigsAfter[i]);
      }
    }
  }

  /// @dev Version in batch, useful when multiple asset changes are expected
  function _noReservesConfigsChangesApartFrom(
    ReserveConfig[] memory allConfigsBefore,
    ReserveConfig[] memory allConfigsAfter,
    address[] memory assetChangedUnderlying
  ) internal pure {
    require(allConfigsBefore.length == allConfigsAfter.length, 'A_UNEXPECTED_NEW_LISTING_HAPPENED');

    for (uint256 i = 0; i < allConfigsBefore.length; i++) {
      bool isAssetExpectedToChange;
      for (uint256 j = 0; j < assetChangedUnderlying.length; j++) {
        if (assetChangedUnderlying[j] == allConfigsBefore[i].underlying) {
          isAssetExpectedToChange = true;
          break;
        }
      }
      if (!isAssetExpectedToChange) {
        _requireNoChangeInConfigs(allConfigsBefore[i], allConfigsAfter[i]);
      }
    }
  }

  function _requireNoChangeInConfigs(
    ReserveConfig memory config1,
    ReserveConfig memory config2
  ) internal pure {
    require(
      keccak256(abi.encodePacked(config1.symbol)) == keccak256(abi.encodePacked(config2.symbol)),
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_SYMBOL_CHANGED'
    );
    require(
      config1.underlying == config2.underlying,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_UNDERLYING_CHANGED'
    );
    require(
      config1.aToken == config2.aToken,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_A_TOKEN_CHANGED'
    );
    require(
      config1.stableDebtToken == config2.stableDebtToken,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_STABLE_DEBT_TOKEN_CHANGED'
    );
    require(
      config1.variableDebtToken == config2.variableDebtToken,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_VARIABLE_DEBT_TOKEN_CHANGED'
    );
    require(
      config1.decimals == config2.decimals,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_DECIMALS_CHANGED'
    );
    require(
      config1.ltv == config2.ltv,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_LTV_CHANGED'
    );
    require(
      config1.liquidationThreshold == config2.liquidationThreshold,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_LIQ_THRESHOLD_CHANGED'
    );
    require(
      config1.liquidationBonus == config2.liquidationBonus,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_LIQ_BONUS_CHANGED'
    );
    require(
      config1.liquidationProtocolFee == config2.liquidationProtocolFee,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_LIQ_PROTOCOL_FEE_CHANGED'
    );
    require(
      config1.reserveFactor == config2.reserveFactor,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_RESERVE_FACTOR_CHANGED'
    );
    require(
      config1.usageAsCollateralEnabled == config2.usageAsCollateralEnabled,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_USAGE_AS_COLLATERAL_ENABLED_CHANGED'
    );
    require(
      config1.borrowingEnabled == config2.borrowingEnabled,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_BORROWING_ENABLED_CHANGED'
    );
    require(
      config1.interestRateStrategy == config2.interestRateStrategy,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_INTEREST_RATE_STRATEGY_CHANGED'
    );
    require(
      config1.stableBorrowRateEnabled == config2.stableBorrowRateEnabled,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_STABLE_BORROWING_CHANGED'
    );
    require(
      config1.isActive == config2.isActive,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_IS_ACTIVE_CHANGED'
    );
    require(
      config1.isFrozen == config2.isFrozen,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_IS_FROZEN_CHANGED'
    );
    require(
      config1.isSiloed == config2.isSiloed,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_IS_SILOED_CHANGED'
    );
    require(
      config1.isBorrowableInIsolation == config2.isBorrowableInIsolation,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_IS_BORROWABLE_IN_ISOLATION_CHANGED'
    );
    require(
      config1.isFlashloanable == config2.isFlashloanable,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_IS_FLASHLOANABLE_CHANGED'
    );
    require(
      config1.supplyCap == config2.supplyCap,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_SUPPLY_CAP_CHANGED'
    );
    require(
      config1.borrowCap == config2.borrowCap,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_BORROW_CAP_CHANGED'
    );
    require(
      config1.debtCeiling == config2.debtCeiling,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_DEBT_CEILING_CHANGED'
    );
    require(
      config1.eModeCategory == config2.eModeCategory,
      '_noReservesConfigsChangesApartNewListings() : UNEXPECTED_E_MODE_CATEGORY_CHANGED'
    );
  }

  function _validateCountOfListings(
    uint256 count,
    ReserveConfig[] memory allConfigsBefore,
    ReserveConfig[] memory allConfigsAfter
  ) internal pure {
    require(
      allConfigsBefore.length == allConfigsAfter.length - count,
      '_validateCountOfListings() : INVALID_COUNT_OF_LISTINGS'
    );
  }

  function _validateReserveTokensImpls(
    IPoolAddressesProvider addressProvider,
    ReserveConfig memory config,
    ReserveTokens memory expectedImpls
  ) internal {
    address poolConfigurator = addressProvider.getPoolConfigurator();
    vm.startPrank(poolConfigurator);
    require(
      IInitializableAdminUpgradeabilityProxy(config.aToken).implementation() ==
        expectedImpls.aToken,
      '_validateReserveTokensImpls() : INVALID_ATOKEN_IMPL'
    );
    require(
      IInitializableAdminUpgradeabilityProxy(config.variableDebtToken).implementation() ==
        expectedImpls.variableDebtToken,
      '_validateReserveTokensImpls() : INVALID_ATOKEN_IMPL'
    );
    require(
      IInitializableAdminUpgradeabilityProxy(config.stableDebtToken).implementation() ==
        expectedImpls.stableDebtToken,
      '_validateReserveTokensImpls() : INVALID_ATOKEN_IMPL'
    );
    vm.stopPrank();
  }

  function _validateAssetSourceOnOracle(
    IPoolAddressesProvider addressesProvider,
    address asset,
    address expectedSource
  ) internal view {
    IAaveOracle oracle = IAaveOracle(addressesProvider.getPriceOracle());

    require(
      oracle.getSourceOfAsset(asset) == expectedSource,
      '_validateAssetSourceOnOracle() : INVALID_PRICE_SOURCE'
    );
  }

  function _validateAssetsOnEmodeCategory(
    uint256 category,
    ReserveConfig[] memory assetsConfigs,
    string[] memory expectedAssets
  ) internal pure {
    string[] memory assetsInCategory = new string[](assetsConfigs.length);

    uint256 countCategory;
    for (uint256 i = 0; i < assetsConfigs.length; i++) {
      if (assetsConfigs[i].eModeCategory == category) {
        assetsInCategory[countCategory] = assetsConfigs[i].symbol;
        require(
          keccak256(bytes(assetsInCategory[countCategory])) ==
            keccak256(bytes(expectedAssets[countCategory])),
          '_getAssetOnEmodeCategory(): INCONSISTENT_ASSETS'
        );
        countCategory++;
        if (countCategory > expectedAssets.length) {
          revert('_getAssetOnEmodeCategory(): MORE_ASSETS_IN_CATEGORY_THAN_EXPECTED');
        }
      }
    }
    if (countCategory < expectedAssets.length) {
      revert('_getAssetOnEmodeCategory(): LESS_ASSETS_IN_CATEGORY_THAN_EXPECTED');
    }
  }
}

/**
 * only applicable to v3 harmony at this point
 */
contract ProtocolV3LegacyTestBase is ProtocolV3TestBase {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  function _getStructReserveConfig(
    IPool pool,
    IPoolDataProvider.TokenData memory reserve
  ) internal view override returns (ReserveConfig memory) {
    ReserveConfig memory localConfig;
    DataTypes.ReserveConfigurationMap memory configuration = pool.getConfiguration(
      reserve.tokenAddress
    );
    localConfig.interestRateStrategy = pool
      .getReserveData(reserve.tokenAddress)
      .interestRateStrategyAddress;
    (
      localConfig.ltv,
      localConfig.liquidationThreshold,
      localConfig.liquidationBonus,
      localConfig.decimals,
      localConfig.reserveFactor,
      localConfig.eModeCategory
    ) = configuration.getParams();
    (
      localConfig.isActive,
      localConfig.isFrozen,
      localConfig.borrowingEnabled,
      localConfig.stableBorrowRateEnabled,
      localConfig.isPaused
    ) = configuration.getFlags();
    localConfig.symbol = reserve.symbol;
    localConfig.underlying = reserve.tokenAddress;
    localConfig.usageAsCollateralEnabled = localConfig.liquidationThreshold != 0;
    localConfig.isSiloed = configuration.getSiloedBorrowing();
    (localConfig.borrowCap, localConfig.supplyCap) = configuration.getCaps();
    localConfig.debtCeiling = configuration.getDebtCeiling();
    localConfig.liquidationProtocolFee = configuration.getLiquidationProtocolFee();
    localConfig.isBorrowableInIsolation = configuration.getBorrowableInIsolation();

    localConfig.isFlashloanable = false;

    return localConfig;
  }
}
