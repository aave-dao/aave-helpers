// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {ICollector} from 'collector-upgrade-rev6/lib/aave-v3-origin/src/contracts/treasury/ICollector.sol';
import {Collector} from 'collector-upgrade-rev6/lib/aave-v3-origin/src/contracts/treasury/Collector.sol';
import {IAccessControl} from 'aave-v3-origin/core/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol';

import {SwapSteward, ISwapSteward} from 'src/financestewards/SwapSteward.sol';
import {PoolV3FinSteward, IPoolV3FinSteward} from 'src/financestewards/PoolV3FinSteward.sol';
import {AggregatorInterface} from 'src/financestewards/AggregatorInterface.sol';
import {CollectorUtils} from 'src/CollectorUtils.sol';

/**
 * @dev Test for SwapSteward contract
 * command: make test-swap-steward
 */
contract SwapStewardTest is Test {
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
  event SwapApprovedToken(address indexed token, address indexed oracleUSD);

  address public alice = address(43);
  address public constant guardian = address(82);
  address public constant USDC_PRICE_FEED = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
  address public constant AAVE_PRICE_FEED = 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9;
  address public constant EXECUTOR = 0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A;
  address public constant PROXY_ADMIN = 0xD3cF979e676265e4f6379749DECe4708B9A22476;
  address public constant ACL_MANAGER = 0xc2aaCf6553D20d1e9d78E365AAba8032af9c85b0;

  bytes32 public constant FUNDS_ADMIN_ROLE = 'FUNDS_ADMIN';

  TransparentUpgradeableProxy public constant COLLECTOR_PROXY = TransparentUpgradeableProxy(payable(address(AaveV3Ethereum.COLLECTOR)));
  ICollector collector = ICollector(address(COLLECTOR_PROXY));
  PoolV3FinSteward public poolv3Steward;
  SwapSteward public steward;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 21353255);

    Collector new_collector_impl = new Collector(ACL_MANAGER);
    poolv3Steward = new PoolV3FinSteward(GovernanceV3Ethereum.EXECUTOR_LVL_1, guardian);
    steward = new SwapSteward(GovernanceV3Ethereum.EXECUTOR_LVL_1, guardian, address(poolv3Steward));

    vm.label(alice, "alice");
    vm.label(guardian, "guardian");
    vm.label(EXECUTOR, "EXECUTOR");
    vm.label(address(AaveV3Ethereum.COLLECTOR), "Collector");
    vm.label(address(steward), "SwapSteward");

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

contract Function_withdrawV2andSwap is SwapStewardTest {
  function test_revertsIf_notOwnerOrQuardian() public {
    vm.startPrank(alice);

    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    steward.withdrawV2andSwap(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      100
    );
    vm.stopPrank();
  }

  function test_resvertsIf_zeroAmount() public {
    vm.startPrank(guardian);

    vm.expectRevert(ISwapSteward.InvalidZeroAmount.selector);
    steward.withdrawV2andSwap(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      0,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      100
    );
    vm.stopPrank();
  }

  function test_resvertsIf_minimumBalanceShield() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    poolv3Steward.setMinimumBalanceShield(AaveV2EthereumAssets.USDC_A_TOKEN, 1_000e6);

    vm.startPrank(guardian);

    uint256 currentBalance = IERC20(AaveV2EthereumAssets.USDC_A_TOKEN).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    vm.expectRevert(abi.encodeWithSelector(IPoolV3FinSteward.MinimumBalanceShield.selector, 1_000e6));
    steward.withdrawV2andSwap(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      currentBalance - 999e6,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      100
    );
    vm.stopPrank();
  }

  function test_resvertsIf_unrecognizedToken() public {
    vm.startPrank(guardian);

    vm.expectRevert(ISwapSteward.UnrecognizedToken.selector);
    steward.withdrawV2andSwap(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      100
    );
    vm.stopPrank();
  }

  function test_success() public {
    uint256 balanceV2Before = IERC20(AaveV2EthereumAssets.USDC_A_TOKEN).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );
    uint256 slippage = 100;

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    steward.setSwappableToken(AaveV3EthereumAssets.USDC_UNDERLYING, USDC_PRICE_FEED);
    steward.setSwappableToken(AaveV3EthereumAssets.AAVE_UNDERLYING, AAVE_PRICE_FEED);

    vm.startPrank(guardian);
    vm.expectEmit(true, true, true, true, address(steward.SWAPPER()));
    emit SwapRequested(
      steward.MILKMAN(),
      AaveV3EthereumAssets.USDC_UNDERLYING,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      USDC_PRICE_FEED,
      AAVE_PRICE_FEED,
      1_000e6,
      address(AaveV3Ethereum.COLLECTOR),
      slippage
    );

    steward.withdrawV2andSwap(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      slippage
    );

    assertLt(
      IERC20(AaveV2EthereumAssets.USDC_A_TOKEN).balanceOf(address(AaveV3Ethereum.COLLECTOR)),
      balanceV2Before
    );

    vm.stopPrank();
  }
}

