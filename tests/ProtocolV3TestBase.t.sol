// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {ProtocolV3TestBase, ReserveConfig} from '../src/ProtocolV3TestBase.sol';
import {IPool, IPoolAddressesProvider, IPoolConfigurator} from 'aave-address-book/AaveV3.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3EthereumEtherFi} from 'aave-address-book/AaveV3EthereumEtherFi.sol';
import {AaveV3Polygon, AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveV3Optimism, AaveV3OptimismAssets} from 'aave-address-book/AaveV3Optimism.sol';
import {AaveV3Arbitrum, AaveV3ArbitrumAssets} from 'aave-address-book/AaveV3Arbitrum.sol';
import {AaveV3Avalanche, AaveV3AvalancheAssets} from 'aave-address-book/AaveV3Avalanche.sol';
import {AaveV3Metis} from 'aave-address-book/AaveV3Metis.sol';
import {AaveV3MegaEth} from 'aave-address-book/AaveV3MegaEth.sol';
import {AaveV3Mantle} from 'aave-address-book/AaveV3Mantle.sol';
import {AaveV3Fantom} from 'aave-address-book/AaveV3Fantom.sol';
import {EngineFlags} from 'aave-v3-origin/contracts/extensions/v3-config-engine/EngineFlags.sol';
import {IAaveV3ConfigEngine} from 'aave-v3-origin/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol';
import {PayloadWithEmit} from './mocks/PayloadWithEmit.sol';
import {PayloadWithStorage} from './mocks/PayloadWithStorage.sol';

contract ProtocolV3TestBaseTest is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('polygon', 74909955);
  }

  function test_e2eTestDPI() public {
    ReserveConfig[] memory configs = _getReservesConfigs(AaveV3Optimism.POOL);
    e2eTestAsset(
      AaveV3Optimism.POOL,
      _findReserveConfig(configs, AaveV3PolygonAssets.WPOL_UNDERLYING),
      _findReserveConfig(configs, AaveV3PolygonAssets.WETH_UNDERLYING)
    );
  }

  function test_e2eTestWithBigTestAssetPrice() public {
    ReserveConfig[] memory configs = _getReservesConfigs(AaveV3Optimism.POOL);

    ReserveConfig memory collateralConfig = _findReserveConfig(
      configs,
      AaveV3PolygonAssets.WETH_UNDERLYING
    );
    ReserveConfig memory testAssetConfig = _findReserveConfig(
      configs,
      AaveV3PolygonAssets.WETH_UNDERLYING
    );

    _changeAssetPrice(AaveV3Optimism.POOL, testAssetConfig, 1000_00); // price increases to 1'000%

    e2eTestAsset(AaveV3Optimism.POOL, collateralConfig, testAssetConfig);
  }

  // function testSnpashot() public {
  //   this.createConfigurationSnapshot('pre-x', AaveV3Polygon.POOL);
  //   // do sth
  //   // this.createConfigurationSnapshot('post-x', AaveV3Polygon.POOL);

  //   // requires --ffi
  //   // diffReports('pre-x', 'post-x');
  // }

  // commented out as it is insanely slow with public rpcs
}

contract ProtocolV3TestE2ETestAsset is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('optimism', 139484866);
  }

  function test_e2eTestAssetMAI() public {
    ReserveConfig[] memory configs = _getReservesConfigs(AaveV3Optimism.POOL);
    e2eTestAsset(
      AaveV3Optimism.POOL,
      _findReserveConfig(configs, AaveV3OptimismAssets.DAI_UNDERLYING),
      _findReserveConfig(configs, AaveV3OptimismAssets.LINK_UNDERLYING)
    );
  }

  function test_e2eTestAssetUSDC() public {
    ReserveConfig[] memory configs = _getReservesConfigs(AaveV3Optimism.POOL);
    e2eTestAsset(
      AaveV3Optimism.POOL,
      _findReserveConfig(configs, AaveV3OptimismAssets.DAI_UNDERLYING),
      _findReserveConfig(configs, AaveV3OptimismAssets.USDC_UNDERLYING)
    );
  }
}

contract ProtocolV3TestE2ETestOptimismAll is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('optimism', 139484866);
  }

  function test_e2e() public {
    e2eTest(AaveV3Optimism.POOL);
  }
}

contract ProtocolV3TestE2ETestMetisAll is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('metis', 20957736);
  }

  function test_e2e() public {
    e2eTest(AaveV3Metis.POOL);
  }
}

