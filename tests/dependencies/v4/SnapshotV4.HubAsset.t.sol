// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'tests/dependencies/v4/SnapshotV4Base.t.sol';

contract SnapshotV4HubAssetTest is SnapshotV4BaseTest {
  // First hub asset: USDC, assetId 0. Used as the mutation target.
  uint256 internal constant TARGET_IDX = 0;

  function test_createV4Snapshot_hubAssets() public view {
    assertEq(_createV4Snapshot().hubAssets, _hubAssetFixtures);
  }

  function test_delta_underlying_andSymbol() public {
    CachedHubAssetFixture memory t = _targetHubAsset();
    IHub.Asset memory asset = _buildAssetFrom(t.input);
    MockERC20Symbol newToken = new MockERC20Symbol('NEW_SYM');
    asset.underlying = address(newToken);
    hub.setAsset(t.assetId, asset);
    Types.V4Snapshot memory snap = _createV4Snapshot();
    assertEq(snap.hubAssets[TARGET_IDX].underlying, address(newToken), 'underlying');
    assertEq(snap.hubAssets[TARGET_IDX].symbol, 'NEW_SYM', 'symbol derives from underlying');
  }

  function test_delta_decimals() public {
    CachedHubAssetFixture memory t = _targetHubAsset();
    IHub.Asset memory asset = _buildAssetFrom(t.input);
    asset.decimals = 18;
    hub.setAsset(t.assetId, asset);
    assertEq(
      uint256(_createV4Snapshot().hubAssets[TARGET_IDX].decimals),
      uint256(asset.decimals),
      'decimals'
    );
  }

  function test_delta_deficitRay() public {
    CachedHubAssetFixture memory t = _targetHubAsset();
    IHub.Asset memory asset = _buildAssetFrom(t.input);
    asset.deficitRay = 999_999;
    hub.setAsset(t.assetId, asset);
    assertEq(
      uint256(_createV4Snapshot().hubAssets[TARGET_IDX].deficitRay),
      uint256(asset.deficitRay),
      'deficitRay'
    );
  }

  function test_delta_swept() public {
    CachedHubAssetFixture memory t = _targetHubAsset();
    IHub.Asset memory asset = _buildAssetFrom(t.input);
    asset.swept = 12_345;
    hub.setAsset(t.assetId, asset);
    assertEq(
      uint256(_createV4Snapshot().hubAssets[TARGET_IDX].swept),
      uint256(asset.swept),
      'swept'
    );
  }

  function test_delta_premiumShares() public {
    CachedHubAssetFixture memory t = _targetHubAsset();
    IHub.Asset memory asset = _buildAssetFrom(t.input);
    asset.premiumShares = 55_555;
    hub.setAsset(t.assetId, asset);
    assertEq(
      uint256(_createV4Snapshot().hubAssets[TARGET_IDX].premiumShares),
      uint256(asset.premiumShares),
      'premiumShares'
    );
  }

  function test_delta_premiumOffsetRay() public {
    CachedHubAssetFixture memory t = _targetHubAsset();
    IHub.Asset memory asset = _buildAssetFrom(t.input);
    asset.premiumOffsetRay = int200(-777);
    hub.setAsset(t.assetId, asset);
    assertEq(
      _createV4Snapshot().hubAssets[TARGET_IDX].premiumOffsetRay,
      asset.premiumOffsetRay,
      'premiumOffsetRay'
    );
  }

  // --- AssetConfig fields ---

  function test_delta_liquidityFee() public {
    CachedHubAssetFixture memory t = _targetHubAsset();
    IHub.AssetConfig memory cfg = _buildAssetConfigFrom(t.input);
    cfg.liquidityFee = 9_999;
    hub.setAssetConfig(t.assetId, cfg);
    assertEq(
      uint256(_createV4Snapshot().hubAssets[TARGET_IDX].liquidityFee),
      uint256(cfg.liquidityFee),
      'liquidityFee'
    );
  }

  function test_delta_irStrategy() public {
    CachedHubAssetFixture memory t = _targetHubAsset();
    IHub.AssetConfig memory cfg = _buildAssetConfigFrom(t.input);
    MockIR newIR = new MockIR();
    newIR.setData(
      t.assetId,
      IAssetInterestRateStrategy.InterestRateData({
        optimalUsageRatio: 1234,
        baseDrawnRate: 567,
        rateGrowthBeforeOptimal: 89,
        rateGrowthAfterOptimal: 10
      }),
      77_777
    );
    cfg.irStrategy = address(newIR);
    hub.setAssetConfig(t.assetId, cfg);
    Types.V4Snapshot memory snap = _createV4Snapshot();
    assertEq(snap.hubAssets[TARGET_IDX].irStrategy, address(newIR), 'irStrategy');
    // IR fields should now reflect the new strategy
    assertEq(snap.hubAssets[TARGET_IDX].optimalUsageRatio, 1234, 'optimalUsageRatio reroute');
    assertEq(snap.hubAssets[TARGET_IDX].maxDrawnRate, 77_777, 'maxDrawnRate reroute');
  }

  function test_delta_feeReceiver() public {
    CachedHubAssetFixture memory t = _targetHubAsset();
    IHub.AssetConfig memory cfg = _buildAssetConfigFrom(t.input);
    address newReceiver = makeAddr('NEW_FEE_RECEIVER');
    cfg.feeReceiver = newReceiver;
    hub.setAssetConfig(t.assetId, cfg);
    assertEq(_createV4Snapshot().hubAssets[TARGET_IDX].feeReceiver, newReceiver, 'feeReceiver');
  }

  function test_delta_reinvestmentController() public {
    CachedHubAssetFixture memory t = _targetHubAsset();
    IHub.AssetConfig memory cfg = _buildAssetConfigFrom(t.input);
    address newReinv = makeAddr('NEW_REINV');
    cfg.reinvestmentController = newReinv;
    hub.setAssetConfig(t.assetId, cfg);
    assertEq(
      _createV4Snapshot().hubAssets[TARGET_IDX].reinvestmentController,
      newReinv,
      'reinvestmentController'
    );
  }

  // --- IR-driven fields (mutate IR mock directly) ---

  function test_delta_optimalUsageRatio() public {
    ir0.setData(
      0,
      IAssetInterestRateStrategy.InterestRateData({
        optimalUsageRatio: 1111,
        baseDrawnRate: 100,
        rateGrowthBeforeOptimal: 400,
        rateGrowthAfterOptimal: 6000
      }),
      30_000
    );
    assertEq(
      _createV4Snapshot().hubAssets[TARGET_IDX].optimalUsageRatio,
      1111,
      'optimalUsageRatio'
    );
  }

  function test_delta_baseDrawnRate() public {
    ir0.setData(
      0,
      IAssetInterestRateStrategy.InterestRateData({
        optimalUsageRatio: 8000,
        baseDrawnRate: 222,
        rateGrowthBeforeOptimal: 400,
        rateGrowthAfterOptimal: 6000
      }),
      30_000
    );
    assertEq(_createV4Snapshot().hubAssets[TARGET_IDX].baseDrawnRate, 222, 'baseDrawnRate');
  }

  function test_delta_rateGrowthBeforeOptimal() public {
    ir0.setData(
      0,
      IAssetInterestRateStrategy.InterestRateData({
        optimalUsageRatio: 8000,
        baseDrawnRate: 100,
        rateGrowthBeforeOptimal: 333,
        rateGrowthAfterOptimal: 6000
      }),
      30_000
    );
    assertEq(
      _createV4Snapshot().hubAssets[TARGET_IDX].rateGrowthBeforeOptimal,
      333,
      'rateGrowthBeforeOptimal'
    );
  }

  function test_delta_rateGrowthAfterOptimal() public {
    ir0.setData(
      0,
      IAssetInterestRateStrategy.InterestRateData({
        optimalUsageRatio: 8000,
        baseDrawnRate: 100,
        rateGrowthBeforeOptimal: 400,
        rateGrowthAfterOptimal: 4444
      }),
      30_000
    );
    assertEq(
      _createV4Snapshot().hubAssets[TARGET_IDX].rateGrowthAfterOptimal,
      4444,
      'rateGrowthAfterOptimal'
    );
  }

  function test_delta_maxDrawnRate() public {
    ir0.setData(
      0,
      IAssetInterestRateStrategy.InterestRateData({
        optimalUsageRatio: 8000,
        baseDrawnRate: 100,
        rateGrowthBeforeOptimal: 400,
        rateGrowthAfterOptimal: 6000
      }),
      55_555
    );
    assertEq(_createV4Snapshot().hubAssets[TARGET_IDX].maxDrawnRate, 55_555, 'maxDrawnRate');
  }

  function _targetHubAsset() internal view returns (CachedHubAssetFixture memory) {
    return _hubAssetFixtures[TARGET_IDX];
  }

  function _buildAssetFrom(
    HubAssetFixture memory f
  ) internal pure returns (IHub.Asset memory asset) {
    asset.underlying = f.underlying;
    asset.decimals = f.decimals;
    asset.liquidityFee = f.liquidityFee;
    asset.irStrategy = f.irStrategy;
    asset.reinvestmentController = f.reinvController;
    asset.feeReceiver = f.feeReceiver;
    asset.deficitRay = f.deficitRay;
    asset.swept = f.swept;
    asset.premiumShares = f.premiumShares;
    asset.premiumOffsetRay = f.premiumOffsetRay;
  }

  function _buildAssetConfigFrom(
    HubAssetFixture memory f
  ) internal pure returns (IHub.AssetConfig memory) {
    return
      IHub.AssetConfig({
        feeReceiver: f.feeReceiver,
        liquidityFee: f.liquidityFee,
        irStrategy: f.irStrategy,
        reinvestmentController: f.reinvController
      });
  }
}
