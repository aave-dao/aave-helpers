// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IERC20Detailed} from 'aave-v3-core/contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {IPoolAddressesProvider} from 'aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPoolDataProvider} from 'aave-v3-core/contracts/interfaces/IPoolDataProvider.sol';
import {IPool} from 'aave-v3-core/contracts/interfaces/IPool.sol';
import {IAaveOracle} from 'aave-v3-core/contracts/interfaces/IAaveOracle.sol';
import {IPoolConfigurator} from 'aave-v3-core/contracts/interfaces/IPoolConfigurator.sol';
import {IERC20Metadata} from 'solidity-utils/contracts/oz-common/interfaces/IERC20Metadata.sol';
import {ReserveConfiguration} from 'aave-v3-core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {ExtendedAggregatorV2V3Interface} from '../../src/interfaces/ExtendedAggregatorV2V3Interface.sol';
import {ProxyHelpers} from 'aave-v3-origin/../tests/utils/ProxyHelpers.sol';
import {CommonTestBase} from '../../src/CommonTestBase.sol';
import {IDefaultInterestRateStrategyV2} from 'aave-v3-core/contracts/interfaces/IDefaultInterestRateStrategyV2.sol';
import {ReserveConfig, ReserveTokens, DataTypes} from 'aave-v3-origin/../tests/utils/ProtocolV3TestBase.sol';
import {ProtocolV3TestBase as TestBase, LocalVars} from './ProtocolV3TestBase.sol';
import {ILegacyDefaultInterestRateStrategy} from '../../src/dependencies/ILegacyDefaultInterestRateStrategy.sol';
import {DiffUtils} from 'aave-v3-origin/../tests/utils/DiffUtils.sol';

