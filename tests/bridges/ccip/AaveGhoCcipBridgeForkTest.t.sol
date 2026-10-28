// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, Vm} from 'forge-std/Test.sol';
import {Strings} from 'aave-v3-origin/contracts/dependencies/openzeppelin/contracts/Strings.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3Arbitrum, AaveV3ArbitrumAssets} from 'aave-address-book/AaveV3Arbitrum.sol';
import {GhoArbitrum} from 'aave-address-book/GhoArbitrum.sol';
import {GovernanceV3Arbitrum} from 'aave-address-book/GovernanceV3Arbitrum.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {IRescuable} from 'solidity-utils/contracts/utils/interfaces/IRescuable.sol';

import {CCIPLocalSimulatorFork, Register, Internal} from './mocks/CCIPLocalSimulatorFork.sol';
import {Constants} from 'tests/bridges/ccip/Constants.sol';
import {Client} from 'src/dependencies/chainlink/libraries/Client.sol';
import {CCIPReceiver} from 'src/dependencies/chainlink/CCIPReceiver.sol';
import {IGhoToken} from 'tests/bridges/ccip/IGhoToken.sol';
import {IRouterClient} from 'src/dependencies/chainlink/interfaces/IRouterClient.sol';
import {ITokenPool} from 'src/dependencies/chainlink/interfaces/ITokenPool.sol';
import {AaveGhoCcipBridge} from 'src/bridges/ccip/AaveGhoCcipBridge.sol';
import {IAaveGhoCcipBridge} from 'src/bridges/ccip/interfaces/IAaveGhoCcipBridge.sol';

contract AaveGhoCcipBridgeForkTestBase is Test, Constants {
  /// @dev Error from CCIP
  error NotAFeeToken(address token);

  address public constant MAINNET_TOKEN_POOL = 0x06179f7C1be40863405f374E7f5F8806c728660A;
  uint32 public constant DEFAULT_GAS_LIMIT = 200_000;
  uint256 public constant AMOUNT_TO_SEND = 1_000_000 ether;
  uint256 public mainnetFork;
  uint256 public arbitrumFork;
  address public owner = makeAddr('owner');

  CCIPLocalSimulatorFork public ccipLocalSimulatorFork;
  AaveGhoCcipBridge mainnetBridge;
  AaveGhoCcipBridge arbitrumBridge;

  function setUp() public {
    mainnetFork = vm.createFork(vm.rpcUrl('mainnet'), 22637440);
    arbitrumFork = vm.createSelectFork(vm.rpcUrl('arbitrum'), 344116880);

    ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
    vm.makePersistent(address(ccipLocalSimulatorFork));

    Register.NetworkDetails memory arbitrumNetworkDetails = Register.NetworkDetails({
      chainSelector: ARBITRUM_CHAIN_SELECTOR,
      routerAddress: ARBITRUM_ROUTER,
      linkAddress: ARBITRUM_LINK,
      wrappedNativeAddress: ARBITRUM_WETH,
      ccipBnMAddress: 0xA189971a2c5AcA0DFC5Ee7a2C44a2Ae27b3CF389,
      ccipLnMAddress: 0x30DeCD269277b8094c00B0bacC3aCaF3fF4Da7fB,
      rmnProxyAddress: ARBITRUM_RMN_PROXY,
      registryModuleOwnerCustomAddress: ARBITRUM_REGISTRY_OWNER,
      tokenAdminRegistryAddress: ARBITRUM_TOKEN_ADMIN
    });
    ccipLocalSimulatorFork.setNetworkDetails(vm.getChainId(), arbitrumNetworkDetails);

    arbitrumBridge = new AaveGhoCcipBridge(
      arbitrumNetworkDetails.routerAddress,
      AaveV3ArbitrumAssets.GHO_UNDERLYING,
      address(AaveV3Arbitrum.COLLECTOR),
      owner
    );

    vm.startPrank(owner);
    IERC20(AaveV3ArbitrumAssets.GHO_UNDERLYING).approve(address(arbitrumBridge), type(uint256).max);
    vm.stopPrank();

    vm.selectFork(mainnetFork);
    Register.NetworkDetails memory mainnetDetails = Register.NetworkDetails({
      chainSelector: MAINNET_CHAIN_SELECTOR,
      routerAddress: MAINNET_ROUTER,
      linkAddress: MAINNET_LINK,
      wrappedNativeAddress: MAINNET_WETH,
      ccipBnMAddress: 0xA189971a2c5AcA0DFC5Ee7a2C44a2Ae27b3CF389,
      ccipLnMAddress: 0x30DeCD269277b8094c00B0bacC3aCaF3fF4Da7fB,
      rmnProxyAddress: MAINNET_RMN_PROXY,
      registryModuleOwnerCustomAddress: MAINNET_REGISTRY_OWNER,
      tokenAdminRegistryAddress: MAINNET_TOKEN_ADMIN
    });
    ccipLocalSimulatorFork.setNetworkDetails(vm.getChainId(), mainnetDetails);

    mainnetBridge = new AaveGhoCcipBridge(
      mainnetDetails.routerAddress,
      AaveV3EthereumAssets.GHO_UNDERLYING,
      address(AaveV3Ethereum.COLLECTOR),
      owner
    );

    vm.startPrank(owner);
    mainnetBridge.setDestinationChain(
      ARBITRUM_CHAIN_SELECTOR,
      abi.encode(address(arbitrumBridge)),
      bytes(''),
      DEFAULT_GAS_LIMIT
    );
    vm.stopPrank();

    vm.startPrank(owner);
    IERC20(AaveV3EthereumAssets.GHO_UNDERLYING).approve(address(mainnetBridge), type(uint256).max);
    vm.stopPrank();

    vm.selectFork(arbitrumFork);
    vm.startPrank(owner);
    arbitrumBridge.setDestinationChain(
      MAINNET_CHAIN_SELECTOR,
      abi.encode(address(mainnetBridge)),
      bytes(''),
      DEFAULT_GAS_LIMIT
    );
    vm.stopPrank();
  }

  function _getMessageFromRecordedLogs() internal returns (Internal.EVM2EVMMessage memory) {
    Vm.Log[] memory entries = vm.getRecordedLogs();
    Internal.EVM2EVMMessage memory message;
    uint256 length = entries.length;
    for (uint256 i; i < length; ++i) {
      if (entries[i].topics[0] == CCIPLocalSimulatorFork.CCIPSendRequested.selector) {
        message = abi.decode(entries[i].data, (Internal.EVM2EVMMessage));
      }
    }

    // Emit event again because getRecordedLogs clears logs after call
    emit CCIPLocalSimulatorFork.CCIPSendRequested(message);

    return message;
  }

  function _buildInvalidMessage() internal returns (Internal.EVM2EVMMessage memory) {
    vm.startPrank(owner);
    vm.selectFork(arbitrumFork);
    arbitrumBridge.removeDestinationChain(MAINNET_CHAIN_SELECTOR);
    vm.stopPrank();

    vm.selectFork(mainnetFork);
    uint256 fee = mainnetBridge.quoteBridge(
      ARBITRUM_CHAIN_SELECTOR,
      AMOUNT_TO_SEND,
      AaveV3EthereumAssets.GHO_UNDERLYING
    );
    deal(AaveV3EthereumAssets.GHO_UNDERLYING, address(mainnetBridge), fee);
    deal(AaveV3EthereumAssets.GHO_UNDERLYING, owner, AMOUNT_TO_SEND);

    vm.startPrank(owner);
    mainnetBridge.send(
      ARBITRUM_CHAIN_SELECTOR,
      AMOUNT_TO_SEND,
      AaveV3EthereumAssets.GHO_UNDERLYING
    );
    vm.stopPrank();

    Internal.EVM2EVMMessage memory message = _getMessageFromRecordedLogs();
    ccipLocalSimulatorFork.switchChainAndRouteMessage(arbitrumFork);

    return message;
  }

  function assertMessage(
    Internal.EVM2EVMMessage memory internalMessage,
    Client.EVMTokenAmount[] memory invalidTokenTransfers
  ) internal pure {
    for (uint256 i = 0; i < internalMessage.tokenAmounts.length; ++i) {
      assertEq(internalMessage.tokenAmounts[i].amount, invalidTokenTransfers[i].amount);
    }
  }
}

