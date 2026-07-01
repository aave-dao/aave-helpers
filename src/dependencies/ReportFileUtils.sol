// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Vm} from 'forge-std/Vm.sol';

/// @title ReportFileUtils
/// @notice Ensures a report/snapshot file exists before it is written to.
/// @dev Foundry bug: when isolation is enabled via the inline forge-config isolate annotation under a
/// non-default profile (e.g. `FOUNDRY_PROFILE=test`), the per-test config loses its absolute `root`, so
/// the `fs_permissions` check rejects creating a not-yet-existing file (only overwriting an existing one
/// works). Snapshot generation therefore reverts on a clean checkout.
/// `vm.ffi` bypasses the cheatcode `fs_permissions` check, so we pre-create the file with it and let
/// the subsequent writes hit an existing path.
/// See https://github.com/foundry-rs/foundry/issues/15512
library ReportFileUtils {
  Vm private constant vm = Vm(address(uint160(uint256(keccak256('hevm cheat code')))));

  function ensureExists(string memory path) internal {
    string[] memory inputs = new string[](3);
    inputs[0] = 'bash';
    inputs[1] = '-c';
    inputs[2] = string.concat(
      'f=\'',
      path,
      '\'; mkdir -p "$(dirname "$f")"; [ -f "$f" ] || printf "{}" > "$f"'
    );
    vm.ffi(inputs);
  }
}
