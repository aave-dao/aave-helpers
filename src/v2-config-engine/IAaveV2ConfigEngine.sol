// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ILendingPoolConfigurator} from 'aave-address-book/AaveV2.sol';
import {IV2RateStrategyFactory} from './IV2RateStrategyFactory.sol';

/// @dev Examples here assume the usage of the `AaveV2Payload` base contracts
/// contained in this same repository
interface IAaveV2ConfigEngine {
  /**
   * @dev Example (mock):
   * PoolContext({
   *   networkName: 'Polygon',
   *   networkAbbreviation: 'Pol'
   * })
   */
  struct PoolContext {
    string networkName;
    string networkAbbreviation;
  }

  /**
   * @dev Example (mock):
   * RateStrategyUpdate({
   *   asset: AaveV2EthereumAssets.AAVE_UNDERLYING,
   *   params: IV2RateStrategyFactory.RateStrategyParams({
   *     optimalUtilizationRate: _bpsToRay(80_00),
   *     baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
   *     variableRateSlope1: EngineFlags.KEEP_CURRENT,
   *     variableRateSlope2: _bpsToRay(75_00),
   *     stableRateSlope1: EngineFlags.KEEP_CURRENT,
   *     stableRateSlope2: _bpsToRay(75_00),
   *   })
   * })
   */
  struct RateStrategyUpdate {
    address asset;
    IV2RateStrategyFactory.RateStrategyParams params;
  }

  /**
   * @notice Performs an update on the rate strategy params of the assets, in the Aave pool configured in this engine instance
   * @dev The engine itself manages if a new rate strategy needs to be deployed or if an existing one can be re-used
   * @param updates `RateStrategyUpdate[]` list of declarative updates containing the new rate strategy params
   *   More information on the documentation of the struct.
   */
  function updateRateStrategies(RateStrategyUpdate[] memory updates) external;

  function RATE_STRATEGIES_FACTORY() external view returns (IV2RateStrategyFactory);

  function POOL_CONFIGURATOR() external view returns (ILendingPoolConfigurator);
}
