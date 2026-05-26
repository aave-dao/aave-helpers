// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {SnapshotV4} from 'src/dependencies/v4/SnapshotV4.sol';
import {V4DiffWriter} from 'src/dependencies/v4/V4DiffWriter.sol';
import {Types} from 'src/dependencies/v4/Types.sol';
import {V4DiffWriterHarness} from 'tests/mocks/v4/V4DiffWriterHarness.sol';

abstract contract V4DiffWriterTestBase is Test {
  address internal spokeA;
  address internal spokeB;
  address internal hubX;
  address internal hubY;
  address internal underlyingUsdc;
  address internal underlyingWeth;
  address internal oracleAddr;
  address internal priceSource;
  address internal irStrategy;
  address internal feeReceiver;
  address internal reinvController;

  function _setUpAddresses() internal {
    spokeA = makeAddr('spokeA');
    spokeB = makeAddr('spokeB');
    hubX = makeAddr('hubX');
    hubY = makeAddr('hubY');
    underlyingUsdc = makeAddr('underlyingUsdc');
    underlyingWeth = makeAddr('underlyingWeth');
    oracleAddr = makeAddr('oracleAddr');
    priceSource = makeAddr('priceSource');
    irStrategy = makeAddr('irStrategy');
    feeReceiver = makeAddr('feeReceiver');
    reinvController = makeAddr('reinvController');
  }

  function _makeReserve(
    address spoke,
    uint256 reserveId,
    string memory symbol,
    uint16 collateralFactor
  ) internal view returns (Types.SpokeReserveSnapshot memory) {
    return
      Types.SpokeReserveSnapshot({
        spokeAddress: spoke,
        reserveId: reserveId,
        underlying: underlyingUsdc,
        symbol: symbol,
        hub: hubX,
        assetId: uint16(reserveId),
        decimals: 6,
        collateralRisk: 1000,
        paused: false,
        frozen: false,
        borrowable: true,
        receiveSharesEnabled: true,
        dynamicConfigKey: 1,
        collateralFactor: collateralFactor,
        maxLiquidationBonus: 10500,
        liquidationFee: 100,
        dynamicConfigs: new Types.DynamicConfigSnapshot[](0),
        oracleAddress: oracleAddr,
        priceSource: priceSource,
        oraclePrice: 1e8
      });
  }

  function _makeHubAsset(
    address hub,
    uint256 assetId,
    string memory symbol,
    uint16 liquidityFee
  ) internal view returns (Types.HubAssetSnapshot memory) {
    return
      Types.HubAssetSnapshot({
        hubAddress: hub,
        assetId: assetId,
        underlying: underlyingUsdc,
        symbol: symbol,
        decimals: 6,
        liquidityFee: liquidityFee,
        irStrategy: irStrategy,
        feeReceiver: feeReceiver,
        reinvestmentController: reinvController,
        optimalUsageRatio: 8000,
        baseDrawnRate: 100,
        rateGrowthBeforeOptimal: 400,
        rateGrowthAfterOptimal: 6000,
        maxDrawnRate: 30_000,
        deficitRay: 0,
        swept: 0,
        premiumShares: 0,
        premiumOffsetRay: int200(0)
      });
  }
}

