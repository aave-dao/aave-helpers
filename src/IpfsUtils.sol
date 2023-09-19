// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import {Vm} from 'forge-std/Vm.sol';
import {console2} from 'forge-std/console2.sol';

library IpfsUtils {
  error FfiFailed();

  function ipfsHashFile(Vm vm, string memory filePath, bool upload) internal returns (bytes32) {
    string[] memory inputs = new string[](7);
    inputs[0] = 'npx';
    inputs[1] = '--yes';
    inputs[2] = '-s';
    inputs[3] = '@bgd-labs/aave-cli@0.0.24-34c06df8b6ba4225f0828e126ea62096c8e57d9f.0';
    inputs[4] = 'ipfs';
    inputs[5] = filePath;
    if (upload) {
      inputs[6] = '-u';
    }
    Vm.FfiResult memory f = vm.tryFfi(inputs);
    if (f.exit_code != 0) {
      console2.logString(string(f.stderr));
      revert FfiFailed();
    }
    require(f.stdout.length != 0, 'CALCULATED_HASH_IS_ZERO');
    console2.logString('Info: This preview will only work when the file has been uploaded to ipfs');
    console2.logString(
      string(
        abi.encodePacked(
          'Preview: https://app.aave.com/governance/ipfs-preview/?ipfsHash=',
          vm.toString(f.stdout)
        )
      )
    );
    return bytes32(f.stdout);
  }
}
