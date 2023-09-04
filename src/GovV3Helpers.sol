// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Vm} from 'forge-std/Vm.sol';
import {ChainIds, ChainHelpers} from './ChainIds.sol';
import {IpfsUtils} from './IpfsUtils.sol';
import {console2} from 'forge-std/console2.sol';
import {PayloadsControllerUtils, IGovernancePowerStrategy, IPayloadsControllerCore, IGovernanceCore} from 'aave-address-book/GovernanceV3.sol';
import {GovernanceV3Sepolia} from 'aave-address-book/GovernanceV3Sepolia.sol';
import {GovernanceV3Arbitrum} from 'aave-address-book/GovernanceV3Arbitrum.sol';
import {GovernanceV3Avalanche} from 'aave-address-book/GovernanceV3Avalanche.sol';
import {GovernanceV3Polygon} from 'aave-address-book/GovernanceV3Polygon.sol';
import {GovernanceV3Optimism} from 'aave-address-book/GovernanceV3Optimism.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {StorageHelpers} from './StorageHelpers.sol';

library GovV3Helpers {
  error CannotFindPayloadsController();
  error ExecutorNotFound();
  error LongBytesNotSupportedYet();

  function ipfsHashFile(Vm vm, string memory filePath) internal returns (bytes32) {
    return IpfsUtils.ipfsHashFile(vm, filePath, false);
  }

  /**
   * @dev builds a action to be registered on a payloadsController
   * - assumes accesscontrol level 1
   * - assumes delegateCall true
   * - assumes standard `execute()` signature on the payload contract
   * - assumes eth value 0
   * - assumes no calldata being necessary
   * @param payloadAddress address of the payload to be executed
   */
  function buildAction(
    address payloadAddress
  ) internal returns (IPayloadsControllerCore.ExecutionAction memory) {
    return buildAction(payloadAddress, PayloadsControllerUtils.AccessControl.Level_1);
  }

  function buildAction(
    address payloadAddress,
    PayloadsControllerUtils.AccessControl accessLevel
  ) internal returns (IPayloadsControllerCore.ExecutionAction memory) {
    address payloadsController = _getPayloadsController(block.chainid);
    require(payloadsController != address(0), 'INVALID CHAIN ID');
    require(payloadAddress != address(0), 'INVALID PAYLOAD ADDRESS');
    require(
      accessLevel != PayloadsControllerUtils.AccessControl.Level_null,
      'INVALID ACCESS LEVEL'
    );

    return
      IPayloadsControllerCore.ExecutionAction({
        target: payloadAddress,
        withDelegateCall: true,
        accessLevel: accessLevel,
        value: 0,
        signature: 'execute()',
        callData: ''
      });
  }

  function createPayload(
    IPayloadsControllerCore.ExecutionAction[] memory actions
  ) internal returns (uint40) {
    address payloadsController = _getPayloadsController(block.chainid);
    require(actions.length > 0, 'INVALID ACTIONS');

    return IPayloadsControllerCore(payloadsController).createPayload(actions);
  }

  function executePayload(Vm vm, address payloadAddress) internal {
    address payloadsController = _getPayloadsController(block.chainid);
    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](1);
    actions[0] = buildAction(payloadAddress);
    uint40 payloadId = GovV3StorageHelpers.injectPayload(vm, payloadsController, actions);
    GovV3StorageHelpers.readyPayloadId(vm, payloadsController, payloadId);
    IPayloadsControllerCore(payloadsController).executePayload(payloadId);
  }

  /**
   * @dev This method allows you to directly execute a payloadId, no matter the state of the payload
   * @param vm Vm
   * @param payloadId id of the payload
   */
  function executePayload(Vm vm, uint40 payloadId) internal {
    address payloadsController = _getPayloadsController(block.chainid);
    require(payloadsController != address(0), 'INVALID CHAIN ID');

    IPayloadsControllerCore.Payload memory payload = IPayloadsControllerCore(payloadsController)
      .getPayloadById(payloadId);
    require(payload.state != IPayloadsControllerCore.PayloadState.None, 'PAYLOAD DOES NOT EXIST');

    GovV3StorageHelpers.readyPayloadId(vm, payloadsController, payloadId);

    IPayloadsControllerCore(payloadsController).executePayload(payloadId);
  }

  function buildMainnet(Vm vm, uint256 payloadId, address payloadAddress) internal {}

  function _buildPayload(
    Vm vm,
    uint256 chainId,
    uint40 payloadId
  ) internal returns (PayloadsControllerUtils.Payload memory) {
    address payloadsController = _getPayloadsController(chainId);
    PayloadsControllerUtils.AccessControl accessLevel = _validatePayloadAndGetAccessLevel(
      vm,
      chainId,
      payloadsController
    );
    return
      PayloadsControllerUtils.Payload({
        chain: chainId,
        accessLevel: accessLevel,
        payloadsController: payloadsController,
        payloadId: payloadId
      });
  }

  function _validatePayloadAndGetAccessLevel(
    Vm vm,
    uint256 chainId,
    address payloadsController
  ) internal returns (PayloadsControllerUtils.AccessControl accessLevel) {
    (uint256 prevFork, uint256 newFork) = ChainHelpers.selectChain(vm, chainId);
    address controller = _getPayloadsController(chainId);

    vm.selectFork(prevFork);
  }

  function _findPayloadId(address payloadsController) internal view returns (uint40) {
    uint40 count = IPayloadsControllerCore(payloadsController).getPayloadsCount();
    for (uint40 i = count - 1; i >= 0; i++) {
      IPayloadsControllerCore.Payload memory payload = IPayloadsControllerCore(payloadsController)
        .getPayloadById(i);
      // if(payload.actions)
    }
  }

  // function buildMainnet(
  //   uint40 payloadId,
  //   PayloadsControllerUtils.AccessControl accessLevel
  // ) internal pure returns (PayloadsControllerUtils.Payload memory) {
  //   require(
  //     accessLevel > PayloadsControllerUtils.AccessControl.Level_null,
  //     'INCORRECT ACCESS LEVEL'
  //   );
  //   return
  //     _buildPayload(
  //       GovernanceV3Ethereum.PAYLOADS_CONTROLLER,
  //       ChainIds.MAINNET,
  //       accessLevel,
  //       payloadId
  //     );
  // }

  // function buildArbitrum(
  //   uint40 payloadId,
  //   PayloadsControllerUtils.AccessControl accessLevel
  // ) internal pure returns (PayloadsControllerUtils.Payload memory) {
  //   require(
  //     accessLevel > PayloadsControllerUtils.AccessControl.Level_null,
  //     'INCORRECT ACCESS LEVEL'
  //   );
  //   return
  //     _buildPayload(
  //       GovernanceV3Arbitrum.PAYLOADS_CONTROLLER,
  //       ChainIds.ARBITRUM,
  //       accessLevel,
  //       payloadId
  //     );
  // }

  // function buildPolygon(
  //   uint40 payloadId,
  //   PayloadsControllerUtils.AccessControl accessLevel
  // ) internal pure returns (PayloadsControllerUtils.Payload memory) {
  //   require(
  //     accessLevel > PayloadsControllerUtils.AccessControl.Level_null,
  //     'INCORRECT ACCESS LEVEL'
  //   );
  //   return
  //     _buildPayload(
  //       GovernanceV3Polygon.PAYLOADS_CONTROLLER,
  //       ChainIds.POLYGON,
  //       accessLevel,
  //       payloadId
  //     );
  // }

  // function buildMetis(
  //   uint40 payloadId,
  //   PayloadsControllerUtils.AccessControl accessLevel
  // ) internal pure returns (PayloadsControllerUtils.Payload memory) {
  //   require(
  //     accessLevel > PayloadsControllerUtils.AccessControl.Level_null,
  //     'INCORRECT ACCESS LEVEL'
  //   );
  //   return
  //     _buildPayload(AaveV3MetisGovV3.PAYLOADS_CONTROLLER, ChainIds.METIS, accessLevel, payloadId);
  // }

  // function buildBase(
  //   uint40 payloadId,
  //   PayloadsControllerUtils.AccessControl accessLevel
  // ) internal pure returns (PayloadsControllerUtils.Payload memory) {
  //   require(
  //     accessLevel > PayloadsControllerUtils.AccessControl.Level_null,
  //     'INCORRECT ACCESS LEVEL'
  //   );
  //   return
  //     _buildPayload(AaveV3BaseGovV3.PAYLOADS_CONTROLLER, ChainIds.BASE, accessLevel, payloadId);
  // }

  // function buildAvalanche(
  //   uint40 payloadId,
  //   PayloadsControllerUtils.AccessControl accessLevel
  // ) internal pure returns (PayloadsControllerUtils.Payload memory) {
  //   require(
  //     accessLevel > PayloadsControllerUtils.AccessControl.Level_null,
  //     'INCORRECT ACCESS LEVEL'
  //   );
  //   return
  //     _buildPayload(
  //       GovernanceV3Avalanche.PAYLOADS_CONTROLLER,
  //       ChainIds.AVALANCHE,
  //       accessLevel,
  //       payloadId
  //     );
  // }

  // function buildOptimism(
  //   uint40 payloadId,
  //   PayloadsControllerUtils.AccessControl accessLevel
  // ) internal pure returns (PayloadsControllerUtils.Payload memory) {
  //   require(
  //     accessLevel > PayloadsControllerUtils.AccessControl.Level_null,
  //     'INCORRECT ACCESS LEVEL'
  //   );
  //   return
  //     _buildPayload(
  //       GovernanceV3Optimism.PAYLOADS_CONTROLLER,
  //       ChainIds.OPTIMISM,
  //       accessLevel,
  //       payloadId
  //     );
  // }

  function _buildPayload(
    address payloadsController,
    uint256 chainId,
    PayloadsControllerUtils.AccessControl accessLevel,
    uint40 payloadId
  ) internal pure returns (PayloadsControllerUtils.Payload memory) {
    return
      PayloadsControllerUtils.Payload({
        chain: chainId,
        accessLevel: accessLevel,
        payloadsController: payloadsController,
        payloadId: payloadId
      });
  }

  function createProposal(
    PayloadsControllerUtils.Payload[] memory payloads,
    address votingPortal,
    bytes32 ipfsHash
  ) internal returns (uint256) {
    return _createProposal(payloads, ipfsHash, votingPortal);
  }

  function _createProposal(
    PayloadsControllerUtils.Payload[] memory payloads,
    bytes32 ipfsHash,
    address votingPortal
  ) private returns (uint256) {
    require(block.chainid == ChainIds.MAINNET, 'MAINNET_ONLY');
    require(payloads.length != 0, 'MINIMUM_ONE_PAYLOAD');
    require(ipfsHash != bytes32(0), 'NON_ZERO_IPFS_HASH');
    require(votingPortal != address(0), 'INVALID_VOTING_PORTAL');

    for (uint256 i; i < payloads.length; i++) {}

    console2.logBytes(
      abi.encodeWithSelector(
        IGovernanceCore.createProposal.selector,
        payloads,
        votingPortal,
        ipfsHash
      )
    );
    return
      IGovernanceCore(GovernanceV3Ethereum.GOVERNANCE).createProposal(
        payloads,
        votingPortal,
        ipfsHash
      );
  }

  function _getPayloadsController(uint256 chainId) internal pure returns (address) {
    if (chainId == ChainIds.MAINNET) {
      return GovernanceV3Ethereum.PAYLOADS_CONTROLLER;
    }
    //  else if (chainId == ChainIds.POLYGON) {
    //   return GovernanceV3Polygon.PAYLOADS_CONTROLLER;
    // } else if (chainId == ChainIds.AVALANCHE) {
    //   return GovernanceV3Avalanche.PAYLOADS_CONTROLLER;
    // } else if (chainId == ChainIds.OPTIMISM) {
    //   return GovernanceV3Optimism.PAYLOADS_CONTROLLER;
    // } else if (chainId == ChainIds.ARBITRUM) {
    //   return GovernanceV3Arbitrum.PAYLOADS_CONTROLLER;
    // } else if (chainId == ChainIds.METIS) {
    //   return GovernanceV3Metis.PAYLOADS_CONTROLLER;
    // } else if (chainId == ChainIds.BASE) {
    //   return GovernanceV3Base.PAYLOADS_CONTROLLER;
    // }

    revert CannotFindPayloadsController();
  }
}

