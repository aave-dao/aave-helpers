// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Test, Vm} from 'forge-std/Test.sol';
import {console2} from 'forge-std/console2.sol';

contract SeatbeltUtils is Test {
  error FfiFailed();

  function generateSeatbeltReport(
    string memory name,
    address payloadsController,
    bytes memory payloadBytecode
  ) internal {
    string[] memory inputs = new string[](11);
    inputs[0] = 'npx';
    inputs[1] = '@bgd-labs/cli@^0.0.47';
    inputs[2] = 'seatbelt-report';
    inputs[3] = '--chainId';
    inputs[4] = vm.toString(block.chainid);
    inputs[5] = '--payloadsController';
    inputs[6] = vm.toString(payloadsController);
    inputs[7] = '--payloadBytecode';
    inputs[8] = vm.toString(payloadBytecode);
    inputs[9] = '--output';
    inputs[10] = string.concat('./reports/seatbelt/', name);

    Vm.FfiResult memory f = vm.tryFfi(inputs);
    if (f.exitCode != 0) {
      console2.logString(string(f.stderr));
    }
  }
}