/// Inherits SnapshotV4 so we can execute `writeV4SnapshotJson` and `diffV4Snapshots`
contract V4DiffWriterTest is V4DiffWriterTestBase, SnapshotV4 {
  string internal constant REPORT = 'v4diff_writer_test';

  function setUp() public {
    _setUpAddresses();
    vm.chainId(1);
  }

  function test_writeSnapshotJson_persistsAllSections() public {
    Types.V4Snapshot memory snap = _baseSnapshot();
    V4DiffWriter.writeSnapshotJson('v4diff_writer_single', snap);

    string memory json = vm.readFile('./reports/v4diff_writer_single.json');

    // Top-level sections are present
    assertTrue(vm.contains(json, '"spokeReserves"'), 'spokeReserves missing');
    assertTrue(vm.contains(json, '"spokeLiquidationConfigs"'), 'spokeLiqConfigs missing');
    assertTrue(vm.contains(json, '"hubAssets"'), 'hubAssets missing');
    assertTrue(vm.contains(json, '"spokeConfigs"'), 'spokeConfigs missing');

    // Per-entity values
    assertTrue(vm.contains(json, '"symbol": "USDC"'), 'reserve symbol');
    assertTrue(vm.contains(json, '"collateralFactor": 7500'), 'CF value');
    assertTrue(vm.contains(json, '"paused": false'), 'paused value');
    assertTrue(vm.contains(json, '"liquidityFee": 10'), 'liqFee value');
    assertTrue(vm.contains(json, '"addCap": 1000000'), 'addCap value');
    assertTrue(vm.contains(json, '"liquidationBonusFactor": 100'), 'liqBonusFactor value');

    vm.removeFile('./reports/v4diff_writer_single.json');
  }

  function test_diffV4Snapshots_emitsChanges() public {
    // Build the two snapshots independently so the "before" arrays aren't mutated by the
    // "after" assignments, ie array references on copy.
    Types.V4Snapshot memory before = _baseSnapshot();
    Types.V4Snapshot memory afterSnap = _baseSnapshot();
    afterSnap.spokeReserves[0].collateralFactor = 8000;
    afterSnap.spokeReserves[0].paused = true;
    afterSnap.hubAssets[0].liquidityFee = 50;
    afterSnap.spokeConfigs[0].addCap = 2_000_000;
    afterSnap.spokeConfigs[0].halted = true;
    afterSnap.spokeLiquidationConfigs[0].liquidationBonusFactor = 200;

    writeV4SnapshotJson(string.concat(REPORT, '_before'), before);
    writeV4SnapshotJson(string.concat(REPORT, '_after'), afterSnap);

    // ---- JSON contents: before has old values, after has new values ----
    string memory beforeJson = vm.readFile(string.concat('./reports/', REPORT, '_before.json'));
    string memory afterJson = vm.readFile(string.concat('./reports/', REPORT, '_after.json'));

    assertTrue(vm.contains(beforeJson, '"collateralFactor": 7500'), 'before CF');
    assertTrue(vm.contains(afterJson, '"collateralFactor": 8000'), 'after CF');

    assertTrue(vm.contains(beforeJson, '"paused": false'), 'before paused');
    assertTrue(vm.contains(afterJson, '"paused": true'), 'after paused');

    assertTrue(vm.contains(beforeJson, '"liquidityFee": 10'), 'before liqFee');
    assertTrue(vm.contains(afterJson, '"liquidityFee": 50'), 'after liqFee');

    assertTrue(vm.contains(beforeJson, '"addCap": 1000000'), 'before addCap');
    assertTrue(vm.contains(afterJson, '"addCap": 2000000'), 'after addCap');

    assertTrue(vm.contains(beforeJson, '"halted": false'), 'before halted');
    assertTrue(vm.contains(afterJson, '"halted": true'), 'after halted');

    assertTrue(vm.contains(beforeJson, '"liquidationBonusFactor": 100'), 'before liqBonus');
    assertTrue(vm.contains(afterJson, '"liquidationBonusFactor": 200'), 'after liqBonus');

    // ---- Run the TypeScript CLI to render the markdown diff ----
    diffV4Snapshots(REPORT);

    string memory md = vm.readFile(
      string.concat('./diffs/', REPORT, '_before_', REPORT, '_after.md')
    );

    // Spoke reserve section: BPS fields are formatted as "W.FF % [bps]"
    assertTrue(vm.contains(md, '## Spoke Reserve Changes'), 'spoke reserve section');
    assertTrue(vm.contains(md, 'collateralFactor'), 'CF row');
    assertTrue(vm.contains(md, '75.00 % [7500]'), 'CF before formatted');
    assertTrue(vm.contains(md, '80.00 % [8000]'), 'CF after formatted');
    assertTrue(vm.contains(md, 'paused'), 'paused row');

    // Hub asset section
    assertTrue(vm.contains(md, '## Hub Asset Changes'), 'hub asset section');
    assertTrue(vm.contains(md, 'liquidityFee'), 'liqFee row');
    assertTrue(vm.contains(md, '0.10 % [10]'), 'liqFee before');
    assertTrue(vm.contains(md, '0.50 % [50]'), 'liqFee after');

    // Spoke cap section — uint40s rendered with thousand separators
    assertTrue(vm.contains(md, '## Hub Spoke Config Changes'), 'spoke config section');
    assertTrue(vm.contains(md, 'addCap'), 'addCap row');
    assertTrue(vm.contains(md, '1,000,000'), 'addCap before');
    assertTrue(vm.contains(md, '2,000,000'), 'addCap after');
    assertTrue(vm.contains(md, 'halted'), 'halted row');

    // Spoke liquidation section
    assertTrue(vm.contains(md, '## Spoke Liquidation Config Changes'), 'liq config section');
    assertTrue(vm.contains(md, 'liquidationBonusFactor'), 'liqBonus row');
    assertTrue(vm.contains(md, '1.00 % [100]'), 'liqBonus before');
    assertTrue(vm.contains(md, '2.00 % [200]'), 'liqBonus after');

    // No noise from unchanged sections is necessary — but the raw diff block always closes the doc
    assertTrue(vm.contains(md, '## Raw diff'), 'raw diff trailer');

    _cleanup();
  }

  function _baseSnapshot() internal view returns (Types.V4Snapshot memory snap) {
    snap.spokeReserves = new Types.SpokeReserveSnapshot[](1);
    snap.spokeReserves[0] = Types.SpokeReserveSnapshot({
      spokeAddress: spokeA,
      reserveId: 0,
      underlying: underlyingUsdc,
      symbol: 'USDC',
      hub: hubX,
      assetId: 0,
      decimals: 6,
      collateralRisk: 1000,
      paused: false,
      frozen: false,
      borrowable: true,
      receiveSharesEnabled: true,
      dynamicConfigKey: 1,
      collateralFactor: 7500,
      maxLiquidationBonus: 10500,
      liquidationFee: 100,
      dynamicConfigs: new Types.DynamicConfigSnapshot[](0),
      oracleAddress: oracleAddr,
      priceSource: priceSource,
      oraclePrice: 1e8
    });

    snap.spokeLiquidationConfigs = new Types.SpokeLiquidationSnapshot[](1);
    snap.spokeLiquidationConfigs[0] = Types.SpokeLiquidationSnapshot({
      spokeAddress: spokeA,
      targetHealthFactor: 1.05e18,
      healthFactorForMaxBonus: 0.95e18,
      liquidationBonusFactor: 100,
      maxUserReservesLimit: 8
    });

    snap.hubAssets = new Types.HubAssetSnapshot[](1);
    snap.hubAssets[0] = Types.HubAssetSnapshot({
      hubAddress: hubX,
      assetId: 0,
      underlying: underlyingUsdc,
      symbol: 'USDC',
      decimals: 6,
      liquidityFee: 10,
      irStrategy: irStrategy,
      feeReceiver: feeReceiver,
      reinvestmentController: reinvController,
      optimalUsageRatio: 8000,
      baseDrawnRate: 100,
      rateGrowthBeforeOptimal: 400,
      rateGrowthAfterOptimal: 6000,
      maxDrawnRate: 30_000,
      deficitRay: 0,
      swept: 0,
      premiumShares: 0,
      premiumOffsetRay: int200(0)
    });

    snap.spokeConfigs = new Types.SpokeConfigSnapshot[](1);
    snap.spokeConfigs[0] = Types.SpokeConfigSnapshot({
      hubAddress: hubX,
      assetId: 0,
      assetSymbol: 'USDC',
      spokeAddress: spokeA,
      addCap: 1_000_000,
      drawCap: 500_000,
      riskPremiumThreshold: 100,
      active: true,
      halted: false
    });
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

/// Individual V4DiffWriter helpers for individual tests
contract V4DiffWriterHarnessTest is V4DiffWriterTestBase {
  V4DiffWriterHarness internal harness;

  function setUp() public {
    _setUpAddresses();
    harness = new V4DiffWriterHarness();
    vm.chainId(1);
  }

  function test_serReserve_includesAllFields() public {
    Types.SpokeReserveSnapshot memory r = _makeReserve(spokeA, 0, 'USDC', 7500);
    string memory json = harness.serReserve(r);

    // vm.serialize* returns compact JSON (no whitespace after colons),
    // unlike the pretty-printed file output.
    assertTrue(vm.contains(json, '"symbol":"USDC"'), 'symbol');
    assertTrue(vm.contains(json, '"decimals":6'), 'decimals');
    assertTrue(vm.contains(json, '"collateralRisk":1000'), 'collateralRisk');
    assertTrue(vm.contains(json, '"paused":false'), 'paused');
    assertTrue(vm.contains(json, '"frozen":false'), 'frozen');
    assertTrue(vm.contains(json, '"borrowable":true'), 'borrowable');
    assertTrue(vm.contains(json, '"receiveSharesEnabled":true'), 'receiveSharesEnabled');
    assertTrue(vm.contains(json, '"dynamicConfigKey":1'), 'dynamicConfigKey');
    assertTrue(vm.contains(json, '"collateralFactor":7500'), 'collateralFactor');
    assertTrue(vm.contains(json, '"maxLiquidationBonus":10500'), 'maxLiquidationBonus');
    assertTrue(vm.contains(json, '"liquidationFee":100'), 'liquidationFee');
    assertTrue(vm.contains(json, '"oraclePrice":"100000000"'), 'oraclePrice');
  }

  function test_writeSpokeReserves_groupsBySpokeAddress() public {
    Types.SpokeReserveSnapshot[] memory reserves = new Types.SpokeReserveSnapshot[](3);
    reserves[0] = _makeReserve(spokeA, 0, 'USDC', 7500);
    reserves[1] = _makeReserve(spokeA, 1, 'WETH', 8000);
    reserves[2] = _makeReserve(spokeB, 0, 'USDC', 7000);

    string memory path = './reports/harness_spoke_reserves.json';
    harness.writeSpokeReserves(path, reserves);

    string memory json = vm.readFile(path);
    assertTrue(vm.contains(json, '"spokeReserves"'), 'section');
    assertTrue(vm.contains(json, '"collateralFactor": 7500'), 'CF reserve 0');
    assertTrue(vm.contains(json, '"collateralFactor": 8000'), 'CF reserve 1');
    assertTrue(vm.contains(json, '"collateralFactor": 7000'), 'CF reserve 2');
    assertTrue(vm.contains(json, vm.toString(spokeA)), 'spoke A key');
    assertTrue(vm.contains(json, vm.toString(spokeB)), 'spoke B key');
    assertTrue(vm.contains(json, '"symbol": "USDC"'), 'USDC symbol');
    assertTrue(vm.contains(json, '"symbol": "WETH"'), 'WETH symbol');

    vm.removeFile(path);
  }

  function test_writeSpokeLiqConfigs_writesAllConfigs() public {
    Types.SpokeLiquidationSnapshot[] memory configs = new Types.SpokeLiquidationSnapshot[](2);
    configs[0] = Types.SpokeLiquidationSnapshot({
      spokeAddress: spokeA,
      targetHealthFactor: 1.05e18,
      healthFactorForMaxBonus: 0.95e18,
      liquidationBonusFactor: 100,
      maxUserReservesLimit: 8
    });
    configs[1] = Types.SpokeLiquidationSnapshot({
      spokeAddress: spokeB,
      targetHealthFactor: 1.10e18,
      healthFactorForMaxBonus: 0.90e18,
      liquidationBonusFactor: 250,
      maxUserReservesLimit: 12
    });

    string memory path = './reports/harness_spoke_liq.json';
    harness.writeSpokeLiqConfigs(path, configs);

    string memory json = vm.readFile(path);
    assertTrue(vm.contains(json, '"spokeLiquidationConfigs"'), 'section');
    assertTrue(vm.contains(json, '"liquidationBonusFactor": 100'), 'first liqBonus');
    assertTrue(vm.contains(json, '"liquidationBonusFactor": 250'), 'second liqBonus');
    assertTrue(vm.contains(json, '"maxUserReservesLimit": 8'), 'first limit');
    assertTrue(vm.contains(json, '"maxUserReservesLimit": 12'), 'second limit');
    assertTrue(vm.contains(json, '"targetHealthFactor": "1050000000000000000"'), 'first HF');

    vm.removeFile(path);
  }

  function test_serializeHubAsset_includesAllFields() public {
    Types.HubAssetSnapshot memory a = _makeHubAsset(hubX, 0, 'USDC', 10);
    string memory json = harness.serializeHubAsset(a);

    assertTrue(vm.contains(json, '"symbol":"USDC"'), 'symbol');
    assertTrue(vm.contains(json, '"decimals":6'), 'decimals');
    assertTrue(vm.contains(json, '"liquidityFee":10'), 'liquidityFee');
    assertTrue(vm.contains(json, '"optimalUsageRatio":8000'), 'optimalUsageRatio');
    assertTrue(vm.contains(json, '"baseDrawnRate":100'), 'baseDrawnRate');
    assertTrue(vm.contains(json, '"rateGrowthBeforeOptimal":400'), 'rateGrowthBeforeOptimal');
    assertTrue(vm.contains(json, '"rateGrowthAfterOptimal":6000'), 'rateGrowthAfterOptimal');
    assertTrue(vm.contains(json, '"maxDrawnRate":"30000"'), 'maxDrawnRate');
    assertTrue(vm.contains(json, '"deficitRay":"0"'), 'deficitRay');
    assertTrue(vm.contains(json, '"premiumOffsetRay":"0"'), 'premiumOffsetRay');
  }

  function test_writeHubAssets_groupsByHubAddress() public {
    Types.HubAssetSnapshot[] memory assets = new Types.HubAssetSnapshot[](3);
    assets[0] = _makeHubAsset(hubX, 0, 'USDC', 10);
    assets[1] = _makeHubAsset(hubX, 1, 'WETH', 20);
    assets[2] = _makeHubAsset(hubY, 0, 'USDC', 30);

    string memory path = './reports/harness_hub_assets.json';
    harness.writeHubAssets(path, assets);

    string memory json = vm.readFile(path);
    assertTrue(vm.contains(json, '"hubAssets"'), 'section');
    assertTrue(vm.contains(json, '"liquidityFee": 10'), 'asset 0 fee');
    assertTrue(vm.contains(json, '"liquidityFee": 20'), 'asset 1 fee');
    assertTrue(vm.contains(json, '"liquidityFee": 30'), 'asset 2 fee');
    assertTrue(vm.contains(json, vm.toString(hubX)), 'hub X key');
    assertTrue(vm.contains(json, vm.toString(hubY)), 'hub Y key');

    vm.removeFile(path);
  }

  function test_writeSpokeConfigs_writesAllConfigs() public {
    Types.SpokeConfigSnapshot[] memory caps = new Types.SpokeConfigSnapshot[](2);
    caps[0] = Types.SpokeConfigSnapshot({
      hubAddress: hubX,
      assetId: 0,
      assetSymbol: 'USDC',
      spokeAddress: spokeA,
      addCap: 1_000_000,
      drawCap: 500_000,
      riskPremiumThreshold: 100,
      active: true,
      halted: false
    });
    caps[1] = Types.SpokeConfigSnapshot({
      hubAddress: hubX,
      assetId: 0,
      assetSymbol: 'USDC',
      spokeAddress: spokeB,
      addCap: 2_000_000,
      drawCap: 800_000,
      riskPremiumThreshold: 200,
      active: false,
      halted: true
    });

    string memory path = './reports/harness_spoke_caps.json';
    harness.writeSpokeConfigs(path, caps);

    string memory json = vm.readFile(path);
    assertTrue(vm.contains(json, '"spokeConfigs"'), 'section');
    assertTrue(vm.contains(json, '"addCap": 1000000'), 'first addCap');
    assertTrue(vm.contains(json, '"addCap": 2000000'), 'second addCap');
    assertTrue(vm.contains(json, '"drawCap": 500000'), 'first drawCap');
    assertTrue(vm.contains(json, '"drawCap": 800000'), 'second drawCap');
    assertTrue(vm.contains(json, '"active": true'), 'first active');
    assertTrue(vm.contains(json, '"active": false'), 'second active');
    assertTrue(vm.contains(json, '"halted": false'), 'first halted');
    assertTrue(vm.contains(json, '"halted": true'), 'second halted');

    vm.removeFile(path);
  }

  function test_writeSnapshotJson_emptyArrays_persistsEmptyObjects() public {
    Types.V4Snapshot memory snap;

    string memory path = './reports/v4diff_writer_empty.json';
    V4DiffWriter.writeSnapshotJson('v4diff_writer_empty', snap);
    string memory json = vm.readFile(path);

    // Every section must be a real JSON object (`{}`), not the stringified
    // form (`"{}"`) the loop-less code path used to produce.
    _assertEmptyObjectSection(json, 'spokeReserves');
    _assertEmptyObjectSection(json, 'spokeLiquidationConfigs');
    _assertEmptyObjectSection(json, 'hubAssets');
    _assertEmptyObjectSection(json, 'spokeConfigs');
    _assertEmptyObjectSection(json, 'positionManagers');
    _assertEmptyObjectSection(json, 'accessManagerRoles');

    vm.removeFile(path);
  }

  function test_writeSpokeReserves_empty_persistsEmptyObject() public {
    string memory path = './reports/harness_spoke_reserves_empty.json';
    harness.writeSpokeReserves(path, new Types.SpokeReserveSnapshot[](0));
    _assertEmptyObjectSection(vm.readFile(path), 'spokeReserves');
    vm.removeFile(path);
  }

  function test_writeSpokeLiqConfigs_empty_persistsEmptyObject() public {
    string memory path = './reports/harness_spoke_liq_empty.json';
    harness.writeSpokeLiqConfigs(path, new Types.SpokeLiquidationSnapshot[](0));
    _assertEmptyObjectSection(vm.readFile(path), 'spokeLiquidationConfigs');
    vm.removeFile(path);
  }

  function test_writeHubAssets_empty_persistsEmptyObject() public {
    string memory path = './reports/harness_hub_assets_empty.json';
    harness.writeHubAssets(path, new Types.HubAssetSnapshot[](0));
    _assertEmptyObjectSection(vm.readFile(path), 'hubAssets');
    vm.removeFile(path);
  }

  function test_writeSpokeConfigs_empty_persistsEmptyObject() public {
    string memory path = './reports/harness_spoke_caps_empty.json';
    harness.writeSpokeConfigs(path, new Types.SpokeConfigSnapshot[](0));
    _assertEmptyObjectSection(vm.readFile(path), 'spokeConfigs');
    vm.removeFile(path);
  }

  function _assertEmptyObjectSection(string memory json, string memory section) internal pure {
    string memory objectMarker = string.concat('"', section, '": {}');
    string memory stringMarker = string.concat('"', section, '": "');
    assertTrue(vm.contains(json, objectMarker), string.concat(section, ' not an empty object'));
    assertFalse(
      vm.contains(json, stringMarker),
      string.concat(section, ' serialized as string')
    );
  }
}
