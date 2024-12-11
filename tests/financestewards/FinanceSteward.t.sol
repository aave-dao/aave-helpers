// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {FinanceSteward, IFinanceSteward} from 'src/financestewards/FinanceSteward.sol';
import {AggregatorInterface} from 'src/financestewards/AggregatorInterface.sol';
import {CollectorUtils} from 'src/CollectorUtils.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {ICollector} from 'collector-upgrade-rev6/lib/aave-v3-origin/src/contracts/treasury/ICollector.sol';
import {Collector} from 'collector-upgrade-rev6/lib/aave-v3-origin/src/contracts/treasury/Collector.sol';
import {IAccessControl} from 'aave-v3-origin/core/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol';


/**
 * Helper contract to mock price feed calls
 */
contract MockOracle {
  function decimals() external pure returns (uint8) {
    return 8;
  }

  function latestAnswer() external pure returns (int256) {
    return 0;
  }
}

/*
 * Oracle missing `decimals` implementation thus invalid.
 */
contract InvalidMockOracle {
  function latestAnswer() external pure returns (int256) {
    return 0;
  }
}

/**
 * @dev Test for Finance Steward contract
 * command: make test-financesteward
 */
contract FinanceSteward_Test is Test {
  event SwapRequested(
    address milkman,
    address indexed fromToken,
    address indexed toToken,
    address fromOracle,
    address toOracle,
    uint256 amount,
    address indexed recipient,
    uint256 slippage
  );
  event BudgetUpdate(address indexed token, uint newAmount);
  event SwapApprovedToken(address indexed token, address indexed oracleUSD);
  event ReceiverWhitelisted(address indexed receiver);
  event MinimumTokenBalanceUpdated(address indexed token, uint newAmount);
  event Upgraded(address indexed impl);

  address public constant guardian = address(82);
  FinanceSteward public steward;

  address public alice = address(43);

  address public constant USDC_PRICE_FEED = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
  address public constant AAVE_PRICE_FEED = 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9;
  address public constant EXECUTOR = 0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A;
  address public constant PROXY_ADMIN = 0xD3cF979e676265e4f6379749DECe4708B9A22476;
  address public constant ACL_MANAGER = 0xc2aaCf6553D20d1e9d78E365AAba8032af9c85b0;
  TransparentUpgradeableProxy public constant COLLECTOR_PROXY = TransparentUpgradeableProxy(payable(0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c));
  bytes32 public constant FUNDS_ADMIN_ROLE = 'FUNDS_ADMIN';

  ICollector collector = ICollector(address(COLLECTOR_PROXY));


  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'),21244865);
    steward = new FinanceSteward(GovernanceV3Ethereum.EXECUTOR_LVL_1, guardian, address(collector));

    Collector new_collector_impl = new Collector(ACL_MANAGER);

    vm.label(0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c, "Collector");
    vm.label(alice, "alice");
    vm.label(guardian, "guardian");
    vm.label(EXECUTOR, "EXECUTOR");
    vm.label(address(steward), "FinanceSteward");

    vm.startPrank(EXECUTOR);

    uint256 streamID = collector.getNextStreamId();

    ProxyAdmin(PROXY_ADMIN).upgrade(COLLECTOR_PROXY, address(new_collector_impl));

    IAccessControl(ACL_MANAGER).grantRole(FUNDS_ADMIN_ROLE, address(steward));
    IAccessControl(ACL_MANAGER).grantRole(FUNDS_ADMIN_ROLE, EXECUTOR);

    collector.initialize(streamID);

    vm.stopPrank();

     vm.prank(0x4B16c5dE96EB2117bBE5fd171E4d203624B014aa); //RANDOM USDC HOLDER
    IERC20(AaveV3EthereumAssets.USDC_UNDERLYING).transfer(
      address(AaveV3Ethereum.COLLECTOR),
      1_000_000e6
    );

    vm.prank(EXECUTOR);
    Ownable(MiscEthereum.AAVE_SWAPPER).transferOwnership(address(steward));
  }
}

