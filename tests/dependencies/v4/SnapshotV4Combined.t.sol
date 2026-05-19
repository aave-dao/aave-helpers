// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'tests/dependencies/v4/SnapshotV4Base.t.sol';

contract SnapshotV4CombinedTest is SnapshotV4BaseTest {
  // Override the base setUp: deploy mocks only and let each test selectively
  // call `_addFixtures()` for partial-config and delta scenarios.
  function setUp() public override {
    _deployMocks();
    _setSpokeOracles();
  }

  /// @dev Empty spokes and hubs produce an all-empty snapshot.
  function test_createV4Snapshot_emptyInputs() public view {
    ISpoke[] memory spokes = new ISpoke[](0);
    IHub[] memory hubs = new IHub[](0);
    Types.V4Snapshot memory snap = createV4Snapshot(spokes, hubs);
    assertEq(snap.spokeReserves.length, 0, 'empty reserves');
    assertEq(snap.spokeLiquidationConfigs.length, 0, 'empty liq');
    assertEq(snap.hubAssets.length, 0, 'empty hubAssets');
    assertEq(snap.spokeConfigs.length, 0, 'empty caps');
  }

  /// @dev Adding only reserves leaves hub assets and spoke configs empty.
  function test_partial_reservesOnly() public {
    _addReserveFixtures();
    Types.V4Snapshot memory snap = _createV4Snapshot();
    assertEq(snap.spokeReserves, _reserveFixtures);
    assertEq(snap.hubAssets.length, 0, 'hub assets should be empty');
    assertEq(snap.spokeConfigs.length, 0, 'spoke caps should be empty');
  }

  /// @dev Adding only hub assets leaves reserves and spoke configs empty.
  function test_partial_hubAssetsOnly() public {
    _addHubAssetFixtures();
    _configureIRStrategies();
    Types.V4Snapshot memory snap = _createV4Snapshot();
    assertEq(snap.hubAssets, _hubAssetFixtures);
    assertEq(snap.spokeReserves.length, 0, 'reserves should be empty');
    assertEq(snap.spokeConfigs.length, 0, 'spoke caps should be empty');
  }

  /// @dev Hub assets without registered spoke configs produce empty spokeConfigs.
  function test_partial_hubAssetsNoSpokeConfigs() public {
    _addHubAssetFixtures();
    _configureIRStrategies();
    Types.V4Snapshot memory snap = _createV4Snapshot();
    assertEq(snap.hubAssets.length, _hubAssetFixtures.length, 'hub assets populated');
    assertEq(snap.spokeConfigs.length, 0, 'no spoke configs registered');
  }

  /// @dev Adding only liq configs leaves other sections empty.
  function test_partial_liqConfigsOnly() public {
    _addLiqConfigFixtures();
    Types.V4Snapshot memory snap = _createV4Snapshot();
    assertEq(snap.spokeLiquidationConfigs, _liqConfigFixtures);
    assertEq(snap.spokeReserves.length, 0, 'reserves should be empty');
    assertEq(snap.hubAssets.length, 0, 'hub assets should be empty');
    assertEq(snap.spokeConfigs.length, 0, 'spoke caps should be empty');
  }

  /// @dev Liq configs are emitted per-spoke regardless of fixture state (zero-default).
  function test_partial_liqConfigsSpokeDriven() public view {
    Types.V4Snapshot memory snap = _createV4Snapshot();
    assertEq(snap.spokeLiquidationConfigs.length, 2, '2 spokes -> 2 liq configs');
    assertEq(
      snap.spokeLiquidationConfigs[0].targetHealthFactor,
      0,
      'default targetHealthFactor is zero'
    );
    assertEq(
      snap.spokeLiquidationConfigs[0].liquidationBonusFactor,
      0,
      'default liquidationBonusFactor is zero'
    );
  }

  /// @dev Mutating one oracle price moves only that reserve's price; other reserves stable.
  function test_delta_oraclePrice() public {
    _addAllFixtures();

    Types.V4Snapshot memory snapA = _createV4Snapshot();

    CachedReserveFixture memory target = _reserveFixtures[0];
    uint256 newPrice = target.input.oraclePrice * 2 + 1;
    target.input.oracle.setReserve(target.reserveId, target.input.priceSource, newPrice);

    Types.V4Snapshot memory snapB = _createV4Snapshot();

    assertEq(snapA.spokeReserves.length, snapB.spokeReserves.length, 'reserves length moved');
    assertEq(snapB.spokeReserves[0].oraclePrice, newPrice, 'price did not update');
    assertTrue(
      snapA.spokeReserves[0].oraclePrice != snapB.spokeReserves[0].oraclePrice,
      'price unchanged'
    );
    for (uint256 i = 1; i < snapB.spokeReserves.length; i++) {
      assertEq(
        snapA.spokeReserves[i].oraclePrice,
        snapB.spokeReserves[i].oraclePrice,
        'unrelated price moved'
      );
    }
    assertEq(
      snapA.spokeReserves[0].underlying,
      snapB.spokeReserves[0].underlying,
      'underlying moved'
    );
    assertEq(snapA.spokeReserves[0].decimals, snapB.spokeReserves[0].decimals, 'decimals moved');
  }

  /// @dev Re-calling addSpokeConfig to flip `halted` moves only that field; array length stable.
  function test_delta_spokeConfigFlag() public {
    _addAllFixtures();

    Types.V4Snapshot memory snapA = _createV4Snapshot();

    SpokeConfigFixture memory orig = _spokeConfigFixtures[0];
    hub.addSpokeConfig(
      orig.assetId,
      address(orig.spoke),
      IHub.SpokeConfig({
        addCap: orig.addCap,
        drawCap: orig.drawCap,
        riskPremiumThreshold: orig.riskPremiumThreshold,
        active: orig.active,
        halted: !orig.halted
      })
    );

    Types.V4Snapshot memory snapB = _createV4Snapshot();

    assertEq(snapA.spokeConfigs.length, snapB.spokeConfigs.length, 'spokeConfigs length moved');
    assertEq(snapB.spokeConfigs[0].halted, !orig.halted, 'halted did not flip');
    assertTrue(snapA.spokeConfigs[0].halted != snapB.spokeConfigs[0].halted, 'halted unchanged');
    assertEq(snapA.spokeConfigs[0].addCap, snapB.spokeConfigs[0].addCap, 'addCap moved');
    assertEq(snapA.spokeConfigs[0].drawCap, snapB.spokeConfigs[0].drawCap, 'drawCap moved');
    assertEq(snapA.spokeConfigs[0].active, snapB.spokeConfigs[0].active, 'active moved');
  }

  /// @dev Mutating IR data moves only the corresponding hub asset's IR fields.
  function test_delta_irData() public {
    _addAllFixtures();

    Types.V4Snapshot memory snapA = _createV4Snapshot();

    uint256 newMaxDrawnRate = 99_999;
    ir0.setData(
      0,
      IAssetInterestRateStrategy.InterestRateData({
        optimalUsageRatio: 8000,
        baseDrawnRate: 100,
        rateGrowthBeforeOptimal: 400,
        rateGrowthAfterOptimal: 6000
      }),
      newMaxDrawnRate
    );

    Types.V4Snapshot memory snapB = _createV4Snapshot();

    assertEq(snapA.hubAssets.length, snapB.hubAssets.length, 'hubAssets length moved');
    assertEq(snapB.hubAssets[0].maxDrawnRate, newMaxDrawnRate, 'maxDrawnRate did not update');
    assertTrue(
      snapA.hubAssets[0].maxDrawnRate != snapB.hubAssets[0].maxDrawnRate,
      'maxDrawnRate unchanged'
    );
    assertEq(
      snapA.hubAssets[1].maxDrawnRate,
      snapB.hubAssets[1].maxDrawnRate,
      'unrelated IR moved'
    );
    assertEq(snapA.hubAssets[0].underlying, snapB.hubAssets[0].underlying, 'underlying moved');
    assertEq(
      snapA.hubAssets[0].liquidityFee,
      snapB.hubAssets[0].liquidityFee,
      'liquidityFee moved'
    );
  }

  /// @dev Snapshot aggregates assets and configs across multiple hubs in pass order.
  function test_multiHub_aggregates() public {
    _addAllFixtures();

    MockHub hub2 = new MockHub();
    {
      IHub.Asset memory asset;
      asset.underlying = address(usdc);
      asset.decimals = 6;
      asset.liquidityFee = 7;
      asset.irStrategy = address(0);
      asset.reinvestmentController = address(0);
      asset.feeReceiver = feeReceiverA;
      IHub.AssetConfig memory config = IHub.AssetConfig({
        feeReceiver: feeReceiverA,
        liquidityFee: 7,
        irStrategy: address(0),
        reinvestmentController: address(0)
      });
      hub2.addAsset(asset, config);
    }
    hub2.addSpokeConfig(
      0,
      address(spokeA),
      IHub.SpokeConfig({
        addCap: 7_000_000,
        drawCap: 6_000_000,
        riskPremiumThreshold: 700,
        active: true,
        halted: false
      })
    );

    ISpoke[] memory spokes = new ISpoke[](2);
    spokes[0] = ISpoke(address(spokeA));
    spokes[1] = ISpoke(address(spokeB));
    IHub[] memory hubs = new IHub[](2);
    hubs[0] = IHub(address(hub));
    hubs[1] = IHub(address(hub2));
    Types.V4Snapshot memory snap = createV4Snapshot(spokes, hubs);

    assertEq(snap.hubAssets.length, _hubAssetFixtures.length + 1, 'hubAssets aggregated');
    assertEq(snap.spokeConfigs.length, _spokeConfigFixtures.length + 1, 'spokeConfigs aggregated');

    assertEq(snap.hubAssets[0].hubAddress, address(hub), 'first asset from hub1');
    assertEq(
      snap.hubAssets[snap.hubAssets.length - 1].hubAddress,
      address(hub2),
      'last asset from hub2'
    );
    assertEq(snap.spokeConfigs[0].hubAddress, address(hub), 'first cap from hub1');
    assertEq(
      snap.spokeConfigs[snap.spokeConfigs.length - 1].hubAddress,
      address(hub2),
      'last cap from hub2'
    );

    Types.SpokeConfigSnapshot memory hub2Cap = snap.spokeConfigs[snap.spokeConfigs.length - 1];
    assertEq(hub2Cap.assetId, 0, 'hub2 cap assetId');
    assertEq(hub2Cap.spokeAddress, address(spokeA), 'hub2 cap spoke');
    assertEq(uint256(hub2Cap.addCap), 7_000_000, 'hub2 addCap');
    assertEq(uint256(hub2Cap.drawCap), 6_000_000, 'hub2 drawCap');
  }

  function _addAllFixtures() internal {
    _addLiqConfigFixtures();
    _addReserveFixtures();
    _addHubAssetFixtures();
    _configureIRStrategies();
    _addSpokeConfigFixtures();
  }
}
