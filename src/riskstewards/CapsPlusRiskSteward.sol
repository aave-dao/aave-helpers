// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IACLManager, IPoolConfigurator, IPoolDataProvider} from 'aave-address-book/AaveV3.sol';
import {Address} from 'solidity-utils/contracts/oz-common/Address.sol';
import {EngineFlags} from '../v3-config-engine/EngineFlags.sol';
import {IAaveV3ConfigEngine} from '../v3-config-engine/IAaveV3ConfigEngine.sol';

library CapsPlusRiskStewardErrors {
  string public constant INVALID_CALLER = 'INVALID_CALLER';
  string public constant NOT_STICTLY_HIGHER = 'NOT_STICTLY_HIGHER';
  string public constant DECOUNCE_NOT_RESPECTED = 'DECOUNCE_NOT_RESPECTED';
  string public constant UPDATE_BIGGER_MAX = 'UPDATE_BIGGER_MAX';
  string public constant ZERO_UPDATES = 'ZERO_UPDATES';
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
    require(capUpdates.length > 0, CapsPlusRiskStewardErrors.ZERO_UPDATES);
    for (uint256 i = 0; i < capUpdates.length; i++) {
      (uint256 currentBorrowCap, uint256 currentSupplyCap) = POOL_DATA_PROVIDER.getReserveCaps(
        capUpdates[i].asset
      );
      Debounce memory debounce = timelocks[capUpdates[i].asset];
      if (capUpdates[i].supplyCap != EngineFlags.KEEP_CURRENT) {
        require(
          capUpdates[i].supplyCap > currentSupplyCap,
          CapsPlusRiskStewardErrors.NOT_STICTLY_HIGHER
        );
        require(
          block.timestamp - debounce.supplyCapLastUpdated > MINIMUM_DELAY,
          CapsPlusRiskStewardErrors.DECOUNCE_NOT_RESPECTED
        );
        require(
          capsIncreaseWithinAllowedRange(currentSupplyCap, capUpdates[i].supplyCap),
          CapsPlusRiskStewardErrors.UPDATE_BIGGER_MAX
        );
        timelocks[capUpdates[i].asset].supplyCapLastUpdated = uint40(block.timestamp);
      }
      if (capUpdates[i].borrowCap != EngineFlags.KEEP_CURRENT) {
        require(
          capUpdates[i].borrowCap > currentBorrowCap,
          CapsPlusRiskStewardErrors.NOT_STICTLY_HIGHER
        );
        require(
          block.timestamp - debounce.borrowCapLastUpdated > MINIMUM_DELAY,
          CapsPlusRiskStewardErrors.DECOUNCE_NOT_RESPECTED
        );
        require(
          capsIncreaseWithinAllowedRange(currentBorrowCap, capUpdates[i].borrowCap),
          CapsPlusRiskStewardErrors.UPDATE_BIGGER_MAX
        );
        timelocks[capUpdates[i].asset].borrowCapLastUpdated = uint40(block.timestamp);
      }
    }
    address(CONFIG_ENGINE).functionDelegateCall(
      abi.encodeWithSelector(CONFIG_ENGINE.updateCaps.selector, capUpdates)
    );
  }

  /**
   * Ensures the cap increase is within the allowed range.
   * @param from current cap
   * @param to new cap
   * @return bool true, if difference is within the max 100% increase window
   */
  function capsIncreaseWithinAllowedRange(uint256 from, uint256 to) public pure returns (bool) {
    return to - from <= from;
  }
}