contract SendMainnetToArbitrum is AaveGhoCcipBridgeForkTestBase {
  address public feeToken = AaveV3EthereumAssets.GHO_UNDERLYING;

  function test_revertsIf_unsupportedChain() public {
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);
    vm.expectRevert(IAaveGhoCcipBridge.UnsupportedChain.selector);
    mainnetBridge.send(BLAST_CHAIN_SELECTOR, AMOUNT_TO_SEND, feeToken);
    vm.stopPrank();
  }

  function test_revertsIf_callerNoBridgerRole() public {
    vm.selectFork(mainnetFork);
    address caller = makeAddr('random-caller');
    vm.startPrank(caller);
    vm.expectRevert('Ownable: caller is not the owner');
    mainnetBridge.send(ARBITRUM_CHAIN_SELECTOR, AMOUNT_TO_SEND, feeToken);
    vm.stopPrank();
  }

  function test_revertsIf_invalidTransferAmount() public {
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);
    vm.expectRevert(IAaveGhoCcipBridge.InvalidZeroAmount.selector);
    mainnetBridge.send(ARBITRUM_CHAIN_SELECTOR, 0, feeToken);
    vm.stopPrank();
  }

  function test_revertsIf_sourceChainNotConfigured() public {
    vm.startPrank(owner);
    vm.selectFork(arbitrumFork);
    arbitrumBridge.removeDestinationChain(MAINNET_CHAIN_SELECTOR);
    vm.stopPrank();

    vm.selectFork(mainnetFork);
    uint256 fee = mainnetBridge.quoteBridge(ARBITRUM_CHAIN_SELECTOR, AMOUNT_TO_SEND, feeToken);
    deal(AaveV3EthereumAssets.GHO_UNDERLYING, address(mainnetBridge), fee);
    deal(AaveV3EthereumAssets.GHO_UNDERLYING, owner, AMOUNT_TO_SEND);

    vm.startPrank(owner);
    vm.expectEmit(false, true, true, true, address(mainnetBridge));
    emit IAaveGhoCcipBridge.BridgeMessageInitiated(
      bytes32(0),
      ARBITRUM_CHAIN_SELECTOR,
      owner,
      AMOUNT_TO_SEND
    );
    mainnetBridge.send(ARBITRUM_CHAIN_SELECTOR, AMOUNT_TO_SEND, feeToken);

    Internal.EVM2EVMMessage memory message = _getMessageFromRecordedLogs();

    vm.expectEmit(true, false, false, false, address(arbitrumBridge));
    emit IAaveGhoCcipBridge.BridgeMessageFailed(message.messageId, bytes(hex'5ea23900'));
    ccipLocalSimulatorFork.switchChainAndRouteMessage(arbitrumFork);

    Client.EVMTokenAmount[] memory messageData = arbitrumBridge.getInvalidMessage(
      message.messageId
    );
    assertTrue(messageData.length > 0);
    Client.EVMTokenAmount[] memory invalidTokenTransfers = arbitrumBridge.getInvalidMessage(
      message.messageId
    );
    assertMessage(message, invalidTokenTransfers);
    vm.stopPrank();
  }

  function test_revertsIf_bridgeLimitExceeded() public {
    vm.selectFork(mainnetFork);
    uint256 bridged = ITokenPool(MAINNET_TOKEN_POOL).getCurrentBridgedAmount();

    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    ITokenPool(MAINNET_TOKEN_POOL).setBridgeLimit(bridged);

    vm.startPrank(owner);
    vm.expectRevert(abi.encodeWithSelector(IAaveGhoCcipBridge.BridgeLimitExceeded.selector, 0));
    mainnetBridge.send(ARBITRUM_CHAIN_SELECTOR, 100 ether, feeToken);
    vm.stopPrank();
  }

  function testFuzz_revertsIf_rateLimitExceeded(uint256 amount) public {
    vm.selectFork(mainnetFork);
    uint128 limit = mainnetBridge.getRateLimit(ARBITRUM_CHAIN_SELECTOR);

    amount = bound(amount, limit + 1, 1e32 - 1); // made top limit to prevent arithmetic overflow
    uint256 fee = 1 ether; // set static fee because quoteBridge reverts if amount exceeds limit
    deal(AaveV3EthereumAssets.GHO_UNDERLYING, address(mainnetBridge), fee);
    deal(AaveV3EthereumAssets.GHO_UNDERLYING, owner, amount);
    deal(owner, 100);

    vm.startPrank(owner);
    vm.expectRevert(abi.encodeWithSelector(IAaveGhoCcipBridge.RateLimitExceeded.selector, limit));
    mainnetBridge.send(ARBITRUM_CHAIN_SELECTOR, amount, feeToken);
    vm.stopPrank();
  }

  function test_successful_fuzz(uint256 amount) public {
    vm.selectFork(mainnetFork);
    uint128 limit = mainnetBridge.getRateLimit(ARBITRUM_CHAIN_SELECTOR);

    amount = bound(amount, 1, limit);
    vm.selectFork(arbitrumFork);

    uint256 beforeBalance = IERC20(AaveV3ArbitrumAssets.GHO_UNDERLYING).balanceOf(
      address(AaveV3Arbitrum.COLLECTOR)
    );

    vm.selectFork(mainnetFork);
    uint256 fee = mainnetBridge.quoteBridge(ARBITRUM_CHAIN_SELECTOR, amount, feeToken);
    deal(AaveV3EthereumAssets.GHO_UNDERLYING, address(mainnetBridge), fee);
    deal(AaveV3EthereumAssets.GHO_UNDERLYING, owner, amount);

    vm.startPrank(owner);
    vm.expectEmit(false, true, true, true, address(mainnetBridge));
    emit IAaveGhoCcipBridge.BridgeMessageInitiated(
      bytes32(0),
      ARBITRUM_CHAIN_SELECTOR,
      owner,
      amount
    );
    mainnetBridge.send(ARBITRUM_CHAIN_SELECTOR, amount, feeToken);

    Internal.EVM2EVMMessage memory message = _getMessageFromRecordedLogs();

    vm.expectEmit(true, true, false, true, address(arbitrumBridge));
    emit IAaveGhoCcipBridge.BridgeMessageFinalized(
      message.messageId,
      address(AaveV3Arbitrum.COLLECTOR),
      amount
    );
    ccipLocalSimulatorFork.switchChainAndRouteMessage(arbitrumFork);
    uint256 afterBalance = IERC20(AaveV3ArbitrumAssets.GHO_UNDERLYING).balanceOf(
      address(AaveV3Arbitrum.COLLECTOR)
    );
    assertEq(afterBalance, beforeBalance + amount, 'Bridged amount not updated correctly');
    vm.stopPrank();
  }

  function test_successful_payWithEth(uint256 amount) public {
    vm.selectFork(mainnetFork);
    uint128 limit = mainnetBridge.getRateLimit(ARBITRUM_CHAIN_SELECTOR);

    amount = bound(amount, 1, limit);
    vm.selectFork(arbitrumFork);

    uint256 beforeBalance = IERC20(AaveV3ArbitrumAssets.GHO_UNDERLYING).balanceOf(
      address(AaveV3Arbitrum.COLLECTOR)
    );

    vm.selectFork(mainnetFork);
    uint256 fee = mainnetBridge.quoteBridge(ARBITRUM_CHAIN_SELECTOR, amount, address(0));
    deal(AaveV3EthereumAssets.GHO_UNDERLYING, owner, amount);
    deal(address(mainnetBridge), fee);

    vm.startPrank(owner);
    vm.expectEmit(false, true, true, true, address(mainnetBridge));
    emit IAaveGhoCcipBridge.BridgeMessageInitiated(
      bytes32(0),
      ARBITRUM_CHAIN_SELECTOR,
      owner,
      amount
    );
    mainnetBridge.send(ARBITRUM_CHAIN_SELECTOR, amount, address(0));

    Internal.EVM2EVMMessage memory message = _getMessageFromRecordedLogs();

    vm.expectEmit(true, true, false, true, address(arbitrumBridge));
    emit IAaveGhoCcipBridge.BridgeMessageFinalized(
      message.messageId,
      address(AaveV3Arbitrum.COLLECTOR),
      amount
    );
    ccipLocalSimulatorFork.switchChainAndRouteMessage(arbitrumFork);
    uint256 afterBalance = IERC20(AaveV3ArbitrumAssets.GHO_UNDERLYING).balanceOf(
      address(AaveV3Arbitrum.COLLECTOR)
    );
    assertEq(afterBalance, beforeBalance + amount, 'Bridged amount not updated correctly');
    vm.stopPrank();
  }
}

