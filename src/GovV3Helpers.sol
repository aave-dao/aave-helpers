// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Vm} from 'forge-std/Vm.sol';
import {console2} from 'forge-std/console2.sol';


library GovHelpers {
  error ExecutorNotFound();
  error LongBytesNotSupportedYet();

  struct Payload {
    address target;
    uint256 value;
    string signature;
    bytes callData;
    bool withDelegatecall;
  }

  function ipfsHashFile(Vm vm, string memory filePath, bool upload) internal returns (bytes32) {
    string[] memory inputs = new string[](8);
    inputs[0] = 'npx';
    inputs[1] = '--yes';
    inputs[2] = '-s';
    inputs[3] = '@bgd-labs/aave-cli';
    inputs[4] = 'ipfs';
    inputs[5] = filePath;
    inputs[6] = '-u';
    inputs[7] = vm.toString(upload);
    bytes memory bs58Hash = vm.ffi(inputs);
    // currenty there is no better way as ffi silently fails
    // revisit once https://github.com/foundry-rs/foundry/pull/4908 progresses
    require(
      bs58Hash.length != 0,
      'CALCULATED_HASH_IS_ZERO_CHECK_IF_YARN_DEPENDENCIES_ARE_INSTALLED'
    );
    console2.logString('Info: This preview will only work when the file has been uploaded to ipfs');
    console2.logString(
      string(
        abi.encodePacked(
          'Preview: https://app.aave.com/governance/ipfs-preview/?ipfsHash=',
          vm.toString(bs58Hash)
        )
      )
    );
    return bytes32(bs58Hash);
  }

  function ipfsHashFile(Vm vm, string memory filePath) internal returns (bytes32) {
    return ipfsHashFile(vm, filePath, false);
  }

  function buildPayload(address payloadAddress) internal pure returns (Payload memory) {
   require(payloadAddress != address(0), 'NON_ZERO_TARGET');
    return
      Payload({
      target: payloadAddress,
      value: 0,
      signature: 'execute()',
      callData: '',
      withDelegatecall: true
    });
  }

}