// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {V4DiffWriter} from 'src/dependencies/v4/V4DiffWriter.sol';
import {Types} from 'src/dependencies/v4/Types.sol';

/// @title V4DiffWriterHarness
/// @notice Harness contract that exposes internal helpers as external entrypoints
contract V4DiffWriterHarness {
  function writeSnapshotJson(string memory reportName, Types.V4Snapshot memory snapshot) external {
    V4DiffWriter.writeSnapshotJson(reportName, snapshot);
  }

  function writeSpokeReserves(
    string memory path,
    Types.SpokeReserveSnapshot[] memory reserves
  ) external {
    V4DiffWriter._writeSpokeReserves(path, reserves);
  }

  function serReserve(Types.SpokeReserveSnapshot memory r) external returns (string memory) {
    return V4DiffWriter._serReserve(r);
  }

  function writeSpokeLiqConfigs(
    string memory path,
    Types.SpokeLiquidationSnapshot[] memory configs
  ) external {
    V4DiffWriter._writeSpokeLiqConfigs(path, configs);
  }

  function writeHubAssets(string memory path, Types.HubAssetSnapshot[] memory assets) external {
    V4DiffWriter._writeHubAssets(path, assets);
  }

  function serializeHubAsset(Types.HubAssetSnapshot memory a) external returns (string memory) {
    return V4DiffWriter._serializeHubAsset(a);
  }

  function writeSpokeConfigs(
    string memory path,
    Types.SpokeConfigSnapshot[] memory configs
  ) external {
    V4DiffWriter._writeSpokeConfigs(path, configs);
  }
}
