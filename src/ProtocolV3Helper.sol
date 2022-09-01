// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5 <0.9.0;

import 'forge-std/Test.sol';
import {IPool, IPoolAddressesProvider, IAaveProtocolDataProvider, TokenData, IInterestRateStrategy} from 'aave-address-book/AaveV3.sol';

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

contract ProtocolV3Helper is Test {
  function createConfigurationSnapshot(string memory reportName, address pool) public {
    string memory path = string.concat('./reports/', reportName, '.md');
    vm.writeFile(path, '# Report\n\n');
    ReserveConfig[] memory configs = _getReservesConfigs(IPool(pool));
    _writeReserveConfigs(path, configs);
    _writeStrategyConfigs(path, configs);
  }

  function _writeStrategyConfigs(string memory path, ReserveConfig[] memory configs) internal {
    vm.writeLine(
      path,
      '| strategy | getBaseStableBorrowRate | getStableRateSlope1 | getStableRateSlope2 | getBaseVariableBorrowRate | getVariableRateSlope1 | getVariableRateSlope2 |'
    );
    vm.writeLine(path, '|---|---|---|---|---|---|---|');
    for (uint256 i = 0; i < configs.length; i++) {
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
            ' |'
          ),
          string.concat(
            vm.toString(strategy.getBaseVariableBorrowRate()),
            ' | ',
            vm.toString(strategy.getVariableRateSlope1()),
            ' | ',
            vm.toString(strategy.getVariableRateSlope2())
          )
        )
      );
    }
  }

  function _writeReserveConfigs(string memory path, ReserveConfig[] memory configs) internal {
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
    vm.writeLine(path, '\n\n');
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
}