// struct Payload {
//   address creator; 0: 160
//   PayloadsControllerUtils.AccessControl maximumAccessLevelRequired; 0: 160-168
//   PayloadState state; 0: 168-176
//   uint40 createdAt; 0: 176-216
//   uint40 queuedAt; 0: 216-256
//   uint40 executedAt; 1: 40
//   uint40 cancelledAt; 1: 40-80
//   uint40 expirationTime; 1: 80-120
//   uint40 delay; 1: 120-160
//   uint40 gracePeriod; 1: 160-200
//   ExecutionAction[] actions; 2: 0
// }
// struct ExecutionAction {
//   address target; 0: 160
//   bool withDelegateCall; 0: 160-168
//   PayloadsControllerUtils.AccessControl accessLevel; 0: 168-176
//   uint256 value; 1:
//   string signature; 2:
//   bytes callData; 3:
// }
library GovV3StorageHelpers {
  error LongBytesNotSupportedYet();

  uint256 constant PAYLOADS_COUNT_SLOT = 1;
  uint256 constant ACCESS_LEVEL_TO_EXECUTOR_SLOT = 2;
  uint256 constant PAYLOADS_SLOT = 3;

  /**
   * Injects the payload into storage
   * @param vm Vm
   * @param payloadsController address
   * @param actions array of actions
   */
  function injectPayload(
    Vm vm,
    address payloadsController,
    IPayloadsControllerCore.ExecutionAction[] memory actions
  ) internal returns (uint40) {
    uint40 count = IPayloadsControllerCore(payloadsController).getPayloadsCount();
    uint256 proposalBaseSlot = StorageHelpers.getStorageSlotUintMapping(PAYLOADS_SLOT, count);

    // overwrite payloads count
    StorageHelpers.writeBitsInStorageSlot(
      vm,
      payloadsController,
      bytes32(PAYLOADS_COUNT_SLOT),
      176,
      216,
      bytes32(uint256(count + 1))
    );

    // overwrite payload state
    StorageHelpers.writeBitsInStorageSlot(
      vm,
      payloadsController,
      bytes32(proposalBaseSlot),
      168,
      176,
      bytes32(uint256(IPayloadsControllerCore.PayloadState.Created))
    );

    // overwrite gracePeriod
    StorageHelpers.writeBitsInStorageSlot(
      vm,
      payloadsController,
      bytes32(proposalBaseSlot + 1),
      160,
      200,
      bytes32(uint256(IPayloadsControllerCore(payloadsController).GRACE_PERIOD()))
    );

    // overwrite array size
    vm.store(payloadsController, bytes32(proposalBaseSlot + 2), bytes32(uint256(actions.length)));

    // overwrite single array slots
    for (uint256 i = 0; i < actions.length; i++) {
      bytes32 slot = bytes32(StorageHelpers.arrLocation(proposalBaseSlot + 2, i, 4));
      bytes32 storageBefore = vm.load(payloadsController, slot);
      // write target
      storageBefore = StorageHelpers.maskValueToBitsAtPosition(
        0,
        160,
        storageBefore,
        bytes32(uint256(uint160(actions[i].target)))
      );
      // write delegateCall
      storageBefore = StorageHelpers.maskValueToBitsAtPosition(
        160,
        168,
        storageBefore,
        bytes32(toUInt256(actions[i].withDelegateCall))
      );
      // write accesslevel
      storageBefore = StorageHelpers.maskValueToBitsAtPosition(
        168,
        176,
        storageBefore,
        bytes32(uint256(actions[i].accessLevel))
      );
      // persist
      vm.store(payloadsController, slot, storageBefore);
      // write signatures
      if (bytes(actions[i].signature).length > 31) revert LongBytesNotSupportedYet();
      vm.store(
        payloadsController,
        bytes32(uint256(slot) + 2),
        bytes32(
          bytes.concat(
            bytes31(bytes(actions[i].signature)),
            bytes1(uint8(bytes(actions[i].signature).length * 2))
          )
        )
      );
    }
    return count;
  }

  /**
   * Alters storage in a way that makes the payload executable
   * @param vm Vm
   * @param payloadsController address
   * @param payloadId id of the payload
   */
  function readyPayloadId(Vm vm, address payloadsController, uint40 payloadId) internal {
    IPayloadsControllerCore.Payload memory payload = IPayloadsControllerCore(payloadsController)
      .getPayloadById(payloadId);
    require(payload.state != IPayloadsControllerCore.PayloadState.None, 'PAYLOAD DOES NOT EXIST');
    uint256 proposalBaseSlot = StorageHelpers.getStorageSlotUintMapping(PAYLOADS_SLOT, payloadId);
    bytes32 storageBefore = vm.load(payloadsController, bytes32(proposalBaseSlot));
    // write state
    storageBefore = StorageHelpers.maskValueToBitsAtPosition(
      168,
      176,
      storageBefore,
      bytes32(uint256(uint8(IPayloadsControllerCore.PayloadState.Queued)))
    );
    // write queuedAt
    storageBefore = StorageHelpers.maskValueToBitsAtPosition(
      216,
      256,
      storageBefore,
      bytes32(uint256(uint40(block.timestamp - payload.delay - 1)))
    );
    // persist
    vm.store(payloadsController, bytes32(proposalBaseSlot), storageBefore);
  }

  function toUInt256(bool x) internal pure returns (uint r) {
    assembly {
      r := x
    }
  }
}
