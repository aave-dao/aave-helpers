// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5 <0.9.0;
pragma abicoder v2;

import {Vm} from 'forge-std/Vm.sol';
import {Test} from 'forge-std/Test.sol';
import {console2} from 'forge-std/console2.sol';
import {AaveGovernanceV2, IAaveGovernanceV2, IExecutorWithTimelock} from 'aave-address-book/AaveGovernanceV2.sol';
import {IPoolAddressesProvider} from 'aave-address-book/AaveV3.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {ProxyHelpers} from './ProxyHelpers.sol';

library GovHelpers {
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

  function _buildL2(address forwarder, address payloadAddress)
    private
    pure
    returns (Payload memory)
  {
    return
      Payload({
        target: forwarder,
        signature: 'execute(address)',
        callData: abi.encode(payloadAddress)
      });
  }

  function createProposal(Payload[] memory delegateCalls, bytes32 ipfsHash)
    internal
    returns (uint256)
  {
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
    require(block.chainid == 1, 'MAINNET_ONLY');
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

  function getProposalById(uint256 proposalId)
    internal
    view
    returns (IAaveGovernanceV2.ProposalWithoutVotes memory)
  {
    return AaveGovernanceV2.GOV.getProposalById(proposalId);
  }
}

/**
 * @dev Mock contract which allows performing a delegatecall to `execute`
 * Intended to be used as replacement for L2 admins/executors to mock governance/gnosis execution.
 */
contract MockExecutor {
  error OnlyQueuedActions();
  error InvalidActionsSetId();
  error InsufficientBalance();
  error FailedActionExecution();
  error DuplicateAction();
  error InconsistentParamsLength();
  error EmptyTargets();

  /**
   * @dev Emitted when an ActionsSet is queued
   * @param id Id of the ActionsSet
   * @param targets Array of targets to be called by the actions set
   * @param values Array of values to pass in each call by the actions set
   * @param signatures Array of function signatures to encode in each call by the actions set
   * @param calldatas Array of calldata to pass in each call by the actions set
   * @param withDelegatecalls Array of whether to delegatecall for each call of the actions set
   * @param executionTime The timestamp at which this actions set can be executed
   **/
  event ActionsSetQueued(
    uint256 indexed id,
    address[] targets,
    uint256[] values,
    string[] signatures,
    bytes[] calldatas,
    bool[] withDelegatecalls,
    uint256 executionTime
  );

  /**
   * @dev Emitted when an ActionsSet is successfully executed
   * @param id Id of the ActionsSet
   * @param initiatorExecution The address that triggered the ActionsSet execution
   * @param returnedData The returned data from the ActionsSet execution
   **/
  event ActionsSetExecuted(
    uint256 indexed id,
    address indexed initiatorExecution,
    bytes[] returnedData
  );

  /**
   * @notice This struct contains the data needed to execute a specified set of actions
   * @param targets Array of targets to call
   * @param values Array of values to pass in each call
   * @param signatures Array of function signatures to encode in each call (can be empty)
   * @param calldatas Array of calldatas to pass in each call, appended to the signature at the same array index if not empty
   * @param withDelegateCalls Array of whether to delegatecall for each call
   * @param executionTime Timestamp starting from which the actions set can be executed
   * @param executed True if the actions set has been executed, false otherwise
   * @param canceled True if the actions set has been canceled, false otherwise
   */
  struct ActionsSet {
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
    uint256 executionTime;
    bool executed;
    bool canceled;
  }

  /**
   * @notice This enum contains all possible actions set states
   */
  enum ActionsSetState {
    Queued,
    Executed,
    Canceled,
    Expired
  }

  // Time between queuing and execution
  uint256 private _delay;
  // Time after the execution time during which the actions set can be executed
  uint256 private _gracePeriod;
  // Minimum allowed delay
  uint256 private _minimumDelay;
  // Maximum allowed delay
  uint256 private _maximumDelay;
  // Address with the ability of canceling actions sets
  address private _guardian;

  // Number of actions sets
  uint256 private _actionsSetCounter;
  // Map of registered actions sets (id => ActionsSet)
  mapping(uint256 => ActionsSet) private _actionsSets;
  // Map of queued actions (actionHash => isQueued)
  mapping(bytes32 => bool) private _queuedActions;

  function execute(uint256 actionsSetId) external payable {
    if (getCurrentState(actionsSetId) != ActionsSetState.Queued) revert OnlyQueuedActions();

    ActionsSet storage actionsSet = _actionsSets[actionsSetId];
    actionsSet.executed = true;
    uint256 actionCount = actionsSet.targets.length;

    bytes[] memory returnedData = new bytes[](actionCount);
    for (uint256 i = 0; i < actionCount; ) {
      returnedData[i] = _executeTransaction(
        actionsSet.targets[i],
        actionsSet.values[i],
        actionsSet.signatures[i],
        actionsSet.calldatas[i],
        actionsSet.executionTime,
        actionsSet.withDelegatecalls[i]
      );
      unchecked {
        ++i;
      }
    }

    emit ActionsSetExecuted(actionsSetId, msg.sender, returnedData);
  }

  /**
   * @notice Non-standard functionality used to skip governance and just execute a payload.
   */
  function execute(address payload) public {
    (bool success, ) = address(payload).delegatecall(abi.encodeWithSignature('execute()'));
    require(success, 'PROPOSAL_EXECUTION_FAILED');
  }

  /**
   * @notice Queue an ActionsSet
   * @dev If a signature is empty, calldata is used for the execution, calldata is appended to signature otherwise
   * @param targets Array of targets to be called by the actions set
   * @param values Array of values to pass in each call by the actions set
   * @param signatures Array of function signatures to encode in each call (can be empty)
   * @param calldatas Array of calldata to pass in each call (can be empty)
   * @param withDelegatecalls Array of whether to delegatecall for each call
   **/
  function queue(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    bool[] memory withDelegatecalls
  ) public {
    if (targets.length == 0) revert EmptyTargets();
    uint256 targetsLength = targets.length;
    if (
      targetsLength != values.length ||
      targetsLength != signatures.length ||
      targetsLength != calldatas.length ||
      targetsLength != withDelegatecalls.length
    ) revert InconsistentParamsLength();

    uint256 actionsSetId = _actionsSetCounter;
    uint256 executionTime = block.timestamp + _delay;
    unchecked {
      ++_actionsSetCounter;
    }

    for (uint256 i = 0; i < targetsLength; ) {
      bytes32 actionHash = keccak256(
        abi.encode(
          targets[i],
          values[i],
          signatures[i],
          calldatas[i],
          executionTime,
          withDelegatecalls[i]
        )
      );
      if (isActionQueued(actionHash)) revert DuplicateAction();
      _queuedActions[actionHash] = true;
      unchecked {
        ++i;
      }
    }

    ActionsSet storage actionsSet = _actionsSets[actionsSetId];
    actionsSet.targets = targets;
    actionsSet.values = values;
    actionsSet.signatures = signatures;
    actionsSet.calldatas = calldatas;
    actionsSet.withDelegatecalls = withDelegatecalls;
    actionsSet.executionTime = executionTime;

    emit ActionsSetQueued(
      actionsSetId,
      targets,
      values,
      signatures,
      calldatas,
      withDelegatecalls,
      executionTime
    );
  }

  function getCurrentState(uint256 actionsSetId) public view returns (ActionsSetState) {
    if (_actionsSetCounter <= actionsSetId) revert InvalidActionsSetId();
    ActionsSet storage actionsSet = _actionsSets[actionsSetId];
    if (actionsSet.canceled) {
      return ActionsSetState.Canceled;
    } else if (actionsSet.executed) {
      return ActionsSetState.Executed;
    } else if (block.timestamp > actionsSet.executionTime + _gracePeriod) {
      return ActionsSetState.Expired;
    } else {
      return ActionsSetState.Queued;
    }
  }

  function isActionQueued(bytes32 actionHash) public view returns (bool) {
    return _queuedActions[actionHash];
  }

  function _executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) internal returns (bytes memory) {
    if (address(this).balance < value) revert InsufficientBalance();

    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    _queuedActions[actionHash] = false;

    bytes memory callData;
    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    bool success;
    bytes memory resultData;
    if (withDelegatecall) {
      (success, resultData) = this.executeDelegateCall{value: value}(target, callData);
    } else {
      // solium-disable-next-line security/no-call-value
      (success, resultData) = target.call{value: value}(callData);
    }
    return _verifyCallResult(success, resultData);
  }

  function executeDelegateCall(address target, bytes calldata data)
    external
    payable
    returns (bool, bytes memory)
  {
    bool success;
    bytes memory resultData;
    // solium-disable-next-line security/no-call-value
    (success, resultData) = target.delegatecall(data);
    return (success, resultData);
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
        revert FailedActionExecution();
      }
    }
  }
}

/**
 * @dev Inheriting from this contract in a forge test allows to
 * 1. Configure on the setUp() of the child contract an executor for governance proposals
 *    (or any address with permissions) just by doing for example a `_selectPayloadExecutor(AaveGovernanceV2.SHORT_EXECUTOR)`
 * 2. Afterwards, on a test you can just do `_executePayload(somePayloadAddress)`, and it will be executed via
 *    DELEGATECALL on the address previously selected on step 1).
 */
abstract contract TestWithExecutor is Test {
  MockExecutor internal _executor;

  function _selectPayloadExecutor(address executor) internal {
    MockExecutor mockExecutor = new MockExecutor();
    vm.etch(executor, address(mockExecutor).code);

    _executor = MockExecutor(executor);
  }

  function _executePayload(address payload) internal {
    _executor.execute(payload);
  }
}