contract SendArbitrumToMainnet is AaveGhoCcipBridgeForkTestBase {
  address public feeToken = AaveV3ArbitrumAssets.GHO_UNDERLYING;

  function test_revertsIf_unsupportedChain() public {
    vm.selectFork(arbitrumFork);
    vm.startPrank(owner);
    vm.expectRevert(IAaveGhoCcipBridge.UnsupportedChain.selector);
    arbitrumBridge.send(BLAST_CHAIN_SELECTOR, AMOUNT_TO_SEND, feeToken);
    vm.stopPrank();
  }

  function test_revertsIf_callerNoBridgerRole() public {
    vm.selectFork(arbitrumFork);
    address caller = makeAddr('random-caller');
    vm.startPrank(caller);
    vm.expectRevert('Ownable: caller is not the owner');
    arbitrumBridge.send(MAINNET_CHAIN_SELECTOR, AMOUNT_TO_SEND, feeToken);
    vm.stopPrank();
  }

  function test_revertsIf_invalidTransferAmount() public {
    vm.selectFork(arbitrumFork);
    vm.startPrank(owner);
    vm.expectRevert(IAaveGhoCcipBridge.InvalidZeroAmount.selector);
    arbitrumBridge.send(MAINNET_CHAIN_SELECTOR, 0, feeToken);
    vm.stopPrank();
  }

  function test_revertsIf_insufficientNativeFee() public {
    vm.selectFork(arbitrumFork);
    vm.startPrank(owner);
    vm.expectRevert(IAaveGhoCcipBridge.InsufficientFee.selector);
    arbitrumBridge.send(MAINNET_CHAIN_SELECTOR, AMOUNT_TO_SEND, address(0));
    vm.stopPrank();
  }

  function test_revertsIf_insufficientFeeToken() public {
    vm.selectFork(arbitrumFork);
    vm.startPrank(owner);
    vm.expectRevert(IAaveGhoCcipBridge.InsufficientFee.selector);
    arbitrumBridge.send(
      MAINNET_CHAIN_SELECTOR,
      AMOUNT_TO_SEND,
      AaveV3ArbitrumAssets.GHO_UNDERLYING
    );
    vm.stopPrank();
  }

  function test_revertsIf_invalidFeeToken() public {
    address invalidFeeToken = makeAddr('new erc20');
    vm.selectFork(arbitrumFork);
    deal(AaveV3ArbitrumAssets.GHO_UNDERLYING, owner, AMOUNT_TO_SEND);

    vm.startPrank(owner);
    vm.expectRevert(abi.encodeWithSelector(NotAFeeToken.selector, invalidFeeToken));
    arbitrumBridge.send(MAINNET_CHAIN_SELECTOR, AMOUNT_TO_SEND, invalidFeeToken);
    vm.stopPrank();
  }

  function test_revertsIf_sourceChainNotConfigured() public {
    vm.startPrank(owner);
    vm.selectFork(mainnetFork);
    mainnetBridge.removeDestinationChain(ARBITRUM_CHAIN_SELECTOR);
    vm.stopPrank();

    vm.selectFork(arbitrumFork);
    uint256 amountToSend = 1_000 ether;
    uint256 fee = arbitrumBridge.quoteBridge(MAINNET_CHAIN_SELECTOR, amountToSend, feeToken);
    deal(AaveV3ArbitrumAssets.GHO_UNDERLYING, address(arbitrumBridge), fee);
    deal(AaveV3ArbitrumAssets.GHO_UNDERLYING, owner, AMOUNT_TO_SEND);

    vm.startPrank(owner);
    vm.expectEmit(false, true, true, true, address(arbitrumBridge));
    emit IAaveGhoCcipBridge.BridgeMessageInitiated(
      bytes32(0),
      MAINNET_CHAIN_SELECTOR,
      owner,
      amountToSend
    );
    arbitrumBridge.send(MAINNET_CHAIN_SELECTOR, amountToSend, feeToken);

    Internal.EVM2EVMMessage memory message = _getMessageFromRecordedLogs();

    vm.expectEmit(true, false, false, false, address(mainnetBridge));
    emit IAaveGhoCcipBridge.BridgeMessageFailed(message.messageId, bytes(hex'5ea23900'));
    ccipLocalSimulatorFork.switchChainAndRouteMessage(mainnetFork);

    Client.EVMTokenAmount[] memory messageData = mainnetBridge.getInvalidMessage(message.messageId);
    assertTrue(messageData.length > 0);
    Client.EVMTokenAmount[] memory invalidTokenTransfers = mainnetBridge.getInvalidMessage(
      message.messageId
    );
    assertMessage(message, invalidTokenTransfers);
    vm.stopPrank();
  }

  function test_revertsIf_fuzzRateLimitExceeded(uint256 amount) public {
    vm.selectFork(arbitrumFork);
    uint128 limit = arbitrumBridge.getRateLimit(MAINNET_CHAIN_SELECTOR);
    (uint256 bucket, uint256 level) = IGhoToken(AaveV3ArbitrumAssets.GHO_UNDERLYING)
      .getFacilitatorBucket(GhoArbitrum.GHO_CCIP_TOKEN_POOL);

    amount = bound(amount, limit + 1, bucket - level); // made top limit to prevent arithmetic overflow
    vm.prank(GovernanceV3Arbitrum.EXECUTOR_LVL_1);
    ITokenPool(GhoArbitrum.GHO_CCIP_TOKEN_POOL).directMint(owner, amount); // Mint amount so enough GHO is available on Arbitrum

    uint256 fee = 1 ether; // set static fee to avoid reverts of quote bridge
    deal(AaveV3ArbitrumAssets.GHO_UNDERLYING, address(arbitrumBridge), fee);
    deal(AaveV3ArbitrumAssets.GHO_UNDERLYING, owner, AMOUNT_TO_SEND);

    vm.startPrank(owner);
    vm.expectRevert(abi.encodeWithSelector(IAaveGhoCcipBridge.RateLimitExceeded.selector, limit));
    arbitrumBridge.send(MAINNET_CHAIN_SELECTOR, amount, feeToken);
    vm.stopPrank();
  }

  function test_successful_fuzz(uint256 amount) public {
    vm.selectFork(mainnetFork);
    uint256 beforeBalance = IERC20(AaveV3EthereumAssets.GHO_UNDERLYING).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    vm.selectFork(arbitrumFork);
    uint128 limit = arbitrumBridge.getRateLimit(MAINNET_CHAIN_SELECTOR);
    amount = bound(amount, 1, limit);

    vm.prank(GovernanceV3Arbitrum.EXECUTOR_LVL_1);
    ITokenPool(GhoArbitrum.GHO_CCIP_TOKEN_POOL).directMint(owner, amount); // Mint amount so enough GHO is available on Arbitrum

    uint256 fee = arbitrumBridge.quoteBridge(MAINNET_CHAIN_SELECTOR, amount, feeToken);
    deal(AaveV3ArbitrumAssets.GHO_UNDERLYING, address(arbitrumBridge), fee);
    deal(AaveV3ArbitrumAssets.GHO_UNDERLYING, owner, amount);

    vm.startPrank(owner);
    vm.expectEmit(false, true, true, true, address(arbitrumBridge));
    emit IAaveGhoCcipBridge.BridgeMessageInitiated(
      bytes32(0),
      MAINNET_CHAIN_SELECTOR,
      owner,
      amount
    );
    arbitrumBridge.send(MAINNET_CHAIN_SELECTOR, amount, feeToken);

    Internal.EVM2EVMMessage memory message = _getMessageFromRecordedLogs();

    vm.expectEmit(true, true, false, true, address(mainnetBridge));
    emit IAaveGhoCcipBridge.BridgeMessageFinalized(
      message.messageId,
      address(AaveV3Ethereum.COLLECTOR),
      amount
    );
    ccipLocalSimulatorFork.switchChainAndRouteMessage(mainnetFork);
    uint256 afterBalance = IERC20(AaveV3EthereumAssets.GHO_UNDERLYING).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );
    assertEq(afterBalance, beforeBalance + amount, 'Bridged amount not updated correctly');
    vm.stopPrank();
  }

  function test_successful_payWithEth(uint256 amount) public {
    vm.selectFork(mainnetFork);
    uint256 beforeBalance = IERC20(AaveV3EthereumAssets.GHO_UNDERLYING).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    vm.selectFork(arbitrumFork);
    uint128 limit = arbitrumBridge.getRateLimit(MAINNET_CHAIN_SELECTOR);
    amount = bound(amount, 1, limit);

    vm.prank(GovernanceV3Arbitrum.EXECUTOR_LVL_1);
    ITokenPool(GhoArbitrum.GHO_CCIP_TOKEN_POOL).directMint(owner, amount); // Mint amount so enough GHO is available on Arbitrum

    uint256 fee = arbitrumBridge.quoteBridge(MAINNET_CHAIN_SELECTOR, amount, address(0));
    deal(AaveV3ArbitrumAssets.GHO_UNDERLYING, owner, amount);
    deal(address(arbitrumBridge), fee);

    vm.startPrank(owner);
    vm.expectEmit(false, true, true, true, address(arbitrumBridge));
    emit IAaveGhoCcipBridge.BridgeMessageInitiated(
      bytes32(0),
      MAINNET_CHAIN_SELECTOR,
      owner,
      amount
    );
    arbitrumBridge.send(MAINNET_CHAIN_SELECTOR, amount, address(0));

    Internal.EVM2EVMMessage memory message = _getMessageFromRecordedLogs();

    vm.expectEmit(true, true, false, true, address(mainnetBridge));
    emit IAaveGhoCcipBridge.BridgeMessageFinalized(
      message.messageId,
      address(AaveV3Ethereum.COLLECTOR),
      amount
    );
    ccipLocalSimulatorFork.switchChainAndRouteMessage(mainnetFork);
    uint256 afterBalance = IERC20(AaveV3EthereumAssets.GHO_UNDERLYING).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );
    assertEq(afterBalance, beforeBalance + amount, 'Bridged amount not updated correctly');
    vm.stopPrank();
  }

  function test_successful_payWithEthExcessFee(uint256 amount) public {
    vm.selectFork(mainnetFork);
    uint256 beforeBalance = IERC20(AaveV3EthereumAssets.GHO_UNDERLYING).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    vm.selectFork(arbitrumFork);
    uint128 limit = arbitrumBridge.getRateLimit(MAINNET_CHAIN_SELECTOR);
    amount = bound(amount, 1, limit);

    vm.prank(GovernanceV3Arbitrum.EXECUTOR_LVL_1);
    ITokenPool(GhoArbitrum.GHO_CCIP_TOKEN_POOL).directMint(owner, amount); // Mint amount so enough GHO is available on Arbitrum

    uint256 fee = arbitrumBridge.quoteBridge(MAINNET_CHAIN_SELECTOR, amount, address(0));
    deal(AaveV3ArbitrumAssets.GHO_UNDERLYING, owner, amount);
    deal(address(arbitrumBridge), fee);

    vm.startPrank(owner);
    vm.expectEmit(false, true, true, true, address(arbitrumBridge));
    emit IAaveGhoCcipBridge.BridgeMessageInitiated(
      bytes32(0),
      MAINNET_CHAIN_SELECTOR,
      owner,
      amount
    );
    arbitrumBridge.send(MAINNET_CHAIN_SELECTOR, amount, address(0));

    Internal.EVM2EVMMessage memory message = _getMessageFromRecordedLogs();

    vm.expectEmit(true, true, false, true, address(mainnetBridge));
    emit IAaveGhoCcipBridge.BridgeMessageFinalized(
      message.messageId,
      address(AaveV3Ethereum.COLLECTOR),
      amount
    );
    ccipLocalSimulatorFork.switchChainAndRouteMessage(mainnetFork);
    uint256 afterBalance = IERC20(AaveV3EthereumAssets.GHO_UNDERLYING).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );
    assertEq(afterBalance, beforeBalance + amount, 'Bridged amount not updated correctly');
    vm.stopPrank();
  }
}

