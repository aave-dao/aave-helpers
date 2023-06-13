// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {EngineFlags} from '../EngineFlags.sol';
import {IAaveV3ConfigEngine as IEngine, IPoolConfigurator, IV3RateStrategyFactory} from '../IAaveV3ConfigEngine.sol';

library RateEngine {
  function executeRateStrategiesUpdate(
    IEngine.EngineConstants calldata engineConstants,
    IEngine.RateStrategyUpdate[] memory updates
  ) external {
    require(updates.length != 0, 'AT_LEAST_ONE_UPDATE_REQUIRED');

    (
      address[] memory ids,
      IV3RateStrategyFactory.RateStrategyParams[] memory rates
    ) = _repackRatesUpdate(updates);

    _configRateStrategies(
      engineConstants.poolConfigurator,
      engineConstants.ratesStrategyFactory,
      ids,
      rates
    );
  }

  function _configRateStrategies(
    IPoolConfigurator poolConfigurator,
    IV3RateStrategyFactory rateStrategiesFactory,
    address[] memory ids,
    IV3RateStrategyFactory.RateStrategyParams[] memory strategiesParams
  ) internal {
    for (uint256 i = 0; i < strategiesParams.length; i++) {
      bool atLeastOneKeepCurrent = strategiesParams[i].variableRateSlope1 ==
        EngineFlags.KEEP_CURRENT ||
        strategiesParams[i].variableRateSlope2 == EngineFlags.KEEP_CURRENT ||
        strategiesParams[i].optimalUsageRatio == EngineFlags.KEEP_CURRENT ||
        strategiesParams[i].baseVariableBorrowRate == EngineFlags.KEEP_CURRENT ||
        strategiesParams[i].stableRateSlope1 == EngineFlags.KEEP_CURRENT ||
        strategiesParams[i].stableRateSlope2 == EngineFlags.KEEP_CURRENT ||
        strategiesParams[i].baseStableRateOffset == EngineFlags.KEEP_CURRENT ||
        strategiesParams[i].stableRateExcessOffset == EngineFlags.KEEP_CURRENT ||
        strategiesParams[i].optimalStableToTotalDebtRatio == EngineFlags.KEEP_CURRENT;

      if (atLeastOneKeepCurrent) {
        IV3RateStrategyFactory.RateStrategyParams memory currentStrategyData = rateStrategiesFactory
          .getStrategyDataOfAsset(ids[i]);

        if (strategiesParams[i].variableRateSlope1 == EngineFlags.KEEP_CURRENT) {
          strategiesParams[i].variableRateSlope1 = currentStrategyData.variableRateSlope1;
        }

        if (strategiesParams[i].variableRateSlope2 == EngineFlags.KEEP_CURRENT) {
          strategiesParams[i].variableRateSlope2 = currentStrategyData.variableRateSlope2;
        }

        if (strategiesParams[i].optimalUsageRatio == EngineFlags.KEEP_CURRENT) {
          strategiesParams[i].optimalUsageRatio = currentStrategyData.optimalUsageRatio;
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

        if (strategiesParams[i].baseStableRateOffset == EngineFlags.KEEP_CURRENT) {
          strategiesParams[i].baseStableRateOffset = currentStrategyData.baseStableRateOffset;
        }

        if (strategiesParams[i].stableRateExcessOffset == EngineFlags.KEEP_CURRENT) {
          strategiesParams[i].stableRateExcessOffset = currentStrategyData.stableRateExcessOffset;
        }

        if (strategiesParams[i].optimalStableToTotalDebtRatio == EngineFlags.KEEP_CURRENT) {
          strategiesParams[i].optimalStableToTotalDebtRatio = currentStrategyData
            .optimalStableToTotalDebtRatio;
        }
      }
    }

    address[] memory strategies = rateStrategiesFactory.createStrategies(strategiesParams);

    for (uint256 i = 0; i < strategies.length; i++) {
      poolConfigurator.setReserveInterestRateStrategyAddress(ids[i], strategies[i]);
    }
  }

  function _repackRatesUpdate(
    IEngine.RateStrategyUpdate[] memory updates
  ) internal pure returns (address[] memory, IV3RateStrategyFactory.RateStrategyParams[] memory) {
    address[] memory ids = new address[](updates.length);
    IV3RateStrategyFactory.RateStrategyParams[]
      memory rates = new IV3RateStrategyFactory.RateStrategyParams[](updates.length);

    for (uint256 i = 0; i < updates.length; i++) {
      ids[i] = updates[i].asset;
      rates[i] = updates[i].params;
    }
    return (ids, rates);
  }
}
