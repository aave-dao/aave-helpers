// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {Script} from 'forge-std/Script.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {CapsPlusRiskSteward} from '../src/riskstewards/CapsPlusRiskSteward.sol';
import {IAaveV3ConfigEngine} from '../src/v3-config-engine/IAaveV3ConfigEngine.sol';
import {EngineFlags} from '../src/v3-config-engine/EngineFlags.sol';

/**
 * @title
 * @author
 * @notice Probably should be deployed via create2 so it can be executed accross chains without any change
 */
contract CapsPlusRiskStewardMainnet is Test {
  address public constant user = address(42);
  CapsPlusRiskSteward public steward;
  error FailedUpdate();

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'));
    steward = new CapsPlusRiskSteward(
      AaveV3Ethereum.AAVE_PROTOCOL_DATA_PROVIDER,
      IAaveV3ConfigEngine(AaveV3Ethereum.LISTING_ENGINE),
      user
    );
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    AaveV3Ethereum.ACL_MANAGER.addRiskAdmin(address(steward));
    vm.stopPrank();
  }

  /**
   * @notice This script doesn't broadcast as it's intended to be used via safe
   */
  function test_run() external {
    vm.startPrank(user);
    IAaveV3ConfigEngine.CapsUpdate[] memory capUpdates = new IAaveV3ConfigEngine.CapsUpdate[](1);
    capUpdates[0] = IAaveV3ConfigEngine.CapsUpdate(
      AaveV3EthereumAssets.DAI_UNDERLYING,
      350_000_000,
      EngineFlags.KEEP_CURRENT
    );

    bytes memory callDatas = abi.encodeWithSelector(
      CapsPlusRiskSteward.updateCaps.selector,
      capUpdates
    );

    bool success;
    bytes memory resultData;
    (success, resultData) = address(steward).call(callDatas);
    _verifyCallResult(success, resultData);

    string[] memory inputs = new string[](8);
    inputs[0] = 'npx';
    inputs[1] = 'ts-node';
    inputs[2] = 'scripts/safe-helper.ts';
    inputs[3] = vm.toString(msg.sender);
    inputs[4] = vm.toString(address(steward));
    inputs[5] = vm.toString(callDatas);
    inputs[6] = vm.toString(block.chainid);
    inputs[7] = 'Call';
    vm.ffi(inputs);
  }

  function _verifyCallResult(bool success, bytes memory returnData)
    private
    pure
    returns (bytes memory)
  {
    if (success) {
      return returnData;
    } else {
      // Look for revert reason and bubble it up if present
      if (returnData.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returnData)
          revert(add(32, returnData), returndata_size)
        }
      } else {
        revert FailedUpdate();
      }
    }
  }
}
