// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {ICollector} from 'collector-upgrade-rev6/lib/aave-v3-origin/src/contracts/treasury/ICollector.sol';
import {Collector} from 'collector-upgrade-rev6/lib/aave-v3-origin/src/contracts/treasury/Collector.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {ITransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol'; 
import {MainnetSwapSteward, ISwapSteward} from 'src/financestewards/MainnetSwapSteward.sol';
import {AggregatorInterface} from 'src/financestewards/AggregatorInterface.sol';
import {CollectorUtils} from 'src/CollectorUtils.sol';
import {IAccessControl} from 'openzeppelin-contracts/contracts/access/AccessControl.sol';

/**
 * @dev Test for SwapSteward contract
 * command: make test-swap-steward
 */
contract MainnetSwapStewardTest is Test {
  event MilkmanAddressUpdated(address oldAddress, address newAddress);
  event PriceCheckerUpdated(address oldAddress, address newAddress);
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

  ITransparentUpgradeableProxy public constant COLLECTOR_PROXY =
    ITransparentUpgradeableProxy(payable(address(AaveV3Ethereum.COLLECTOR)));
  ICollector collector = ICollector(address(COLLECTOR_PROXY));
  MainnetSwapSteward public steward;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 21353255);

    Collector new_collector_impl = new Collector(ACL_MANAGER);
    address[] memory v2Pools = new address[](1);
    v2Pools[0] = address(AaveV2Ethereum.POOL);
    address[] memory v3Pools = new address[](3);
    v3Pools[0] = address(AaveV3Ethereum.POOL);
    v3Pools[1] = 0x0AA97c284e98396202b6A04024F5E2c65026F3c0;
    v3Pools[2] = 0x4e033931ad43597d96D6bcc25c280717730B58B1;

    steward = new MainnetSwapSteward(
      GovernanceV3Ethereum.EXECUTOR_LVL_1,
      guardian,
      address(collector)
    );

    vm.label(alice, 'alice');
    vm.label(guardian, 'guardian');
    vm.label(EXECUTOR, 'EXECUTOR');
    vm.label(address(AaveV3Ethereum.COLLECTOR), 'Collector');
    vm.label(address(steward), 'MainnetSwapSteward');

    vm.startPrank(EXECUTOR);

    uint256 streamID = collector.getNextStreamId();

    ProxyAdmin(PROXY_ADMIN).upgradeAndCall(COLLECTOR_PROXY, address(new_collector_impl), '');
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

contract Function_tokenSwap is MainnetSwapStewardTest {
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

contract Function_setSwappableToken is MainnetSwapStewardTest {
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


contract SetPriceChecker is MainnetSwapStewardTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('Ownable: caller is not the owner');
    steward.setPriceChecker(makeAddr('price-checker'));
  }

  function test_revertsIf_invalidZeroAddress() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    vm.expectRevert(ISwapSteward.InvalidZeroAddress.selector);
    steward.setPriceChecker(address(0));
  }

  function test_successful() public {
    address newChecker = makeAddr('new-checker');
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    vm.expectEmit(true, true, true, true, address(steward));
    emit PriceCheckerUpdated(steward.PRICE_CHECKER(), newChecker);
    steward.setPriceChecker(newChecker);

    assertEq(address(steward.PRICE_CHECKER()), newChecker);
  }
}

contract SetMilkman is MainnetSwapStewardTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('Ownable: caller is not the owner');
    steward.setMilkman(makeAddr('new-milkman'));
  }

  function test_revertsIf_invalidZeroAddress() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    vm.expectRevert(ISwapSteward.InvalidZeroAddress.selector);
    steward.setMilkman(address(0));
  }

  function test_successful() public {
    address newMilkman = makeAddr('new-milkman');
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    vm.expectEmit(true, true, true, true, address(steward));
    emit MilkmanAddressUpdated(steward.MILKMAN(), newMilkman);
    steward.setMilkman(newMilkman);

    assertEq(address(steward.MILKMAN()), newMilkman);
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