contract RecoverFailedMessageTokensTest is AaveGhoCcipBridgeForkTestBase {
  address public feeToken = AaveV3EthereumAssets.GHO_UNDERLYING;

  function test_revertIf_callerNotOwner() public {
    vm.selectFork(mainnetFork);
    vm.expectRevert('Ownable: caller is not the owner');
    mainnetBridge.recoverFailedMessageTokens(bytes32(0));
    vm.stopPrank();
  }

  function test_revertIf_messageNotFound() public {
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);

    vm.expectRevert(IAaveGhoCcipBridge.MessageNotFound.selector);
    mainnetBridge.recoverFailedMessageTokens(bytes32(0));
    vm.stopPrank();
  }

  function test_successfulMessageRecovery() public {
    Internal.EVM2EVMMessage memory message = _buildInvalidMessage();

    vm.selectFork(arbitrumFork);
    uint256 balanceBefore = IERC20(AaveV3ArbitrumAssets.GHO_UNDERLYING).balanceOf(
      address(AaveV3Arbitrum.COLLECTOR)
    );

    vm.startPrank(owner);
    vm.expectEmit(true, false, false, false, address(arbitrumBridge));
    emit IAaveGhoCcipBridge.BridgeMessageRecovered(message.messageId);
    arbitrumBridge.recoverFailedMessageTokens(message.messageId);

    uint256 balanceAfter = IERC20(AaveV3ArbitrumAssets.GHO_UNDERLYING).balanceOf(
      address(AaveV3Arbitrum.COLLECTOR)
    );

    assertEq(balanceAfter, balanceBefore + AMOUNT_TO_SEND);
    vm.stopPrank();
  }
}

