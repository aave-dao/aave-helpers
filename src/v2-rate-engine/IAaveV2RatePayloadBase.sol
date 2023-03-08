// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IV2RateStrategyFactory} from './IV2RateStrategyFactory.sol';

/// @dev Examples here assume the usage of the `AaveV2RatePayloadBase` base contracts
/// contained in this same repository
interface IAaveV2RatePayloadBase {

  /**
   * @dev Example (mock):
   * RateStrategyUpdate({
   *   asset: AaveV2EthereumAssets.AAVE_UNDERLYING,
   *   params: Rates.RateStrategyParams({
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
    * @dev to be defined in the child with a list of set of parameters of rate strategies
    * @return updates `RateStrategyUpdate[]` list of declarative updates containing the new rate strategy params
    *   More information on the documentation of the struct.
    */
   function updateRateStrategies() external view returns (RateStrategyUpdate[] memory updates);

}
