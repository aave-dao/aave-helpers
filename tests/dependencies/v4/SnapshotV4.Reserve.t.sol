// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'tests/dependencies/v4/SnapshotV4Base.t.sol';

contract SnapshotV4ReserveTest is SnapshotV4BaseTest {
  // First reserve in the fixture set: USDC on spokeA, reserveId 0. Used as the
  // mutation target for all per-field delta tests below.
  uint256 internal constant TARGET_IDX = 0;

  /// @dev All reserve fixtures match the snapshot array.
  function test_createV4Snapshot_spokeReserves() public view {
    assertEq(_createV4Snapshot().spokeReserves, _reserveFixtures);
  }

  // --- ReserveConfig fields ---

  /// @dev Flipping ReserveConfig.paused propagates to the reserve snapshot.
  function test_delta_paused() public {
    CachedReserveFixture memory t = _targetReserve();
    ISpoke.ReserveConfig memory cfg = _buildReserveConfigFrom(t.input);
    cfg.paused = !cfg.paused;
    t.input.spoke.setReserveConfig(t.reserveId, cfg);
    assertEq(_createV4Snapshot().spokeReserves[TARGET_IDX].paused, cfg.paused, 'paused');
  }

  /// @dev Flipping ReserveConfig.frozen propagates.
  function test_delta_frozen() public {
    CachedReserveFixture memory t = _targetReserve();
    ISpoke.ReserveConfig memory cfg = _buildReserveConfigFrom(t.input);
    cfg.frozen = !cfg.frozen;
    t.input.spoke.setReserveConfig(t.reserveId, cfg);
    assertEq(_createV4Snapshot().spokeReserves[TARGET_IDX].frozen, cfg.frozen, 'frozen');
  }

  /// @dev Flipping ReserveConfig.borrowable propagates.
  function test_delta_borrowable() public {
    CachedReserveFixture memory t = _targetReserve();
    ISpoke.ReserveConfig memory cfg = _buildReserveConfigFrom(t.input);
    cfg.borrowable = !cfg.borrowable;
    t.input.spoke.setReserveConfig(t.reserveId, cfg);
    assertEq(
      _createV4Snapshot().spokeReserves[TARGET_IDX].borrowable,
      cfg.borrowable,
      'borrowable'
    );
  }

  /// @dev Flipping ReserveConfig.receiveSharesEnabled propagates.
  function test_delta_receiveSharesEnabled() public {
    CachedReserveFixture memory t = _targetReserve();
    ISpoke.ReserveConfig memory cfg = _buildReserveConfigFrom(t.input);
    cfg.receiveSharesEnabled = !cfg.receiveSharesEnabled;
    t.input.spoke.setReserveConfig(t.reserveId, cfg);
    assertEq(
      _createV4Snapshot().spokeReserves[TARGET_IDX].receiveSharesEnabled,
      cfg.receiveSharesEnabled,
      'receiveSharesEnabled'
    );
  }

  /// @dev Mutating ReserveConfig.collateralRisk propagates.
  function test_delta_collateralRisk() public {
    CachedReserveFixture memory t = _targetReserve();
    ISpoke.ReserveConfig memory cfg = _buildReserveConfigFrom(t.input);
    cfg.collateralRisk = 9_999;
    t.input.spoke.setReserveConfig(t.reserveId, cfg);
    assertEq(
      uint256(_createV4Snapshot().spokeReserves[TARGET_IDX].collateralRisk),
      uint256(cfg.collateralRisk),
      'collateralRisk'
    );
  }

  // --- DynamicReserveConfig fields ---

  /// @dev Mutating DynamicReserveConfig.collateralFactor propagates.
  function test_delta_collateralFactor() public {
    CachedReserveFixture memory t = _targetReserve();
    ISpoke.DynamicReserveConfig memory dyn = _buildDynamicReserveConfigFrom(t.input);
    dyn.collateralFactor = 9_500;
    t.input.spoke.setDynamicReserveConfig(t.reserveId, t.input.dynamicConfigKey, dyn);
    assertEq(
      uint256(_createV4Snapshot().spokeReserves[TARGET_IDX].collateralFactor),
      uint256(dyn.collateralFactor),
      'collateralFactor'
    );
  }

  /// @dev Mutating DynamicReserveConfig.maxLiquidationBonus propagates.
  function test_delta_maxLiquidationBonus() public {
    CachedReserveFixture memory t = _targetReserve();
    ISpoke.DynamicReserveConfig memory dyn = _buildDynamicReserveConfigFrom(t.input);
    dyn.maxLiquidationBonus = 12_345;
    t.input.spoke.setDynamicReserveConfig(t.reserveId, t.input.dynamicConfigKey, dyn);
    assertEq(
      uint256(_createV4Snapshot().spokeReserves[TARGET_IDX].maxLiquidationBonus),
      uint256(dyn.maxLiquidationBonus),
      'maxLiquidationBonus'
    );
  }

  /// @dev Mutating DynamicReserveConfig.liquidationFee propagates.
  function test_delta_liquidationFee() public {
    CachedReserveFixture memory t = _targetReserve();
    ISpoke.DynamicReserveConfig memory dyn = _buildDynamicReserveConfigFrom(t.input);
    dyn.liquidationFee = 250;
    t.input.spoke.setDynamicReserveConfig(t.reserveId, t.input.dynamicConfigKey, dyn);
    assertEq(
      uint256(_createV4Snapshot().spokeReserves[TARGET_IDX].liquidationFee),
      uint256(dyn.liquidationFee),
      'liquidationFee'
    );
  }

  // --- Oracle-driven fields ---

  /// @dev Updating the oracle's price for a reserve propagates.
  function test_delta_oraclePrice() public {
    CachedReserveFixture memory t = _targetReserve();
    uint256 newPrice = t.input.oraclePrice * 2 + 1;
    t.input.oracle.setReserve(t.reserveId, t.input.priceSource, newPrice);
    assertEq(_createV4Snapshot().spokeReserves[TARGET_IDX].oraclePrice, newPrice, 'oraclePrice');
  }

  /// @dev Updating the oracle's price source for a reserve propagates.
  function test_delta_priceSource() public {
    CachedReserveFixture memory t = _targetReserve();
    address newSource = makeAddr('NEW_PRICE_SOURCE');
    t.input.oracle.setReserve(t.reserveId, newSource, t.input.oraclePrice);
    assertEq(_createV4Snapshot().spokeReserves[TARGET_IDX].priceSource, newSource, 'priceSource');
  }

  /// @dev Swapping the spoke's oracle reroutes `oracleAddress` for its reserves.
  function test_delta_oracleAddress() public {
    CachedReserveFixture memory t = _targetReserve();
    MockOracle newOracle = new MockOracle();
    newOracle.setReserve(t.reserveId, t.input.priceSource, t.input.oraclePrice);
    t.input.spoke.setOracle(address(newOracle));
    assertEq(
      _createV4Snapshot().spokeReserves[TARGET_IDX].oracleAddress,
      address(newOracle),
      'oracleAddress'
    );
  }

  function _targetReserve() internal view returns (CachedReserveFixture memory) {
    return _reserveFixtures[TARGET_IDX];
  }

  function _buildReserveConfigFrom(
    ReserveFixture memory f
  ) internal pure returns (ISpoke.ReserveConfig memory) {
    return
      ISpoke.ReserveConfig({
        collateralRisk: f.collateralRisk,
        paused: f.paused,
        frozen: f.frozen,
        borrowable: f.borrowable,
        receiveSharesEnabled: f.receiveSharesEnabled
      });
  }

  function _buildDynamicReserveConfigFrom(
    ReserveFixture memory f
  ) internal pure returns (ISpoke.DynamicReserveConfig memory) {
    return
      ISpoke.DynamicReserveConfig({
        collateralFactor: f.collateralFactor,
        maxLiquidationBonus: f.maxLiquidationBonus,
        liquidationFee: f.liquidationFee
      });
  }
}