contract ProtocolV3TestE2ETestAvalancheAll is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('avalanche', 66702537);
  }

  function test_e2e() public {
    e2eTest(AaveV3Avalanche.POOL);
  }

  function test_deal() public {
    deal2(AaveV3AvalancheAssets.USDC_UNDERLYING, address(this), 1000);
  }
}

contract ProtocolV3TestE2ETestArbitrumAll is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('arbitrum', 365906782);
  }

  function test_e2e() public {
    e2eTest(AaveV3Arbitrum.POOL);
  }

  function test_deal() public {
    deal2(AaveV3ArbitrumAssets.USDCn_UNDERLYING, address(this), 1000);
  }
}

contract ProtocolV3TestE2ETestAllMainnet is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('mainnet', 23438415);
  }

  function test_e2e() public {
    e2eTest(AaveV3Ethereum.POOL);
  }
}

contract ProtocolV3TestOptimismSnapshot is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('optimism', 139484866);
  }

  function test_snapshotState() public {
    createConfigurationSnapshot('snapshot', AaveV3Optimism.POOL, true, false, false, false);
  }
}

contract ProtocolV3TestMegaEthSnapshot is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('megaeth', 7862955);
  }

  /// forge-config: default.isolate = true
  function test_snapshotState() public {
    defaultTest(
      'megaeth',
      AaveV3MegaEth.POOL,
      0x3a0A755D940283cD96D69F88645BeaA2bAfBC0bb,
      false,
      false
    );
  }
}

contract ProtocolV3TestMantleSnapshot is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('mantle', 91335553);
  }

  /// forge-config: default.isolate = true
  function test_snapshotState() public {
    defaultTest(
      'mantle',
      AaveV3Mantle.POOL,
      0x6F5b52c16886775395129dB05117D65420863250,
      false,
      false
    );
  }

  // overriding the executor storage check as payload artifacts does not exist
  function _validateNoExecutorStorageChange(string memory, address) internal view override {}

  // Mantle's per-tx limit is well above the EIP-7825 floor; raise it so this payload fits.
  function _getMaxPayloadGas() internal view override returns (uint256) {
    return 30_000_000;
  }
}

contract ProtocolV3TestPlausibilityEMode is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('mainnet', 24955851);
  }

  function test_borrowCapIncrease_borrowDisabled_noEMode_reverts() public {
    ReserveConfig[] memory configsBefore = _getReservesConfigs(AaveV3Ethereum.POOL);
    ReserveConfig[] memory configsAfter = _getReservesConfigs(AaveV3Ethereum.POOL);

    // pick first asset that has borrowing enabled and a borrow cap
    uint256 idx;
    for (uint256 i; i < configsAfter.length; i++) {
      if (configsAfter[i].borrowingEnabled && configsAfter[i].borrowCap > 0) {
        idx = i;
        break;
      }
    }

    // simulate: borrowing disabled, borrow cap increased
    configsAfter[idx].borrowingEnabled = false;
    configsAfter[idx].borrowCap = configsBefore[idx].borrowCap + 1;

    // disable borrowing on-chain so _isBorrowableInAnyEMode reads real state
    IPoolAddressesProvider provider = IPoolAddressesProvider(
      AaveV3Ethereum.POOL.ADDRESSES_PROVIDER()
    );
    IPoolConfigurator configurator = IPoolConfigurator(provider.getPoolConfigurator());
    vm.startPrank(provider.getACLAdmin());
    configurator.setReserveBorrowing(configsAfter[idx].underlying, false);
    // remove from all e-mode categories
    uint16 reserveId = AaveV3Ethereum.POOL.getReserveData(configsAfter[idx].underlying).id;
    for (uint256 cat = 1; cat <= 255; cat++) {
      uint128 bitmap = AaveV3Ethereum.POOL.getEModeCategoryBorrowableBitmap(uint8(cat));
      if (bitmap != 0 && (bitmap >> reserveId) & 1 != 0) {
        configurator.setAssetBorrowableInEMode(configsAfter[idx].underlying, uint8(cat), false);
      }
    }
    vm.stopPrank();

    vm.expectRevert('PL_BORROW_CAP_BORROW_DISABLED');
    this.configChangePlausibilityTest(AaveV3Ethereum.POOL, configsBefore, configsAfter);
  }

  function test_borrowCapIncrease_borrowDisabled_eModeBorrowable_passes() public {
    ReserveConfig[] memory configsBefore = _getReservesConfigs(AaveV3EthereumEtherFi.POOL);
    ReserveConfig[] memory configsAfter = _getReservesConfigs(AaveV3EthereumEtherFi.POOL);

    uint256 idx;
    for (uint256 i; i < configsAfter.length; i++) {
      if (
        configsAfter[i].borrowingEnabled &&
        configsAfter[i].borrowCap > 0 &&
        configsAfter[i].borrowCap != configsAfter[i].supplyCap
      ) {
        idx = i;
        break;
      }
    }

    // simulate: borrowing disabled, borrow cap increased
    configsAfter[idx].borrowingEnabled = false;
    configsAfter[idx].borrowCap = configsBefore[idx].borrowCap + 1;

    IPoolAddressesProvider provider = IPoolAddressesProvider(
      AaveV3EthereumEtherFi.POOL.ADDRESSES_PROVIDER()
    );
    IPoolConfigurator configurator = IPoolConfigurator(provider.getPoolConfigurator());
    vm.startPrank(provider.getACLAdmin());
    // disable standard borrowing
    configurator.setReserveBorrowing(configsAfter[idx].underlying, false);
    // ensure asset is borrowable in e-mode category 1
    // first ensure category 1 exists
    configurator.setEModeCategory({
      categoryId: 1,
      ltv: 90_00,
      liquidationThreshold: 93_00,
      liquidationBonus: 101_00,
      label: 'test',
      isolated: false
    });
    configurator.setAssetBorrowableInEMode(configsAfter[idx].underlying, 1, true);
    vm.stopPrank();

    // should pass because asset is borrowable in e-mode
    this.configChangePlausibilityTest(AaveV3EthereumEtherFi.POOL, configsBefore, configsAfter);
  }

  function test_borrowCapIncrease_borrowEnabled_passes() public {
    ReserveConfig[] memory configsBefore = _getReservesConfigs(AaveV3Ethereum.POOL);
    ReserveConfig[] memory configsAfter = _getReservesConfigs(AaveV3Ethereum.POOL);

    uint256 idx;
    for (uint256 i; i < configsAfter.length; i++) {
      if (configsAfter[i].borrowingEnabled && configsAfter[i].borrowCap > 0) {
        idx = i;
        break;
      }
    }

    // borrow cap increased, borrowing still enabled — should pass
    configsAfter[idx].borrowCap = configsBefore[idx].borrowCap + 1;
    this.configChangePlausibilityTest(AaveV3Ethereum.POOL, configsBefore, configsAfter);
  }
}

