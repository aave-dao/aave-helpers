// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAaveV3ConfigEngine} from '../../src/v3-config-engine/IAaveV3ConfigEngine.sol';
import {AaveV3PolygonMockListing} from '../mocks/AaveV3PolygonMockListing.sol';
import {AaveV3EthereumMockCustomListing} from '../mocks/AaveV3EthereumMockCustomListing.sol';
import {AaveV3EthereumMockCapUpdate} from '../mocks/AaveV3EthereumMockCapUpdate.sol';
import {AaveV3AvalancheCollateralUpdate} from '../mocks/AaveV3AvalancheCollateralUpdate.sol';
import {AaveV3AvalancheCollateralUpdateNoChange} from '../mocks/AaveV3AvalancheCollateralUpdateNoChange.sol';
import {AaveV3AvalancheCollateralUpdateWrongBonus, AaveV3AvalancheCollateralUpdateCorrectBonus} from '../mocks/AaveV3AvalancheCollateralUpdateEdgeBonus.sol';
import {AaveV3PolygonBorrowUpdate} from '../mocks/AaveV3PolygonBorrowUpdate.sol';
import {AaveV3PolygonPriceFeedUpdate} from '../mocks/AaveV3PolygonPriceFeedUpdate.sol';
import {AaveV3PolygonEModeCategoryUpdate, AaveV3AvalancheEModeCategoryUpdateEdgeBonus} from '../mocks/AaveV3PolygonEModeCategoryUpdate.sol';
import {AaveV3AvalancheEModeCategoryUpdateNoChange} from '../mocks/AaveV3AvalancheEModeCategoryUpdateNoChange.sol';
import {AaveV3EthereumAssetEModeUpdate} from '../mocks/AaveV3EthereumAssetEModeUpdate.sol';
import {AaveV3PolygonBorrowUpdateNoChange} from '../mocks/AaveV3PolygonBorrowUpdateNoChange.sol';
import {AaveV3OptimismMockRatesUpdate} from '../mocks/AaveV3OptimismMockRatesUpdate.sol';
import {DeployRatesFactoryPolLib, DeployRatesFactoryEthLib, DeployRatesFactoryAvaLib, DeployRatesFactoryArbLib, DeployRatesFactoryOptLib} from '../../scripts/V3RateStrategyFactory.s.sol';
import {DeployEnginePolLib, DeployEngineEthLib, DeployEngineAvaLib, DeployEngineOptLib, DeployEngineArbLib} from '../../scripts/AaveV3ConfigEngine.s.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3Polygon, AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveV3Optimism, AaveV3OptimismAssets} from 'aave-address-book/AaveV3Optimism.sol';
import {AaveV3Avalanche, AaveV3AvalancheAssets} from 'aave-address-book/AaveV3Avalanche.sol';
import {AaveV3Arbitrum, AaveV3ArbitrumAssets} from 'aave-address-book/AaveV3Arbitrum.sol';
import {IDefaultInterestRateStrategy} from 'aave-address-book/AaveV3.sol';
import {AaveV3PolygonRatesUpdates070322} from '../mocks/gauntlet-updates/AaveV3PolygonRatesUpdates070322.sol';
import {AaveV3AvalancheRatesUpdates070322} from '../mocks/gauntlet-updates/AaveV3AvalancheRatesUpdates070322.sol';
import {AaveV3OptimismRatesUpdates070322} from '../mocks/gauntlet-updates/AaveV3OptimismRatesUpdates070322.sol';
import {AaveV3ArbitrumRatesUpdates070322} from '../mocks/gauntlet-updates/AaveV3ArbitrumRatesUpdates070322.sol';
import '../../src/ProtocolV3TestBase.sol';