contract SetDestinationChainTest is AaveGhoCcipBridgeForkTestBase {
  function test_revertIf_callerNotOwner() public {
    vm.selectFork(mainnetFork);
    vm.expectRevert('Ownable: caller is not the owner');
    mainnetBridge.setDestinationChain(
      ARBITRUM_CHAIN_SELECTOR,
      abi.encode(arbitrumBridge),
      bytes(''),
      DEFAULT_GAS_LIMIT
    );
  }

  function test_successful() public {
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);

    vm.expectEmit(address(mainnetBridge));
    emit IAaveGhoCcipBridge.DestinationChainSet(
      ARBITRUM_CHAIN_SELECTOR,
      abi.encode(arbitrumBridge),
      DEFAULT_GAS_LIMIT,
      bytes('')
    );
    mainnetBridge.setDestinationChain(
      ARBITRUM_CHAIN_SELECTOR,
      abi.encode(arbitrumBridge),
      bytes(''),
      DEFAULT_GAS_LIMIT
    );

    IAaveGhoCcipBridge.RemoteChainConfig memory config = mainnetBridge.getDestinationRemoteConfig(
      ARBITRUM_CHAIN_SELECTOR
    );

    assertEq(
      config.destination,
      abi.encode(arbitrumBridge),
      'Destination bridge not set correctly in the mapping'
    );
    vm.stopPrank();
  }
}

