// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5 <0.9.0;

import 'forge-std/Test.sol';
import {IAaveOracle, IPool, IPoolAddressesProvider, IAaveProtocolDataProvider, TokenData, IInterestRateStrategy, DataTypes} from 'aave-address-book/AaveV3.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';

struct ReserveTokens {
  address aToken;
  address stableDebtToken;
  address variableDebtToken;
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
  bool isActive;
  bool isFrozen;
  bool isSiloed;
  uint256 supplyCap;
  uint256 borrowCap;
  uint256 debtCeiling;
  uint256 eModeCategory;
}

struct LocalVars {
  TokenData[] reserves;
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

interface IInitializableAdminUpgradeabilityProxy {
  function upgradeTo(address newImplementation) external;

  function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;

  function admin() external returns (address);

  function implementation() external returns (address);
}

contract ProtocolV3TestBase is Test {
  address public constant ETH_MOCK_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  function createConfigurationSnapshot(string memory reportName, IPool pool) public {
    string memory path = string.concat(
      './reports/',
      vm.toString(address(pool)),
      '_',
      reportName,
      '.md'
    );
    vm.writeFile(path, '# Report\n\n');
    ReserveConfig[] memory configs = _getReservesConfigs(pool);
    _writeReserveConfigs(path, configs);
    _writeStrategyConfigs(path, configs);
    _writeEModeConfigs(path, configs, pool);
  }

  function e2eTest(IPool pool) public {
    ReserveConfig[] memory configs = _getReservesConfigs(pool);
    deal(address(this), 1000 ether);
    uint256 snapshot = vm.snapshot();
    _supplyWithdrawFlow(configs, pool);
    vm.revertTo(snapshot);
    _variableBorrowFlow(configs, pool);
    vm.revertTo(snapshot);
    _stableBorrowFlow(configs, pool);
    vm.revertTo(snapshot);
  }

  /**
   * @dev forwards time by x blocks
   */
  function _skipBlocks(uint128 blocks) private {
    vm.roll(block.number + blocks);
    vm.warp(block.timestamp + blocks * 12); // assuming a block is around 12seconds
  }

  /**
   * @dev returns the first collateral in the list that cannot be borrowed in stable mode
   */
  function _getFirstCollateral(ReserveConfig[] memory configs)
    private
    pure
    returns (ReserveConfig memory config)
  {
    for (uint256 i = 0; i < configs.length; i++) {
      if (configs[i].usageAsCollateralEnabled && !configs[i].stableBorrowRateEnabled)
        return configs[i];
    }
    revert('ERROR: No collateral found');
  }

  /**
   * @dev tests that all assets can be deposited & withdrawn
   */
  function _supplyWithdrawFlow(ReserveConfig[] memory configs, IPool pool) internal {
    // test all basic interactions
    for (uint256 i = 0; i < configs.length; i++) {
      uint256 amount = 100 * 10**configs[i].decimals;
      if (!configs[i].isFrozen) {
        _deposit(configs[i], pool, amount);
        _skipBlocks(1000);
        assertEq(_withdraw(configs[i], pool, amount, false), amount);
        _deposit(configs[i], pool, amount);
        _skipBlocks(1000);
        assertGe(_withdraw(configs[i], pool, amount, true), amount);
      } else {
        console.log('SKIP: REASON_FROZEN %s', configs[i].symbol);
      }
    }
  }

  /**
   * @dev tests that all assets with borrowing enabled can be borrowed
   */
  function _variableBorrowFlow(ReserveConfig[] memory configs, IPool pool) internal {
    // put 1M whatever collateral, which should be enough to borrow 1 of each
    ReserveConfig memory collateralConfig = _getFirstCollateral(configs);
    _deposit(collateralConfig, pool, 1000000 ether);
    for (uint256 i = 0; i < configs.length; i++) {
      uint256 amount = 10**configs[i].decimals;
      if (configs[i].borrowingEnabled) {
        _borrow(configs[i], pool, amount, false);
      } else {
        console.log('SKIP: BORROWING_DISABLED %s', configs[i].symbol);
      }
    }
  }

  /**
   * @dev tests that all assets with stable borrowing enabled can be borrowed
   */
  function _stableBorrowFlow(ReserveConfig[] memory configs, IPool pool) internal {
    // put 1M whatever collateral, which should be enough to borrow 1 of each
    ReserveConfig memory collateralConfig = _getFirstCollateral(configs);
    _deposit(collateralConfig, pool, 1000000 ether);
    for (uint256 i = 0; i < configs.length; i++) {
      uint256 amount = 10**configs[i].decimals;
      if (configs[i].borrowingEnabled && configs[i].stableBorrowRateEnabled) {
        _borrow(configs[i], pool, amount, true);
      } else {
        console.log('SKIP: STABLE_BORROWING_DISABLED %s', configs[i].symbol);
      }
    }
  }

  function _deposit(
    ReserveConfig memory config,
    IPool pool,
    uint256 amount
  ) internal {
    deal(config.underlying, address(this), amount);
    IERC20(config.underlying).approve(address(pool), amount);
    console.log('SUPPLY: %s, Amount: %s', config.symbol, amount);
    pool.deposit(config.underlying, amount, address(this), 0);
  }

  function _withdraw(
    ReserveConfig memory config,
    IPool pool,
    uint256 amount,
    bool max
  ) internal returns (uint256) {
    uint256 amountOut = pool.withdraw(
      config.underlying,
      max ? type(uint256).max : amount,
      address(this)
    );
    console.log('WITHDRAW: %s, Amount: %s', config.symbol, amountOut);
    return amountOut;
  }

  function _borrow(
    ReserveConfig memory config,
    IPool pool,
    uint256 amount,
    bool stable
  ) internal {
    console.log('BORROW: %s, Amount %s, Stable: %s', config.symbol, amount, stable);
    pool.borrow(config.underlying, amount, stable ? 1 : 2, 0, address(this));
  }

  function _isInUint256Array(uint256[] memory haystack, uint256 needle)
    private
    pure
    returns (bool)
  {
    for (uint256 i = 0; i < haystack.length; i++) {
      if (haystack[i] == needle) return true;
    }
    return false;
  }

  function _isInAddressArray(address[] memory haystack, address needle)
    private
    pure
    returns (bool)
  {
    for (uint256 i = 0; i < haystack.length; i++) {
      if (haystack[i] == needle) return true;
    }
    return false;
  }

  function _writeEModeConfigs(
    string memory path,
    ReserveConfig[] memory configs,
    IPool pool
  ) internal {
    vm.writeLine(path, '## EMode categories\n\n');
    vm.writeLine(
      path,
      '| id | label | ltv | liquidationThreshold | liquidationBonus | priceSource |'
    );
    vm.writeLine(path, '|---|---|---|---|---|---|');
    uint256[] memory usedCategories = new uint256[](configs.length);
    for (uint256 i = 0; i < configs.length; i++) {
      if (!_isInUint256Array(usedCategories, configs[i].eModeCategory)) {
        usedCategories[i] = configs[i].eModeCategory;
        DataTypes.EModeCategory memory category = pool.getEModeCategoryData(
          uint8(configs[i].eModeCategory)
        );
        vm.writeLine(
          path,
          string.concat(
            '| ',
            vm.toString(configs[i].eModeCategory),
            ' | ',
            category.label,
            ' | ',
            vm.toString(category.ltv),
            ' | ',
            vm.toString(category.liquidationThreshold),
            ' | ',
            vm.toString(category.liquidationBonus),
            ' | ',
            vm.toString(category.priceSource),
            ' |'
          )
        );
      }
    }
    vm.writeLine(path, '\n');
  }

  function _writeStrategyConfigs(string memory path, ReserveConfig[] memory configs) internal {
    vm.writeLine(path, '## InterestRateStrategies\n');
    vm.writeLine(
      path,
      string.concat(
        '| strategy | getBaseStableBorrowRate | getStableRateSlope1 | getStableRateSlope2 | optimalStableToTotal | maxStabletoTotalExcess ',
        '| getBaseVariableBorrowRate | getVariableRateSlope1 | getVariableRateSlope2 | optimalUsageRatio | maxExcessUsageRatio |'
      )
    );
    vm.writeLine(path, '|---|---|---|---|---|---|---|---|---|---|---|');
    address[] memory usedStrategies = new address[](configs.length);
    for (uint256 i = 0; i < configs.length; i++) {
      if (!_isInAddressArray(usedStrategies, configs[i].interestRateStrategy)) {
        usedStrategies[i] = configs[i].interestRateStrategy;
        IInterestRateStrategy strategy = IInterestRateStrategy(configs[i].interestRateStrategy);
        vm.writeLine(
          path,
          string.concat(
            string.concat(
              '| ',
              vm.toString(address(strategy)),
              ' | ',
              vm.toString(strategy.getBaseStableBorrowRate()),
              ' | ',
              vm.toString(strategy.getStableRateSlope1()),
              ' | ',
              vm.toString(strategy.getStableRateSlope2()),
              ' | ',
              vm.toString(strategy.OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO()),
              ' | ',
              vm.toString(strategy.MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO()),
              ' | '
            ),
            string.concat(
              vm.toString(strategy.getBaseVariableBorrowRate()),
              ' | ',
              vm.toString(strategy.getVariableRateSlope1()),
              ' | ',
              vm.toString(strategy.getVariableRateSlope2()),
              ' | ',
              vm.toString(strategy.OPTIMAL_USAGE_RATIO()),
              ' | ',
              vm.toString(strategy.MAX_EXCESS_USAGE_RATIO()),
              ' |'
            )
          )
        );
      }
    }
    vm.writeLine(path, '\n');
  }

  function _writeReserveConfigs(string memory path, ReserveConfig[] memory configs) internal {
    vm.writeLine(path, '## Reserve Configurations\n');
    vm.writeLine(
      path,
      string.concat(
        '| symbol | underlying | aToken | stableDebtToken | variableDebtToken | decimals | ltv | liquidationThreshold | liquidationBonus | ',
        'liquidationProtocolFee | reserveFactor | usageAsCollateralEnabled | borrowingEnabled | stableBorrowRateEnabled | supplyCap | borrowCap | debtCeiling | eModeCategory | ',
        'interestRateStrategy | isActive | isFrozen | isSiloed |'
      )
    );
    vm.writeLine(
      path,
      string.concat(
        '|---|---|---|---|---|---|---|---|---',
        '|---|---|---|---|---|---|---|---|---',
        '|---|---|---|---|'
      )
    );
    for (uint256 i = 0; i < configs.length; i++) {
      ReserveConfig memory config = configs[i];
      vm.writeLine(
        path,
        string.concat(
          string.concat(
            '| ',
            config.symbol,
            ' | ',
            vm.toString(config.underlying),
            ' | ',
            vm.toString(config.aToken),
            ' | ',
            vm.toString(config.stableDebtToken),
            ' | ',
            vm.toString(config.variableDebtToken),
            ' | ',
            vm.toString(config.decimals),
            ' | ',
            vm.toString(config.ltv),
            ' | ',
            vm.toString(config.liquidationThreshold),
            ' | ',
            vm.toString(config.liquidationBonus),
            ' | '
          ),
          string.concat(
            vm.toString(config.liquidationProtocolFee),
            ' | ',
            vm.toString(config.reserveFactor),
            ' | ',
            vm.toString(config.usageAsCollateralEnabled),
            ' | ',
            vm.toString(config.borrowingEnabled),
            ' | ',
            vm.toString(config.stableBorrowRateEnabled),
            ' | ',
            vm.toString(config.supplyCap),
            ' | ',
            vm.toString(config.borrowCap),
            ' | ',
            vm.toString(config.debtCeiling),
            ' | ',
            vm.toString(config.eModeCategory),
            ' | '
          ),
          string.concat(
            vm.toString(config.interestRateStrategy),
            ' | ',
            vm.toString(config.isActive),
            ' | ',
            vm.toString(config.isFrozen),
            ' | ',
            vm.toString(config.isSiloed),
            ' |'
          )
        )
      );
    }
    vm.writeLine(path, '\n');
  }

  function _getReservesConfigs(IPool pool) internal view returns (ReserveConfig[] memory) {
    IPoolAddressesProvider addressesProvider = IPoolAddressesProvider(pool.ADDRESSES_PROVIDER());
    IAaveProtocolDataProvider poolDataProvider = IAaveProtocolDataProvider(
      addressesProvider.getPoolDataProvider()
    );
    LocalVars memory vars;

    vars.reserves = poolDataProvider.getAllReservesTokens();

    vars.configs = new ReserveConfig[](vars.reserves.length);

    for (uint256 i = 0; i < vars.reserves.length; i++) {
      vars.configs[i] = _getStructReserveConfig(pool, poolDataProvider, vars.reserves[i]);
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

  function _getStructReserveTokens(IAaveProtocolDataProvider pdp, address underlyingAddress)
    internal
    view
    returns (ReserveTokens memory)
  {
    ReserveTokens memory reserveTokens;
    (reserveTokens.aToken, reserveTokens.stableDebtToken, reserveTokens.variableDebtToken) = pdp
      .getReserveTokensAddresses(underlyingAddress);

    return reserveTokens;
  }

  function _getStructReserveConfig(
    IPool pool,
    IAaveProtocolDataProvider pdp,
    TokenData memory reserve
  ) internal view returns (ReserveConfig memory) {
    ReserveConfig memory localConfig;
    (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      bool stableBorrowRateEnabled,
      bool isActive,
      bool isFrozen
    ) = pdp.getReserveConfigurationData(reserve.tokenAddress);
    localConfig.symbol = reserve.symbol;
    localConfig.underlying = reserve.tokenAddress;
    localConfig.decimals = decimals;
    localConfig.ltv = ltv;
    localConfig.liquidationThreshold = liquidationThreshold;
    localConfig.liquidationBonus = liquidationBonus;
    localConfig.reserveFactor = reserveFactor;
    localConfig.usageAsCollateralEnabled = usageAsCollateralEnabled;
    localConfig.borrowingEnabled = borrowingEnabled;
    localConfig.stableBorrowRateEnabled = stableBorrowRateEnabled;
    localConfig.interestRateStrategy = pool
      .getReserveData(reserve.tokenAddress)
      .interestRateStrategyAddress;
    localConfig.isActive = isActive;
    localConfig.isFrozen = isFrozen;
    localConfig.isSiloed = pdp.getSiloedBorrowing(reserve.tokenAddress);
    (localConfig.borrowCap, localConfig.supplyCap) = pdp.getReserveCaps(reserve.tokenAddress);
    localConfig.debtCeiling = pdp.getDebtCeiling(reserve.tokenAddress);
    localConfig.eModeCategory = pdp.getReserveEModeCategory(reserve.tokenAddress);
    localConfig.liquidationProtocolFee = pdp.getLiquidationProtocolFee(reserve.tokenAddress);

    return localConfig;
  }

  function _findReserveConfig(ReserveConfig[] memory configs, address underlying)
    internal
    pure
    returns (ReserveConfig memory)
  {
    for (uint256 i = 0; i < configs.length; i++) {
      if (configs[i].underlying == underlying) {
        return configs[i];
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
    IInterestRateStrategy strategy = IInterestRateStrategy(interestRateStrategyAddress);

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
      '_validateInterestRateStrategy() : INVALID_BASE_VARIABLE_BORROW'
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

  function _requireNoChangeInConfigs(ReserveConfig memory config1, ReserveConfig memory config2)
    internal
    pure
  {
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
    IPoolAddressesProvider addressProvider,
    address asset,
    address expectedSource
  ) external view {
    IAaveOracle oracle = IAaveOracle(addressProvider.getPriceOracle());

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
