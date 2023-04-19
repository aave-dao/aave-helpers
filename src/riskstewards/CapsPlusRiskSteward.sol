// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IACLManager, IPoolConfigurator, IPoolDataProvider} from 'aave-address-book/AaveV3.sol';
import {Address} from 'solidity-utils/contracts/oz-common/Address.sol';
import {EngineFlags} from '../v3-config-engine/EngineFlags.sol';
import {IAaveV3ConfigEngine} from '../v3-config-engine/IAaveV3ConfigEngine.sol';

library CapsPlusRiskStewardErrors {
  /**
   * @notice Only the permissioned council is allowed to call methods on the steward.
   */
  string public constant INVALID_CALLER = 'INVALID_CALLER';
  /**
   * @notice The steward only allows cap increases.
   */
  string public constant NOT_STRICTLY_HIGHER = 'NOT_STRICTLY_HIGHER';
  /**
   * @notice A single cap can only be increased once every 5 days
   */
  string public constant DEBOUNCE_NOT_RESPECTED = 'DEBOUNCE_NOT_RESPECTED';
  /**
   * @notice A single cap increase must not increase the cap by more than 100%
   */
  string public constant UPDATE_ABOVE_MAX = 'UPDATE_ABOVE_MAX';
  /**
   * @notice There must be at least one cap update per execution
   */
  string public constant NO_ZERO_UPDATES = 'NO_ZERO_UPDATES';
  /**
   * @notice The steward does allow updates of caps, but not the initialization of non existing caps.
   */
  string public constant NO_CAP_INITIALIZE = 'NO_CAP_INITIALIZE';
}

/**
 * @title CapsPlusRiskSteward
 * @author BGD labs
 * @notice Contract managing caps on an aave v3 pool
 */
contract CapsPlusRiskSteward {
  using Address for address;
  struct Debounce {
    uint40 supplyCapLastUpdated;
    uint40 borrowCapLastUpdated;
  }

  uint256 public constant MINIMUM_DELAY = 5 days;

  IAaveV3ConfigEngine public immutable CONFIG_ENGINE;
  IPoolDataProvider public immutable POOL_DATA_PROVIDER;
  address public immutable RISK_COUNCIL;

  mapping(address => Debounce) public timelocks;

  modifier onlyRiskCouncil() {
    require(RISK_COUNCIL == msg.sender, CapsPlusRiskStewardErrors.INVALID_CALLER);
    _;
  }

  constructor(
    IPoolDataProvider poolDataProvider,
    IAaveV3ConfigEngine engine,
    address riskCouncil
  ) {
    POOL_DATA_PROVIDER = poolDataProvider;
    RISK_COUNCIL = riskCouncil;
    CONFIG_ENGINE = engine;
  }

  /**
   * Allows increasing borrow and supply caps accross multiple assets
   * @dev A cap increase is only possible ever 5 days per asset
   * @dev A cap increase is only allowed to increase the cap by 50%
   * @param capUpdates caps to be updated
   */
  function updateCaps(IAaveV3ConfigEngine.CapsUpdate[] memory capUpdates) public onlyRiskCouncil {
    require(capUpdates.length > 0, CapsPlusRiskStewardErrors.NO_ZERO_UPDATES);
    for (uint256 i = 0; i < capUpdates.length; i++) {
      (uint256 currentBorrowCap, uint256 currentSupplyCap) = POOL_DATA_PROVIDER.getReserveCaps(
        capUpdates[i].asset
      );
      Debounce memory debounce = timelocks[capUpdates[i].asset];
      if (capUpdates[i].supplyCap != EngineFlags.KEEP_CURRENT) {
        _validateCapIncrease(
          currentSupplyCap,
          capUpdates[i].supplyCap,
          debounce.supplyCapLastUpdated
        );
        timelocks[capUpdates[i].asset].supplyCapLastUpdated = uint40(block.timestamp);
      }
      if (capUpdates[i].borrowCap != EngineFlags.KEEP_CURRENT) {
        _validateCapIncrease(
          currentBorrowCap,
          capUpdates[i].borrowCap,
          debounce.borrowCapLastUpdated
        );
        timelocks[capUpdates[i].asset].borrowCapLastUpdated = uint40(block.timestamp);
      }
    }
    address(CONFIG_ENGINE).functionDelegateCall(
      abi.encodeWithSelector(CONFIG_ENGINE.updateCaps.selector, capUpdates)
    );
  }

  function _validateCapIncrease(
    uint256 currentCap,
    uint256 newCap,
    uint40 lastUpdated
  ) internal view {
    require(currentCap != 0, CapsPlusRiskStewardErrors.NO_CAP_INITIALIZE);
    require(newCap > currentCap, CapsPlusRiskStewardErrors.NOT_STRICTLY_HIGHER);
    require(
      block.timestamp - lastUpdated > MINIMUM_DELAY,
      CapsPlusRiskStewardErrors.DEBOUNCE_NOT_RESPECTED
    );
    require(
      _capsIncreaseWithinAllowedRange(currentCap, newCap),
      CapsPlusRiskStewardErrors.UPDATE_ABOVE_MAX
    );
  }

  /**
   * Ensures the cap increase is within the allowed range.
   * @param from current cap
   * @param to new cap
   * @return bool true, if difference is within the max 100% increase window
   */
  function _capsIncreaseWithinAllowedRange(uint256 from, uint256 to) internal pure returns (bool) {
    return to - from <= from;
  }
}