contract RemoveDestinationChainTest is AaveGhoCcipBridgeForkTestBase {
  function test_revertIf_callerNotOwner() public {
    vm.selectFork(mainnetFork);
    vm.expectRevert('Ownable: caller is not the owner');
    mainnetBridge.removeDestinationChain(ARBITRUM_CHAIN_SELECTOR);
    vm.stopPrank();
  }

  function test_successful() public {
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);

    vm.expectEmit(address(mainnetBridge));
    emit IAaveGhoCcipBridge.DestinationChainSet(
      ARBITRUM_CHAIN_SELECTOR,
      abi.encode(arbitrumBridge),
      DEFAULT_GAS_LIMIT,
      bytes('')
    );
    mainnetBridge.setDestinationChain(
      ARBITRUM_CHAIN_SELECTOR,
      abi.encode(arbitrumBridge),
      bytes(''),
      DEFAULT_GAS_LIMIT
    );

    IAaveGhoCcipBridge.RemoteChainConfig memory config = mainnetBridge.getDestinationRemoteConfig(
      ARBITRUM_CHAIN_SELECTOR
    );

    assertEq(
      config.destination,
      abi.encode(arbitrumBridge),
      'Destination bridge not set correctly in the mapping'
    );

    vm.expectEmit(address(mainnetBridge));
    emit IAaveGhoCcipBridge.DestinationChainSet(ARBITRUM_CHAIN_SELECTOR, bytes(''), 0, bytes(''));
    mainnetBridge.removeDestinationChain(ARBITRUM_CHAIN_SELECTOR);

    config = mainnetBridge.getDestinationRemoteConfig(ARBITRUM_CHAIN_SELECTOR);

    assertEq(
      config.destination,
      bytes(''),
      'Destination bridge not removed correctly in the mapping'
    );
    vm.stopPrank();
  }
}