contract Function_withdrawV3andSwap is SwapStewardTest {
  function test_revertsIf_notOwnerOrQuardian() public {
    vm.startPrank(alice);

    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    steward.withdrawV3andSwap(
      address(AaveV3Ethereum.POOL),
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      100
    );
    vm.stopPrank();
  }

  function test_resvertsIf_zeroAmount() public {
    vm.startPrank(guardian);

    vm.expectRevert(ISwapSteward.InvalidZeroAmount.selector);
    steward.withdrawV3andSwap(
      address(AaveV3Ethereum.POOL),
      AaveV3EthereumAssets.USDC_UNDERLYING,
      0,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      100
    );
    vm.stopPrank();
  }

  function test_resvertsIf_minimumBalanceShield() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    poolv3Steward.setMinimumBalanceShield(AaveV3EthereumAssets.USDC_A_TOKEN, 1_000e6);

    vm.startPrank(guardian);

    uint256 currentBalance = IERC20(AaveV3EthereumAssets.USDC_A_TOKEN).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    vm.expectRevert(abi.encodeWithSelector(IPoolV3FinSteward.MinimumBalanceShield.selector, 1_000e6));
    steward.withdrawV3andSwap(
      address(AaveV3Ethereum.POOL),
      AaveV3EthereumAssets.USDC_UNDERLYING,
      currentBalance - 999e6,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      100
    );
    vm.stopPrank();
  }

  function test_resvertsIf_unrecognizedToken() public {
    vm.startPrank(guardian);

    vm.expectRevert(ISwapSteward.UnrecognizedToken.selector);
    steward.withdrawV3andSwap(
      address(AaveV3Ethereum.POOL),
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      100
    );
    vm.stopPrank();
  }

  function test_success() public {
    uint256 balanceV3Before = IERC20(AaveV3EthereumAssets.USDC_A_TOKEN).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );
    uint256 slippage = 100;

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    steward.setSwappableToken(AaveV3EthereumAssets.USDC_UNDERLYING, USDC_PRICE_FEED);
    steward.setSwappableToken(AaveV3EthereumAssets.AAVE_UNDERLYING, AAVE_PRICE_FEED);

    vm.startPrank(guardian);
    vm.expectEmit(true, true, true, true, address(steward.SWAPPER()));
    emit SwapRequested(
      steward.MILKMAN(),
      AaveV3EthereumAssets.USDC_UNDERLYING,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      USDC_PRICE_FEED,
      AAVE_PRICE_FEED,
      1_000e6,
      address(AaveV3Ethereum.COLLECTOR),
      slippage
    );

    steward.withdrawV3andSwap(
      address(AaveV3Ethereum.POOL),
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      slippage
    );

    assertLt(
      IERC20(AaveV3EthereumAssets.USDC_A_TOKEN).balanceOf(address(AaveV3Ethereum.COLLECTOR)),
      balanceV3Before
    );
    vm.stopPrank();
  }
}

