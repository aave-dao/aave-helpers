// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ILendingPool} from 'aave-address-book/AaveV2.sol';
import {Initializable} from 'solidity-utils/contracts/transparent-proxy/Initializable.sol';
import {IV2RateStrategyFactory} from './IV2RateStrategyFactory.sol';
import {DefaultReserveInterestRateStrategy} from '../dependencies/DefaultReserveInterestRateStrategy.sol';
import {IDefaultInterestRateStrategy, ILendingPoolAddressesProvider} from 'aave-address-book/AaveV2.sol';

/**
 * @title V2RateStrategyFactory
 * @notice Factory contract to create and keep record of Aave v2 rate strategy contracts
 * @dev Associated to an specific Aave v2 Pool, via its addresses provider
 * @author BGD labs
 */
contract V2RateStrategyFactory is Initializable, IV2RateStrategyFactory {
  ILendingPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  mapping(bytes32 => address) internal _strategyByParamsHash;
  address[] internal _strategies;

  constructor(ILendingPoolAddressesProvider addressesProvider) Initializable() {
    ADDRESSES_PROVIDER = addressesProvider;
  }

  /// @dev Passing a arbitrary list of rate strategies to be registered as if they would have been deployed
  /// from this factory, as they share exactly the same code
  function initialize(IDefaultInterestRateStrategy[] memory liveStrategies) external initializer {
    for (uint256 i = 0; i < liveStrategies.length; i++) {
      RateStrategyParams memory params = getStrategyData(liveStrategies[i]);

      bytes32 hashedParams = strategyHashFromParams(params);

      _strategyByParamsHash[hashedParams] = address(liveStrategies[i]);
      _strategies.push(address(liveStrategies[i]));

      emit RateStrategyCreated(address(liveStrategies[i]), hashedParams, params);
    }
  }

  ///@inheritdoc IV2RateStrategyFactory
  function createStrategies(RateStrategyParams[] memory params) public returns (address[] memory) {
    address[] memory strategies = new address[](params.length);
    for (uint256 i = 0; i < params.length; i++) {
      bytes32 strategyHashedParams = strategyHashFromParams(params[i]);

      address cachedStrategy = _strategyByParamsHash[strategyHashedParams];

      if (cachedStrategy == address(0)) {
        cachedStrategy = address(
          new DefaultReserveInterestRateStrategy(
            ADDRESSES_PROVIDER,
            params[i].optimalUtilizationRate,
            params[i].baseVariableBorrowRate,
            params[i].variableRateSlope1,
            params[i].variableRateSlope2,
            params[i].stableRateSlope1,
            params[i].stableRateSlope2
          )
        );
        _strategyByParamsHash[strategyHashedParams] = cachedStrategy;
        _strategies.push(cachedStrategy);

        emit RateStrategyCreated(cachedStrategy, strategyHashedParams, params[i]);
      }

      strategies[i] = cachedStrategy;
    }

    return strategies;
  }

  ///@inheritdoc IV2RateStrategyFactory
  function strategyHashFromParams(RateStrategyParams memory params) public pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          params.optimalUtilizationRate,
          params.baseVariableBorrowRate,
          params.variableRateSlope1,
          params.variableRateSlope2,
          params.stableRateSlope1,
          params.stableRateSlope2
        )
      );
  }

  ///@inheritdoc IV2RateStrategyFactory
  function getAllStrategies() external view returns (address[] memory) {
    return _strategies;
  }

  ///@inheritdoc IV2RateStrategyFactory
  function getStrategyByParams(RateStrategyParams memory params) external view returns (address) {
    return _strategyByParamsHash[strategyHashFromParams(params)];
  }

  ///@inheritdoc IV2RateStrategyFactory
  function getStrategyDataOfAsset(address asset) external view returns (RateStrategyParams memory) {
    RateStrategyParams memory params;

    IDefaultInterestRateStrategy strategy = IDefaultInterestRateStrategy(
      ILendingPool(ADDRESSES_PROVIDER.getLendingPool())
        .getReserveData(asset)
        .interestRateStrategyAddress
    );

    if (address(strategy) != address(0)) {
      params = getStrategyData(strategy);
    }

    return params;
  }

  ///@inheritdoc IV2RateStrategyFactory
  function getStrategyData(
    IDefaultInterestRateStrategy strategy
  ) public view returns (RateStrategyParams memory) {
    return
      RateStrategyParams({
        optimalUtilizationRate: strategy.OPTIMAL_UTILIZATION_RATE(),
        baseVariableBorrowRate: strategy.baseVariableBorrowRate(),
        variableRateSlope1: strategy.variableRateSlope1(),
        variableRateSlope2: strategy.variableRateSlope2(),
        stableRateSlope1: strategy.stableRateSlope1(),
        stableRateSlope2: strategy.stableRateSlope2()
      });
  }
}
