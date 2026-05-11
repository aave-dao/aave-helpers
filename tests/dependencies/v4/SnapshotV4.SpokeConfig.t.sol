// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'tests/dependencies/v4/SnapshotV4Base.t.sol';

contract SnapshotV4SpokeConfigTest is SnapshotV4BaseTest {
  // First spoke-config fixture: assetId 0 / spokeA. Used as the mutation target.
  uint256 internal constant TARGET_IDX = 0;

  /// @dev All spoke config fixtures match the snapshot array.
  function test_createV4Snapshot_spokeConfigs() public view {
    assertEq(_createV4Snapshot().spokeConfigs, _spokeConfigFixtures);
  }

  /// @dev Updating SpokeConfig.addCap propagates.
  function test_delta_addCap() public {
    SpokeConfigFixture memory t = _targetSpokeConfig();
    IHub.SpokeConfig memory cfg = _newConfigFrom(t);
    cfg.addCap = t.addCap + 7_000;
    hub.addSpokeConfig(t.assetId, address(t.spoke), cfg);
    assertEq(
      uint256(_createV4Snapshot().spokeConfigs[TARGET_IDX].addCap),
      uint256(cfg.addCap),
      'addCap'
    );
  }

  /// @dev Updating SpokeConfig.drawCap propagates.
  function test_delta_drawCap() public {
    SpokeConfigFixture memory t = _targetSpokeConfig();
    IHub.SpokeConfig memory cfg = _newConfigFrom(t);
    cfg.drawCap = t.drawCap + 3_000;
    hub.addSpokeConfig(t.assetId, address(t.spoke), cfg);
    assertEq(
      uint256(_createV4Snapshot().spokeConfigs[TARGET_IDX].drawCap),
      uint256(cfg.drawCap),
      'drawCap'
    );
  }

  /// @dev Updating SpokeConfig.riskPremiumThreshold propagates.
  function test_delta_riskPremiumThreshold() public {
    SpokeConfigFixture memory t = _targetSpokeConfig();
    IHub.SpokeConfig memory cfg = _newConfigFrom(t);
    cfg.riskPremiumThreshold = 555;
    hub.addSpokeConfig(t.assetId, address(t.spoke), cfg);
    assertEq(
      uint256(_createV4Snapshot().spokeConfigs[TARGET_IDX].riskPremiumThreshold),
      uint256(cfg.riskPremiumThreshold),
      'riskPremiumThreshold'
    );
  }

  /// @dev Flipping SpokeConfig.active propagates.
  function test_delta_active() public {
    SpokeConfigFixture memory t = _targetSpokeConfig();
    IHub.SpokeConfig memory cfg = _newConfigFrom(t);
    cfg.active = !cfg.active;
    hub.addSpokeConfig(t.assetId, address(t.spoke), cfg);
    assertEq(_createV4Snapshot().spokeConfigs[TARGET_IDX].active, cfg.active, 'active');
  }

  /// @dev Flipping SpokeConfig.halted propagates.
  function test_delta_halted() public {
    SpokeConfigFixture memory t = _targetSpokeConfig();
    IHub.SpokeConfig memory cfg = _newConfigFrom(t);
    cfg.halted = !cfg.halted;
    hub.addSpokeConfig(t.assetId, address(t.spoke), cfg);
    assertEq(_createV4Snapshot().spokeConfigs[TARGET_IDX].halted, cfg.halted, 'halted');
  }

  /// @dev Re-calling addSpokeConfig for an existing (assetId, spoke) doesn't duplicate the entry.
  function test_delta_reAdd_doesNotDuplicate() public {
    Types.V4Snapshot memory snapA = _createV4Snapshot();
    SpokeConfigFixture memory t = _targetSpokeConfig();
    IHub.SpokeConfig memory cfg = _newConfigFrom(t);
    cfg.halted = !cfg.halted;
    hub.addSpokeConfig(t.assetId, address(t.spoke), cfg);
    Types.V4Snapshot memory snapB = _createV4Snapshot();
    assertEq(snapA.spokeConfigs.length, snapB.spokeConfigs.length, 'no duplicate push');
  }

  function _targetSpokeConfig() internal view returns (SpokeConfigFixture memory) {
    return _spokeConfigFixtures[TARGET_IDX];
  }

  function _newConfigFrom(
    SpokeConfigFixture memory f
  ) internal pure returns (IHub.SpokeConfig memory) {
    return
      IHub.SpokeConfig({
        addCap: f.addCap,
        drawCap: f.drawCap,
        riskPremiumThreshold: f.riskPremiumThreshold,
        active: f.active,
        halted: f.halted
      });
  }
}
