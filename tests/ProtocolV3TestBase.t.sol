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

contract ProtocolV3TestStorageValidation is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('mainnet', 24655671);
  }

  function test_noExecutorStorageChange_passes() public {
    defaultTest(
      'V3StorageValidation_pass',
      AaveV3Ethereum.POOL,
      address(new PayloadWithEmit()),
      false,
      false
    );
  }

  function test_executorStorageChange_reverts() public {
    address payload = address(new PayloadWithStorage());
    vm.expectRevert();
    this.defaultTest('V3StorageValidation_fail', AaveV3Ethereum.POOL, payload, false, false);
  }
}
