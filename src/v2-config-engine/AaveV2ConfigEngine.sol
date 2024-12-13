// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {EngineFlags} from 'aave-v3-origin/contracts/extensions/v3-config-engine/EngineFlags.sol';
import './IAaveV2ConfigEngine.sol';

/**
 * @dev Helper smart contract abstracting the complexity of changing rates configurations on Aave v2.
 *      It is planned to be used via delegatecall, by any contract having appropriate permissions to update rates
 * IMPORTANT!!! This contract MUST BE STATELESS always, as in practise is a library to be used via DELEGATECALL
 * @author BGD Labs
 */
contract AaveV2ConfigEngine is IAaveV2ConfigEngine {
  struct AssetsConfig {
    address[] ids;
    IV2RateStrategyFactory.RateStrategyParams[] rates;
  }

  ILendingPoolConfigurator public immutable POOL_CONFIGURATOR;
  IV2RateStrategyFactory public immutable RATE_STRATEGIES_FACTORY;

  constructor(ILendingPoolConfigurator configurator, IV2RateStrategyFactory rateStrategiesFactory) {
    require(address(configurator) != address(0), 'ONLY_NONZERO_CONFIGURATOR');
    require(address(rateStrategiesFactory) != address(0), 'ONLY_NONZERO_RATES_FACTORY');

    POOL_CONFIGURATOR = configurator;
    RATE_STRATEGIES_FACTORY = rateStrategiesFactory;
  }

  /// @inheritdoc IAaveV2ConfigEngine
  function updateRateStrategies(RateStrategyUpdate[] memory updates) public {
    require(updates.length != 0, 'AT_LEAST_ONE_UPDATE_REQUIRED');

    AssetsConfig memory configs = _repackRatesUpdate(updates);

    _configRateStrategies(configs.ids, configs.rates);
  }

  function _configRateStrategies(
    address[] memory ids,
    IV2RateStrategyFactory.RateStrategyParams[] memory strategiesParams
  ) internal {
    for (uint256 i = 0; i < strategiesParams.length; i++) {
      if (
        strategiesParams[i].variableRateSlope1 == EngineFlags.KEEP_CURRENT ||
        strategiesParams[i].variableRateSlope2 == EngineFlags.KEEP_CURRENT ||
        strategiesParams[i].optimalUtilizationRate == EngineFlags.KEEP_CURRENT ||
        strategiesParams[i].baseVariableBorrowRate == EngineFlags.KEEP_CURRENT ||
        strategiesParams[i].stableRateSlope1 == EngineFlags.KEEP_CURRENT ||
        strategiesParams[i].stableRateSlope2 == EngineFlags.KEEP_CURRENT
      ) {
        IV2RateStrategyFactory.RateStrategyParams
          memory currentStrategyData = RATE_STRATEGIES_FACTORY.getStrategyDataOfAsset(ids[i]);

        if (strategiesParams[i].variableRateSlope1 == EngineFlags.KEEP_CURRENT) {
          strategiesParams[i].variableRateSlope1 = currentStrategyData.variableRateSlope1;
        }

        if (strategiesParams[i].variableRateSlope2 == EngineFlags.KEEP_CURRENT) {
          strategiesParams[i].variableRateSlope2 = currentStrategyData.variableRateSlope2;
        }

        if (strategiesParams[i].optimalUtilizationRate == EngineFlags.KEEP_CURRENT) {
          strategiesParams[i].optimalUtilizationRate = currentStrategyData.optimalUtilizationRate;
        }

        if (strategiesParams[i].baseVariableBorrowRate == EngineFlags.KEEP_CURRENT) {
          strategiesParams[i].baseVariableBorrowRate = currentStrategyData.baseVariableBorrowRate;
        }

        if (strategiesParams[i].stableRateSlope1 == EngineFlags.KEEP_CURRENT) {
          strategiesParams[i].stableRateSlope1 = currentStrategyData.stableRateSlope1;
        }

        if (strategiesParams[i].stableRateSlope2 == EngineFlags.KEEP_CURRENT) {
          strategiesParams[i].stableRateSlope2 = currentStrategyData.stableRateSlope2;
        }
      }
    }

    address[] memory strategies = RATE_STRATEGIES_FACTORY.createStrategies(strategiesParams);

    for (uint256 i = 0; i < strategies.length; i++) {
      POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(ids[i], strategies[i]);
    }
  }

  function _repackRatesUpdate(
    RateStrategyUpdate[] memory updates
  ) internal pure returns (AssetsConfig memory) {
    address[] memory ids = new address[](updates.length);
    IV2RateStrategyFactory.RateStrategyParams[]
      memory rates = new IV2RateStrategyFactory.RateStrategyParams[](updates.length);

    for (uint256 i = 0; i < updates.length; i++) {
      ids[i] = updates[i].asset;
      rates[i] = updates[i].params;
    }

    return AssetsConfig({ids: ids, rates: rates});
  }
}
