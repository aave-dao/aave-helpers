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
  error CanNotFindPayload();
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

  function buildMainnet(
    Vm vm,
    IPayloadsControllerCore.ExecutionAction[] memory actions
  ) internal returns (PayloadsControllerUtils.Payload memory) {
    return _buildPayload(vm, ChainIds.MAINNET, actions);
  }

  function _buildPayload(
    Vm vm,
    uint256 chainId,
    IPayloadsControllerCore.ExecutionAction[] memory actions
  ) internal returns (PayloadsControllerUtils.Payload memory) {
    address payloadsController = _getPayloadsController(chainId);
    (PayloadsControllerUtils.AccessControl accessLevel, uint40 payloadId) = _findAndValidatePayload(
      vm,
      chainId,
      payloadsController,
      actions
    );
    return
      PayloadsControllerUtils.Payload({
        chain: chainId,
        accessLevel: accessLevel,
        payloadsController: payloadsController,
        payloadId: payloadId
      });
  }

  function _findAndValidatePayload(
    Vm vm,
    uint256 chainId,
    address payloadsController,
    IPayloadsControllerCore.ExecutionAction[] memory actions
  ) internal returns (PayloadsControllerUtils.AccessControl, uint40) {
    (uint256 prevFork, ) = ChainHelpers.selectChain(vm, chainId);
    (uint40 payloadId, IPayloadsControllerCore.Payload memory payload) = _findPayloadId(
      payloadsController,
      actions
    );
    require(
      payload.state == IPayloadsControllerCore.PayloadState.Created,
      'MUST_BE_IN_CREATED_STATE'
    );
    require(payload.expirationTime >= block.timestamp, 'EXPIRATION_MUST_BE_IN_THE_FUTURE');
    vm.selectFork(prevFork);
    return (payload.maximumAccessLevelRequired, payloadId);
  }

  function _findPayloadId(
    address payloadsController,
    IPayloadsControllerCore.ExecutionAction[] memory actions
  ) internal view returns (uint40, IPayloadsControllerCore.Payload memory) {
    uint40 count = IPayloadsControllerCore(payloadsController).getPayloadsCount();
    for (uint40 payloadId = count - 1; payloadId >= 0; payloadId++) {
      IPayloadsControllerCore.Payload memory payload = IPayloadsControllerCore(payloadsController)
        .getPayloadById(payloadId);
      if (_actionsAreEqual(actions, payload.actions)) {
        return (payloadId, payload);
      }
    }
    revert CanNotFindPayload();
  }

  function _actionsAreEqual(
    IPayloadsControllerCore.ExecutionAction[] memory actionsA,
    IPayloadsControllerCore.ExecutionAction[] memory actionsB
  ) internal pure returns (bool) {
    // must be equal size for equlity
    if (actionsA.length != actionsB.length) return false;
    for (uint256 actionId = 0; actionId < actionsA.length; actionId++) {
      if (actionsA[actionId].target != actionsB[actionId].target) return false;
      if (actionsA[actionId].withDelegateCall != actionsB[actionId].withDelegateCall) return false;
      if (actionsA[actionId].accessLevel != actionsB[actionId].accessLevel) return false;
      if (actionsA[actionId].value != actionsB[actionId].value) return false;
      if (
        keccak256(abi.encodePacked(actionsA[actionId].signature)) !=
        keccak256(abi.encodePacked(actionsB[actionId].signature))
      ) return false;
      if (keccak256(actionsA[actionId].callData) != keccak256(actionsB[actionId].callData))
        return false;
    }
    return true;
  }

  function createProposal(
    PayloadsControllerUtils.Payload[] memory payloads,
    bytes32 ipfsHash
  ) internal returns (uint256) {
    return createProposal(payloads, GovernanceV3Ethereum.VOTING_PORTAL_ETH_ETH, ipfsHash);
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

    uint256 fee = IGovernanceCore(GovernanceV3Ethereum.GOVERNANCE).getCancellationFee();

    console2.logBytes(
      abi.encodeWithSelector(
        IGovernanceCore.createProposal.selector,
        payloads,
        votingPortal,
        ipfsHash
      )
    );
    return
      IGovernanceCore(GovernanceV3Ethereum.GOVERNANCE).createProposal{value: fee}(
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

library GovV3StorageHelpers {
  error LongBytesNotSupportedYet();

  uint256 constant PROPOSALS_COUNT_SLOT = 3;
  uint256 constant PROPOSALS_SLOT = 7;

  uint256 constant PAYLOADS_COUNT_SLOT = 1;
  uint256 constant ACCESS_LEVEL_TO_EXECUTOR_SLOT = 2;
  uint256 constant PAYLOADS_SLOT = 3;

  // enum State {
  //     Null, // proposal does not exists
  //     Created, // created, waiting for a cooldown to initiate the balances snapshot
  //     Active, // balances snapshot set, voting in progress
  //     Queued, // voting results submitted, but proposal is under grace period when guardian can cancel it
  //     Executed, // results sent to the execution chain(s)
  //     Failed, // voting was not successful
  //     Cancelled, // got cancelled by guardian, or because proposition power of creator dropped below allowed minimum
  //     Expired
  //   }
  // struct Proposal {
  //   State state; 0: 0-8
  //   PayloadsControllerUtils.AccessControl accessLevel; 0: 8-16
  //   uint40 creationTime; 0: 16-56
  //   uint24 votingDuration; 0: 56-96
  //   uint40 votingActivationTime; 0: 96-136
  //   uint40 queuingTime; 0: 136-176
  //   uint40 cancelTimestamp; 0: 176-216
  //   address creator; 1
  //   address votingPortal; 2
  //   bytes32 snapshotBlockHash; 3
  //   bytes32 ipfsHash; 4
  //   uint128 forVotes; 5: 0-128
  //   uint128 againstVotes; 5: 128-256
  //   uint256 cancellationFee; 6
  //   PayloadsControllerUtils.Payload[] payloads; 7
  // }
  // struct Payload {
  //   uint256 chain; 0
  //   AccessControl accessLevel; 1: 0-8
  //   address payloadsController; 1: 8-168 // address which holds the logic to execute after success proposal voting
  //   uint40 payloadId; 1: 168-208 // number of the payload placed to payloadsController, max is: ~10¹²
  // }

  function injectProposal(
    Vm vm,
    PayloadsControllerUtils.Payload[] memory payloads,
    address votingPortal
  ) internal returns (uint256) {
    uint256 count = IGovernanceCore(GovernanceV3Ethereum.GOVERNANCE).getProposalsCount();
    uint256 proposalBaseSlot = StorageHelpers.getStorageSlotUintMapping(PROPOSALS_SLOT, count);

    // overwrite proposals count
    vm.store(
      GovernanceV3Ethereum.GOVERNANCE,
      bytes32(PROPOSALS_COUNT_SLOT),
      bytes32(uint256(count + 1))
    );
    // overwrite array size
    vm.store(
      GovernanceV3Ethereum.GOVERNANCE,
      bytes32(proposalBaseSlot + 7),
      bytes32(uint256(payloads.length))
    );
    // overwrite single array slots
    for (uint256 i = 0; i < payloads.length; i++) {
      bytes32 slot = bytes32(StorageHelpers.arrLocation(proposalBaseSlot + 7, i, 2));
      vm.store(GovernanceV3Ethereum.GOVERNANCE, slot, bytes32(payloads[i].chain));
      bytes32 storageBefore = vm.load(GovernanceV3Ethereum.GOVERNANCE, bytes32(uint256(slot) + 1));
      // write target
      storageBefore = StorageHelpers.maskValueToBitsAtPosition(
        0,
        8,
        storageBefore,
        bytes32(uint256(uint8(payloads[i].accessLevel)))
      );
      // write delegateCall
      storageBefore = StorageHelpers.maskValueToBitsAtPosition(
        8,
        168,
        storageBefore,
        bytes32(uint256(uint160(payloads[i].payloadsController)))
      );
      // write accesslevel
      storageBefore = StorageHelpers.maskValueToBitsAtPosition(
        168,
        208,
        storageBefore,
        bytes32(uint256(payloads[i].payloadId))
      );
      // persist
      vm.store(GovernanceV3Ethereum.GOVERNANCE, bytes32(uint256(slot) + 1), storageBefore);
    }
    return count;
  }

  function readyProposal() internal {}

  // ### PayoadsController Storage ###
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
  //
  // struct ExecutionAction {
  //   address target; 0: 160
  //   bool withDelegateCall; 0: 160-168
  //   PayloadsControllerUtils.AccessControl accessLevel; 0: 168-176
  //   uint256 value; 1:
  //   string signature; 2:
  //   bytes callData; 3:
  // }
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
    uint256 payloadBaseSlot = StorageHelpers.getStorageSlotUintMapping(PAYLOADS_SLOT, count);

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
      bytes32(payloadBaseSlot),
      168,
      176,
      bytes32(uint256(IPayloadsControllerCore.PayloadState.Created))
    );

    // overwrite gracePeriod
    StorageHelpers.writeBitsInStorageSlot(
      vm,
      payloadsController,
      bytes32(payloadBaseSlot + 1),
      160,
      200,
      bytes32(uint256(IPayloadsControllerCore(payloadsController).GRACE_PERIOD()))
    );

    // overwrite array size
    vm.store(payloadsController, bytes32(payloadBaseSlot + 2), bytes32(uint256(actions.length)));

    // overwrite single array slots
    for (uint256 i = 0; i < actions.length; i++) {
      bytes32 slot = bytes32(StorageHelpers.arrLocation(payloadBaseSlot + 2, i, 4));
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
    uint256 payloadBaseSlot = StorageHelpers.getStorageSlotUintMapping(PAYLOADS_SLOT, payloadId);
    bytes32 storageBefore = vm.load(payloadsController, bytes32(payloadBaseSlot));
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
    vm.store(payloadsController, bytes32(payloadBaseSlot), storageBefore);
  }

  function toUInt256(bool x) internal pure returns (uint r) {
    assembly {
      r := x
    }
  }
}
