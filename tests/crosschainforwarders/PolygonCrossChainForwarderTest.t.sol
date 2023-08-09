// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {AaveV3Polygon, AaveMisc} from 'aave-address-book/AaveAddressBook.sol';
import {AaveGovernanceV2, IExecutorWithTimelock} from 'aave-address-book/AaveGovernanceV2.sol';
import {IStateReceiver} from 'governance-crosschain-bridges/contracts/dependencies/polygon/fxportal/FxChild.sol';
import {GovHelpers} from '../../src/GovHelpers.sol';
import {ProtocolV3TestBase, ReserveConfig, ReserveTokens, IERC20} from '../../src/ProtocolV3TestBase.sol';
import {CrosschainForwarderPolygon} from '../../src/crosschainforwarders/CrosschainForwarderPolygon.sol';
import {PayloadWithEmit} from '../mocks/PayloadWithEmit.sol';

/**
 * This test covers syncing between mainnet and polygon.
 */
contract PolygonCrossChainForwarderTest is ProtocolV3TestBase {
  event TestEvent();
  // the identifiers of the forks
  uint256 mainnetFork;
  uint256 polygonFork;

  address public constant BRIDGE_ADMIN = 0x0000000000000000000000000000000000001001;

  address public constant FX_CHILD_ADDRESS = 0x8397259c983751DAf40400790063935a11afa28a;

  address public constant POLYGON_BRIDGE_EXECUTOR = AaveGovernanceV2.POLYGON_BRIDGE_EXECUTOR;

  PayloadWithEmit public payloadWithEmit;

  CrosschainForwarderPolygon public forwarder;

  function setUp() public {
    mainnetFork = vm.createSelectFork(vm.rpcUrl('mainnet'), 15275388);
    forwarder = new CrosschainForwarderPolygon();
    polygonFork = vm.createSelectFork(vm.rpcUrl('polygon'), 31507646);
    payloadWithEmit = new PayloadWithEmit();
  }

  // utility to transform memory to calldata so array range access is available
  function _cutBytes(bytes calldata input) public pure returns (bytes calldata) {
    return input[64:];
  }

  function testProposalE2E() public {
    // 1. create l1 proposal
    vm.selectFork(mainnetFork);
    vm.startPrank(AaveMisc.ECOSYSTEM_RESERVE);
    GovHelpers.Payload[] memory payloads = new GovHelpers.Payload[](1);
    payloads[0] = GovHelpers.Payload({
      value: 0,
      withDelegatecall: true,
      target: address(forwarder),
      signature: 'execute(address)',
      callData: abi.encode(address(payloadWithEmit))
    });

    uint256 proposalId = GovHelpers.createProposal(
      payloads,
      0xf6e50d5a3f824f5ab4ffa15fb79f4fa1871b8bf7af9e9b32c1aaaa9ea633006d
    );
    vm.stopPrank();

    // 2. execute proposal and record logs so we can extract the emitted StateSynced event
    vm.recordLogs();
    GovHelpers.passVoteAndExecute(vm, proposalId);

    Vm.Log[] memory entries = vm.getRecordedLogs();
    assertEq(keccak256('StateSynced(uint256,address,bytes)'), entries[2].topics[0]);
    assertEq(address(uint160(uint256(entries[2].topics[2]))), FX_CHILD_ADDRESS);

    // 3. mock the receive on l2 with the data emitted on StateSynced
    vm.selectFork(polygonFork);
    vm.startPrank(BRIDGE_ADMIN);
    IStateReceiver(FX_CHILD_ADDRESS).onStateReceive(
      uint256(entries[2].topics[1]),
      this._cutBytes(entries[2].data)
    );
    vm.stopPrank();

    // 4. Forward time & execute proposal
    vm.expectEmit(true, true, true, true);
    emit TestEvent();
    GovHelpers.executeLatestActionSet(vm, POLYGON_BRIDGE_EXECUTOR);
  }
}