contract Function_tokenSwap is SwapStewardTest {
  function test_revertsIf_notOwnerOrQuardian() public {
    vm.startPrank(alice);

    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    steward.tokenSwap(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      100
    );
    vm.stopPrank();
  }

  function test_resvertsIf_zeroAmount() public {
    vm.startPrank(guardian);

    vm.expectRevert(ISwapSteward.InvalidZeroAmount.selector);
    steward.tokenSwap(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      0,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      100
    );
    vm.stopPrank();
  }

  function test_resvertsIf_minimumBalanceShield() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    poolv3Steward.setMinimumBalanceShield(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);

    vm.startPrank(guardian);

    uint256 currentBalance = IERC20(AaveV3EthereumAssets.USDC_UNDERLYING).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    vm.expectRevert(abi.encodeWithSelector(IPoolV3FinSteward.MinimumBalanceShield.selector, 1_000e6));
    steward.tokenSwap(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      currentBalance - 999e6,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      100
    );
    vm.stopPrank();
  }

  function test_resvertsIf_unrecognizedToken() public {
    vm.startPrank(guardian);

    vm.expectRevert(ISwapSteward.UnrecognizedToken.selector);
    steward.tokenSwap(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      100
    );
    vm.stopPrank();
  }

  function test_resvertsIf_invalidPriceFeedAnswer() public {
    address mockOracle = address(new MockOracle());

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    steward.setSwappableToken(AaveV3EthereumAssets.USDC_UNDERLYING, mockOracle);
    steward.setSwappableToken(
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      AaveV3EthereumAssets.AAVE_ORACLE
    );

    vm.startPrank(guardian);
    vm.expectRevert(ISwapSteward.PriceFeedFailure.selector);
    steward.tokenSwap(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      100
    );
    vm.stopPrank();
  }

  function test_success() public {
    uint256 slippage = 100;

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    steward.setSwappableToken(AaveV3EthereumAssets.USDC_UNDERLYING, USDC_PRICE_FEED);
    steward.setSwappableToken(AaveV3EthereumAssets.AAVE_UNDERLYING, AAVE_PRICE_FEED);

    vm.startPrank(guardian);
    vm.expectEmit(true, true, true, true, address(steward.SWAPPER()));
    emit SwapRequested(
      steward.MILKMAN(),
      AaveV3EthereumAssets.USDC_UNDERLYING,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      USDC_PRICE_FEED,
      AAVE_PRICE_FEED,
      1_000e6,
      address(AaveV3Ethereum.COLLECTOR),
      slippage
    );

    steward.tokenSwap(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      slippage
    );
    vm.stopPrank();
  }
}

contract Function_setSwappableToken is SwapStewardTest {
  function test_revertsIf_notOwner() public {
    vm.startPrank(alice);
    vm.expectRevert('Ownable: caller is not the owner');
    steward.setSwappableToken(AaveV3EthereumAssets.USDC_UNDERLYING, USDC_PRICE_FEED);
    vm.stopPrank();
  }

  function test_resvertsIf_missingPriceFeed() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    vm.expectRevert(ISwapSteward.MissingPriceFeed.selector);
    steward.setSwappableToken(AaveV3EthereumAssets.USDC_UNDERLYING, address(0));
    vm.stopPrank();
  }

  function test_resvertsIf_incompatibleOracleMissingImplementations() public {
    address mockOracle = address(new InvalidMockOracle());

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    vm.expectRevert();
    steward.setSwappableToken(AaveV3EthereumAssets.USDC_UNDERLYING, mockOracle);

    vm.stopPrank();
  }

  function test_success() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    vm.expectEmit(true, true, true, true, address(steward));
    emit SwapApprovedToken(AaveV3EthereumAssets.USDC_UNDERLYING, USDC_PRICE_FEED);
    steward.setSwappableToken(AaveV3EthereumAssets.USDC_UNDERLYING, USDC_PRICE_FEED);
    vm.stopPrank();
  }
}

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