contract Function_approve is FinanceSteward_Test {
  function test_revertsIf_notOwnerOrQuardian() public {
    vm.startPrank(alice);

    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    steward.approve(AaveV3EthereumAssets.USDC_UNDERLYING, alice, 1_000e6);
    vm.stopPrank();
  }

  function test_resvertsIf_unrecognizedReceiver() public {
    vm.startPrank(guardian);

    vm.expectRevert(IFinanceSteward.UnrecognizedReceiver.selector);
    steward.approve(AaveV3EthereumAssets.USDC_UNDERLYING, alice, 1_000e6);
    vm.stopPrank();
  }

  function test_resvertsIf_exceedsBalance() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    steward.setWhitelistedReceiver(alice);

    vm.startPrank(guardian);

    uint256 currentBalance = IERC20(AaveV3EthereumAssets.USDC_UNDERLYING).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    vm.expectRevert(IFinanceSteward.ExceedsBalance.selector);
    steward.approve(AaveV3EthereumAssets.USDC_UNDERLYING, alice, currentBalance + 1_000e6);
    vm.stopPrank();
  }

  function test_resvertsIf_minimumBalanceShield() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    steward.setWhitelistedReceiver(alice);
    steward.setMinimumBalanceShield(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);

    vm.startPrank(guardian);

    uint256 currentBalance = IERC20(AaveV3EthereumAssets.USDC_UNDERLYING).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    vm.expectRevert(abi.encodeWithSelector(IFinanceSteward.MinimumBalanceShield.selector, 1_000e6));
    steward.approve(AaveV3EthereumAssets.USDC_UNDERLYING, alice, currentBalance - 999e6);
    vm.stopPrank();
  }

  function test_resvertsIf_exceedsBudget() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    steward.setWhitelistedReceiver(alice);

    vm.expectEmit(true, true, true, true, address(steward));
    emit BudgetUpdate(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);
    steward.increaseBudget(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);

    vm.startPrank(guardian);

    vm.expectRevert(abi.encodeWithSelector(IFinanceSteward.ExceedsBudget.selector, 1_000e6));
    steward.approve(AaveV3EthereumAssets.USDC_UNDERLYING, alice, 1_001e6);
    vm.stopPrank();
  }

  function test_success() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    steward.setWhitelistedReceiver(alice);

    vm.expectEmit(true, true, true, true, address(steward));
    emit BudgetUpdate(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);
    steward.increaseBudget(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);

    assertEq(IERC20(AaveV3EthereumAssets.USDC_UNDERLYING).allowance(address(AaveV3Ethereum.COLLECTOR), alice), 0);

    vm.startPrank(guardian);
    steward.approve(AaveV3EthereumAssets.USDC_UNDERLYING, alice, 1_000e6);
    vm.stopPrank();

    assertEq(IERC20(AaveV3EthereumAssets.USDC_UNDERLYING).allowance(address(AaveV3Ethereum.COLLECTOR), alice), 1_000e6);
  }
}

contract Function_transfer is FinanceSteward_Test {
  function test_revertsIf_notOwnerOrQuardian() public {
    vm.startPrank(alice);

    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    steward.transfer(AaveV3EthereumAssets.USDC_UNDERLYING, alice, 1_000e6);
    vm.stopPrank();
  }

  function test_resvertsIf_unrecognizedReceiver() public {
    vm.startPrank(guardian);

    vm.expectRevert(IFinanceSteward.UnrecognizedReceiver.selector);
    steward.transfer(AaveV3EthereumAssets.USDC_UNDERLYING, alice, 1_000e6);
    vm.stopPrank();
  }

  function test_resvertsIf_exceedsBalance() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    steward.setWhitelistedReceiver(alice);

    vm.startPrank(guardian);

    uint256 currentBalance = IERC20(AaveV3EthereumAssets.USDC_UNDERLYING).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    vm.expectRevert(IFinanceSteward.ExceedsBalance.selector);
    steward.transfer(AaveV3EthereumAssets.USDC_UNDERLYING, alice, currentBalance + 1_000e6);
    vm.stopPrank();
  }

  function test_resvertsIf_minimumBalanceShield() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    steward.setWhitelistedReceiver(alice);
    steward.setMinimumBalanceShield(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);

    vm.startPrank(guardian);

    uint256 currentBalance = IERC20(AaveV3EthereumAssets.USDC_UNDERLYING).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    vm.expectRevert(abi.encodeWithSelector(IFinanceSteward.MinimumBalanceShield.selector, 1_000e6));
    steward.transfer(AaveV3EthereumAssets.USDC_UNDERLYING, alice, currentBalance - 999e6);
    vm.stopPrank();
  }

  function test_resvertsIf_exceedsBudget() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    steward.setWhitelistedReceiver(alice);
    steward.increaseBudget(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);

    vm.startPrank(guardian);

    vm.expectRevert(abi.encodeWithSelector(IFinanceSteward.ExceedsBudget.selector, 1_000e6));
    steward.transfer(AaveV3EthereumAssets.USDC_UNDERLYING, alice, 1_001e6);
    vm.stopPrank();
  }

  function test_success() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    steward.setWhitelistedReceiver(alice);
    steward.increaseBudget(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);

    uint256 balance = IERC20(AaveV3EthereumAssets.USDC_UNDERLYING).balanceOf(address(AaveV3Ethereum.COLLECTOR));

    vm.startPrank(guardian);

    steward.transfer(AaveV3EthereumAssets.USDC_UNDERLYING, alice, 1_000e6);

    assertEq(IERC20(AaveV3EthereumAssets.USDC_UNDERLYING).balanceOf(address(AaveV3Ethereum.COLLECTOR)), balance - 1_000e6);
    vm.stopPrank();
  }
}

