// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {ProtocolV3TestBase, ReserveConfig} from '../src/ProtocolV3TestBase.sol';
import {AaveV3Polygon, AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';
import {PayloadWithEmit} from '../../tests/mocks/PayloadWithEmit.sol';

contract ProtocolV3TestBaseTest is ProtocolV3TestBase {
  function setUp() public override {
    // TODO: add zkSync market once activated
    vm.createSelectFork('polygon', 47135218);
    super.setUp();
  }

  function test_xe2eTestDPI() public {
    ReserveConfig[] memory configs = _getReservesConfigs(AaveV3Polygon.POOL);
    e2eTestAsset(
      AaveV3Polygon.POOL,
      _findReserveConfig(configs, AaveV3PolygonAssets.WMATIC_UNDERLYING),
      _findReserveConfig(configs, AaveV3PolygonAssets.DPI_UNDERLYING)
    );
  }

  // function test_e2e() public {
  //   e2eTest(AaveV3Polygon.POOL);
  // }

  // function testSnapshot() public {
  //   this.createConfigurationSnapshot('pre-x', AaveV3Polygon.POOL);
  //   this.createConfigurationSnapshot('post-x', AaveV3Polygon.POOL);

  //   // requires --ffi
  //   diffReports('pre-x', 'post-x');
  // }
}