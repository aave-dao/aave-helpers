// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {IDefaultInterestRateStrategy} from 'aave-address-book/AaveV2.sol';
import {V2RateStrategyFactory, IV2RateStrategyFactory} from '../../src/v2-config-engine/V2RateStrategyFactory.sol';
import '../../src/ProtocolV2TestBase.sol';

contract V2RateStrategyFactoryTest is ProtocolV2TestBase {
  using stdStorage for StdStorage;
  V2RateStrategyFactory public rateStrategyFactory;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 16613098);
    rateStrategyFactory = new V2RateStrategyFactory(AaveV2Ethereum.POOL_ADDRESSES_PROVIDER);
  }

  function testCreateStrategies() public {
    address strategyAddress = AaveV2Ethereum
      .POOL
      .getReserveData(AaveV2EthereumAssets.AAVE_UNDERLYING)
      .interestRateStrategyAddress;
    IDefaultInterestRateStrategy strategy = IDefaultInterestRateStrategy(strategyAddress);

    InterestStrategyValues memory expectedStrategyValues = InterestStrategyValues({
      addressesProvider: address(AaveV2Ethereum.POOL_ADDRESSES_PROVIDER),
      optimalUsageRatio: strategy.OPTIMAL_UTILIZATION_RATE(), // TODO: Fix to optimalUtilizationRate
      baseVariableBorrowRate: strategy.baseVariableBorrowRate(),
      variableRateSlope1: strategy.variableRateSlope1(),
      variableRateSlope2: strategy.variableRateSlope2(),
      stableRateSlope1: strategy.stableRateSlope1(),
      stableRateSlope2: strategy.stableRateSlope2()
    });

    IV2RateStrategyFactory.RateStrategyParams[]
      memory rateStrategyParams = new IV2RateStrategyFactory.RateStrategyParams[](1);

    rateStrategyParams[0] = IV2RateStrategyFactory.RateStrategyParams({
      optimalUtilizationRate: expectedStrategyValues.optimalUsageRatio,
      baseVariableBorrowRate: expectedStrategyValues.baseVariableBorrowRate,
      variableRateSlope1: expectedStrategyValues.variableRateSlope1,
      variableRateSlope2: expectedStrategyValues.variableRateSlope2,
      stableRateSlope1: expectedStrategyValues.stableRateSlope1,
      stableRateSlope2: expectedStrategyValues.stableRateSlope2
    });

    address[] memory createdStrategyAddresses = rateStrategyFactory.createStrategies(
      rateStrategyParams
    );

    _validateInterestRateStrategy(
      createdStrategyAddresses[0],
      createdStrategyAddresses[0],
      expectedStrategyValues
    );
  }

  function testMultipleCreateStrategies() public {
    address strategyAddress = AaveV2Ethereum
      .POOL
      .getReserveData(AaveV2EthereumAssets.USDC_UNDERLYING)
      .interestRateStrategyAddress;
    IDefaultInterestRateStrategy strategy = IDefaultInterestRateStrategy(strategyAddress);

    IV2RateStrategyFactory.RateStrategyParams[]
      memory rateStrategyParams = new IV2RateStrategyFactory.RateStrategyParams[](1);
    rateStrategyParams[0] = IV2RateStrategyFactory.RateStrategyParams({
      optimalUtilizationRate: strategy.OPTIMAL_UTILIZATION_RATE(),
      baseVariableBorrowRate: strategy.baseVariableBorrowRate(),
      variableRateSlope1: strategy.variableRateSlope1(),
      variableRateSlope2: strategy.variableRateSlope2(),
      stableRateSlope1: strategy.stableRateSlope1(),
      stableRateSlope2: strategy.stableRateSlope2()
    });

    address[] memory createdStrategyAddresses = rateStrategyFactory.createStrategies(
      rateStrategyParams
    );

    address[] memory expectedStrategyAddresses = rateStrategyFactory.createStrategies(
      rateStrategyParams
    );

    // Asserts multiple strategies with same params created to have the same address
    assertEq(createdStrategyAddresses, expectedStrategyAddresses);
  }
}
