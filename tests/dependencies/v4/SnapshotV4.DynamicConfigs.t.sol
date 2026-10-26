// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'tests/dependencies/v4/SnapshotV4Base.t.sol';
import {ISpoke} from 'aave-address-book/AaveV4.sol';

/// @dev Regression tests for historical DynamicReserveConfig keys in the snapshot/diff
/// pipeline. A risk steward can mutate an old key in place (`updateDynamicReserveConfig`
/// on a key below `reserve.dynamicConfigKey`), which changes risk params for every user
/// position still anchored to that key without touching the reserve's latest config.
/// Such a change must surface in the snapshot and in the rendered markdown diff.
contract SnapshotV4DynamicConfigsTest is SnapshotV4BaseTest {
  string internal constant REPORT = 'v4_dynconfig_oldkey_test';

  // USDC on spokeA, reserveId 0. Fixture pins its latest key to 1 (see
  // `_addReserveFixtures`), leaving key 0 free to act as the historical key.
  uint256 internal constant TARGET_IDX = 0;
  uint16 internal constant TARGET_RESERVE_ID = 0;
  uint32 internal constant OLD_KEY = 0;

  function setUp() public override {
    super.setUp();
    vm.chainId(1);
    // Populate the historical key. The mock's addReserve only writes the latest key.
    spokeA.setDynamicReserveConfig(
      TARGET_RESERVE_ID,
      OLD_KEY,
      ISpoke.DynamicReserveConfig({
        collateralFactor: 7000,
        maxLiquidationBonus: 10200,
        liquidationFee: 50
      })
    );
  }

  /// @dev The snapshot records every historical key, not just the latest one.
  function test_snapshot_capturesAllDynamicConfigKeys() public view {
    Types.SpokeReserveSnapshot memory snap = _createV4Snapshot().spokeReserves[TARGET_IDX];

    assertEq(snap.dynamicConfigs.length, 2, 'both keys captured');
    assertEq(uint256(snap.dynamicConfigs[0].key), uint256(OLD_KEY), 'old key');
    assertEq(uint256(snap.dynamicConfigs[0].collateralFactor), 7000, 'old key CF');
    assertEq(uint256(snap.dynamicConfigs[1].key), 1, 'latest key');
    assertEq(uint256(snap.dynamicConfigs[1].collateralFactor), 7500, 'latest key CF');
  }

  /// @dev Updating a historical key in place — the latest key untouched — must show up
  /// in the markdown diff produced by the full JSON + FFI pipeline.
  function test_diff_showsUpdateToOldDynamicConfigKey() public {
    Types.V4Snapshot memory before = _createV4Snapshot();
    writeV4SnapshotJson(string.concat(REPORT, '_before'), before);

    // Risk-steward style in-place update of the historical key only.
    spokeA.setDynamicReserveConfig(
      TARGET_RESERVE_ID,
      OLD_KEY,
      ISpoke.DynamicReserveConfig({
        collateralFactor: 6000,
        maxLiquidationBonus: 10200,
        liquidationFee: 50
      })
    );

    Types.V4Snapshot memory afterSnap = _createV4Snapshot();
    writeV4SnapshotJson(string.concat(REPORT, '_after'), afterSnap);

    // The reserve's latest-key view is unchanged — only the historical entry moved.
    assertEq(
      uint256(afterSnap.spokeReserves[TARGET_IDX].collateralFactor),
      uint256(before.spokeReserves[TARGET_IDX].collateralFactor),
      'latest-key CF untouched'
    );
    assertEq(uint256(afterSnap.spokeReserves[TARGET_IDX].dynamicConfigs[0].collateralFactor), 6000);

    diffV4Snapshots(REPORT);

    string memory md = vm.readFile(
      string.concat('./diffs/', REPORT, '_before_', REPORT, '_after.md')
    );

    assertTrue(vm.contains(md, '## Spoke Reserve Changes'), 'spoke reserve section');
    assertTrue(vm.contains(md, '**dynamicConfigs**'), 'dynamicConfigs block');
    assertTrue(vm.contains(md, string.concat('| key ', vm.toString(OLD_KEY), ' |')), 'old key row');
    assertTrue(vm.contains(md, '70.00 % [7000]'), 'old key CF before');
    assertTrue(vm.contains(md, '60.00 % [6000]'), 'old key CF after');

    _cleanup();
  }

  function _cleanup() internal {
    string memory beforePath = string.concat('./reports/', REPORT, '_before.json');
    string memory afterPath = string.concat('./reports/', REPORT, '_after.json');
    string memory diffPath = string.concat('./diffs/', REPORT, '_before_', REPORT, '_after.md');
    if (vm.exists(beforePath)) vm.removeFile(beforePath);
    if (vm.exists(afterPath)) vm.removeFile(afterPath);
    if (vm.exists(diffPath)) vm.removeFile(diffPath);
  }
}
