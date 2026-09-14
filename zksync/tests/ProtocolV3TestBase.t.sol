// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {AaveV3ZkSync} from 'aave-address-book/AaveV3ZkSync.sol';
import {ProtocolV3TestBase} from '../src/ProtocolV3TestBase.sol';
import {PayloadWithEmit} from '../../tests/mocks/PayloadWithEmit.sol';
import {IPool, DataTypes} from 'aave-address-book/AaveV3.sol';
import {ReserveConfig} from 'aave-v3-origin-tests/utils/ProtocolV3TestBase.sol';

contract ProtocolV3TestBaseTest is ProtocolV3TestBase {
  PayloadWithEmit payload;

  function setUp() public override {
    vm.createSelectFork('zksync', 64899746);
    payload = new PayloadWithEmit();

    super.setUp();
  }

  function test_helpers() public {
    defaultTest('zksync', AaveV3ZkSync.POOL, address(payload));
  }

  function test_snapshotLegacyConfiguration() public {
    ReserveConfig[] memory configs = new ReserveConfig[](1);
    configs[0] = _getReservesConfigs(AaveV3ZkSync.POOL)[0];
    string memory key = string.concat('.reserves.', vm.toString(configs[0].underlying));
    // Set unrelated bits too, including the bits adjacent to the legacy fields.
    uint256 unrelated = ~((uint256(type(uint40).max) << 212) | (uint256(3) << 61));
    for (uint256 flags = 0; flags < 4; flags++) {
      uint40 debtCeiling = flags % 2 == 0 ? 0 : type(uint40).max;
      _mockConfiguration(
        configs[0].underlying,
        unrelated | (uint256(debtCeiling) << 212) | (flags << 61)
      );
      _switchOffZkVm();
      snapshotHelper.createConfigurationSnapshot(
        'legacy-configuration',
        AaveV3ZkSync.POOL,
        true,
        false,
        false,
        false,
        configs
      );
      string memory json = vm.readFile('./reports/legacy-configuration.json');
      assertEq(vm.parseJsonUint(json, string.concat(key, '.debtCeiling')), debtCeiling);
      assertEq(vm.parseJsonBool(json, string.concat(key, '.isSiloed')), flags & 2 != 0);
      assertEq(
        vm.parseJsonBool(json, string.concat(key, '.isBorrowableInIsolation')),
        flags & 1 != 0
      );
    }
  }

  function test_goodCollateralSkipsIsolatedReserve() public {
    ReserveConfig[] memory configs = _collateralCandidates();
    _mockConfiguration(configs[0].underlying, uint256(1) << 212);
    // Virtual accounting (bit 252) must not be mistaken for a debt ceiling.
    _mockConfiguration(configs[1].underlying, uint256(1) << 252);
    assertEq(_getGoodCollateral(configs, AaveV3ZkSync.POOL).underlying, configs[1].underlying);
  }

  function test_goodCollateralRejectsOnlyIsolatedReserves() public {
    ReserveConfig[] memory configs = _collateralCandidates();
    _mockConfiguration(configs[0].underlying, uint256(1) << 212);
    _mockConfiguration(configs[1].underlying, uint256(type(uint40).max) << 212);
    vm.expectRevert('ERROR: No usable collateral found');
    this.getGoodCollateral(configs);
  }

  function getGoodCollateral(
    ReserveConfig[] memory configs
  ) external view returns (ReserveConfig memory) {
    return _getGoodCollateral(configs, AaveV3ZkSync.POOL);
  }

  function _collateralCandidates() internal pure returns (ReserveConfig[] memory configs) {
    configs = new ReserveConfig[](2);
    for (uint256 i = 0; i < configs.length; i++) {
      configs[i].underlying = address(uint160(i + 1));
      configs[i].isActive = true;
      configs[i].usageAsCollateralEnabled = true;
      configs[i].ltv = 8000;
    }
  }

  function _mockConfiguration(address asset, uint256 data) internal {
    vm.mockCall(
      address(AaveV3ZkSync.POOL),
      abi.encodeCall(IPool.getConfiguration, (asset)),
      abi.encode(DataTypes.ReserveConfigurationMap({data: data}))
    );
  }
}