contract Function_createStream is FinanceSteward_Test {
  uint256 public constant DURATION = 1 days;

  function test_revertsIf_notOwnerOrQuardian() public {
    IFinanceSteward.StreamData memory data = IFinanceSteward.StreamData(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6,
      block.timestamp,
      block.timestamp + DURATION
    );

    vm.startPrank(alice);

    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    steward.createStream(alice, data);
    vm.stopPrank();
  }

  function test_resvertsIf_invalidDate() public {
    IFinanceSteward.StreamData memory data = IFinanceSteward.StreamData(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6,
      block.timestamp - 1,
      block.timestamp + DURATION
    );

    vm.startPrank(guardian);

    vm.expectRevert(IFinanceSteward.InvalidDate.selector);
    steward.createStream(alice, data);

    data = IFinanceSteward.StreamData(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6,
      block.timestamp,
      block.timestamp - 1
    );

    vm.expectRevert(IFinanceSteward.InvalidDate.selector);
    steward.createStream(alice, data);

    vm.stopPrank();
  }

  function test_resvertsIf_unrecognizedReceiver() public {
    IFinanceSteward.StreamData memory data = IFinanceSteward.StreamData(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6,
      block.timestamp,
      block.timestamp + DURATION
    );

    vm.startPrank(guardian);

    vm.expectRevert(IFinanceSteward.UnrecognizedReceiver.selector);
    steward.createStream(alice, data);
    vm.stopPrank();
  }

  function test_resvertsIf_exceedsBalance() public {
    uint256 currentBalance = IERC20(AaveV3EthereumAssets.USDC_UNDERLYING).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    IFinanceSteward.StreamData memory data = IFinanceSteward.StreamData(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      currentBalance + 1_000e6,
      block.timestamp,
      block.timestamp + DURATION
    );

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    steward.setWhitelistedReceiver(alice);

    vm.startPrank(guardian);

    vm.expectRevert(IFinanceSteward.ExceedsBalance.selector);
    steward.createStream(alice, data);
    vm.stopPrank();
  }

  function test_resvertsIf_minimumBalanceShield() public {
    uint256 currentBalance = IERC20(AaveV3EthereumAssets.USDC_UNDERLYING).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    IFinanceSteward.StreamData memory data = IFinanceSteward.StreamData(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      currentBalance - 999e6,
      block.timestamp,
      block.timestamp + DURATION
    );

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    steward.setWhitelistedReceiver(alice);
    steward.setMinimumBalanceShield(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);

    vm.startPrank(guardian);

    vm.expectRevert(abi.encodeWithSelector(IFinanceSteward.MinimumBalanceShield.selector, 1_000e6));
    steward.createStream(alice, data);
    vm.stopPrank();
  }

  function test_resvertsIf_exceedsBudget() public {
    IFinanceSteward.StreamData memory data = IFinanceSteward.StreamData(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_001e6,
      block.timestamp,
      block.timestamp + DURATION
    );

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    steward.setWhitelistedReceiver(alice);
    steward.increaseBudget(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);

    vm.startPrank(guardian);

    vm.expectRevert(abi.encodeWithSelector(IFinanceSteward.ExceedsBudget.selector, 1_000e6));
    steward.createStream(alice, data);
    vm.stopPrank();
  }

  function test_success() public {
    IFinanceSteward.StreamData memory data = IFinanceSteward.StreamData(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6,
      block.timestamp,
      block.timestamp + DURATION
    );

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    steward.setWhitelistedReceiver(alice);
    steward.increaseBudget(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);

    uint256 streamId = AaveV3Ethereum.COLLECTOR.getNextStreamId();

    vm.startPrank(guardian);
    steward.createStream(alice, data);
    vm.stopPrank();

    vm.warp(block.timestamp + 5 days);

    vm.startPrank(alice);
    AaveV3Ethereum.COLLECTOR.withdrawFromStream(streamId, 1);
    vm.stopPrank();
  }
}