contract AaveV3ConfigEngineTest is ProtocolV3TestBase {
  using stdStorage for StdStorage;

  uint256 mainnetFork;
  uint256 polygonFork;
  uint256 optimismFork;
  uint256 avalancheFork;
  uint256 arbitrumFork;

  function setUp() public {
    mainnetFork = vm.createSelectFork(vm.rpcUrl('mainnet'), 18515746);
    optimismFork = vm.createSelectFork(vm.rpcUrl('optimism'), 115008197);
    polygonFork = vm.createSelectFork(vm.rpcUrl('polygon'), 55734786);
    avalancheFork = vm.createSelectFork(vm.rpcUrl('avalanche'), 37426577);
    arbitrumFork = vm.createSelectFork(vm.rpcUrl('arbitrum'), 147823152);
  }

  event CollateralConfigurationChanged(
    address indexed asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  );

  event EModeCategoryAdded(
    uint8 indexed categoryId,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus,
    address oracle,
    string label
  );

  function testListings() public {
    vm.selectFork(polygonFork);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEnginePolLib.deploy());
    AaveV3PolygonMockListing payload = new AaveV3PolygonMockListing(engine);

    vm.startPrank(AaveV3Polygon.ACL_ADMIN);
    AaveV3Polygon.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    ReserveConfig[] memory allConfigsBefore = createConfigurationSnapshot(
      'preTestEngineListing',
      AaveV3Polygon.POOL
    );

    payload.execute();

    ReserveConfig[] memory allConfigsAfter = createConfigurationSnapshot(
      'postTestEngineListing',
      AaveV3Polygon.POOL
    );

    diffReports('preTestEngineListing', 'postTestEngineListing');

    ReserveConfig memory expectedAssetConfig = ReserveConfig({
      symbol: '1INCH',
      underlying: 0x9c2C5fd7b07E95EE044DDeba0E97a665F142394f,
      aToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
      variableDebtToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
      stableDebtToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
      decimals: 18,
      ltv: 82_50,
      liquidationThreshold: 86_00,
      liquidationBonus: 105_00,
      liquidationProtocolFee: 10_00,
      reserveFactor: 10_00,
      usageAsCollateralEnabled: true,
      borrowingEnabled: true,
      interestRateStrategy: _findReserveConfigBySymbol(allConfigsAfter, 'AAVE')
        .interestRateStrategy,
      stableBorrowRateEnabled: false,
      isPaused: false,
      isActive: true,
      isFrozen: false,
      isSiloed: false,
      isBorrowableInIsolation: false,
      isFlashloanable: false,
      supplyCap: 85_000,
      borrowCap: 60_000,
      debtCeiling: 0,
      eModeCategory: 1
    });

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);

    _noReservesConfigsChangesApartNewListings(allConfigsBefore, allConfigsAfter);

    _validateReserveTokensImpls(
      AaveV3Polygon.POOL_ADDRESSES_PROVIDER,
      _findReserveConfigBySymbol(allConfigsAfter, '1INCH'),
      ReserveTokens({
        aToken: AaveV3Polygon.DEFAULT_A_TOKEN_IMPL_REV_2,
        stableDebtToken: AaveV3Polygon.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_3,
        variableDebtToken: AaveV3Polygon.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_2
      })
    );

    _validateAssetSourceOnOracle(
      AaveV3Polygon.POOL_ADDRESSES_PROVIDER,
      0x9c2C5fd7b07E95EE044DDeba0E97a665F142394f,
      0x443C5116CdF663Eb387e72C688D276e702135C87
    );

    // impl should be same as e.g. AAVE
    _validateReserveTokensImpls(
      AaveV3Polygon.POOL_ADDRESSES_PROVIDER,
      _findReserveConfigBySymbol(allConfigsAfter, 'CRV'),
      ReserveTokens({
        aToken: AaveV3Polygon.DEFAULT_A_TOKEN_IMPL_REV_2,
        stableDebtToken: AaveV3Polygon.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_3,
        variableDebtToken: AaveV3Polygon.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_2
      })
    );
  }

  function testListingsCustom() public {
    vm.selectFork(mainnetFork);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEngineEthLib.deploy());
    AaveV3EthereumMockCustomListing payload = new AaveV3EthereumMockCustomListing(engine);

    vm.startPrank(AaveV3Ethereum.ACL_ADMIN);
    AaveV3Ethereum.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    ReserveConfig[] memory allConfigsBefore = createConfigurationSnapshot(
      'preTestEngineListingCustom',
      AaveV3Ethereum.POOL
    );

    payload.execute();

    ReserveConfig[] memory allConfigsAfter = createConfigurationSnapshot(
      'postTestEngineListingCustom',
      AaveV3Ethereum.POOL
    );

    diffReports('preTestEngineListingCustom', 'postTestEngineListingCustom');

    ReserveConfig memory expectedAssetConfig = ReserveConfig({
      symbol: 'PSP',
      underlying: 0xcAfE001067cDEF266AfB7Eb5A286dCFD277f3dE5,
      aToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
      variableDebtToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
      stableDebtToken: address(0), // Mock, as they don't get validated, because of the "dynamic" deployment on proposal execution
      decimals: 18,
      ltv: 82_50,
      liquidationThreshold: 86_00,
      liquidationBonus: 105_00,
      liquidationProtocolFee: 10_00,
      reserveFactor: 10_00,
      usageAsCollateralEnabled: true,
      borrowingEnabled: true,
      interestRateStrategy: _findReserveConfigBySymbol(allConfigsAfter, 'AAVE')
        .interestRateStrategy,
      stableBorrowRateEnabled: true,
      isPaused: false,
      isActive: true,
      isFrozen: false,
      isSiloed: false,
      isBorrowableInIsolation: false,
      isFlashloanable: false,
      supplyCap: 85_000,
      borrowCap: 60_000,
      debtCeiling: 0,
      eModeCategory: 0
    });

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);

    _noReservesConfigsChangesApartNewListings(allConfigsBefore, allConfigsAfter);

    _validateReserveTokensImpls(
      AaveV3Ethereum.POOL_ADDRESSES_PROVIDER,
      _findReserveConfigBySymbol(allConfigsAfter, 'PSP'),
      ReserveTokens({
        aToken: AaveV3Ethereum.DEFAULT_A_TOKEN_IMPL_REV_1,
        stableDebtToken: AaveV3Ethereum.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1,
        variableDebtToken: AaveV3Ethereum.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1
      })
    );

    _validateAssetSourceOnOracle(
      AaveV3Ethereum.POOL_ADDRESSES_PROVIDER,
      0xcAfE001067cDEF266AfB7Eb5A286dCFD277f3dE5,
      0x72AFAECF99C9d9C8215fF44C77B94B99C28741e8
    );

    // impl should be same as e.g. AAVE
    _validateReserveTokensImpls(
      AaveV3Ethereum.POOL_ADDRESSES_PROVIDER,
      _findReserveConfigBySymbol(allConfigsAfter, 'AAVE'),
      ReserveTokens({
        aToken: AaveV3Ethereum.DEFAULT_A_TOKEN_IMPL_REV_1,
        stableDebtToken: AaveV3Ethereum.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1,
        variableDebtToken: AaveV3Ethereum.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1
      })
    );
  }

  function testCapsUpdates() public {
    vm.selectFork(mainnetFork);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEngineEthLib.deploy());
    AaveV3EthereumMockCapUpdate payload = new AaveV3EthereumMockCapUpdate(engine);

    vm.startPrank(AaveV3Ethereum.ACL_ADMIN);
    AaveV3Ethereum.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    ReserveConfig[] memory allConfigsBefore = createConfigurationSnapshot(
      'preTestEngineCaps',
      AaveV3Ethereum.POOL
    );

    payload.execute();

    ReserveConfig[] memory allConfigsAfter = createConfigurationSnapshot(
      'postTestEngineCaps',
      AaveV3Ethereum.POOL
    );

    diffReports('preTestEngineCaps', 'postTestEngineCaps');

    ReserveConfig memory expectedAssetConfig = _findReserveConfig(
      allConfigsBefore,
      AaveV3EthereumAssets.AAVE_UNDERLYING
    );

    expectedAssetConfig.supplyCap = 1_000_000;

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);
  }

  function testCollateralsUpdates() public {
    vm.selectFork(avalancheFork);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEngineAvaLib.deploy());
    AaveV3AvalancheCollateralUpdate payload = new AaveV3AvalancheCollateralUpdate(engine);

    vm.startPrank(AaveV3Avalanche.ACL_ADMIN);
    AaveV3Avalanche.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    ReserveConfig[] memory allConfigsBefore = createConfigurationSnapshot(
      'preTestEngineCollateral',
      AaveV3Avalanche.POOL
    );

    vm.expectEmit(true, true, true, true);
    emit CollateralConfigurationChanged(allConfigsBefore[6].underlying, 62_00, 72_00, 106_00);

    payload.execute();

    ReserveConfig[] memory allConfigsAfter = createConfigurationSnapshot(
      'postTestEngineCollateral',
      AaveV3Avalanche.POOL
    );

    diffReports('preTestEngineCollateral', 'postTestEngineCollateral');

    ReserveConfig memory expectedAssetConfig = _findReserveConfig(
      allConfigsBefore,
      AaveV3AvalancheAssets.AAVEe_UNDERLYING
    );
    expectedAssetConfig.ltv = 62_00;
    expectedAssetConfig.liquidationThreshold = 72_00;
    expectedAssetConfig.liquidationBonus = 106_00; // 100_00 + 6_00

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);
  }

  // TODO manage this after testFail* deprecation.
  // This should not be necessary, but there seems there is no other way
  // of validating that when all collateral params are KEEP_CURRENT, the config
  // engine doesn't call the POOL_CONFIGURATOR.
  // So the solution is expecting the event emitted on the POOL_CONFIGURATOR,
  // and as this doesn't happen, expect the failure of the test
  function testFailCollateralsUpdatesNoChange() public {
    vm.selectFork(avalancheFork);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEngineAvaLib.deploy());
    AaveV3AvalancheCollateralUpdateNoChange payload = new AaveV3AvalancheCollateralUpdateNoChange(
      engine
    );

    vm.startPrank(AaveV3Avalanche.ACL_ADMIN);
    AaveV3Avalanche.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    ReserveConfig[] memory allConfigsBefore = _getReservesConfigs(AaveV3Avalanche.POOL);

    vm.expectEmit(true, true, true, true);
    emit CollateralConfigurationChanged(
      allConfigsBefore[6].underlying,
      allConfigsBefore[6].ltv,
      allConfigsBefore[6].liquidationThreshold,
      allConfigsBefore[6].liquidationBonus
    );

    payload.execute();
  }

  // Same as testFailCollateralsUpdatesNoChange, but this time should work, as we are not expecting any event emitted
  function testCollateralsUpdatesNoChange() public {
    vm.selectFork(avalancheFork);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEngineAvaLib.deploy());
    AaveV3AvalancheCollateralUpdateNoChange payload = new AaveV3AvalancheCollateralUpdateNoChange(
      engine
    );

    vm.startPrank(AaveV3Avalanche.ACL_ADMIN);
    AaveV3Avalanche.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    ReserveConfig[] memory allConfigsBefore = createConfigurationSnapshot(
      'preTestEngineCollateralNoChange',
      AaveV3Avalanche.POOL
    );

    payload.execute();

    ReserveConfig[] memory allConfigsAfter = createConfigurationSnapshot(
      'postTestEngineCollateralNoChange',
      AaveV3Avalanche.POOL
    );

    diffReports('preTestEngineCollateralNoChange', 'postTestEngineCollateralNoChange');

    ReserveConfig memory expectedAssetConfig = _findReserveConfig(
      allConfigsBefore,
      AaveV3AvalancheAssets.AAVEe_UNDERLYING
    );

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);
  }

  function testCollateralUpdateWrongBonus() public {
    vm.selectFork(avalancheFork);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEngineAvaLib.deploy());
    AaveV3AvalancheCollateralUpdateWrongBonus payload = new AaveV3AvalancheCollateralUpdateWrongBonus(
        engine
      );

    vm.startPrank(AaveV3Avalanche.ACL_ADMIN);
    AaveV3Avalanche.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    vm.expectRevert(bytes('INVALID_LT_LB_RATIO'));
    payload.execute();
  }

  function testCollateralUpdateCorrectBonus() public {
    vm.selectFork(avalancheFork);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEngineAvaLib.deploy());
    AaveV3AvalancheCollateralUpdateCorrectBonus payload = new AaveV3AvalancheCollateralUpdateCorrectBonus(
        engine
      );

    vm.startPrank(AaveV3Avalanche.ACL_ADMIN);
    AaveV3Avalanche.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    ReserveConfig[] memory allConfigsBefore = createConfigurationSnapshot(
      'preTestEngineCollateralEdgeBonus',
      AaveV3Avalanche.POOL
    );

    payload.execute();

    ReserveConfig[] memory allConfigsAfter = createConfigurationSnapshot(
      'postTestEngineCollateralEdgeBonus',
      AaveV3Avalanche.POOL
    );

    diffReports('preTestEngineCollateralEdgeBonus', 'postTestEngineCollateralEdgeBonus');

    ReserveConfig memory expectedAssetConfig = _findReserveConfig(
      allConfigsBefore,
      AaveV3AvalancheAssets.AAVEe_UNDERLYING
    );
    expectedAssetConfig.ltv = 62_00;
    expectedAssetConfig.liquidationThreshold = 90_00;
    expectedAssetConfig.liquidationBonus = 111_00; // 100_00 + 11_00

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);
  }

  function testBorrowsUpdates() public {
    vm.selectFork(polygonFork);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEnginePolLib.deploy());
    AaveV3PolygonBorrowUpdate payload = new AaveV3PolygonBorrowUpdate(engine);

    vm.startPrank(AaveV3Polygon.ACL_ADMIN);
    AaveV3Polygon.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    ReserveConfig[] memory allConfigsBefore = createConfigurationSnapshot(
      'preTestEngineBorrow',
      AaveV3Polygon.POOL
    );

    payload.execute();

    ReserveConfig[] memory allConfigsAfter = createConfigurationSnapshot(
      'postTestEngineBorrow',
      AaveV3Polygon.POOL
    );

    diffReports('preTestEngineBorrow', 'postTestEngineBorrow');

    ReserveConfig memory expectedAssetConfig = _findReserveConfig(
      allConfigsBefore,
      AaveV3PolygonAssets.AAVE_UNDERLYING
    );

    expectedAssetConfig.reserveFactor = 15_00;
    expectedAssetConfig.borrowingEnabled = true;
    expectedAssetConfig.isFlashloanable = false;

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);
  }

  function testBorrowUpdatesNoChange() public {
    vm.selectFork(polygonFork);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEnginePolLib.deploy());
    AaveV3PolygonBorrowUpdateNoChange payload = new AaveV3PolygonBorrowUpdateNoChange(engine);

    vm.startPrank(AaveV3Polygon.ACL_ADMIN);
    AaveV3Polygon.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    ReserveConfig[] memory allConfigsBefore = createConfigurationSnapshot(
      'preTestEngineBorrowNoChange',
      AaveV3Polygon.POOL
    );

    payload.execute();

    ReserveConfig[] memory allConfigsAfter = createConfigurationSnapshot(
      'postTestEngineBorrowNoChange',
      AaveV3Polygon.POOL
    );

    diffReports('preTestEngineBorrowNoChange', 'postTestEngineBorrowNoChange');

    ReserveConfig memory expectedAssetConfig = _findReserveConfig(
      allConfigsBefore,
      AaveV3PolygonAssets.AAVE_UNDERLYING
    );

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);
  }

  function testRateStrategiesUpdates() public {
    vm.selectFork(optimismFork);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEngineOptLib.deploy());
    AaveV3OptimismMockRatesUpdate payload = new AaveV3OptimismMockRatesUpdate(engine);

    vm.startPrank(AaveV3Optimism.ACL_ADMIN);
    AaveV3Optimism.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    IDefaultInterestRateStrategy initialStrategy = IDefaultInterestRateStrategy(
      AaveV3OptimismAssets.USDT_INTEREST_RATE_STRATEGY
    );

    createConfigurationSnapshot('preTestEngineRates', AaveV3Optimism.POOL);

    payload.execute();

    createConfigurationSnapshot('postTestEngineRates', AaveV3Optimism.POOL);

    diffReports('preTestEngineRates', 'postTestEngineRates');

    address updatedStrategyAddress = AaveV3Optimism
      .AAVE_PROTOCOL_DATA_PROVIDER
      .getInterestRateStrategyAddress(AaveV3OptimismAssets.USDT_UNDERLYING);

    InterestStrategyValues memory expectedInterestStrategyValues = InterestStrategyValues({
      addressesProvider: address(AaveV3Optimism.POOL_ADDRESSES_PROVIDER),
      optimalUsageRatio: _bpsToRay(80_00),
      baseVariableBorrowRate: initialStrategy.getBaseVariableBorrowRate(),
      variableRateSlope1: initialStrategy.getVariableRateSlope1(),
      variableRateSlope2: _bpsToRay(75_00),
      stableRateSlope1: initialStrategy.getStableRateSlope1(),
      stableRateSlope2: _bpsToRay(75_00),
      baseStableBorrowRate: initialStrategy.getBaseStableBorrowRate(),
      optimalStableToTotalDebtRatio: initialStrategy.OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO()
    });

    _validateInterestRateStrategy(
      updatedStrategyAddress,
      updatedStrategyAddress,
      expectedInterestStrategyValues
    );
  }

  function testPolygonRateStrategiesUpdates() public {
    vm.selectFork(polygonFork);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEnginePolLib.deploy());
    AaveV3PolygonRatesUpdates070322 payload = new AaveV3PolygonRatesUpdates070322(engine);

    vm.startPrank(AaveV3Polygon.ACL_ADMIN);
    AaveV3Polygon.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    createConfigurationSnapshot('preTestEnginePolV3', AaveV3Polygon.POOL);

    payload.execute();

    createConfigurationSnapshot('postTestEnginePolV3', AaveV3Polygon.POOL);

    diffReports('preTestEnginePolV3', 'postTestEnginePolV3');
  }

  function testAvaxRateStrategiesUpdates() public {
    vm.selectFork(avalancheFork);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEngineAvaLib.deploy());
    AaveV3AvalancheRatesUpdates070322 payload = new AaveV3AvalancheRatesUpdates070322(engine);

    vm.startPrank(AaveV3Avalanche.ACL_ADMIN);
    AaveV3Avalanche.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    createConfigurationSnapshot('preTestEngineAvaV3', AaveV3Avalanche.POOL);

    payload.execute();

    createConfigurationSnapshot('postTestEngineAvaV3', AaveV3Avalanche.POOL);

    diffReports('preTestEngineAvaV3', 'postTestEngineAvaV3');
  }

  function testOptimismRateStrategiesUpdates() public {
    vm.selectFork(optimismFork);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEngineOptLib.deploy());
    AaveV3OptimismRatesUpdates070322 payload = new AaveV3OptimismRatesUpdates070322(engine);

    vm.startPrank(AaveV3Optimism.ACL_ADMIN);
    AaveV3Optimism.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    createConfigurationSnapshot('preTestEngineOptV3', AaveV3Optimism.POOL);

    payload.execute();

    createConfigurationSnapshot('postTestEngineOptV3', AaveV3Optimism.POOL);

    diffReports('preTestEngineOptV3', 'postTestEngineOptV3');
  }

  function testArbitrumRateStrategiesUpdates() public {
    vm.selectFork(arbitrumFork);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEngineArbLib.deploy());
    AaveV3ArbitrumRatesUpdates070322 payload = new AaveV3ArbitrumRatesUpdates070322(engine);

    vm.startPrank(AaveV3Arbitrum.ACL_ADMIN);
    AaveV3Arbitrum.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    createConfigurationSnapshot('preTestEngineArbV3', AaveV3Arbitrum.POOL);

    payload.execute();

    createConfigurationSnapshot('postTestEngineArbV3', AaveV3Arbitrum.POOL);

    diffReports('preTestEngineArbV3', 'postTestEngineArbV3');
  }

  function testPriceFeedsUpdates() public {
    vm.selectFork(polygonFork);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEnginePolLib.deploy());
    AaveV3PolygonPriceFeedUpdate payload = new AaveV3PolygonPriceFeedUpdate(engine);

    vm.startPrank(AaveV3Polygon.ACL_ADMIN);
    AaveV3Polygon.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    createConfigurationSnapshot('preTestEnginePriceFeed', AaveV3Polygon.POOL);

    payload.execute();

    createConfigurationSnapshot('postTestEnginePriceFeed', AaveV3Polygon.POOL);

    diffReports('preTestEnginePriceFeed', 'postTestEnginePriceFeed');

    _validateAssetSourceOnOracle(
      AaveV3Polygon.POOL_ADDRESSES_PROVIDER,
      AaveV3PolygonAssets.USDC_UNDERLYING,
      AaveV3PolygonAssets.USDC_ORACLE
    );
  }

  function testEModeCategoryUpdates() public {
    vm.selectFork(polygonFork);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEnginePolLib.deploy());
    AaveV3PolygonEModeCategoryUpdate payload = new AaveV3PolygonEModeCategoryUpdate(engine);

    vm.startPrank(AaveV3Polygon.ACL_ADMIN);
    AaveV3Polygon.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    DataTypes.EModeCategory memory eModeCategoryDataBefore = AaveV3Polygon
      .POOL
      .getEModeCategoryData(1);

    createConfigurationSnapshot('preTestEngineEModeCategoryUpdate', AaveV3Polygon.POOL);

    payload.execute();

    createConfigurationSnapshot('postTestEngineEModeCategoryUpdate', AaveV3Polygon.POOL);

    diffReports('preTestEngineEModeCategoryUpdate', 'postTestEngineEModeCategoryUpdate');

    eModeCategoryDataBefore.ltv = 97_40;
    eModeCategoryDataBefore.liquidationThreshold = 97_60;
    eModeCategoryDataBefore.liquidationBonus = 101_50; // 100_00 + 1_50

    _validateEmodeCategory(AaveV3Polygon.POOL_ADDRESSES_PROVIDER, 1, eModeCategoryDataBefore);
  }

  function testEModeCategoryUpdatesWrongBonus() public {
    vm.selectFork(avalancheFork);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEngineAvaLib.deploy());
    AaveV3AvalancheEModeCategoryUpdateEdgeBonus payload = new AaveV3AvalancheEModeCategoryUpdateEdgeBonus(
        engine
      );

    vm.startPrank(AaveV3Avalanche.ACL_ADMIN);
    AaveV3Avalanche.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    vm.expectRevert(bytes('INVALID_LT_LB_RATIO'));
    payload.execute();
  }

  // TODO manage this after testFail* deprecation.
  function testFailEModeCategoryUpdatesNoChange() public {
    vm.selectFork(avalancheFork);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEngineAvaLib.deploy());
    AaveV3AvalancheEModeCategoryUpdateNoChange payload = new AaveV3AvalancheEModeCategoryUpdateNoChange(
        engine
      );

    DataTypes.EModeCategory memory eModeCategoryDataBefore = AaveV3Avalanche
      .POOL
      .getEModeCategoryData(1);

    vm.startPrank(AaveV3Avalanche.ACL_ADMIN);
    AaveV3Avalanche.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    vm.expectEmit(true, true, true, true);
    emit EModeCategoryAdded(
      1,
      eModeCategoryDataBefore.ltv,
      eModeCategoryDataBefore.liquidationThreshold,
      eModeCategoryDataBefore.liquidationBonus,
      eModeCategoryDataBefore.priceSource,
      eModeCategoryDataBefore.label
    );

    payload.execute();
  }

  // Same as testFailEModeCategoryUpdatesNoChange, but this time should work, as we are not expecting any event emitted
  function testEModeCategoryUpdatesNoChange() public {
    vm.selectFork(avalancheFork);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEngineAvaLib.deploy());
    AaveV3AvalancheEModeCategoryUpdateNoChange payload = new AaveV3AvalancheEModeCategoryUpdateNoChange(
        engine
      );

    vm.startPrank(AaveV3Avalanche.ACL_ADMIN);
    AaveV3Avalanche.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    DataTypes.EModeCategory memory eModeCategoryDataBefore = AaveV3Avalanche
      .POOL
      .getEModeCategoryData(1);

    createConfigurationSnapshot('preTestEngineEModeCategoryNoChange', AaveV3Avalanche.POOL);

    payload.execute();

    createConfigurationSnapshot('postTestEngineEModeCategoryNoChange', AaveV3Avalanche.POOL);

    diffReports('preTestEngineEModeCategoryNoChange', 'postTestEngineEModeCategoryNoChange');

    _validateEmodeCategory(AaveV3Avalanche.POOL_ADDRESSES_PROVIDER, 1, eModeCategoryDataBefore);
  }

  function testAssetEModeUpdates() public {
    vm.selectFork(mainnetFork);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEngineEthLib.deploy());
    AaveV3EthereumAssetEModeUpdate payload = new AaveV3EthereumAssetEModeUpdate(engine);

    vm.startPrank(AaveV3Ethereum.ACL_ADMIN);
    AaveV3Ethereum.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    createConfigurationSnapshot('preTestEngineAssetEModeUpdate', AaveV3Ethereum.POOL);

    payload.execute();

    createConfigurationSnapshot('postTestEngineAssetEModeUpdate', AaveV3Ethereum.POOL);

    diffReports('preTestEngineAssetEModeUpdate', 'postTestEngineAssetEModeUpdate');

    assertEq(
      AaveV3Ethereum.AAVE_PROTOCOL_DATA_PROVIDER.getReserveEModeCategory(
        AaveV3EthereumAssets.rETH_UNDERLYING
      ),
      1
    );
  }

  function _bpsToRay(uint256 amount) internal pure returns (uint256) {
    return (amount * 1e27) / 10_000;
  }
}
