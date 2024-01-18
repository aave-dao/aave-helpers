// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Ethereum} from 'aave-address-book/AaveAddressBook.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {IDefaultInterestRateStrategy} from 'aave-address-book/AaveV3.sol';
import {V3RateStrategyFactory, IV3RateStrategyFactory} from '../../src/v3-config-engine/V3RateStrategyFactory.sol';
import '../../src/ProtocolV3TestBase.sol';

contract V3RateStrategyFactoryTest is ProtocolV3TestBase {
  using stdStorage for StdStorage;
  V3RateStrategyFactory rateStrategyFactory;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 19036639);
    rateStrategyFactory = new V3RateStrategyFactory(AaveV3Ethereum.POOL_ADDRESSES_PROVIDER);
  }

  function testCreateStrategies() public {
    IDefaultInterestRateStrategy strategy = IDefaultInterestRateStrategy(
      AaveV3EthereumAssets.AAVE_INTEREST_RATE_STRATEGY
    );

    InterestStrategyValues memory expectedStrategyValues = InterestStrategyValues({
      addressesProvider: address(AaveV3Ethereum.POOL_ADDRESSES_PROVIDER),
      optimalUsageRatio: strategy.OPTIMAL_USAGE_RATIO(),
      baseVariableBorrowRate: strategy.getBaseVariableBorrowRate(),
      variableRateSlope1: strategy.getVariableRateSlope1(),
      variableRateSlope2: strategy.getVariableRateSlope2(),
      stableRateSlope1: strategy.getStableRateSlope1(),
      stableRateSlope2: strategy.getStableRateSlope2(),
      baseStableBorrowRate: strategy.getBaseStableBorrowRate(),
      optimalStableToTotalDebtRatio: strategy.OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO()
    });

    IV3RateStrategyFactory.RateStrategyParams[]
      memory rateStrategyParams = new IV3RateStrategyFactory.RateStrategyParams[](1);

    rateStrategyParams[0] = IV3RateStrategyFactory.RateStrategyParams({
      optimalUsageRatio: expectedStrategyValues.optimalUsageRatio,
      baseVariableBorrowRate: expectedStrategyValues.baseVariableBorrowRate,
      variableRateSlope1: expectedStrategyValues.variableRateSlope1,
      variableRateSlope2: expectedStrategyValues.variableRateSlope2,
      stableRateSlope1: expectedStrategyValues.stableRateSlope1,
      stableRateSlope2: expectedStrategyValues.stableRateSlope2,
      baseStableRateOffset: (expectedStrategyValues.baseStableBorrowRate > 0)
        ? (expectedStrategyValues.baseStableBorrowRate - expectedStrategyValues.variableRateSlope1)
        : 0,
      stableRateExcessOffset: strategy.getStableRateExcessOffset(),
      optimalStableToTotalDebtRatio: expectedStrategyValues.optimalStableToTotalDebtRatio
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

  function test_multipleCreateStrategies() public {
    IDefaultInterestRateStrategy strategy = IDefaultInterestRateStrategy(
      AaveV3EthereumAssets.USDT_INTEREST_RATE_STRATEGY
    );

    IV3RateStrategyFactory.RateStrategyParams[]
      memory rateStrategyParams = new IV3RateStrategyFactory.RateStrategyParams[](1);
    rateStrategyParams[0] = IV3RateStrategyFactory.RateStrategyParams({
      optimalUsageRatio: strategy.OPTIMAL_USAGE_RATIO(),
      baseVariableBorrowRate: strategy.getBaseVariableBorrowRate(),
      variableRateSlope1: strategy.getVariableRateSlope1(),
      variableRateSlope2: strategy.getVariableRateSlope2(),
      stableRateSlope1: strategy.getStableRateSlope1(),
      stableRateSlope2: strategy.getStableRateSlope2(),
      baseStableRateOffset: (strategy.getBaseStableBorrowRate() > 0)
        ? (strategy.getBaseStableBorrowRate() - strategy.getVariableRateSlope1())
        : 0,
      stableRateExcessOffset: strategy.getStableRateExcessOffset(),
      optimalStableToTotalDebtRatio: strategy.OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO()
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
