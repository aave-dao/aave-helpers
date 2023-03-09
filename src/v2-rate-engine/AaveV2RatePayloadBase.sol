// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ILendingPool, ILendingPoolConfigurator, IAaveOracle} from 'aave-address-book/AaveV2.sol';
import {WadRayMath} from 'aave-v3-core/contracts/protocol/libraries/math/WadRayMath.sol';
import {IV2RateStrategyFactory as Rates} from './IV2RateStrategyFactory.sol';
import {EngineFlags} from '../v3-config-engine/EngineFlags.sol'; // TODO: Fix
import {IAaveV2RatePayloadBase} from './IAaveV2RatePayloadBase.sol';

/**
 * @dev Base smart contract for an Aave v2 rates update
 * @author BGD Labs
 */
abstract contract AaveV2RatePayloadBase is IAaveV2RatePayloadBase {

  Rates public immutable RATE_STRATEGIES_FACTORY;
  ILendingPoolConfigurator public immutable POOL_CONFIGURATOR;

  constructor(
    Rates ratesFactory,
    ILendingPoolConfigurator configurator
  ) {
    require(address(ratesFactory) != address(0), 'ONLY_NONZERO_RATES_FACTORY');
    require(address(configurator) != address(0), 'ONLY_NONZERO_CONFIGURATOR');

    RATE_STRATEGIES_FACTORY = ratesFactory;
    POOL_CONFIGURATOR = configurator;
  }

  /// @dev to be overriden on the child if any extra logic is needed pre-rates-updates
  function _preExecute() internal virtual {}

  /// @dev to be overriden on the child if any extra logic is needed post-rates-updates
  function _postExecute() internal virtual {}

  function execute() external {
    _preExecute();

    RateStrategyUpdate[] memory strategies = updateRateStrategies();
    require(strategies.length != 0, 'AT_LEAST_ONE_UPDATE_REQUIRED');

    if (strategies.length != 0) {
      for (uint256 i = 0; i < strategies.length; i++) {
        if (
          strategies[i].params.variableRateSlope1 == EngineFlags.KEEP_CURRENT ||
          strategies[i].params.variableRateSlope2 == EngineFlags.KEEP_CURRENT ||
          strategies[i].params.optimalUtilizationRate == EngineFlags.KEEP_CURRENT ||
          strategies[i].params.baseVariableBorrowRate == EngineFlags.KEEP_CURRENT ||
          strategies[i].params.stableRateSlope1 == EngineFlags.KEEP_CURRENT ||
          strategies[i].params.stableRateSlope2 == EngineFlags.KEEP_CURRENT
        ) {
          Rates.RateStrategyParams
            memory currentStrategyData = RATE_STRATEGIES_FACTORY.getStrategyDataOfAsset(strategies[i].asset);

          if (strategies[i].params.variableRateSlope1 == EngineFlags.KEEP_CURRENT) {
            strategies[i].params.variableRateSlope1 = currentStrategyData.variableRateSlope1;
          }

          if (strategies[i].params.variableRateSlope2 == EngineFlags.KEEP_CURRENT) {
            strategies[i].params.variableRateSlope2 = currentStrategyData.variableRateSlope2;
          }

          if (strategies[i].params.optimalUtilizationRate == EngineFlags.KEEP_CURRENT) {
            strategies[i].params.optimalUtilizationRate = currentStrategyData.optimalUtilizationRate;
          }

          if (strategies[i].params.baseVariableBorrowRate == EngineFlags.KEEP_CURRENT) {
            strategies[i].params.baseVariableBorrowRate = currentStrategyData.baseVariableBorrowRate;
          }

          if (strategies[i].params.stableRateSlope1 == EngineFlags.KEEP_CURRENT) {
            strategies[i].params.stableRateSlope1 = currentStrategyData.stableRateSlope1;
          }

          if (strategies[i].params.stableRateSlope2 == EngineFlags.KEEP_CURRENT) {
            strategies[i].params.stableRateSlope2 = currentStrategyData.stableRateSlope2;
          }
        }
      }

      Rates.RateStrategyParams[] memory ratesParams = _formatStrategies(strategies);
      address[] memory strategiesAddresses = RATE_STRATEGIES_FACTORY.createStrategies(ratesParams);

      for (uint256 i = 0; i < strategies.length; i++) {
        POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(strategies[i].asset, strategiesAddresses[i]);
      }
    }

    _postExecute();
  }

  /** @dev Converts basis points to RAY units
   * e.g. 10_00 (10.00%) will return 100000000000000000000000000
   */
  function _bpsToRay(uint256 amount) internal pure returns (uint256) {
    return (amount * WadRayMath.RAY) / 10_000;
  }

  function _formatStrategies(RateStrategyUpdate[] memory strategies) internal pure returns (Rates.RateStrategyParams[] memory) {
    Rates.RateStrategyParams[] memory ratesParams = new Rates.RateStrategyParams[](strategies.length);
    for (uint256 i = 0; i < strategies.length; i++) {
      ratesParams[i] = strategies[i].params;
    }
    return ratesParams;
  }

  /// @dev to be defined in the child with a list of set of parameters of rate strategies
  function updateRateStrategies()
    public
    view
    virtual
    returns (RateStrategyUpdate[] memory updates)
  {}

}