contract ProtocolV3TestBaseReserveConfigChangesTest is ProtocolV3TestBase {
  address internal constant ASSET_A = address(1);
  address internal constant ASSET_B = address(2);
  address internal constant ASSET_C = address(3);
  address internal constant ASSET_D = address(4);

  function test_validateExpectedReserveConfigChanges() public view {
    this.validateReserveConfigChanges(_configsBefore(), _configsAfter());
  }

  function test_revertsWhenDeclaredBorrowCapIsNotApplied() public {
    ReserveConfig[] memory configsAfter = _configsAfter();
    configsAfter[1].borrowCap = 701;

    vm.expectRevert(bytes('_validateReserveConfig: InvalidBorrowCap()'));
    this.validateReserveConfigChanges(_configsBefore(), configsAfter);
  }

  function test_revertsWhenUndeclaredReserveConfigChanges() public {
    ReserveConfig[] memory configsAfter = _configsAfter();
    configsAfter[2].supplyCap = 301;

    vm.expectRevert(bytes('_validateReserveConfig: InvalidSupplyCap()'));
    this.validateReserveConfigChanges(_configsBefore(), configsAfter);
  }

  function validateReserveConfigChanges(
    ReserveConfig[] memory configsBefore,
    ReserveConfig[] memory configsAfter
  ) external pure {
    address[] memory updatedAssets = new address[](3);
    updatedAssets[0] = ASSET_A;
    updatedAssets[1] = ASSET_B;
    updatedAssets[2] = ASSET_C;
    _validateReserveConfigChanges(configsBefore, configsAfter, updatedAssets);
  }

  function _expectedCollateralChanges()
    internal
    pure
    override
    returns (IAaveV3ConfigEngine.CollateralUpdate[] memory)
  {
    IAaveV3ConfigEngine.CollateralUpdate[]
      memory updates = new IAaveV3ConfigEngine.CollateralUpdate[](1);
    updates[0] = IAaveV3ConfigEngine.CollateralUpdate({
      asset: ASSET_A,
      ltv: 0,
      liqThreshold: 0,
      liqBonus: 5_00,
      liqProtocolFee: EngineFlags.KEEP_CURRENT
    });
    return updates;
  }

  function _expectedCapsChanges()
    internal
    pure
    override
    returns (IAaveV3ConfigEngine.CapsUpdate[] memory)
  {
    IAaveV3ConfigEngine.CapsUpdate[] memory updates = new IAaveV3ConfigEngine.CapsUpdate[](1);
    updates[0] = IAaveV3ConfigEngine.CapsUpdate({
      asset: ASSET_B,
      supplyCap: EngineFlags.KEEP_CURRENT,
      borrowCap: 700
    });
    return updates;
  }

  function _expectedBorrowChanges()
    internal
    pure
    override
    returns (IAaveV3ConfigEngine.BorrowUpdate[] memory)
  {
    IAaveV3ConfigEngine.BorrowUpdate[] memory updates = new IAaveV3ConfigEngine.BorrowUpdate[](1);
    updates[0] = IAaveV3ConfigEngine.BorrowUpdate({
      asset: ASSET_B,
      enabledToBorrow: EngineFlags.DISABLED,
      flashloanable: EngineFlags.KEEP_CURRENT,
      reserveFactor: 25_00
    });
    return updates;
  }

  function _expectedFreezeChanges()
    internal
    pure
    override
    returns (address[] memory assets, bool[] memory frozen)
  {
    assets = new address[](1);
    frozen = new bool[](1);
    assets[0] = ASSET_C;
    frozen[0] = true;
  }

  function _expectedListings()
    internal
    pure
    override
    returns (IAaveV3ConfigEngine.Listing[] memory listings, uint256[] memory decimals)
  {
    listings = new IAaveV3ConfigEngine.Listing[](1);
    decimals = new uint256[](1);
    listings[0] = IAaveV3ConfigEngine.Listing({
      asset: ASSET_D,
      assetSymbol: 'ASSET_D',
      priceFeed: address(0),
      rateStrategyParams: IAaveV3ConfigEngine.InterestRateInputData({
        optimalUsageRatio: 80_00,
        baseVariableBorrowRate: 0,
        variableRateSlope1: 10_00,
        variableRateSlope2: 100_00
      }),
      enabledToBorrow: EngineFlags.ENABLED,
      flashloanable: EngineFlags.DISABLED,
      ltv: 50_00,
      liqThreshold: 60_00,
      liqBonus: 5_00,
      reserveFactor: 10_00,
      supplyCap: 1_000,
      borrowCap: 200,
      liqProtocolFee: 15_00
    });
    decimals[0] = 6;
  }

  function _configsBefore() internal pure returns (ReserveConfig[] memory) {
    ReserveConfig[] memory configs = new ReserveConfig[](3);
    configs[0] = _reserveConfig('ASSET_A', ASSET_A, 75_00, 80_00, true, 1_000, 500);
    configs[1] = _reserveConfig('ASSET_B', ASSET_B, 70_00, 75_00, true, 2_000, 600);
    configs[2] = _reserveConfig('ASSET_C', ASSET_C, 60_00, 65_00, true, 300, 100);
    return configs;
  }

  function _configsAfter() internal pure returns (ReserveConfig[] memory) {
    ReserveConfig[] memory configs = new ReserveConfig[](4);
    ReserveConfig[] memory configsBefore = _configsBefore();
    configs[0] = configsBefore[0];
    configs[1] = configsBefore[1];
    configs[2] = configsBefore[2];
    configs[0].ltv = 0;
    configs[0].liquidationThreshold = 0;
    configs[0].liquidationBonus = 105_00;
    configs[0].usageAsCollateralEnabled = false;
    configs[1].borrowCap = 700;
    configs[1].borrowingEnabled = false;
    configs[1].reserveFactor = 25_00;
    configs[2].isFrozen = true;
    configs[3] = _reserveConfig('ASSET_D', ASSET_D, 50_00, 60_00, true, 1_000, 200);
    configs[3].decimals = 6;
    configs[3].liquidationBonus = 105_00;
    configs[3].liquidationProtocolFee = 15_00;
    configs[3].reserveFactor = 10_00;
    configs[3].isFlashloanable = false;
    return configs;
  }

  function _reserveConfig(
    string memory symbol,
    address underlying,
    uint256 ltv,
    uint256 liquidationThreshold,
    bool usageAsCollateralEnabled,
    uint256 supplyCap,
    uint256 borrowCap
  ) internal pure returns (ReserveConfig memory) {
    return
      ReserveConfig({
        symbol: symbol,
        underlying: underlying,
        aToken: address(uint160(underlying) + 10),
        variableDebtToken: address(uint160(underlying) + 20),
        decimals: 18,
        ltv: ltv,
        liquidationThreshold: liquidationThreshold,
        liquidationBonus: 106_00,
        liquidationProtocolFee: 10_00,
        reserveFactor: 20_00,
        usageAsCollateralEnabled: usageAsCollateralEnabled,
        borrowingEnabled: true,
        interestRateStrategy: address(uint160(underlying) + 30),
        isPaused: false,
        isActive: true,
        isFrozen: false,
        isFlashloanable: true,
        supplyCap: supplyCap,
        borrowCap: borrowCap,
        virtualBalance: 0,
        aTokenUnderlyingBalance: 0
      });
  }
}

