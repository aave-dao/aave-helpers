// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5 <0.9.0;
pragma abicoder v2;

import {Vm} from 'forge-std/Vm.sol';
import {Test} from 'forge-std/Test.sol';
import {console2} from 'forge-std/console2.sol';
import {AaveGovernanceV2, IAaveGovernanceV2, IExecutorWithTimelock} from 'aave-address-book/AaveGovernanceV2.sol';
import {IPoolAddressesProvider} from 'aave-address-book/AaveV3.sol';
import {AaveV3Avalanche} from 'aave-address-book/AaveV3Avalanche.sol';
import {AaveV3Harmony} from 'aave-address-book/AaveV3Harmony.sol';
import {AaveV3Fantom} from 'aave-address-book/AaveV3Fantom.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {ProxyHelpers} from './ProxyHelpers.sol';
import {ChainIds} from './ChainIds.sol';

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

  struct SPropCreateParams {
    address executor;
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
    bytes32 ipfsHash;
  }

  struct Payload {
    address target;
    string signature;
    bytes callData;
  }

  function ipfsHashFile(Vm vm, string memory filePath, bool upload) internal returns (bytes32) {
    string[] memory inputs = new string[](6);
    inputs[0] = 'npx';
    inputs[1] = 'aave-cli';
    inputs[2] = 'ipfs';
    inputs[3] = filePath;
    inputs[4] = '-u';
    inputs[5] = vm.toString(upload);
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

  function buildMainnet(address payloadAddress) internal pure returns (Payload memory) {
    require(
      payloadAddress != AaveGovernanceV2.CROSSCHAIN_FORWARDER_OPTIMISM &&
        payloadAddress != AaveGovernanceV2.CROSSCHAIN_FORWARDER_ARBITRUM &&
        payloadAddress != AaveGovernanceV2.CROSSCHAIN_FORWARDER_POLYGON,
      'PAYLOAD_CANT_BE_FORWARDER'
    );

    return Payload({target: payloadAddress, signature: 'execute()', callData: ''});
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

  function _buildL2(
    address forwarder,
    address payloadAddress
  ) private pure returns (Payload memory) {
    return
      Payload({
        target: forwarder,
        signature: 'execute(address)',
        callData: abi.encode(payloadAddress)
      });
  }

  function createProposal(
    Payload[] memory delegateCalls,
    bytes32 ipfsHash
  ) internal returns (uint256) {
    return _createProposal(AaveGovernanceV2.SHORT_EXECUTOR, delegateCalls, ipfsHash, false);
  }

  function createProposal(
    Payload[] memory delegateCalls,
    bytes32 ipfsHash,
    bool emitLog
  ) internal returns (uint256) {
    return _createProposal(AaveGovernanceV2.SHORT_EXECUTOR, delegateCalls, ipfsHash, emitLog);
  }

  function createProposal(
    address executor,
    Payload[] memory delegateCalls,
    bytes32 ipfsHash
  ) internal returns (uint256) {
    return _createProposal(executor, delegateCalls, ipfsHash, false);
  }

  function createProposal(
    address executor,
    Payload[] memory delegateCalls,
    bytes32 ipfsHash,
    bool emitLog
  ) internal returns (uint256) {
    return _createProposal(executor, delegateCalls, ipfsHash, emitLog);
  }

  function _createProposal(
    address executor,
    Payload[] memory delegateCalls,
    bytes32 ipfsHash,
    bool emitLog
  ) private returns (uint256) {
    require(block.chainid == ChainIds.MAINNET, 'MAINNET_ONLY');
    require(delegateCalls.length != 0, 'MINIMUM_ONE_PAYLOAD');
    require(ipfsHash != bytes32(0), 'NON_ZERO_IPFS_HASH');

    address[] memory targets = new address[](delegateCalls.length);
    uint256[] memory values = new uint256[](delegateCalls.length);
    string[] memory signatures = new string[](delegateCalls.length);
    bytes[] memory calldatas = new bytes[](delegateCalls.length);
    bool[] memory withDelegatecalls = new bool[](delegateCalls.length);
    for (uint256 i = 0; i < delegateCalls.length; i++) {
      require(delegateCalls[i].target != address(0), 'NON_ZERO_TARGET');
      targets[i] = delegateCalls[i].target;
      signatures[i] = delegateCalls[i].signature;
      calldatas[i] = delegateCalls[i].callData;
      values[i] = 0;
      withDelegatecalls[i] = true;
    }

    if (emitLog) {
      console2.logBytes(
        abi.encodeWithSelector(
          AaveGovernanceV2.GOV.create.selector,
          IExecutorWithTimelock(executor),
          targets,
          values,
          signatures,
          calldatas,
          withDelegatecalls,
          ipfsHash
        )
      );
    }

    return
      AaveGovernanceV2.GOV.create(
        IExecutorWithTimelock(executor),
        targets,
        values,
        signatures,
        calldatas,
        withDelegatecalls,
        ipfsHash
      );
  }

  /**
   * @dev Impersonate the ecosystem reserve and creates the proposal.
   */
  function createTestProposal(Vm vm, SPropCreateParams memory params) internal returns (uint256) {
    vm.deal(AaveMisc.ECOSYSTEM_RESERVE, 1 ether);
    vm.startPrank(AaveMisc.ECOSYSTEM_RESERVE);
    uint256 proposalId = AaveGovernanceV2.GOV.create(
      IExecutorWithTimelock(params.executor),
      params.targets,
      params.values,
      params.signatures,
      params.calldatas,
      params.withDelegatecalls,
      params.ipfsHash
    );
    vm.stopPrank();
    return proposalId;
  }

  function _getProposalSlot(uint256 proposalId) private pure returns (bytes32 slot) {
    uint256 proposalsMapSlot = 0x4;
    return bytes32(uint256(keccak256(abi.encode(proposalId, proposalsMapSlot))) + 11);
  }

  /**
   * Alter storage slots so the proposal passes
   */
  function passVoteAndExecute(Vm vm, uint256 proposalId) internal {
    passVoteAndQueue(vm, proposalId);
    uint256 executionTime = AaveGovernanceV2.GOV.getProposalById(proposalId).executionTime;
    vm.warp(executionTime + 1);
    AaveGovernanceV2.GOV.execute(proposalId);
  }

  function passVoteAndQueue(Vm vm, uint256 proposalId) internal {
    passVote(vm, proposalId);
    AaveGovernanceV2.GOV.queue(proposalId);
  }

  function passVote(Vm vm, uint256 proposalId) internal {
    uint256 power = 5000000 ether;
    vm.roll(block.number + 1);
    vm.store(address(AaveGovernanceV2.GOV), _getProposalSlot(proposalId), bytes32(power));
    uint256 endBlock = AaveGovernanceV2.GOV.getProposalById(proposalId).endBlock;
    vm.roll(endBlock + 1);
  }

  function getProposalById(
    uint256 proposalId
  ) internal view returns (IAaveGovernanceV2.ProposalWithoutVotes memory) {
    return AaveGovernanceV2.GOV.getProposalById(proposalId);
  }

  /**
   * @dev executes latest actionset on a l2 executor
   * @param vm Vm instance passed down from test
   */
  function executeLatestActionSet(Vm vm) internal {
    address executor = _getExecutor();
    uint256 proposalCount = uint256(vm.load(executor, bytes32(uint256(5))));
    executeActionSet(vm, proposalCount - 1);
  }

  /**
   * @dev executes specified actionset on a l2 executor
   * @param vm Vm instance passed down from test
   * @param actionSetId id of actionset to execute
   */
  function executeActionSet(Vm vm, uint256 actionSetId) internal {
    address executor = _getExecutor();
    uint256 proposalBaseSlot = _getStorageSlotUintMapping(6, actionSetId);
    vm.store(executor, bytes32(proposalBaseSlot + 5), bytes32(block.timestamp));
    CommonExecutor(executor).execute(actionSetId);
  }

  /**
   * @dev executes specified payloadAddress on a l2 executor via proposalExecution
   * This method automatically picks the correct executor based on the current chain
   * @notice this method only acceps executors, not guardians
   * @param vm Vm instance passed down from test
   * @param payloadAddress address of payload to execute
   */
  function executePayload(Vm vm, address payloadAddress) internal {
    address executor = _getExecutor();
    executePayload(vm, payloadAddress, executor);
  }

  /**
   * @dev executes specified payloadAddress on a specified executor via delegatecall
   * @notice this method accepts arbitrary executors (guardians and executors)
   * @param vm Vm instance passed down from test
   * @param payloadAddress address of payload to execute
   * @param executor address of the executor
   */
  function executePayload(Vm vm, address payloadAddress, address executor) internal {
    if (
      block.chainid == ChainIds.MAINNET &&
      (executor == AaveGovernanceV2.SHORT_EXECUTOR || executor == AaveGovernanceV2.LONG_EXECUTOR)
    ) {
      address[] memory targets = new address[](1);
      targets[0] = payloadAddress;
      uint256[] memory values = new uint256[](1);
      string[] memory signatures = new string[](1);
      signatures[0] = 'execute()';
      bytes[] memory calldatas = new bytes[](1);
      bool[] memory withDelegatecalls = new bool[](1);
      withDelegatecalls[0] = true;
      SPropCreateParams memory proposal = SPropCreateParams(
        executor,
        targets,
        values,
        signatures,
        calldatas,
        withDelegatecalls,
        bytes32(0)
      );
      uint256 proposalId = createTestProposal(vm, proposal);
      passVoteAndExecute(vm, proposalId);
    } else if (_getExecutor() == executor) {
      Payload[] memory proposals = new Payload[](1);
      proposals[0] = Payload(payloadAddress, 'execute()', '');
      uint256 proposalId = _queueProposalToL2ExecutorStorage(vm, executor, proposals);
      CommonExecutor(executor).execute(proposalId);
    } else {
      MockExecutor mockExecutor = new MockExecutor();
      vm.etch(executor, address(mockExecutor).code);
      MockExecutor(executor).execute(payloadAddress);
    }
  }

  function _getStorageSlotUintMapping(uint256 slot, uint256 key) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(key, slot)));
  }

  function _arrLocation(
    uint256 slot,
    uint256 index,
    uint256 elementSize
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(slot))) + (index * elementSize);
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
    uint256 proposalBaseSlot = _getStorageSlotUintMapping(6, proposalCount);
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
        bytes32(_arrLocation(proposalBaseSlot, i, 1)),
        bytes32(uint256(uint160(params[i].target)))
      );
      // values
      vm.store(l2Executor, bytes32(_arrLocation(proposalBaseSlot + 1, i, 1)), bytes32(0));
      // signatures
      if (bytes(params[i].signature).length > 31) revert LongBytesNotSupportedYet();
      vm.store(
        l2Executor,
        bytes32(_arrLocation(proposalBaseSlot + 2, i, 1)),
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
        bytes32(_arrLocation(proposalBaseSlot + 3, i, 1)),
        bytes32(
          bytes.concat(
            bytes31(bytes(params[i].callData)),
            bytes1(uint8(bytes(params[i].callData).length * 2))
          )
        )
      );
      // withDelegateCalls
      vm.store(l2Executor, bytes32(_arrLocation(proposalBaseSlot + 4, i, 1)), bytes32(uint256(1)));
    }
    // executiontime
    vm.store(l2Executor, bytes32(proposalBaseSlot + 5), bytes32(block.timestamp));
    return proposalCount;
  }

  // /**
  //  * @notice Executor storage is the same on all l2s
  //  * @param vm vm
  //  * @param params proposal
  // WIP: not sure if worth it
  //  */
  // function _queueProposalToL1ExecutorStorage(
  //   Vm vm,
  //   address l1Executor,
  //   Payload[] memory params
  // ) internal returns (uint256) {
  //   // count is stored in slot 5
  //   uint256 proposalCount = uint256(vm.load(address(AaveGovernanceV2.GOV), bytes32(uint256(3))));
  //   // bump counter by 1
  //   vm.store(address(AaveGovernanceV2.GOV), bytes32(uint256(3)), bytes32(proposalCount + 1));

  //   // set storage array sizes
  //   // proposals
  //   uint256 proposalBaseSlot = _getStorageSlotUintMapping(4, proposalCount);
  //   // id
  //   vm.store(address(AaveGovernanceV2.GOV), bytes32(proposalBaseSlot), bytes32(proposalCount));
  //   // creator
  //   vm.store(
  //     address(AaveGovernanceV2.GOV),
  //     bytes32(proposalBaseSlot + 1),
  //     bytes32(uint256(uint160(msg.sender)))
  //   );
  //   vm.store(
  //     address(AaveGovernanceV2.GOV),
  //     bytes32(proposalBaseSlot + 2),
  //     bytes32(uint256(uint160(l1Executor)))
  //   );
  //   // targets
  //   vm.store(address(AaveGovernanceV2.GOV), bytes32(proposalBaseSlot + 3), bytes32(params.length));
  //   // values
  //   vm.store(address(AaveGovernanceV2.GOV), bytes32(proposalBaseSlot + 4), bytes32(params.length));
  //   // signatures
  //   vm.store(address(AaveGovernanceV2.GOV), bytes32(proposalBaseSlot + 5), bytes32(params.length));
  //   // calldatas
  //   vm.store(address(AaveGovernanceV2.GOV), bytes32(proposalBaseSlot + 6), bytes32(params.length));
  //   // withDelegateCalls
  //   vm.store(address(AaveGovernanceV2.GOV), bytes32(proposalBaseSlot + 7), bytes32(params.length));
  //   // startBlock
  //   vm.store(
  //     address(AaveGovernanceV2.GOV),
  //     bytes32(proposalBaseSlot + 8),
  //     bytes32(block.number - 1)
  //   );
  //   // endBlock
  //   vm.store(address(AaveGovernanceV2.GOV), bytes32(proposalBaseSlot + 9), bytes32(block.number));
  //   // executionTime
  //   vm.store(address(AaveGovernanceV2.GOV), bytes32(proposalBaseSlot + 10), bytes32(params.length));
  //   // forVotes
  //   vm.store(
  //     address(AaveGovernanceV2.GOV),
  //     bytes32(proposalBaseSlot + 11),
  //     bytes32(uint256(10_000_000 ether))
  //   );
  //   // strategy
  //   vm.store(
  //     address(AaveGovernanceV2.GOV),
  //     bytes32(proposalBaseSlot + 15),
  //     bytes32(uint256(uint160(0xb7e383ef9B1E9189Fc0F71fb30af8aa14377429e)))
  //   );
  //   // store actual values
  //   for (uint256 i = 0; i < params.length; i++) {
  //     // targets
  //     vm.store(
  //       address(AaveGovernanceV2.GOV),
  //       bytes32(_arrLocation(proposalBaseSlot + 3, i, 1)),
  //       bytes32(uint256(uint160(params[i].target)))
  //     );
  //     // values
  //     vm.store(
  //       address(AaveGovernanceV2.GOV),
  //       bytes32(_arrLocation(proposalBaseSlot + 4, i, 1)),
  //       bytes32(0)
  //     );
  //     // signatures
  //     if (bytes(params[i].signature).length > 31) revert LongBytesNotSupportedYet();
  //     vm.store(
  //       address(AaveGovernanceV2.GOV),
  //       bytes32(_arrLocation(proposalBaseSlot + 5, i, 1)),
  //       bytes32(
  //         bytes.concat(
  //           bytes31(bytes(params[i].signature)),
  //           bytes1(uint8(bytes(params[i].signature).length * 2))
  //         )
  //       )
  //     );
  //     // calldatas
  //     if (params[i].callData.length > 31) revert LongBytesNotSupportedYet();
  //     vm.store(
  //       address(AaveGovernanceV2.GOV),
  //       bytes32(_arrLocation(proposalBaseSlot + 6, i, 1)),
  //       bytes32(
  //         bytes.concat(
  //           bytes31(bytes(params[i].callData)),
  //           bytes1(uint8(bytes(params[i].callData).length * 2))
  //         )
  //       )
  //     );
  //     // withDelegateCalls
  //     vm.store(
  //       address(AaveGovernanceV2.GOV),
  //       bytes32(_arrLocation(proposalBaseSlot + 7, i, 1)),
  //       bytes32(uint256(1))
  //     );
  //   }
  //   return proposalCount;
  // }

  function _getExecutor() internal view returns (address) {
    if (block.chainid == ChainIds.OPTIMISM) return AaveGovernanceV2.OPTIMISM_BRIDGE_EXECUTOR;
    if (block.chainid == ChainIds.POLYGON) return AaveGovernanceV2.POLYGON_BRIDGE_EXECUTOR;
    if (block.chainid == ChainIds.METIS) return AaveGovernanceV2.METIS_BRIDGE_EXECUTOR;
    if (block.chainid == ChainIds.ARBITRUM) return AaveGovernanceV2.ARBITRUM_BRIDGE_EXECUTOR;
    return address(0);
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

/**
 * @dev Inheriting from this contract in a forge test allows to
 * @notice @deprecated kept, to not break existing tests
 * 1. Configure on the setUp() of the child contract an executor for governance proposals
 *    (or any address with permissions) just by doing for example a `_selectPayloadExecutor(AaveGovernanceV2.SHORT_EXECUTOR)`
 * 2. Afterwards, on a test you can just do `_executePayload(somePayloadAddress)`, and it will be executed via
 *    DELEGATECALL on the address previously selected on step 1).
 */
abstract contract TestWithExecutor is Test {
  address internal _executor;

  function _selectPayloadExecutor(address executor) internal {
    _executor = executor;
  }

  function _executePayload(address payloadAddress) internal {
    GovHelpers.executePayload(vm, payloadAddress, _executor);
  }
}
