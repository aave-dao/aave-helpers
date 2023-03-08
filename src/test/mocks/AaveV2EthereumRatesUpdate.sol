// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../v2-rate-engine/AaveV2RatePayloadBase.sol';
import {AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';

/**
 * @dev Smart contract for a mock rates update, for testing purposes
 * IMPORTANT Parameters are pseudo-random, DON'T USE THIS ANYHOW IN PRODUCTION
 * @author BGD Labs
 */
contract AaveV2EthereumRatesUpdate is AaveV2RatePayloadBase {
  constructor(
    Rates ratesFactory,
    ILendingPoolConfigurator configurator
  ) AaveV2RatePayloadBase(ratesFactory, configurator) {}

  function updateRateStrategies() public pure override returns (RateStrategyUpdate[] memory) {
    RateStrategyUpdate[] memory rateStrategy = new RateStrategyUpdate[](1);

    rateStrategy[0] = RateStrategyUpdate({
      asset: AaveV2EthereumAssets.USDC_UNDERLYING,
      params: Rates.RateStrategyParams({
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