contract ProtocolV3TestBaseReserveConfigChangesNoChangesTest is ProtocolV3TestBase {
  address internal constant ASSET_A = address(1);
  address internal constant ASSET_B = address(2);

  function test_validateNoReserveConfigChanges() public view {
    this.validateReserveConfigChanges(_configsBefore(), _configsBefore());
  }

  function test_revertsWhenUnexpectedReserveConfigChanges() public {
    ReserveConfig[] memory configsAfter = _configsBefore();
    configsAfter[1].borrowCap = 701;

    vm.expectRevert(
      bytes('_noReservesConfigsChangesApartNewListings() : UNEXPECTED_BORROW_CAP_CHANGED')
    );
    this.validateReserveConfigChanges(_configsBefore(), configsAfter);
  }

  function test_revertsWhenUnexpectedNewListing() public {
    ReserveConfig[] memory configsAfter = new ReserveConfig[](3);
    ReserveConfig[] memory configsBefore = _configsBefore();
    configsAfter[0] = configsBefore[0];
    configsAfter[1] = configsBefore[1];
    configsAfter[2] = _reserveConfig('ASSET_C', address(3), 60_00, 65_00, true, 300, 100);

    vm.expectRevert(bytes('_validateCountOfListings() : INVALID_COUNT_OF_LISTINGS'));
    this.validateReserveConfigChanges(_configsBefore(), configsAfter);
  }

  function validateReserveConfigChanges(
    ReserveConfig[] memory configsBefore,
    ReserveConfig[] memory configsAfter
  ) external pure {
    _validateReserveConfigChanges(configsBefore, configsAfter);
  }

  function _configsBefore() internal pure returns (ReserveConfig[] memory) {
    ReserveConfig[] memory configs = new ReserveConfig[](2);
    configs[0] = _reserveConfig('ASSET_A', ASSET_A, 75_00, 80_00, true, 1_000, 500);
    configs[1] = _reserveConfig('ASSET_B', ASSET_B, 70_00, 75_00, true, 2_000, 600);
    return configs;
  }

  function _reserveConfig(
    string memory symbol,
    address underlying,
    uint256 ltv,
    uint256 liquidationThreshold,
    bool usageAsCollateralEnabled,
    uint256 supplyCap,
    uint256 borrowCap
  ) internal pure returns (ReserveConfig memory) {
    return
      ReserveConfig({
        symbol: symbol,
        underlying: underlying,
        aToken: address(uint160(underlying) + 10),
        variableDebtToken: address(uint160(underlying) + 20),
        decimals: 18,
        ltv: ltv,
        liquidationThreshold: liquidationThreshold,
        liquidationBonus: 106_00,
        liquidationProtocolFee: 10_00,
        reserveFactor: 20_00,
        usageAsCollateralEnabled: usageAsCollateralEnabled,
        borrowingEnabled: true,
        interestRateStrategy: address(uint160(underlying) + 30),
        isPaused: false,
        isActive: true,
        isFrozen: false,
        isFlashloanable: true,
        supplyCap: supplyCap,
        borrowCap: borrowCap,
        virtualBalance: 0,
        aTokenUnderlyingBalance: 0
      });
  }
}

contract ProtocolV3TestStorageValidation is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('mainnet', 24655671);
  }

  /// forge-config: default.isolate = true
  function test_noExecutorStorageChange_passes() public {
    defaultTest(
      'V3StorageValidation_pass',
      AaveV3Ethereum.POOL,
      address(new PayloadWithEmit()),
      false,
      false
    );
  }

  /// forge-config: default.isolate = true
  function test_executorStorageChange_reverts() public {
    address payload = address(new PayloadWithStorage());
    vm.expectRevert();
    this.defaultTest('V3StorageValidation_fail', AaveV3Ethereum.POOL, payload, false, false);
  }
}
