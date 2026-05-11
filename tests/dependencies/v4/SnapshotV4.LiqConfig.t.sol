// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'tests/dependencies/v4/SnapshotV4Base.t.sol';

contract SnapshotV4LiqConfigTest is SnapshotV4BaseTest {
  // First liq-config fixture: spokeA. Used as the mutation target.
  uint256 internal constant TARGET_IDX = 0;

  /// @dev All liq config fixtures match the snapshot array.
  function test_createV4Snapshot_liquidationConfigs() public view {
    assertEq(_createV4Snapshot().spokeLiquidationConfigs, _liqConfigFixtures);
  }

  /// @dev Mutating targetHealthFactor propagates.
  function test_delta_targetHealthFactor() public {
    LiqConfigFixture memory t = _targetLiqConfig();
    uint128 newVal = uint128(uint256(t.targetHealthFactor) * 2 + 1);
    t.spoke.setLiquidationConfig(
      ISpoke.LiquidationConfig({
        targetHealthFactor: newVal,
        healthFactorForMaxBonus: t.healthFactorForMaxBonus,
        liquidationBonusFactor: t.liquidationBonusFactor
      })
    );
    assertEq(
      _createV4Snapshot().spokeLiquidationConfigs[TARGET_IDX].targetHealthFactor,
      uint256(newVal),
      'targetHealthFactor'
    );
  }

  /// @dev Mutating healthFactorForMaxBonus propagates.
  function test_delta_healthFactorForMaxBonus() public {
    LiqConfigFixture memory t = _targetLiqConfig();
    uint64 newVal = uint64(uint256(t.healthFactorForMaxBonus) - 1);
    t.spoke.setLiquidationConfig(
      ISpoke.LiquidationConfig({
        targetHealthFactor: t.targetHealthFactor,
        healthFactorForMaxBonus: newVal,
        liquidationBonusFactor: t.liquidationBonusFactor
      })
    );
    assertEq(
      _createV4Snapshot().spokeLiquidationConfigs[TARGET_IDX].healthFactorForMaxBonus,
      uint256(newVal),
      'healthFactorForMaxBonus'
    );
  }

  /// @dev Mutating liquidationBonusFactor propagates.
  function test_delta_liquidationBonusFactor() public {
    LiqConfigFixture memory t = _targetLiqConfig();
    uint16 newVal = t.liquidationBonusFactor + 50;
    t.spoke.setLiquidationConfig(
      ISpoke.LiquidationConfig({
        targetHealthFactor: t.targetHealthFactor,
        healthFactorForMaxBonus: t.healthFactorForMaxBonus,
        liquidationBonusFactor: newVal
      })
    );
    assertEq(
      uint256(_createV4Snapshot().spokeLiquidationConfigs[TARGET_IDX].liquidationBonusFactor),
      uint256(newVal),
      'liquidationBonusFactor'
    );
  }

  /// @dev Mutating maxUserReservesLimit propagates.
  function test_delta_maxUserReservesLimit() public {
    LiqConfigFixture memory t = _targetLiqConfig();
    uint16 newVal = t.maxUserReservesLimit + 1;
    t.spoke.setMaxUserReservesLimit(newVal);
    assertEq(
      uint256(_createV4Snapshot().spokeLiquidationConfigs[TARGET_IDX].maxUserReservesLimit),
      uint256(newVal),
      'maxUserReservesLimit'
    );
  }

  function _targetLiqConfig() internal view returns (LiqConfigFixture memory) {
    return _liqConfigFixtures[TARGET_IDX];
  }
}
