// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../src/v2-config-engine/AaveV2Payload.sol';
import {AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';

/**
 * @dev Smart contract for a mock rates update, for testing purposes
 * IMPORTANT Parameters are pseudo-random, DON'T USE THIS ANYHOW IN PRODUCTION
 * @author BGD Labs
 */
contract AaveV2EthereumRatesUpdate is AaveV2Payload {
  constructor(IEngine customEngine) AaveV2Payload(customEngine) {}

  function rateStrategiesUpdates()
    public
    pure
    override
    returns (IEngine.RateStrategyUpdate[] memory)
  {
    IEngine.RateStrategyUpdate[] memory rateStrategy = new IEngine.RateStrategyUpdate[](1);

    rateStrategy[0] = IEngine.RateStrategyUpdate({
      asset: AaveV2EthereumAssets.USDC_UNDERLYING,
      params: IV2RateStrategyFactory.RateStrategyParams({
        optimalUtilizationRate: _bpsToRay(69_00),
        baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
        variableRateSlope1: _bpsToRay(42_00),
        variableRateSlope2: EngineFlags.KEEP_CURRENT,
        stableRateSlope1: _bpsToRay(69_00),
        stableRateSlope2: EngineFlags.KEEP_CURRENT
      })
    });

    return rateStrategy;
  }
}