contract SnapshotHelpersV3 is CommonTestBase, DiffUtils {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  function createConfigurationSnapshot(
    string memory reportName,
    IPool pool,
    bool reserveConfigs,
    bool strategyConfigs,
    bool eModeConigs,
    bool poolConfigs,
    ReserveConfig[] memory configs
  ) public returns (ReserveConfig[] memory) {
    _switchOnZkVm();
    string memory path = string(abi.encodePacked('./reports/', reportName, '.json'));
    // overwrite with empty json to later be extended
    vm.writeFile(
      path,
      '{ "eModes": {}, "reserves": {}, "strategies": {}, "poolConfiguration": {} }'
    );
    vm.serializeUint('root', 'chainId', block.chainid);
    if (reserveConfigs) writeReserveConfigs(path, configs, pool);
    if (strategyConfigs) writeStrategyConfigs(path, configs);
    if (eModeConigs) writeEModeConfigs(path, configs, pool);
    if (poolConfigs) writePoolConfiguration(path, pool);

    return configs;
  }

  function writeEModeConfigs(
    string memory path,
    ReserveConfig[] memory configs,
    IPool pool
  ) public {
    _switchOnZkVm();
    // keys for json stringification
    string memory eModesKey = 'emodes';
    string memory content = '{}';
    vm.serializeJson(eModesKey, '{}');

    uint256[] memory usedCategories = new uint256[](configs.length);
    for (uint256 i = 0; i < configs.length; i++) {
      if (!_isInUint256Array(usedCategories, configs[i].eModeCategory)) {
        usedCategories[i] = configs[i].eModeCategory;
        DataTypes.EModeCategory memory category = pool.getEModeCategoryData(
          uint8(configs[i].eModeCategory)
        );
        string memory key = vm.toString(configs[i].eModeCategory);
        vm.serializeJson(key, '{}');
        vm.serializeUint(key, 'eModeCategory', configs[i].eModeCategory);
        vm.serializeString(key, 'label', category.label);
        vm.serializeUint(key, 'ltv', category.ltv);
        vm.serializeUint(key, 'liquidationThreshold', category.liquidationThreshold);
        vm.serializeUint(key, 'liquidationBonus', category.liquidationBonus);
        string memory object = vm.serializeAddress(key, 'priceSource', category.priceSource);
        content = vm.serializeString(eModesKey, key, object);
      }
    }
    string memory output = vm.serializeString('root', 'eModes', content);
    vm.writeJson(output, path);
  }

  function writeStrategyConfigs(string memory path, ReserveConfig[] memory configs) public {
    _switchOnZkVm();
    // keys for json stringification
    string memory strategiesKey = 'stategies';
    string memory content = '{}';
    vm.serializeJson(strategiesKey, '{}');

    for (uint256 i = 0; i < configs.length; i++) {
      IDefaultInterestRateStrategyV2 strategyV2 = IDefaultInterestRateStrategyV2(
        configs[i].interestRateStrategy
      );
      ILegacyDefaultInterestRateStrategy strategyV1 = ILegacyDefaultInterestRateStrategy(
        configs[i].interestRateStrategy
      );
      address asset = configs[i].underlying;
      string memory key = vm.toString(asset);
      vm.serializeJson(key, '{}');
      vm.serializeString(key, 'address', vm.toString(configs[i].interestRateStrategy));
      string memory object;
      try strategyV1.getVariableRateSlope1() {
        vm.serializeString(
          key,
          'baseStableBorrowRate',
          vm.toString(strategyV1.getBaseStableBorrowRate())
        );
        vm.serializeString(key, 'stableRateSlope1', vm.toString(strategyV1.getStableRateSlope1()));
        vm.serializeString(key, 'stableRateSlope2', vm.toString(strategyV1.getStableRateSlope2()));
        vm.serializeString(
          key,
          'baseVariableBorrowRate',
          vm.toString(strategyV1.getBaseVariableBorrowRate())
        );
        vm.serializeString(
          key,
          'variableRateSlope1',
          vm.toString(strategyV1.getVariableRateSlope1())
        );
        vm.serializeString(
          key,
          'variableRateSlope2',
          vm.toString(strategyV1.getVariableRateSlope2())
        );
        vm.serializeString(
          key,
          'optimalStableToTotalDebtRatio',
          vm.toString(strategyV1.OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO())
        );
        vm.serializeString(
          key,
          'maxExcessStableToTotalDebtRatio',
          vm.toString(strategyV1.MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO())
        );
        vm.serializeString(key, 'optimalUsageRatio', vm.toString(strategyV1.OPTIMAL_USAGE_RATIO()));
        object = vm.serializeString(
          key,
          'maxExcessUsageRatio',
          vm.toString(strategyV1.MAX_EXCESS_USAGE_RATIO())
        );
      } catch {
        vm.serializeString(
          key,
          'baseVariableBorrowRate',
          vm.toString(strategyV2.getBaseVariableBorrowRate(asset))
        );
        vm.serializeString(
          key,
          'variableRateSlope1',
          vm.toString(strategyV2.getVariableRateSlope1(asset))
        );
        vm.serializeString(
          key,
          'variableRateSlope2',
          vm.toString(strategyV2.getVariableRateSlope2(asset))
        );
        vm.serializeString(
          key,
          'maxVariableBorrowRate',
          vm.toString(strategyV2.getMaxVariableBorrowRate(asset))
        );
        object = vm.serializeString(
          key,
          'optimalUsageRatio',
          vm.toString(strategyV2.getOptimalUsageRatio(asset))
        );
      }
      content = vm.serializeString(strategiesKey, key, object);
    }
    string memory output = vm.serializeString('root', 'strategies', content);
    vm.writeJson(output, path);
  }

  function writeReserveConfigs(
    string memory path,
    ReserveConfig[] memory configs,
    IPool pool
  ) public {
    _switchOnZkVm();
    // keys for json stringification
    string memory reservesKey = 'reserves';
    string memory content = '{}';

    IPoolAddressesProvider addressesProvider = IPoolAddressesProvider(pool.ADDRESSES_PROVIDER());
    IAaveOracle oracle = IAaveOracle(addressesProvider.getPriceOracle());
    for (uint256 i = 0; i < configs.length; i++) {
      ReserveConfig memory config = configs[i];
      ExtendedAggregatorV2V3Interface assetOracle = ExtendedAggregatorV2V3Interface(
        oracle.getSourceOfAsset(config.underlying)
      );

      string memory key = vm.toString(config.underlying);
      vm.serializeString(key, 'symbol', config.symbol);
      vm.serializeUint(key, 'ltv', config.ltv);
      vm.serializeUint(key, 'liquidationThreshold', config.liquidationThreshold);
      vm.serializeUint(key, 'liquidationBonus', config.liquidationBonus);
      vm.serializeUint(key, 'liquidationProtocolFee', config.liquidationProtocolFee);
      vm.serializeUint(key, 'reserveFactor', config.reserveFactor);
      vm.serializeUint(key, 'decimals', config.decimals);
      vm.serializeUint(key, 'borrowCap', config.borrowCap);
      vm.serializeUint(key, 'supplyCap', config.supplyCap);
      vm.serializeUint(key, 'debtCeiling', config.debtCeiling);
      vm.serializeUint(key, 'eModeCategory', config.eModeCategory);
      vm.serializeBool(key, 'usageAsCollateralEnabled', config.usageAsCollateralEnabled);
      vm.serializeBool(key, 'borrowingEnabled', config.borrowingEnabled);
      vm.serializeBool(key, 'stableBorrowRateEnabled', config.stableBorrowRateEnabled);
      vm.serializeBool(key, 'isPaused', config.isPaused);
      vm.serializeBool(key, 'isActive', config.isActive);
      vm.serializeBool(key, 'isFrozen', config.isFrozen);
      vm.serializeBool(key, 'isSiloed', config.isSiloed);
      vm.serializeBool(key, 'isBorrowableInIsolation', config.isBorrowableInIsolation);
      vm.serializeBool(key, 'isFlashloanable', config.isFlashloanable);
      vm.serializeAddress(key, 'interestRateStrategy', config.interestRateStrategy);
      vm.serializeAddress(key, 'underlying', config.underlying);
      vm.serializeAddress(key, 'aToken', config.aToken);
      vm.serializeAddress(key, 'stableDebtToken', config.stableDebtToken);
      vm.serializeAddress(key, 'variableDebtToken', config.variableDebtToken);
      vm.serializeAddress(
        key,
        'aTokenImpl',
        ProxyHelpers.getInitializableAdminUpgradeabilityProxyImplementation(vm, config.aToken)
      );
      vm.serializeString(key, 'aTokenSymbol', IERC20Detailed(config.aToken).symbol());
      vm.serializeString(key, 'aTokenName', IERC20Detailed(config.aToken).name());
      vm.serializeAddress(
        key,
        'stableDebtTokenImpl',
        ProxyHelpers.getInitializableAdminUpgradeabilityProxyImplementation(
          vm,
          config.stableDebtToken
        )
      );
      vm.serializeString(
        key,
        'stableDebtTokenSymbol',
        IERC20Detailed(config.stableDebtToken).symbol()
      );
      vm.serializeString(key, 'stableDebtTokenName', IERC20Detailed(config.stableDebtToken).name());
      vm.serializeAddress(
        key,
        'variableDebtTokenImpl',
        ProxyHelpers.getInitializableAdminUpgradeabilityProxyImplementation(
          vm,
          config.variableDebtToken
        )
      );
      vm.serializeString(
        key,
        'variableDebtTokenSymbol',
        IERC20Detailed(config.variableDebtToken).symbol()
      );
      vm.serializeString(
        key,
        'variableDebtTokenName',
        IERC20Detailed(config.variableDebtToken).name()
      );
      vm.serializeAddress(key, 'oracle', address(assetOracle));
      if (address(assetOracle) != address(0)) {
        try assetOracle.description() returns (string memory name) {
          vm.serializeString(key, 'oracleDescription', name);
        } catch {
          try assetOracle.name() returns (string memory name) {
            vm.serializeString(key, 'oracleName', name);
          } catch {}
        }
        try assetOracle.decimals() returns (uint8 decimals) {
          vm.serializeUint(key, 'oracleDecimals', decimals);
        } catch {
          try assetOracle.DECIMALS() returns (uint8 decimals) {
            vm.serializeUint(key, 'oracleDecimals', decimals);
          } catch {}
        }
      }

      vm.serializeBool(key, 'virtualAccountingActive', config.virtualAccActive);
      vm.serializeUint(key, 'virtualBalance', config.virtualBalance);
      vm.serializeUint(key, 'aTokenUnderlyingBalance', config.aTokenUnderlyingBalance);

      string memory out = vm.serializeUint(
        key,
        'oracleLatestAnswer',
        uint256(oracle.getAssetPrice(config.underlying))
      );
      content = vm.serializeString(reservesKey, key, out);
    }
    string memory output = vm.serializeString('root', 'reserves', content);
    vm.writeJson(output, path);
  }

  function writePoolConfiguration(string memory path, IPool pool) public {
    _switchOnZkVm();
    // keys for json stringification
    string memory poolConfigKey = 'poolConfig';

    // addresses provider
    IPoolAddressesProvider addressesProvider = IPoolAddressesProvider(pool.ADDRESSES_PROVIDER());
    vm.serializeAddress(poolConfigKey, 'poolAddressesProvider', address(addressesProvider));

    // oracles
    vm.serializeAddress(poolConfigKey, 'oracle', addressesProvider.getPriceOracle());
    vm.serializeAddress(
      poolConfigKey,
      'priceOracleSentinel',
      addressesProvider.getPriceOracleSentinel()
    );

    // pool configurator
    IPoolConfigurator configurator = IPoolConfigurator(addressesProvider.getPoolConfigurator());
    vm.serializeAddress(poolConfigKey, 'poolConfigurator', address(configurator));
    vm.serializeAddress(
      poolConfigKey,
      'poolConfiguratorImpl',
      ProxyHelpers.getInitializableAdminUpgradeabilityProxyImplementation(vm, address(configurator))
    );

    // PoolDataProvider
    IPoolDataProvider pdp = IPoolDataProvider(addressesProvider.getPoolDataProvider());
    vm.serializeAddress(poolConfigKey, 'protocolDataProvider', address(pdp));

    // pool
    vm.serializeAddress(
      poolConfigKey,
      'poolImpl',
      ProxyHelpers.getInitializableAdminUpgradeabilityProxyImplementation(vm, address(pool))
    );
    string memory content = vm.serializeAddress(poolConfigKey, 'pool', address(pool));

    string memory output = vm.serializeString('root', 'poolConfig', content);
    vm.writeJson(output, path);
  }

  function _isInUint256Array(
    uint256[] memory haystack,
    uint256 needle
  ) internal pure returns (bool) {
    for (uint256 i = 0; i < haystack.length; i++) {
      if (haystack[i] == needle) return true;
    }
    return false;
  }

  function _switchOnZkVm() internal {
    (bool success, ) = address(vm).call(abi.encodeWithSignature('zkVm(bool)', true));
    require(success, 'ERROR SWITCHING ON ZKVM');
  }
}