contract Function_cancelStream is FinanceSteward_Test {
uint256 constant STREAM_ID = uint256(100050);
  function test_revertsIf_notOwnerOrQuardian() public {

    vm.startPrank(alice);

    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    steward.cancelStream(STREAM_ID);
    vm.stopPrank();
  }

  function test_success() public {
  (      address sender,,,,,,,  ) = collector.getStream(STREAM_ID);
    assertNotEq(sender, address(0));
    vm.startPrank(guardian);
    steward.cancelStream(STREAM_ID);
    vm.stopPrank();
  }
}

contract Function_increaseBudget is FinanceSteward_Test {
  function test_revertsIf_notOwner() public {
    vm.startPrank(alice);

    vm.expectRevert('Ownable: caller is not the owner');
    steward.increaseBudget(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);
    vm.stopPrank();
  }

  function test_success() public {
    assertEq(steward.tokenBudget(AaveV3EthereumAssets.USDC_UNDERLYING), 0);
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    vm.expectEmit(true, true, true, true, address(steward));
    emit BudgetUpdate(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);
    steward.increaseBudget(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);
    vm.stopPrank();

    assertEq(steward.tokenBudget(AaveV3EthereumAssets.USDC_UNDERLYING), 1_000e6);
  }
}

contract Function_decreaseBudget is FinanceSteward_Test {
  function test_revertsIf_notOwner() public {
    vm.startPrank(alice);

    vm.expectRevert('Ownable: caller is not the owner');
    steward.decreaseBudget(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);
    vm.stopPrank();
  }

  function test_decreaseBudgetLessThanTotal() public {
    assertEq(steward.tokenBudget(AaveV3EthereumAssets.USDC_UNDERLYING), 0);

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    vm.expectEmit(true, true, true, true, address(steward));
    emit BudgetUpdate(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);

    steward.increaseBudget(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);

    assertEq(steward.tokenBudget(AaveV3EthereumAssets.USDC_UNDERLYING), 1_000e6);

    vm.expectEmit(true, true, true, true, address(steward));
    emit BudgetUpdate(AaveV3EthereumAssets.USDC_UNDERLYING, 750e6);
    steward.decreaseBudget(AaveV3EthereumAssets.USDC_UNDERLYING, 250e6);

    assertEq(steward.tokenBudget(AaveV3EthereumAssets.USDC_UNDERLYING), 750e6);
    vm.stopPrank();
  }

  function test_success() public {
    assertEq(steward.tokenBudget(AaveV3EthereumAssets.USDC_UNDERLYING), 0);

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    steward.decreaseBudget(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);
    assertEq(steward.tokenBudget(AaveV3EthereumAssets.USDC_UNDERLYING), 0);
    vm.stopPrank();
  }
}

contract Function_setWhitelistedReceiver is FinanceSteward_Test {
  function test_revertsIf_notOwner() public {
    vm.startPrank(alice);

    vm.expectRevert('Ownable: caller is not the owner');
    steward.setWhitelistedReceiver(alice);
    vm.stopPrank();
  }

  function test_success() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    vm.expectEmit(true, true, true, true, address(steward));
    emit ReceiverWhitelisted(alice);
    steward.setWhitelistedReceiver(alice);
    vm.stopPrank();
  }
}

contract Function_setMinimumBalanceShield is FinanceSteward_Test {
  function test_revertsIf_notOwner() public {
    vm.startPrank(alice);

    vm.expectRevert('Ownable: caller is not the owner');
    steward.setMinimumBalanceShield(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);
    vm.stopPrank();
  }

  function test_success() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    vm.expectEmit(true, true, true, true, address(steward));
    emit MinimumTokenBalanceUpdated(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);
    steward.setMinimumBalanceShield(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);
    vm.stopPrank();
  }
}
