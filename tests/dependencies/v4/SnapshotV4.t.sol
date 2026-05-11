// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'tests/dependencies/v4/SnapshotV4Base.t.sol';

contract SnapshotV4Test is SnapshotV4BaseTest {
  function test_createV4Snapshot_spokeReserves() public view {
    assertEq(_createV4Snapshot().spokeReserves, _reserveFixtures);
  }

  function test_createV4Snapshot_liquidationConfigs() public view {
    assertEq(_createV4Snapshot().spokeLiquidationConfigs, _liqConfigFixtures);
  }

  function test_createV4Snapshot_hubAssets() public view {
    assertEq(_createV4Snapshot().hubAssets, _hubAssetFixtures);
  }

  function test_createV4Snapshot_spokeCaps() public view {
    assertEq(_createV4Snapshot().spokeCaps, _spokeCapFixtures);
  }

  function test_createV4Snapshot_emptyInputs() public view {
    ISpoke[] memory spokes = new ISpoke[](0);
    IHub[] memory hubs = new IHub[](0);
    Types.V4Snapshot memory snap = createV4Snapshot(spokes, hubs);
    assertEq(snap.spokeReserves.length, 0, 'empty reserves');
    assertEq(snap.spokeLiquidationConfigs.length, 0, 'empty liq');
    assertEq(snap.hubAssets.length, 0, 'empty hubAssets');
    assertEq(snap.spokeCaps.length, 0, 'empty caps');
  }
}
