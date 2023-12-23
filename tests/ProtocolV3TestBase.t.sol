// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {ProtocolV3LegacyTestBase, ProtocolV3TestBase, ReserveConfig} from '../src/ProtocolV3TestBase.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3Polygon, AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveV3Optimism, AaveV3OptimismAssets} from 'aave-address-book/AaveV3Optimism.sol';
import {AaveV3Avalanche, AaveV3AvalancheAssets} from 'aave-address-book/AaveV3Avalanche.sol';
import {PayloadWithEmit} from './mocks/PayloadWithEmit.sol';

contract ProtocolV3TestBaseTest is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('polygon', 47135218);
  }

  function test_e2eTestDPI() public {
    ReserveConfig[] memory configs = _getReservesConfigs(AaveV3Optimism.POOL);
    e2eTestAsset(
      AaveV3Optimism.POOL,
      _findReserveConfig(configs, AaveV3PolygonAssets.WMATIC_UNDERLYING),
      _findReserveConfig(configs, AaveV3PolygonAssets.DPI_UNDERLYING)
    );
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
    vm.createSelectFork('optimism', 105565839);
  }

  function test_e2eTestAssetMAI() public {
    ReserveConfig[] memory configs = _getReservesConfigs(AaveV3Optimism.POOL);
    e2eTestAsset(
      AaveV3Optimism.POOL,
      _findReserveConfig(configs, AaveV3OptimismAssets.DAI_UNDERLYING),
      _findReserveConfig(configs, AaveV3OptimismAssets.MAI_UNDERLYING)
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

contract ProtocolV3TestE2ETestAll is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('optimism', 105213914);
  }

  function test_e2e() public {
    e2eTest(AaveV3Optimism.POOL);
  }
}

contract ProtocolV3TestE2ETestAvalancheAll is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('avalanche', 38700698);
  }

  function test_e2e() public {
    e2eTest(AaveV3Avalanche.POOL);
  }

  function test_deal() public {
    deal2(AaveV3AvalancheAssets.USDC_UNDERLYING, address(this), 1000);
  }
}

contract ProtocolV3TestE2ETestAllMainnet is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('mainnet', 18763779);
  }

  function test_e2e() public {
    e2eTest(AaveV3Ethereum.POOL);
  }
}

contract ProtocolV3TestE2ETestSnapshot is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('optimism', 105213914);
  }

  function test_snapshot() public {
    createConfigurationSnapshot('snapshot', AaveV3Optimism.POOL, true, false, false, false);
  }
}
