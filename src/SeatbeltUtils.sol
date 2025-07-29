// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Vm} from 'forge-std/Vm.sol';
import {console2} from 'forge-std/console2.sol';

library SeatbeltUtils {
  error FfiFailed();

  function generateReport(Vm vm, address payloadsController, address payload, string memory name) internal {
    string[] memory inputs = new string[](11);
    inputs[0] = 'npx';
    inputs[1] = '@bgd-labs/cli@^0.0.36';
    inputs[2] = 'seatbelt-report';
    inputs[3] = '--chainId';
    inputs[4] = vm.toString(block.chainid);
    inputs[5] = '--payloadsController';
    inputs[6] = vm.toString(payloadsController);
    inputs[7] = '--payload';
    inputs[8] = vm.toString(payload);
    inputs[9] = '--output';
    inputs[10] = string.concat('./reports/seatbelt/', name);

    Vm.FfiResult memory f = vm.tryFfi(inputs);
    if (f.exitCode != 0) {
      console2.logString(string(f.stderr));
      revert FfiFailed();
    }
  }
}