contract ProcessMessageTest is AaveGhoCcipBridgeForkTestBase {
  function test_revertsIf_callerNotSelf() public {
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);

    Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](0);

    // build dummy message for test
    Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
      messageId: bytes32(0),
      sourceChainSelector: ARBITRUM_CHAIN_SELECTOR,
      sender: abi.encode(address(0)),
      data: '',
      destTokenAmounts: tokenAmounts
    });

    vm.expectRevert(IAaveGhoCcipBridge.OnlySelf.selector);
    mainnetBridge.processMessage(message);
    vm.stopPrank();
  }

  function test_revertsIf_invalidToken() public {
    vm.selectFork(mainnetFork);
    vm.startPrank(address(mainnetBridge));

    Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
    tokenAmounts[0].token = AaveV3EthereumAssets.USDC_UNDERLYING;
    tokenAmounts[0].amount = 1_000e6;

    // build dummy message for test
    Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
      messageId: bytes32(0),
      sourceChainSelector: ARBITRUM_CHAIN_SELECTOR,
      sender: abi.encode(address(arbitrumBridge)),
      data: '',
      destTokenAmounts: tokenAmounts
    });

    vm.expectRevert(IAaveGhoCcipBridge.InvalidToken.selector);
    mainnetBridge.processMessage(message);
    vm.stopPrank();
  }
}

contract CcipReceiveTest is AaveGhoCcipBridgeForkTestBase {
  function test_revertsIf_invalidRouter() public {
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);

    Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](0);

    // build dummy message for test
    Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
      messageId: bytes32(0),
      sourceChainSelector: ARBITRUM_CHAIN_SELECTOR,
      sender: abi.encode(address(0)),
      data: '',
      destTokenAmounts: tokenAmounts
    });

    vm.expectRevert(abi.encodeWithSelector(CCIPReceiver.InvalidRouter.selector, owner));
    mainnetBridge.ccipReceive(message);
    vm.stopPrank();
  }

  function test_successful_receivedInvalidMessage() public {
    vm.startPrank(owner);
    vm.selectFork(mainnetFork);

    Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](0);

    // build dummy message for test
    Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
      messageId: bytes32(0),
      sourceChainSelector: ARBITRUM_CHAIN_SELECTOR,
      sender: abi.encode(address(0)),
      data: '',
      destTokenAmounts: tokenAmounts
    });
    vm.stopPrank();

    vm.startPrank(mainnetBridge.ROUTER());
    vm.expectEmit(address(mainnetBridge));
    emit IAaveGhoCcipBridge.BridgeMessageFailed(bytes32(0), hex'5ea23900');
    mainnetBridge.ccipReceive(message);
    vm.stopPrank();
  }
}

