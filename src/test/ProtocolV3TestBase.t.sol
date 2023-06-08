// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {ProtocolV3_0_1TestBase, ReserveConfig} from '../ProtocolV3TestBase.sol';
import {AaveV3Polygon} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveV3Optimism, AaveV3OptimismAssets} from 'aave-address-book/AaveV3Optimism.sol';

contract ProtocolV3TestBaseTest is ProtocolV3_0_1TestBase {
  function setUp() public {
    vm.createSelectFork('polygon', 36329200);
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

contract ProtocolV3TestE2ETestAsset is ProtocolV3_0_1TestBase {
  function setUp() public {
    vm.createSelectFork('optimism', 105213914);
  }

  function testFail_e2eTestAsset() public {
    ReserveConfig[] memory configs = _getReservesConfigs(AaveV3Optimism.POOL);
    e2eTestAsset(
      AaveV3Optimism.POOL,
      _findReserveConfig(configs, AaveV3OptimismAssets.DAI_UNDERLYING),
      _findReserveConfig(configs, AaveV3OptimismAssets.MAI_UNDERLYING)
    );
  }

  function test_e2eTestAsset() public {
    ReserveConfig[] memory configs = _getReservesConfigs(AaveV3Optimism.POOL);
    e2eTestAsset(
      AaveV3Optimism.POOL,
      _findReserveConfig(configs, AaveV3OptimismAssets.DAI_UNDERLYING),
      _findReserveConfig(configs, AaveV3OptimismAssets.USDC_UNDERLYING)
    );
  }
}

contract ProtocolV3TestE2ETestAll is ProtocolV3_0_1TestBase {
  function setUp() public {
    vm.createSelectFork('optimism', 105213914);
  }

  function test_e2e() public {
    e2eTest(AaveV3Optimism.POOL);
  }
}

contract ProtocolV3TestE2ETestSnapshot is ProtocolV3_0_1TestBase {
  function setUp() public {
    vm.createSelectFork('optimism', 105213914);
  }

  function test_snapshot() public {
    createConfigurationSnapshot('snapshot', AaveV3Optimism.POOL, true, false, false, false);
  }
}
