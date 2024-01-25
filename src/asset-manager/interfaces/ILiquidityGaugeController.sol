// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILiquidityGaugeController {
  /// @param gauge_addr The address of the gauge to vote for
  /// @param user_weight Caller's assigned weight to gauge
  function vote_for_gauge_weights(address gauge_addr, uint256 user_weight) external;

  /// @param gauge Address of gauge to get weight assigned by caller
  function get_gauge_weight(address gauge) external view returns (uint256);
}
