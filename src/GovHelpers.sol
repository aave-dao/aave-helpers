// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5 <0.9.0;
pragma abicoder v2;

import {Vm} from 'forge-std/Vm.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {IExecutorWithTimelock} from 'aave-address-book/common/IExecutorWithTimelock.sol';
import {IPoolAddressesProvider} from 'aave-address-book/AaveV3.sol';
import {AaveV3Avalanche} from 'aave-address-book/AaveV3Avalanche.sol';
import {AaveV3Harmony} from 'aave-address-book/AaveV3Harmony.sol';
import {AaveV3Fantom} from 'aave-address-book/AaveV3Fantom.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {ProxyHelpers} from './ProxyHelpers.sol';
import {ChainIds} from './ChainIds.sol';
import {StorageHelpers} from './StorageHelpers.sol';

interface CommonExecutor {
  /**
   * @dev Execute the ActionsSet
   * @param actionsSetId id of the ActionsSet to execute
   **/
  function execute(uint256 actionsSetId) external payable;
}

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

  function buildMainnet(address payloadAddress) internal pure returns (Payload memory) {
    require(payloadAddress != address(0), 'NON_ZERO_TARGET');
    require(
      payloadAddress != AaveGovernanceV2.CROSSCHAIN_FORWARDER_OPTIMISM &&
        payloadAddress != AaveGovernanceV2.CROSSCHAIN_FORWARDER_METIS &&
        payloadAddress != AaveGovernanceV2.CROSSCHAIN_FORWARDER_ARBITRUM &&
        payloadAddress != AaveGovernanceV2.CROSSCHAIN_FORWARDER_POLYGON &&
        payloadAddress != AaveGovernanceV2.CROSSCHAIN_FORWARDER_BASE,
      'PAYLOAD_CANT_BE_FORWARDER'
    );

    return
      Payload({
        target: payloadAddress,
        signature: 'execute()',
        callData: '',
        value: 0,
        withDelegatecall: true
      });
  }

  function buildOptimism(address payloadAddress) internal pure returns (Payload memory) {
    return
      _buildL2({
        forwarder: AaveGovernanceV2.CROSSCHAIN_FORWARDER_OPTIMISM,
        payloadAddress: payloadAddress
      });
  }

  function buildArbitrum(address payloadAddress) internal pure returns (Payload memory) {
    return
      _buildL2({
        forwarder: AaveGovernanceV2.CROSSCHAIN_FORWARDER_ARBITRUM,
        payloadAddress: payloadAddress
      });
  }

  function buildPolygon(address payloadAddress) internal pure returns (Payload memory) {
    return
      _buildL2({
        forwarder: AaveGovernanceV2.CROSSCHAIN_FORWARDER_POLYGON,
        payloadAddress: payloadAddress
      });
  }

  function buildMetis(address payloadAddress) internal pure returns (Payload memory) {
    return
      _buildL2({
        forwarder: AaveGovernanceV2.CROSSCHAIN_FORWARDER_METIS,
        payloadAddress: payloadAddress
      });
  }

  function buildBase(address payloadAddress) internal pure returns (Payload memory) {
    return
      _buildL2({
        forwarder: AaveGovernanceV2.CROSSCHAIN_FORWARDER_BASE,
        payloadAddress: payloadAddress
      });
  }

  function _buildL2(
    address forwarder,
    address payloadAddress
  ) private pure returns (Payload memory) {
    require(payloadAddress != address(0), 'NON_ZERO_TARGET');
    return
      Payload({
        target: forwarder,
        value: 0,
        signature: 'execute(address)',
        callData: abi.encode(payloadAddress),
        withDelegatecall: true
      });
  }

  /**
   * @dev executes latest actionset on a l2 executor
   * @param vm Vm instance passed down from test
   */
  function executeLatestActionSet(Vm vm, address executor) internal {
    uint256 proposalCount = uint256(vm.load(executor, bytes32(uint256(5))));
    executeActionSet(vm, proposalCount - 1, executor);
  }

  /**
   * @dev executes specified actionset on a l2 executor
   * @param vm Vm instance passed down from test
   * @param actionSetId id of actionset to execute
   */
  function executeActionSet(Vm vm, uint256 actionSetId, address executor) internal {
    uint256 proposalBaseSlot = StorageHelpers.getStorageSlotUintMapping(6, actionSetId);
    vm.store(executor, bytes32(proposalBaseSlot + 5), bytes32(block.timestamp));
    CommonExecutor(executor).execute(actionSetId);
  }

  /**
   * @dev executes specified payloadAddress on a specified executor via delegatecall
   * @notice this method accepts arbitrary executors (guardians and executors)
   * @param vm Vm instance passed down from test
   * @param executor address of the executor
   * @param payloadAddress address of payload to execute
   */
  function executePayload(Vm vm, address payloadAddress, address executor) internal {
    if (_isKnownL2Executor(executor)) {
      Payload[] memory proposals = new Payload[](1);
      proposals[0] = Payload({
        target: payloadAddress,
        signature: 'execute()',
        callData: '',
        withDelegatecall: true,
        value: 0
      });
      uint256 proposalId = _queueProposalToL2ExecutorStorage(vm, executor, proposals);
      CommonExecutor(executor).execute(proposalId);
    } else {
      MockExecutor mockExecutor = new MockExecutor();
      vm.etch(executor, address(mockExecutor).code);
      MockExecutor(executor).execute(payloadAddress);
    }
  }

  /**
   * @notice Executor storage is the same on all l2s
   * @param vm vm
   * @param params proposal
   */
  function _queueProposalToL2ExecutorStorage(
    Vm vm,
    address l2Executor,
    Payload[] memory params
  ) internal returns (uint256) {
    // count is stored in slot 5
    uint256 proposalCount = uint256(vm.load(l2Executor, bytes32(uint256(5))));
    // bump counter by 1
    vm.store(l2Executor, bytes32(uint256(5)), bytes32(proposalCount + 1));

    // set storage array sizes
    // actionSetSlot
    uint256 proposalBaseSlot = StorageHelpers.getStorageSlotUintMapping(6, proposalCount);
    // targets
    vm.store(l2Executor, bytes32(proposalBaseSlot), bytes32(params.length));
    // values
    vm.store(l2Executor, bytes32(proposalBaseSlot + 1), bytes32(params.length));
    // signatures
    vm.store(l2Executor, bytes32(proposalBaseSlot + 2), bytes32(params.length));
    // calldatas
    vm.store(l2Executor, bytes32(proposalBaseSlot + 3), bytes32(params.length));
    // withDelegateCalls
    vm.store(l2Executor, bytes32(proposalBaseSlot + 4), bytes32(params.length));

    // store actual values
    for (uint256 i = 0; i < params.length; i++) {
      // targets
      vm.store(
        l2Executor,
        bytes32(StorageHelpers.arrLocation(proposalBaseSlot, i, 1)),
        bytes32(uint256(uint160(params[i].target)))
      );
      // values
      vm.store(
        l2Executor,
        bytes32(StorageHelpers.arrLocation(proposalBaseSlot + 1, i, 1)),
        bytes32(0)
      );
      // signatures
      if (bytes(params[i].signature).length > 31) revert LongBytesNotSupportedYet();
      vm.store(
        l2Executor,
        bytes32(StorageHelpers.arrLocation(proposalBaseSlot + 2, i, 1)),
        bytes32(
          bytes.concat(
            bytes31(bytes(params[i].signature)),
            bytes1(uint8(bytes(params[i].signature).length * 2))
          )
        )
      );
      // calldatas
      if (params[i].callData.length > 31) revert LongBytesNotSupportedYet();
      vm.store(
        l2Executor,
        bytes32(StorageHelpers.arrLocation(proposalBaseSlot + 3, i, 1)),
        bytes32(
          bytes.concat(
            bytes31(bytes(params[i].callData)),
            bytes1(uint8(bytes(params[i].callData).length * 2))
          )
        )
      );
      // withDelegateCalls
      vm.store(
        l2Executor,
        bytes32(StorageHelpers.arrLocation(proposalBaseSlot + 4, i, 1)),
        bytes32(uint256(1))
      );
    }
    // executiontime
    vm.store(l2Executor, bytes32(proposalBaseSlot + 5), bytes32(block.timestamp));
    return proposalCount;
  }

  function _isKnownL2Executor(address executor) internal view returns (bool) {
    if (executor == AaveGovernanceV2.OPTIMISM_BRIDGE_EXECUTOR && block.chainid == ChainIds.OPTIMISM)
      return true;
    if (executor == AaveGovernanceV2.POLYGON_BRIDGE_EXECUTOR && block.chainid == ChainIds.POLYGON)
      return true;
    if (executor == AaveGovernanceV2.METIS_BRIDGE_EXECUTOR && block.chainid == ChainIds.METIS)
      return true;
    if (executor == AaveGovernanceV2.ARBITRUM_BRIDGE_EXECUTOR && block.chainid == ChainIds.ARBITRUM)
      return true;
    if (executor == AaveGovernanceV2.BASE_BRIDGE_EXECUTOR && block.chainid == ChainIds.BASE)
      return true;
    // not a l2, but following same interface & storage
    if (executor == AaveGovernanceV2.ARC_TIMELOCK && block.chainid == ChainIds.MAINNET) return true;
    return false;
  }
}

/**
 * @dev Mock contract which allows performing a delegatecall to `execute`
 * Intended to be used as replacement for L2 admins/executors to mock governance/gnosis execution.
 */
contract MockExecutor {
  /**
   * @notice Non-standard functionality used to skip governance and just execute a payload.
   */
  function execute(address payload) public {
    (bool success, ) = payload.delegatecall(abi.encodeWithSignature('execute()'));
    require(success, 'PROPOSAL_EXECUTION_FAILED');
  }
}
