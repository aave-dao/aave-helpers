// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Vm} from 'forge-std/Vm.sol';
import {ChainIds} from './ChainIds.sol';
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
    IPayloadsControllerCore.ExecutionAction[] memory actions,
    PayloadsControllerUtils.AccessControl accessLevel
  ) internal returns (uint256) {
    address payloadsController = _getPayloadsController(block.chainid);
    require(payloadsController != address(0), 'INVALID CHAIN ID');
    require(actions.length > 0, 'INVALID ACTIONS');

    return IPayloadsControllerCore(payloadsController).createPayload(actions);
  }

  function buildMainnet(
    uint40 payloadId,
    PayloadsControllerUtils.AccessControl accessLevel
  ) internal pure returns (PayloadsControllerUtils.Payload memory) {
    require(
      accessLevel > PayloadsControllerUtils.AccessControl.Level_null,
      'INCORRECT ACCESS LEVEL'
    );
    return
      _buildPayload(
        GovernanceV3Ethereum.PAYLOADS_CONTROLLER,
        ChainIds.MAINNET,
        accessLevel,
        payloadId
      );
  }

  function buildArbitrum(
    uint40 payloadId,
    PayloadsControllerUtils.AccessControl accessLevel
  ) internal pure returns (PayloadsControllerUtils.Payload memory) {
    require(
      accessLevel > PayloadsControllerUtils.AccessControl.Level_null,
      'INCORRECT ACCESS LEVEL'
    );
    return
      _buildPayload(
        GovernanceV3Arbitrum.PAYLOADS_CONTROLLER,
        ChainIds.ARBITRUM,
        accessLevel,
        payloadId
      );
  }

  function buildPolygon(
    uint40 payloadId,
    PayloadsControllerUtils.AccessControl accessLevel
  ) internal pure returns (PayloadsControllerUtils.Payload memory) {
    require(
      accessLevel > PayloadsControllerUtils.AccessControl.Level_null,
      'INCORRECT ACCESS LEVEL'
    );
    return
      _buildPayload(
        GovernanceV3Polygon.PAYLOADS_CONTROLLER,
        ChainIds.POLYGON,
        accessLevel,
        payloadId
      );
  }

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

  function buildAvalanche(
    uint40 payloadId,
    PayloadsControllerUtils.AccessControl accessLevel
  ) internal pure returns (PayloadsControllerUtils.Payload memory) {
    require(
      accessLevel > PayloadsControllerUtils.AccessControl.Level_null,
      'INCORRECT ACCESS LEVEL'
    );
    return
      _buildPayload(
        GovernanceV3Avalanche.PAYLOADS_CONTROLLER,
        ChainIds.AVALANCHE,
        accessLevel,
        payloadId
      );
  }

  function buildOptimism(
    uint40 payloadId,
    PayloadsControllerUtils.AccessControl accessLevel
  ) internal pure returns (PayloadsControllerUtils.Payload memory) {
    require(
      accessLevel > PayloadsControllerUtils.AccessControl.Level_null,
      'INCORRECT ACCESS LEVEL'
    );
    return
      _buildPayload(
        GovernanceV3Optimism.PAYLOADS_CONTROLLER,
        ChainIds.OPTIMISM,
        accessLevel,
        payloadId
      );
  }

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
    return _createProposal(payloads, ipfsHash, votingPortal, false);
  }

  function createProposal(
    PayloadsControllerUtils.Payload[] memory payloads,
    address votingPortal,
    bytes32 ipfsHash,
    bool emitLog
  ) internal returns (uint256) {
    return _createProposal(payloads, ipfsHash, votingPortal, emitLog);
  }

  function _createProposal(
    PayloadsControllerUtils.Payload[] memory payloads,
    bytes32 ipfsHash,
    address votingPortal,
    bool emitLog
  ) private returns (uint256) {
    require(block.chainid == ChainIds.MAINNET, 'MAINNET_ONLY');
    require(payloads.length != 0, 'MINIMUM_ONE_PAYLOAD');
    require(ipfsHash != bytes32(0), 'NON_ZERO_IPFS_HASH');
    require(votingPortal != address(0), 'INVALID_VOTING_PORTAL');

    if (emitLog) {
      console2.logBytes(
        abi.encodeWithSelector(
          GovernanceV3Ethereum.GOVERNANCE.createProposal.selector,
          payloads,
          votingPortal,
          ipfsHash
        )
      );
    }
    return
      IGovernanceCore(GovernanceV3Ethereum.GOVERNANCE).createProposal(
        payloads,
        votingPortal,
        ipfsHash
      );
  }

  function executePayload(Vm vm, uint40 payloadId) internal {
    address payloadsController = _getPayloadsController(block.chainid);
    require(payloadsController != address(0), 'INVALID CHAIN ID');

    IPayloadsControllerCore.Payload memory payload = IPayloadsControllerCore(payloadsController)
      .getPayloadById(payloadId);
    require(payload.state != IPayloadsControllerCore.PayloadState.None, 'PAYLOAD DOES NOT EXIST');

    // struct Payload {
    //   address creator; 0: 160
    //   PayloadsControllerUtils.AccessControl maximumAccessLevelRequired; 0: 160-168
    //   PayloadState state; 0: 168-176
    //   uint40 createdAt; 0: 176-216
    //   uint40 queuedAt; 0: 216-256
    //   uint40 executedAt; 1: 40
    //   uint40 cancelledAt; 1: 40-80
    //   uint40 expirationTime; 80-120
    //   uint40 delay; 120-160
    //   uint40 gracePeriod; 160-200
    //   ExecutionAction[] actions; 200-256
    // }

    uint256 proposalBaseSlot = StorageHelpers.getStorageSlotUintMapping(3, payloadId);
    vm.store(
      payloadsController,
      bytes32(proposalBaseSlot),
      bytes32(
        abi.encodePacked(
          uint40(block.timestamp - payload.delay - 1), //payload.queuedAt,
          payload.createdAt,
          IPayloadsControllerCore.PayloadState.Queued, // overwriting state to be queued
          payload.maximumAccessLevelRequired,
          payload.creator
        )
      )
    );
    // vm.store(
    //   payloadsController,
    //   bytes32(proposalBaseSlot + 1),
    //   bytes32(
    //     abi.encodePacked(
    //       uint56(payload.actions.length),
    //       payload.gracePeriod,
    //       payload.delay,
    //       payload.expirationTime,
    //       payload.cancelledAt,
    //       payload.executedAt
    //     )
    //   )
    // );

    IPayloadsControllerCore(payloadsController).executePayload(payloadId);
  }

  function _getPayloadsController(uint256 chainId) internal pure returns (address) {
    if (chainId == ChainIds.MAINNET) {
      return GovernanceV3Ethereum.PAYLOADS_CONTROLLER;
    } else if (chainId == ChainIds.POLYGON) {
      return GovernanceV3Polygon.PAYLOADS_CONTROLLER;
    } else if (chainId == ChainIds.AVALANCHE) {
      return GovernanceV3Avalanche.PAYLOADS_CONTROLLER;
    } else if (chainId == ChainIds.OPTIMISM) {
      return GovernanceV3Optimism.PAYLOADS_CONTROLLER;
    } else if (chainId == ChainIds.ARBITRUM) {
      return GovernanceV3Arbitrum.PAYLOADS_CONTROLLER;
      // } else if (chainId == ChainIds.METIS) {
      //   return AaveV3MetisGovV3.PAYLOADS_CONTROLLER;
      // } else if (chainId == ChainIds.BASE) {
      //   return AaveV3BaseGovV3.PAYLOADS_CONTROLLER;
    }

    revert CannotFindPayloadsController();
  }
}
