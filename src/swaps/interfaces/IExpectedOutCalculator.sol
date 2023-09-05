// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity 0.8.19;

interface IExpectedOutCalculator {
  function getExpectedOut(
    uint256 _amountIn,
    address _fromToken,
    address _toToken,
    bytes calldata _data
  ) external view returns (uint256);
}

interface IPriceChecker {
  function EXPECTED_OUT_CALCULATOR() external view returns (IExpectedOutCalculator);
}