contract QuoteTransferTest is AaveGhoCcipBridgeForkTestBase {
  address public feeToken = address(0);

  function test_revertsIf_unsupportedChain() public {
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);
    vm.expectRevert(IAaveGhoCcipBridge.UnsupportedChain.selector);
    mainnetBridge.quoteBridge(BLAST_CHAIN_SELECTOR, AMOUNT_TO_SEND, feeToken);
    vm.stopPrank();
  }

  function test_revertsIf_invalidTransferAmount() public {
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);
    vm.expectRevert(IAaveGhoCcipBridge.InvalidZeroAmount.selector);
    mainnetBridge.quoteBridge(ARBITRUM_CHAIN_SELECTOR, 0, feeToken);
    vm.stopPrank();
  }

  function test_revertsIf_rateLimitExceeded() public {
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);
    uint128 limit = mainnetBridge.getRateLimit(ARBITRUM_CHAIN_SELECTOR);
    vm.expectRevert(abi.encodeWithSelector(IAaveGhoCcipBridge.RateLimitExceeded.selector, limit));
    mainnetBridge.quoteBridge(ARBITRUM_CHAIN_SELECTOR, limit + 1, feeToken);
    vm.stopPrank();
  }

  function test_revertsIf_invalidFeeToken() public {
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);
    vm.expectRevert(abi.encodeWithSelector(NotAFeeToken.selector, address(1)));
    mainnetBridge.quoteBridge(ARBITRUM_CHAIN_SELECTOR, AMOUNT_TO_SEND, address(1));
    vm.stopPrank();
  }

  function test_successful() public {
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);
    uint256 fee = mainnetBridge.quoteBridge(ARBITRUM_CHAIN_SELECTOR, AMOUNT_TO_SEND, feeToken);

    assertGt(fee, 0);
    vm.stopPrank();
  }
}

contract RescuableTest is AaveGhoCcipBridgeForkTestBase {
  uint256 amount = 100_000 ether;

  function test_revertsIf_callertNotRescueGuardian() public {
    vm.selectFork(mainnetFork);
    vm.expectRevert(IRescuable.OnlyRescueGuardian.selector);
    mainnetBridge.emergencyTokenTransfer(
      AaveV3EthereumAssets.GHO_UNDERLYING,
      address(AaveV3Ethereum.COLLECTOR),
      amount
    );
  }

  function test_successful() public {
    vm.selectFork(mainnetFork);
    deal(AaveV3EthereumAssets.GHO_UNDERLYING, address(mainnetBridge), amount);

    assertEq(mainnetBridge.whoCanRescue(), owner);
    assertEq(mainnetBridge.maxRescue(AaveV3EthereumAssets.GHO_UNDERLYING), amount);

    uint256 balanceBefore = IERC20(AaveV3EthereumAssets.GHO_UNDERLYING).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    vm.prank(owner);
    mainnetBridge.emergencyTokenTransfer(
      AaveV3EthereumAssets.GHO_UNDERLYING,
      address(AaveV3Ethereum.COLLECTOR),
      amount
    );

    assertEq(
      IERC20(AaveV3EthereumAssets.GHO_UNDERLYING).balanceOf(address(AaveV3Ethereum.COLLECTOR)),
      balanceBefore + amount
    );
  }
}

contract GetInvalidMessageTest is AaveGhoCcipBridgeForkTestBase {
  address public feeToken = AaveV3EthereumAssets.GHO_UNDERLYING;

  function test_revertIf_messageNotFound() external {
    vm.selectFork(mainnetFork);
    vm.startPrank(owner);
    vm.expectRevert(IAaveGhoCcipBridge.MessageNotFound.selector);
    mainnetBridge.getInvalidMessage(bytes32(0));
    vm.stopPrank();
  }

  function test_successful() external {
    Internal.EVM2EVMMessage memory message = _buildInvalidMessage();

    vm.selectFork(arbitrumFork);
    vm.startPrank(owner);

    Client.EVMTokenAmount[] memory tokenAmounts = arbitrumBridge.getInvalidMessage(
      message.messageId
    );
    assertEq(tokenAmounts.length, 1);
    vm.stopPrank();
  }
}

contract ReceiveTest is AaveGhoCcipBridgeForkTestBase {
  function test_receiveEther_arbitrum(uint256 amount) public {
    amount = bound(amount, 0, 100 ether);

    vm.selectFork(arbitrumFork);
    assertEq(address(arbitrumBridge).balance, 0);

    (bool ok, ) = address(arbitrumBridge).call{value: amount}('');

    assertTrue(ok);

    assertEq(address(arbitrumBridge).balance, amount);
  }

  function test_receiveEther_mainnet(uint256 amount) public {
    amount = bound(amount, 0, 100 ether);

    vm.selectFork(mainnetFork);
    assertEq(address(mainnetBridge).balance, 0);

    (bool ok, ) = address(mainnetBridge).call{value: amount}('');

    assertTrue(ok);

    assertEq(address(mainnetBridge).balance, amount);
  }
}
