// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5 <0.9.0;

import 'forge-std/Test.sol';
import {IPool} from 'aave-address-book/AaveV3.sol';
import {ReserveConfig} from 'aave-v3-origin-tests/utils/ProtocolV3TestBase.sol';
import {SnapshotHelpersV3} from './SnapshotHelpersV3.sol';
import {ProtocolV3TestBase as BaseProtocolV3TestBase} from '../../src/ProtocolV3TestBase.sol';

/**
 * only applicable to harmony at this point
 */
contract ProtocolV3TestBase is BaseProtocolV3TestBase {
  SnapshotHelpersV3 public snapshotHelper;

  function setUp() public virtual {
    snapshotHelper = new SnapshotHelpersV3();
    vm.makePersistent(address(snapshotHelper));
    vm.allowCheatcodes(address(snapshotHelper));
  }

  /**
   * @dev Generates a markdown compatible snapshot of the whole pool configuration into `/reports`.
   * @param reportName filename suffix for the generated reports.
   * @param pool the pool to be snapshot
   * @return ReserveConfig[] list of configs
   */
  function createConfigurationSnapshot(
    string memory reportName,
    IPool pool
  ) public override returns (ReserveConfig[] memory) {
    return createConfigurationSnapshot(reportName, pool, true, true, true, true);
  }

  function createConfigurationSnapshot(
    string memory reportName,
    IPool pool,
    bool reserveConfigs,
    bool strategyConfigs,
    bool eModeConigs,
    bool poolConfigs
  ) public override returns (ReserveConfig[] memory) {
    ReserveConfig[] memory configs = _getReservesConfigs(pool);
    _switchOffZkVm();
    return
      snapshotHelper.createConfigurationSnapshot(
        reportName,
        pool,
        reserveConfigs,
        strategyConfigs,
        eModeConigs,
        poolConfigs,
        configs
      );
  }

  function _writeEModeConfigs(string memory path, IPool pool) internal override {
    _switchOffZkVm();
    return snapshotHelper.writeEModeConfigs(path, pool);
  }

  function _writeStrategyConfigs(
    string memory path,
    ReserveConfig[] memory configs
  ) internal override {
    _switchOffZkVm();
    return snapshotHelper.writeStrategyConfigs(path, configs);
  }

  function _writeReserveConfigs(
    string memory path,
    ReserveConfig[] memory configs,
    IPool pool
  ) internal override {
    _switchOffZkVm();
    return snapshotHelper.writeReserveConfigs(path, configs, pool);
  }

  function _writePoolConfiguration(string memory path, IPool pool) internal override {
    _switchOffZkVm();
    return snapshotHelper.writePoolConfiguration(path, pool);
  }

  function _switchOffZkVm() internal {
    (bool success, ) = address(vm).call(abi.encodeWithSignature('zkVm(bool)', false));
    require(success, 'ERROR SWITCHING OFF ZKVM');
  }
}
