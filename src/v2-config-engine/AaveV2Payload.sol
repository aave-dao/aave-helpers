// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Address} from 'solidity-utils/contracts/oz-common/Address.sol';
import {WadRayMath} from 'aave-v3-origin/contracts/protocol/libraries/math/WadRayMath.sol';
import {IAaveV2ConfigEngine as IEngine} from './IAaveV2ConfigEngine.sol';
import {IV2RateStrategyFactory} from './IV2RateStrategyFactory.sol';
import {EngineFlags} from 'aave-v3-origin/contracts/extensions/v3-config-engine/EngineFlags.sol';

/**
 * @dev Base smart contract for an Aave v3.0.1 configs update.
 * - Assumes this contract has the right permissions
 * - Connected to a IAaveV2ConfigEngine engine contact, which abstract the complexities of
 *   interaction with the Aave protocol.
 * - At the moment covering:
 *    Updates of interest rate strategies.
 * @author BGD Labs
 */
abstract contract AaveV2Payload {
  using Address for address;

  IEngine public immutable LISTING_ENGINE;

  constructor(IEngine engine) {
    LISTING_ENGINE = engine;
  }

  /// @dev to be overridden on the child if any extra logic is needed pre-listing
  function _preExecute() internal virtual {}

  /// @dev to be overridden on the child if any extra logic is needed post-listing
  function _postExecute() internal virtual {}

  function execute() external {
    _preExecute();

    IEngine.RateStrategyUpdate[] memory rates = rateStrategiesUpdates();

    if (rates.length != 0) {
      address(LISTING_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(LISTING_ENGINE.updateRateStrategies.selector, rates)
      );
    }

    _postExecute();
  }

  /** @dev Converts basis points to RAY units
   * e.g. 10_00 (10.00%) will return 100000000000000000000000000
   */
  function _bpsToRay(uint256 amount) internal pure returns (uint256) {
    return (amount * WadRayMath.RAY) / 10_000;
  }

  /// @dev to be defined in the child with a list of set of parameters of rate strategies
  function rateStrategiesUpdates()
    public
    view
    virtual
    returns (IEngine.RateStrategyUpdate[] memory)
  {}
}
