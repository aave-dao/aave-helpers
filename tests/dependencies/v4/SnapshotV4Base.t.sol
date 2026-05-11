// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {ISpoke, IHub} from 'aave-address-book/AaveV4.sol';
import {IHubBase} from 'aave-v4/hub/interfaces/IHubBase.sol';
import {IAssetInterestRateStrategy} from 'aave-v4/hub/interfaces/IAssetInterestRateStrategy.sol';
import {SnapshotV4} from 'src/dependencies/v4/SnapshotV4.sol';
import {Types} from 'src/dependencies/v4/Types.sol';
import {MockSpoke, MockHub, MockOracle, MockIR, MockERC20Symbol} from 'tests/mocks/v4/V4Mocks.sol';

abstract contract SnapshotV4BaseTest is Test, SnapshotV4 {
  struct ReserveFixture {
    MockSpoke spoke;
    MockOracle oracle;
    address underlying;
    address hubAddr;
    uint16 assetId;
    uint8 decimals;
    bool paused;
    bool frozen;
    bool borrowable;
    bool receiveSharesEnabled;
    uint24 collateralRisk;
    uint32 dynamicConfigKey;
    uint16 collateralFactor;
    uint32 maxLiquidationBonus;
    uint16 liquidationFee;
    address priceSource;
    uint256 oraclePrice;
  }

  struct CachedReserveFixture {
    ReserveFixture input;
    uint16 reserveId;
  }

  /// @notice Fixtures captured by `_addReserve`
  CachedReserveFixture[] internal _reserveFixtures;

  struct HubAssetFixture {
    address underlying;
    uint8 decimals;
    uint16 liquidityFee;
    address irStrategy;
    address feeReceiver;
    address reinvController;
    uint200 deficitRay;
    uint120 swept;
    uint120 premiumShares;
    int200 premiumOffsetRay;
  }

  /// @dev Stored alongside the input fixture so tests can match snapshots against
  /// the `assetId` returned by `MockHub.addAsset`.
  struct CachedHubAssetFixture {
    HubAssetFixture input;
    uint256 assetId;
  }

  /// @notice Fixtures captured by `_addHubAsset`
  CachedHubAssetFixture[] internal _hubAssetFixtures;

  struct LiqConfigFixture {
    MockSpoke spoke;
    uint128 targetHealthFactor;
    uint64 healthFactorForMaxBonus;
    uint16 liquidationBonusFactor;
    uint16 maxUserReservesLimit;
  }

  /// @notice Fixtures captured by `_addLiqConfig`. The spoke's `setLiquidationConfig`
  /// and `setMaxUserReservesLimit` calls produce no return value, so no wrapper struct.
  LiqConfigFixture[] internal _liqConfigFixtures;

  struct SpokeCapFixture {
    uint256 assetId;
    MockSpoke spoke;
    uint40 addCap;
    uint40 drawCap;
    uint24 riskPremiumThreshold;
    bool active;
    bool halted;
  }

  /// @notice Fixtures captured by `_addSpokeCap`. `MockHub.addSpokeConfig` returns nothing
  /// and the snapshot key (hub, assetId, spoke) is already in the input, so no wrapper struct.
  SpokeCapFixture[] internal _spokeCapFixtures;

  MockSpoke internal spokeA;
  MockSpoke internal spokeB;
  MockHub internal hub;
  MockOracle internal oracleA;
  MockOracle internal oracleB;
  MockIR internal ir0;
  MockIR internal ir1;

  MockERC20Symbol internal usdc;
  MockERC20Symbol internal weth;
  MockERC20Symbol internal wbtc;

  address internal priceSource0 = makeAddr('CHAINLINK_USDC');
  address internal priceSource1 = makeAddr('CHAINLINK_WETH');
  address internal priceSource2 = makeAddr('CHAINLINK_WBTC');

  address internal feeReceiverA = makeAddr('FEE_RECEIVER_A');
  address internal feeReceiverB = makeAddr('FEE_RECEIVER_B');
  address internal reinvA = makeAddr('REINVEST_A');
  address internal reinvB = makeAddr('REINVEST_B');

  function setUp() public {
    _deployMocks();
    _setSpokeOracles();
    _addLiqConfigFixtures();
    _addReserveFixtures();
    _addHubAssetFixtures();
    _configureIRStrategies();
    _addSpokeCapFixtures();
  }

  function _setSpokeOracles() internal {
    spokeA.setOracle(address(oracleA));
    spokeB.setOracle(address(oracleB));
  }

  function _addLiqConfigFixtures() internal {
    _addLiqConfig(
      LiqConfigFixture({
        spoke: spokeA,
        targetHealthFactor: 1.05e18,
        healthFactorForMaxBonus: 0.95e18,
        liquidationBonusFactor: 100,
        maxUserReservesLimit: 8
      })
    );
    _addLiqConfig(
      LiqConfigFixture({
        spoke: spokeB,
        targetHealthFactor: 1.10e18,
        healthFactorForMaxBonus: 0.97e18,
        liquidationBonusFactor: 200,
        maxUserReservesLimit: 12
      })
    );
  }

  function _addLiqConfig(LiqConfigFixture memory f) internal {
    f.spoke.setMaxUserReservesLimit(f.maxUserReservesLimit);
    f.spoke.setLiquidationConfig(
      ISpoke.LiquidationConfig({
        targetHealthFactor: f.targetHealthFactor,
        healthFactorForMaxBonus: f.healthFactorForMaxBonus,
        liquidationBonusFactor: f.liquidationBonusFactor
      })
    );
    _liqConfigFixtures.push(f);
  }

  /// @notice Assert a `SpokeLiquidationSnapshot` matches the stored fixture inputs.
  function assertEq(
    Types.SpokeLiquidationSnapshot memory snap,
    LiqConfigFixture memory expected,
    uint256 idx
  ) internal pure {
    string memory pfx = string.concat('liqConfig[', vm.toString(idx), '] ');
    assertEq(snap.spokeAddress, address(expected.spoke), string.concat(pfx, 'spoke'));
    assertEq(
      snap.targetHealthFactor,
      uint256(expected.targetHealthFactor),
      string.concat(pfx, 'targetHealthFactor')
    );
    assertEq(
      snap.healthFactorForMaxBonus,
      uint256(expected.healthFactorForMaxBonus),
      string.concat(pfx, 'healthFactorForMaxBonus')
    );
    assertEq(
      uint256(snap.liquidationBonusFactor),
      uint256(expected.liquidationBonusFactor),
      string.concat(pfx, 'liquidationBonusFactor')
    );
    assertEq(
      uint256(snap.maxUserReservesLimit),
      uint256(expected.maxUserReservesLimit),
      string.concat(pfx, 'maxUserReservesLimit')
    );
  }

  function _deployMocks() internal {
    usdc = new MockERC20Symbol('USDC');
    weth = new MockERC20Symbol('WETH');
    wbtc = new MockERC20Symbol('WBTC');

    oracleA = new MockOracle();
    oracleB = new MockOracle();

    ir0 = new MockIR();
    ir1 = new MockIR();

    hub = new MockHub();
    spokeA = new MockSpoke();
    spokeB = new MockSpoke();
  }

  function _addHubAssetFixtures() internal {
    _addHubAsset(
      HubAssetFixture({
        underlying: address(usdc),
        decimals: 6,
        liquidityFee: 10,
        irStrategy: address(ir0),
        feeReceiver: feeReceiverA,
        reinvController: reinvA,
        deficitRay: 11,
        swept: 22,
        premiumShares: 33,
        premiumOffsetRay: int200(44)
      })
    );
    _addHubAsset(
      HubAssetFixture({
        underlying: address(weth),
        decimals: 18,
        liquidityFee: 20,
        irStrategy: address(ir1),
        feeReceiver: feeReceiverB,
        reinvController: reinvB,
        deficitRay: 55,
        swept: 66,
        premiumShares: 77,
        premiumOffsetRay: int200(-88)
      })
    );
    // No IR strategy on this one — exercises the `irStrategy == address(0)` branch.
    _addHubAsset(
      HubAssetFixture({
        underlying: address(wbtc),
        decimals: 8,
        liquidityFee: 30,
        irStrategy: address(0),
        feeReceiver: feeReceiverA,
        reinvController: address(0),
        deficitRay: 99,
        swept: 100,
        premiumShares: 101,
        premiumOffsetRay: int200(102)
      })
    );
  }

  function _configureIRStrategies() internal {
    ir0.setData(
      0,
      IAssetInterestRateStrategy.InterestRateData({
        optimalUsageRatio: 8000,
        baseDrawnRate: 100,
        rateGrowthBeforeOptimal: 400,
        rateGrowthAfterOptimal: 6000
      }),
      30_000
    );
    ir1.setData(
      1,
      IAssetInterestRateStrategy.InterestRateData({
        optimalUsageRatio: 7000,
        baseDrawnRate: 200,
        rateGrowthBeforeOptimal: 500,
        rateGrowthAfterOptimal: 7000
      }),
      50_000
    );
  }

  function _addSpokeCapFixtures() internal {
    _addSpokeCap(
      SpokeCapFixture({
        assetId: 0,
        spoke: spokeA,
        addCap: 1_000_000,
        drawCap: 500_000,
        riskPremiumThreshold: 100,
        active: true,
        halted: false
      })
    );
    _addSpokeCap(
      SpokeCapFixture({
        assetId: 0,
        spoke: spokeB,
        addCap: 2_000_000,
        drawCap: 1_500_000,
        riskPremiumThreshold: 200,
        active: true,
        halted: true
      })
    );
    _addSpokeCap(
      SpokeCapFixture({
        assetId: 1,
        spoke: spokeA,
        addCap: 3_000_000,
        drawCap: 2_500_000,
        riskPremiumThreshold: 300,
        active: false,
        halted: false
      })
    );
    _addSpokeCap(
      SpokeCapFixture({
        assetId: 2,
        spoke: spokeB,
        addCap: 4_000_000,
        drawCap: 3_500_000,
        riskPremiumThreshold: 400,
        active: true,
        halted: false
      })
    );
  }

  function _addSpokeCap(SpokeCapFixture memory f) internal {
    hub.addSpokeConfig(
      f.assetId,
      address(f.spoke),
      IHub.SpokeConfig({
        addCap: f.addCap,
        drawCap: f.drawCap,
        riskPremiumThreshold: f.riskPremiumThreshold,
        active: f.active,
        halted: f.halted
      })
    );
    _spokeCapFixtures.push(f);
  }

  /// @notice Assert a `SpokeCapSnapshot` matches the stored fixture inputs.
  /// `assetSymbol` is resolved from the asset's underlying token, mirroring
  /// `SnapshotV4._snapshotCapsForHub`.
  function assertEq(
    Types.SpokeCapSnapshot memory snap,
    SpokeCapFixture memory expected,
    uint256 idx
  ) internal view {
    string memory pfx = string.concat('spokeCap[', vm.toString(idx), '] ');
    assertEq(snap.hubAddress, address(hub), string.concat(pfx, 'hub'));
    assertEq(snap.assetId, expected.assetId, string.concat(pfx, 'assetId'));
    assertEq(snap.spokeAddress, address(expected.spoke), string.concat(pfx, 'spoke'));
    (address underlying, ) = hub.getAssetUnderlyingAndDecimals(expected.assetId);
    assertEq(
      snap.assetSymbol,
      MockERC20Symbol(underlying).symbol(),
      string.concat(pfx, 'assetSymbol')
    );
    assertEq(uint256(snap.addCap), uint256(expected.addCap), string.concat(pfx, 'addCap'));
    assertEq(uint256(snap.drawCap), uint256(expected.drawCap), string.concat(pfx, 'drawCap'));
    assertEq(
      uint256(snap.riskPremiumThreshold),
      uint256(expected.riskPremiumThreshold),
      string.concat(pfx, 'riskPremiumThreshold')
    );
    assertEq(snap.active, expected.active, string.concat(pfx, 'active'));
    assertEq(snap.halted, expected.halted, string.concat(pfx, 'halted'));
  }

  function _createV4Snapshot() internal view returns (Types.V4Snapshot memory) {
    ISpoke[] memory spokes = new ISpoke[](2);
    spokes[0] = ISpoke(address(spokeA));
    spokes[1] = ISpoke(address(spokeB));
    IHub[] memory hubs = new IHub[](1);
    hubs[0] = IHub(address(hub));
    return createV4Snapshot(spokes, hubs);
  }

  function _addReserveFixtures() internal {
    _addReserve(
      ReserveFixture({
        spoke: spokeA,
        oracle: oracleA,
        underlying: address(usdc),
        hubAddr: address(hub),
        assetId: 0,
        decimals: 6,
        paused: false,
        frozen: false,
        borrowable: true,
        receiveSharesEnabled: true,
        collateralRisk: 1000,
        dynamicConfigKey: 1,
        collateralFactor: 7500,
        maxLiquidationBonus: 10500,
        liquidationFee: 100,
        priceSource: priceSource0,
        oraclePrice: 1e8
      })
    );
    _addReserve(
      ReserveFixture({
        spoke: spokeA,
        oracle: oracleA,
        underlying: address(weth),
        hubAddr: address(hub),
        assetId: 1,
        decimals: 18,
        paused: false,
        frozen: true,
        borrowable: false,
        receiveSharesEnabled: false,
        collateralRisk: 2500,
        dynamicConfigKey: 2,
        collateralFactor: 8000,
        maxLiquidationBonus: 11000,
        liquidationFee: 150,
        priceSource: priceSource1,
        oraclePrice: 2_000e8
      })
    );

    _addReserve(
      ReserveFixture({
        spoke: spokeB,
        oracle: oracleB,
        underlying: address(wbtc),
        hubAddr: address(hub),
        assetId: 2,
        decimals: 8,
        paused: true,
        frozen: false,
        borrowable: true,
        receiveSharesEnabled: true,
        collateralRisk: 3000,
        dynamicConfigKey: 3,
        collateralFactor: 7000,
        maxLiquidationBonus: 11500,
        liquidationFee: 200,
        priceSource: priceSource2,
        oraclePrice: 60_000e8
      })
    );
  }

  function _addReserve(ReserveFixture memory f) internal {
    ISpoke.Reserve memory reserve;
    reserve.underlying = f.underlying;
    reserve.hub = IHubBase(f.hubAddr);
    reserve.assetId = f.assetId;
    reserve.decimals = f.decimals;
    reserve.collateralRisk = f.collateralRisk;
    reserve.dynamicConfigKey = f.dynamicConfigKey;

    ISpoke.ReserveConfig memory config = ISpoke.ReserveConfig({
      collateralRisk: f.collateralRisk,
      paused: f.paused,
      frozen: f.frozen,
      borrowable: f.borrowable,
      receiveSharesEnabled: f.receiveSharesEnabled
    });

    ISpoke.DynamicReserveConfig memory dyn = ISpoke.DynamicReserveConfig({
      collateralFactor: f.collateralFactor,
      maxLiquidationBonus: f.maxLiquidationBonus,
      liquidationFee: f.liquidationFee
    });

    uint256 reserveId = f.spoke.addReserve(reserve, config, dyn);
    f.oracle.setReserve(reserveId, f.priceSource, f.oraclePrice);
    _reserveFixtures.push(CachedReserveFixture({input: f, reserveId: uint16(reserveId)}));
  }

  /// @notice Assert a `SpokeReserveSnapshot` matches the stored fixture inputs.
  function assertEq(
    Types.SpokeReserveSnapshot memory snap,
    CachedReserveFixture memory expected,
    uint256 idx
  ) internal view {
    string memory pfx = string.concat('reserve[', vm.toString(idx), '] ');
    assertEq(snap.spokeAddress, address(expected.input.spoke), string.concat(pfx, 'spoke'));
    assertEq(snap.reserveId, expected.reserveId, string.concat(pfx, 'reserveId'));
    assertEq(snap.underlying, expected.input.underlying, string.concat(pfx, 'underlying'));
    assertEq(
      snap.symbol,
      MockERC20Symbol(expected.input.underlying).symbol(),
      string.concat(pfx, 'symbol')
    );
    assertEq(snap.hub, expected.input.hubAddr, string.concat(pfx, 'hub'));
    assertEq(uint256(snap.assetId), uint256(expected.input.assetId), string.concat(pfx, 'assetId'));
    assertEq(
      uint256(snap.decimals),
      uint256(expected.input.decimals),
      string.concat(pfx, 'decimals')
    );
    assertEq(
      uint256(snap.collateralRisk),
      uint256(expected.input.collateralRisk),
      string.concat(pfx, 'collateralRisk')
    );
    assertEq(snap.paused, expected.input.paused, string.concat(pfx, 'paused'));
    assertEq(snap.frozen, expected.input.frozen, string.concat(pfx, 'frozen'));
    assertEq(snap.borrowable, expected.input.borrowable, string.concat(pfx, 'borrowable'));
    assertEq(
      snap.receiveSharesEnabled,
      expected.input.receiveSharesEnabled,
      string.concat(pfx, 'receiveSharesEnabled')
    );
    assertEq(
      uint256(snap.dynamicConfigKey),
      uint256(expected.input.dynamicConfigKey),
      string.concat(pfx, 'dynamicConfigKey')
    );
    assertEq(
      uint256(snap.collateralFactor),
      uint256(expected.input.collateralFactor),
      string.concat(pfx, 'collateralFactor')
    );
    assertEq(
      uint256(snap.maxLiquidationBonus),
      uint256(expected.input.maxLiquidationBonus),
      string.concat(pfx, 'maxLiquidationBonus')
    );
    assertEq(
      uint256(snap.liquidationFee),
      uint256(expected.input.liquidationFee),
      string.concat(pfx, 'liquidationFee')
    );
    assertEq(
      snap.oracleAddress,
      address(expected.input.oracle),
      string.concat(pfx, 'oracleAddress')
    );
    assertEq(snap.priceSource, expected.input.priceSource, string.concat(pfx, 'priceSource'));
    assertEq(snap.oraclePrice, expected.input.oraclePrice, string.concat(pfx, 'oraclePrice'));
  }

  /// @notice Assert a `HubAssetSnapshot` matches the stored fixture inputs.
  /// IR-strategy fields are zero when `irStrategy == address(0)`; otherwise queried
  /// from the IR mock at assert time, mirroring how `SnapshotV4` resolves them.
  function assertEq(
    Types.HubAssetSnapshot memory snap,
    CachedHubAssetFixture memory expected,
    uint256 idx
  ) internal view {
    string memory pfx = string.concat('hubAsset[', vm.toString(idx), '] ');
    assertEq(snap.hubAddress, address(hub), string.concat(pfx, 'hub'));
    assertEq(snap.assetId, expected.assetId, string.concat(pfx, 'assetId'));
    assertEq(snap.underlying, expected.input.underlying, string.concat(pfx, 'underlying'));
    assertEq(
      snap.symbol,
      MockERC20Symbol(expected.input.underlying).symbol(),
      string.concat(pfx, 'symbol')
    );
    assertEq(
      uint256(snap.decimals),
      uint256(expected.input.decimals),
      string.concat(pfx, 'decimals')
    );
    assertEq(
      uint256(snap.liquidityFee),
      uint256(expected.input.liquidityFee),
      string.concat(pfx, 'liquidityFee')
    );
    assertEq(snap.irStrategy, expected.input.irStrategy, string.concat(pfx, 'irStrategy'));
    assertEq(snap.feeReceiver, expected.input.feeReceiver, string.concat(pfx, 'feeReceiver'));
    assertEq(
      snap.reinvestmentController,
      expected.input.reinvController,
      string.concat(pfx, 'reinvController')
    );

    // IR strategy fields — zero when address(0), otherwise queried from the mock.
    uint256 expOptimalUR;
    uint256 expBaseRate;
    uint256 expGrowthBefore;
    uint256 expGrowthAfter;
    uint256 expMaxDrawnRate;
    if (expected.input.irStrategy != address(0)) {
      IAssetInterestRateStrategy ir = IAssetInterestRateStrategy(expected.input.irStrategy);
      IAssetInterestRateStrategy.InterestRateData memory data = ir.getInterestRateData(
        expected.assetId
      );
      expOptimalUR = data.optimalUsageRatio;
      expBaseRate = data.baseDrawnRate;
      expGrowthBefore = data.rateGrowthBeforeOptimal;
      expGrowthAfter = data.rateGrowthAfterOptimal;
      expMaxDrawnRate = ir.getMaxDrawnRate(expected.assetId);
    }
    assertEq(snap.optimalUsageRatio, expOptimalUR, string.concat(pfx, 'optimalUsageRatio'));
    assertEq(snap.baseDrawnRate, expBaseRate, string.concat(pfx, 'baseDrawnRate'));
    assertEq(
      snap.rateGrowthBeforeOptimal,
      expGrowthBefore,
      string.concat(pfx, 'rateGrowthBeforeOptimal')
    );
    assertEq(
      snap.rateGrowthAfterOptimal,
      expGrowthAfter,
      string.concat(pfx, 'rateGrowthAfterOptimal')
    );
    assertEq(snap.maxDrawnRate, expMaxDrawnRate, string.concat(pfx, 'maxDrawnRate'));

    // Asset state — written directly from the fixture into the mock, so equality is exact.
    assertEq(
      uint256(snap.deficitRay),
      uint256(expected.input.deficitRay),
      string.concat(pfx, 'deficitRay')
    );
    assertEq(uint256(snap.swept), uint256(expected.input.swept), string.concat(pfx, 'swept'));
    assertEq(
      uint256(snap.premiumShares),
      uint256(expected.input.premiumShares),
      string.concat(pfx, 'premiumShares')
    );
    assertEq(
      snap.premiumOffsetRay,
      expected.input.premiumOffsetRay,
      string.concat(pfx, 'premiumOffsetRay')
    );
  }

  function _addHubAsset(HubAssetFixture memory f) internal {
    IHub.Asset memory asset;
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

    IHub.AssetConfig memory config = IHub.AssetConfig({
      feeReceiver: f.feeReceiver,
      liquidityFee: f.liquidityFee,
      irStrategy: f.irStrategy,
      reinvestmentController: f.reinvController
    });

    uint256 assetId = hub.addAsset(asset, config);
    _hubAssetFixtures.push(CachedHubAssetFixture({input: f, assetId: assetId}));
  }

  function assertEq(
    Types.SpokeReserveSnapshot[] memory snaps,
    CachedReserveFixture[] memory expected
  ) internal view {
    assertEq(snaps.length, expected.length, 'spokeReserves length');
    for (uint256 i; i < expected.length; i++) {
      assertEq(snaps[i], expected[i], i);
    }
  }

  function assertEq(
    Types.HubAssetSnapshot[] memory snaps,
    CachedHubAssetFixture[] memory expected
  ) internal view {
    assertEq(snaps.length, expected.length, 'hubAssets length');
    for (uint256 i; i < expected.length; i++) {
      assertEq(snaps[i], expected[i], i);
    }
  }

  function assertEq(
    Types.SpokeLiquidationSnapshot[] memory snaps,
    LiqConfigFixture[] memory expected
  ) internal pure {
    assertEq(snaps.length, expected.length, 'liqConfigs length');
    for (uint256 i; i < expected.length; i++) {
      assertEq(snaps[i], expected[i], i);
    }
  }

  function assertEq(
    Types.SpokeCapSnapshot[] memory snaps,
    SpokeCapFixture[] memory expected
  ) internal view {
    assertEq(snaps.length, expected.length, 'spokeCaps length');
    for (uint256 i; i < expected.length; i++) {
      assertEq(snaps[i], expected[i], i);
    }
  }
}
