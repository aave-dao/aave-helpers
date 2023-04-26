// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAaveV3ConfigEngine} from '../v3-config-engine/IAaveV3ConfigEngine.sol';
import {AaveV3PolygonMockListing} from './mocks/AaveV3PolygonMockListing.sol';
import {AaveV3EthereumMockCustomListing} from './mocks/AaveV3EthereumMockCustomListing.sol';
import {AaveV3EthereumMockCapUpdate} from './mocks/AaveV3EthereumMockCapUpdate.sol';
import {AaveV3AvalancheCollateralUpdate} from './mocks/AaveV3AvalancheCollateralUpdate.sol';
import {AaveV3PolygonBorrowUpdate} from './mocks/AaveV3PolygonBorrowUpdate.sol';
import {AaveV3PolygonPriceFeedUpdate} from './mocks/AaveV3PolygonPriceFeedUpdate.sol';
import {AaveV3PolygonEModeCategoryUpdate} from './mocks/AaveV3PolygonEModeCategoryUpdate.sol';
import {AaveV3OptimismMockRatesUpdate} from './mocks/AaveV3OptimismMockRatesUpdate.sol';
import {DeployRatesFactoryPolLib, DeployRatesFactoryEthLib, DeployRatesFactoryAvaLib, DeployRatesFactoryArbLib, DeployRatesFactoryOptLib} from '../../scripts/V3RateStrategyFactory.s.sol';
import {DeployEnginePolLib, DeployEngineEthLib, DeployEngineAvaLib, DeployEngineOptLib, DeployEngineArbLib} from '../../scripts/AaveV3ConfigEngine.s.sol';
import {AaveV3Ethereum, AaveV3Polygon, AaveV3Optimism, AaveV3Avalanche, AaveV3Arbitrum} from 'aave-address-book/AaveAddressBook.sol';
import {AaveV3OptimismAssets} from 'aave-address-book/AaveV3Optimism.sol';
import {AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';
import {IDefaultInterestRateStrategy} from 'aave-address-book/AaveV3.sol';
import {AaveV3PolygonRatesUpdates070322} from './mocks/gauntlet-updates/AaveV3PolygonRatesUpdates070322.sol';
import {AaveV3AvalancheRatesUpdates070322} from './mocks/gauntlet-updates/AaveV3AvalancheRatesUpdates070322.sol';
import {AaveV3OptimismRatesUpdates070322} from './mocks/gauntlet-updates/AaveV3OptimismRatesUpdates070322.sol';
import {AaveV3ArbitrumRatesUpdates070322} from './mocks/gauntlet-updates/AaveV3ArbitrumRatesUpdates070322.sol';
import '../ProtocolV3TestBase.sol';

contract AaveV3ConfigEngineTest is ProtocolV3TestBase {
  using stdStorage for StdStorage;

  function testListings() public {
    vm.createSelectFork(vm.rpcUrl('polygon'), 40037250);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEnginePolLib.deploy());
    AaveV3PolygonMockListing payload = new AaveV3PolygonMockListing(engine);

    vm.startPrank(AaveV3Polygon.ACL_ADMIN);
    AaveV3Polygon.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    ReserveConfig[] memory allConfigsBefore = _getReservesConfigs(AaveV3Polygon.POOL);

    createConfigurationSnapshot('preTestEngineListing', AaveV3Polygon.POOL);

    payload.execute();

    createConfigurationSnapshot('postTestEngineListing', AaveV3Polygon.POOL);

    diffReports('preTestEngineListing', 'postTestEngineListing');

    ReserveConfig[] memory allConfigsAfter = _getReservesConfigs(AaveV3Polygon.POOL);

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
      AaveV3Polygon.POOL_ADDRESSES_PROVIDER,
      _findReserveConfigBySymbol(allConfigsAfter, '1INCH'),
      ReserveTokens({
        aToken: engine.ATOKEN_IMPL(),
        stableDebtToken: engine.STOKEN_IMPL(),
        variableDebtToken: engine.VTOKEN_IMPL()
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
      _findReserveConfigBySymbol(allConfigsAfter, 'AAVE'),
      ReserveTokens({
        aToken: engine.ATOKEN_IMPL(),
        stableDebtToken: engine.STOKEN_IMPL(),
        variableDebtToken: engine.VTOKEN_IMPL()
      })
    );
  }

  function testListingsCustom() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 16775965);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEngineEthLib.deploy());
    AaveV3EthereumMockCustomListing payload = new AaveV3EthereumMockCustomListing(engine);

    vm.startPrank(AaveV3Ethereum.ACL_ADMIN);
    AaveV3Ethereum.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    ReserveConfig[] memory allConfigsBefore = _getReservesConfigs(AaveV3Ethereum.POOL);

    createConfigurationSnapshot('preTestEngineListingCustom', AaveV3Ethereum.POOL);

    payload.execute();

    createConfigurationSnapshot('postTestEngineListingCustom', AaveV3Ethereum.POOL);

    diffReports('preTestEngineListingCustom', 'postTestEngineListingCustom');

    ReserveConfig[] memory allConfigsAfter = _getReservesConfigs(AaveV3Ethereum.POOL);

    ReserveConfig memory expectedAssetConfig = ReserveConfig({
      symbol: '1INCH',
      underlying: 0x111111111117dC0aa78b770fA6A738034120C302,
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
      _findReserveConfigBySymbol(allConfigsAfter, '1INCH'),
      ReserveTokens({
        aToken: AaveV3Ethereum.DEFAULT_A_TOKEN_IMPL_REV_1,
        stableDebtToken: AaveV3Ethereum.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1,
        variableDebtToken: AaveV3Ethereum.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1
      })
    );

    _validateAssetSourceOnOracle(
      AaveV3Ethereum.POOL_ADDRESSES_PROVIDER,
      0x111111111117dC0aa78b770fA6A738034120C302,
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
    vm.createSelectFork(vm.rpcUrl('mainnet'), 16775971);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEngineEthLib.deploy());
    AaveV3EthereumMockCapUpdate payload = new AaveV3EthereumMockCapUpdate(engine);

    vm.startPrank(AaveV3Ethereum.ACL_ADMIN);
    AaveV3Ethereum.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    ReserveConfig[] memory allConfigsBefore = _getReservesConfigs(AaveV3Ethereum.POOL);

    createConfigurationSnapshot('preTestEngineCaps', AaveV3Ethereum.POOL);

    payload.execute();

    createConfigurationSnapshot('postTestEngineCaps', AaveV3Ethereum.POOL);

    diffReports('preTestEngineCaps', 'postTestEngineCaps');

    ReserveConfig[] memory allConfigsAfter = _getReservesConfigs(AaveV3Ethereum.POOL);

    ReserveConfig memory expectedAssetConfig = ReserveConfig({
      symbol: allConfigsBefore[6].symbol,
      underlying: allConfigsBefore[6].underlying,
      aToken: allConfigsBefore[6].aToken,
      variableDebtToken: allConfigsBefore[6].variableDebtToken,
      stableDebtToken: allConfigsBefore[6].stableDebtToken,
      decimals: allConfigsBefore[6].decimals,
      ltv: allConfigsBefore[6].ltv,
      liquidationThreshold: allConfigsBefore[6].liquidationThreshold,
      liquidationBonus: allConfigsBefore[6].liquidationBonus,
      liquidationProtocolFee: allConfigsBefore[6].liquidationProtocolFee,
      reserveFactor: allConfigsBefore[6].reserveFactor,
      usageAsCollateralEnabled: allConfigsBefore[6].usageAsCollateralEnabled,
      borrowingEnabled: allConfigsBefore[6].borrowingEnabled,
      interestRateStrategy: allConfigsBefore[6].interestRateStrategy,
      stableBorrowRateEnabled: allConfigsBefore[6].stableBorrowRateEnabled,
      isActive: allConfigsBefore[6].isActive,
      isFrozen: allConfigsBefore[6].isFrozen,
      isSiloed: allConfigsBefore[6].isSiloed,
      isBorrowableInIsolation: allConfigsBefore[6].isBorrowableInIsolation,
      isFlashloanable: allConfigsBefore[6].isFlashloanable,
      supplyCap: 1_000_000,
      borrowCap: allConfigsBefore[6].borrowCap,
      debtCeiling: allConfigsBefore[6].debtCeiling,
      eModeCategory: allConfigsBefore[6].eModeCategory
    });

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);
  }

  function testCollateralsUpdates() public {
    vm.createSelectFork(vm.rpcUrl('avalanche'), 27094357);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEngineAvaLib.deploy());
    AaveV3AvalancheCollateralUpdate payload = new AaveV3AvalancheCollateralUpdate(engine);

    vm.startPrank(AaveV3Avalanche.ACL_ADMIN);
    AaveV3Avalanche.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    ReserveConfig[] memory allConfigsBefore = _getReservesConfigs(AaveV3Avalanche.POOL);

    createConfigurationSnapshot('preTestEngineCollateral', AaveV3Avalanche.POOL);

    payload.execute();

    createConfigurationSnapshot('postTestEngineCollateral', AaveV3Avalanche.POOL);

    diffReports('preTestEngineCollateral', 'postTestEngineCollateral');

    ReserveConfig[] memory allConfigsAfter = _getReservesConfigs(AaveV3Avalanche.POOL);

    ReserveConfig memory expectedAssetConfig = ReserveConfig({
      symbol: allConfigsBefore[6].symbol,
      underlying: allConfigsBefore[6].underlying,
      aToken: allConfigsBefore[6].aToken,
      variableDebtToken: allConfigsBefore[6].variableDebtToken,
      stableDebtToken: allConfigsBefore[6].stableDebtToken,
      decimals: allConfigsBefore[6].decimals,
      ltv: 62_00,
      liquidationThreshold: 72_00,
      liquidationBonus: 106_00, // 100_00 + 6_00
      liquidationProtocolFee: allConfigsBefore[6].liquidationProtocolFee,
      reserveFactor: allConfigsBefore[6].reserveFactor,
      usageAsCollateralEnabled: allConfigsBefore[6].usageAsCollateralEnabled,
      borrowingEnabled: allConfigsBefore[6].borrowingEnabled,
      interestRateStrategy: allConfigsBefore[6].interestRateStrategy,
      stableBorrowRateEnabled: allConfigsBefore[6].stableBorrowRateEnabled,
      isActive: allConfigsBefore[6].isActive,
      isFrozen: allConfigsBefore[6].isFrozen,
      isSiloed: allConfigsBefore[6].isSiloed,
      isBorrowableInIsolation: allConfigsBefore[6].isBorrowableInIsolation,
      isFlashloanable: allConfigsBefore[6].isFlashloanable,
      supplyCap: allConfigsBefore[6].supplyCap,
      borrowCap: allConfigsBefore[6].borrowCap,
      debtCeiling: allConfigsBefore[6].debtCeiling,
      eModeCategory: allConfigsBefore[6].eModeCategory
    });

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);
  }

  function testBorrowsUpdates() public {
    vm.createSelectFork(vm.rpcUrl('polygon'), 40037250);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEnginePolLib.deploy());
    AaveV3PolygonBorrowUpdate payload = new AaveV3PolygonBorrowUpdate(engine);

    vm.startPrank(AaveV3Polygon.ACL_ADMIN);
    AaveV3Polygon.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    ReserveConfig[] memory allConfigsBefore = _getReservesConfigs(AaveV3Polygon.POOL);

    createConfigurationSnapshot('preTestEngineBorrow', AaveV3Polygon.POOL);

    payload.execute();

    createConfigurationSnapshot('postTestEngineBorrow', AaveV3Polygon.POOL);

    diffReports('preTestEngineBorrow', 'postTestEngineBorrow');

    ReserveConfig[] memory allConfigsAfter = _getReservesConfigs(AaveV3Polygon.POOL);

    ReserveConfig memory expectedAssetConfig = ReserveConfig({
      symbol: allConfigsBefore[6].symbol,
      underlying: allConfigsBefore[6].underlying,
      aToken: allConfigsBefore[6].aToken,
      variableDebtToken: allConfigsBefore[6].variableDebtToken,
      stableDebtToken: allConfigsBefore[6].stableDebtToken,
      decimals: allConfigsBefore[6].decimals,
      ltv: allConfigsBefore[6].ltv,
      liquidationThreshold: allConfigsBefore[6].liquidationThreshold,
      liquidationBonus: allConfigsBefore[6].liquidationBonus,
      liquidationProtocolFee: allConfigsBefore[6].liquidationProtocolFee,
      reserveFactor: 15_00,
      usageAsCollateralEnabled: allConfigsBefore[6].usageAsCollateralEnabled,
      borrowingEnabled: true,
      interestRateStrategy: allConfigsBefore[6].interestRateStrategy,
      stableBorrowRateEnabled: allConfigsBefore[6].stableBorrowRateEnabled,
      isActive: allConfigsBefore[6].isActive,
      isFrozen: allConfigsBefore[6].isFrozen,
      isSiloed: allConfigsBefore[6].isSiloed,
      isBorrowableInIsolation: allConfigsBefore[6].isBorrowableInIsolation,
      isFlashloanable: allConfigsBefore[6].isFlashloanable,
      supplyCap: allConfigsBefore[6].supplyCap,
      borrowCap: allConfigsBefore[6].borrowCap,
      debtCeiling: allConfigsBefore[6].debtCeiling,
      eModeCategory: allConfigsBefore[6].eModeCategory
    });

    _validateReserveConfig(expectedAssetConfig, allConfigsAfter);
  }

  function testRateStrategiesUpdates() public {
    vm.createSelectFork(vm.rpcUrl('optimism'), 78907810);

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
    vm.createSelectFork(vm.rpcUrl('polygon'), 40037250);

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
    vm.createSelectFork(vm.rpcUrl('avalanche'), 27094357);

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
    vm.createSelectFork(vm.rpcUrl('optimism'), 78907810);

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
    vm.createSelectFork(vm.rpcUrl('arbitrum'), 67332070);

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
    vm.createSelectFork(vm.rpcUrl('polygon'), 40037250);

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
    vm.createSelectFork(vm.rpcUrl('polygon'), 40037250);

    IAaveV3ConfigEngine engine = IAaveV3ConfigEngine(DeployEnginePolLib.deploy());
    AaveV3PolygonEModeCategoryUpdate payload = new AaveV3PolygonEModeCategoryUpdate(engine);

    vm.startPrank(AaveV3Polygon.ACL_ADMIN);
    AaveV3Polygon.ACL_MANAGER.addPoolAdmin(address(payload));
    vm.stopPrank();

    createConfigurationSnapshot('preTestEngineEModeCategoryUpdate', AaveV3Polygon.POOL);

    payload.execute();

    createConfigurationSnapshot('postTestEngineEModeCategoryUpdate', AaveV3Polygon.POOL);

    diffReports('preTestEngineEModeCategoryUpdate', 'postTestEngineEModeCategoryUpdate');

    // TODO: Add validation function
  }

  function _bpsToRay(uint256 amount) internal pure returns (uint256) {
    return (amount * 1e27) / 10_000;
  }
}
