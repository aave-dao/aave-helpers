// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from 'aave-address-book/AaveV3.sol';

interface IDefaultInterestRateStrategyV2 {
  struct InterestRateData {
    uint16 optimalUsageRatio;
    uint32 baseVariableBorrowRate;
    uint32 variableRateSlope1;
    uint32 variableRateSlope2;
  }

  struct InterestRateDataRay {
    uint256 optimalUsageRatio;
    uint256 baseVariableBorrowRate;
    uint256 variableRateSlope1;
    uint256 variableRateSlope2;
  }

  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  function MAX_BORROW_RATE() external view returns (uint256);

  function MIN_OPTIMAL_POINT() external view returns (uint256);

  function MAX_OPTIMAL_POINT() external view returns (uint256);

  function getInterestRateData(address reserve) external view returns (InterestRateDataRay memory);

  function getInterestRateDataBps(address reserve) external view returns (InterestRateData memory);

  function getOptimalUsageRatio(address reserve) external view returns (uint256);

  function getVariableRateSlope1(address reserve) external view returns (uint256);

  function getVariableRateSlope2(address reserve) external view returns (uint256);

  function getBaseVariableBorrowRate(address reserve) external view returns (uint256);

  function getMaxVariableBorrowRate(address reserve) external view returns (uint256);

  function setInterestRateParams(address reserve, InterestRateData calldata rateData) external;
}
