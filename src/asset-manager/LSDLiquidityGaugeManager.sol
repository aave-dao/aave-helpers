// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ILiquidityGaugeController} from './interfaces/ILiquidityGaugeController.sol';
import {Common} from './Common.sol';

/// @author Llama
abstract contract LSDLiquidityGaugeManager is Common {
  event GaugeControllerChanged(address indexed oldController, address indexed newController);
  event GaugeVote(address indexed gauge, uint256 amount);

  /// @notice Setting to the same controller address as currently set.
  error SameController();

  /// @notice Address of LSD Gauge Controller
  address public gaugeControllerBalancer;

  /// @notice Set the gauge controller used for gauge weight voting
  /// @param _gaugeController The gauge controller address
  function setGaugeController(address _gaugeController) public onlyOwnerOrGuardian {
    if (_gaugeController == address(0)) revert InvalidZeroAddress();

    address oldController = gaugeControllerBalancer;
    if (oldController == _gaugeController) revert SameController();

    gaugeControllerBalancer = _gaugeController;

    emit GaugeControllerChanged(oldController, gaugeControllerBalancer);
  }

  /// @notice Vote for a gauge's weight
  /// @param gauge the address of the gauge to vote for
  /// @param weight the weight of gaugeAddress in basis points [0, 10.000]
  function voteForGaugeWeight(address gauge, uint256 weight) external onlyOwnerOrGuardian {
    if (gauge == address(0)) revert InvalidZeroAddress();

    ILiquidityGaugeController(gaugeControllerBalancer).vote_for_gauge_weights(gauge, weight);
    emit GaugeVote(gauge, weight);
  }
}
