// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {IRescuable} from 'solidity-utils/contracts/utils/Rescuable.sol';

import {AaveSwapper} from 'src/swaps/AaveSwapper.sol';
import {IAaveSwapper} from 'src/swaps/interfaces/IAaveSwapper.sol';
import {IAggregatorV3Interface} from '../../src/swaps/interfaces/IAggregatorV3Interface.sol';

interface IComposableCoW {
  function singleOrders(address user, bytes32 hash) external returns (bool);
}

contract MockOracle {
  fallback() external {} // Nothing Happens
}

contract AaveSwapperTest is Test {
  event DepositedIntoV2(address indexed token, uint256 amount);
  event DepositedIntoV3(address indexed token, uint256 amount);
  event GuardianUpdated(address oldGuardian, address newGuardian);
  event LimitSwapRequested(
    address milkman,
    address indexed fromToken,
    address indexed toToken,
    uint256 amount,
    address indexed recipient,
    uint256 minAmountOut
  );
  event SwapCanceled(address indexed fromToken, address indexed toToken, uint256 amount);
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
  event TWAPSwapCanceled(address indexed fromToken, address indexed toToken, uint256 amount);
  event TWAPSwapRequested(
    address handler,
    address indexed fromToken,
    address indexed toToken,
    address recipient,
    uint256 totalAmount
  );

  address public constant BAL80WETH20 = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
  address public constant BPT_PRICE_CHECKER = 0xBeA6AAC5bDCe0206A9f909d80a467C93A7D6Da7c;
  address public constant CHAINLINK_PRICE_CHECKER = 0xe80a1C615F75AFF7Ed8F08c9F21f9d00982D666c;
  address public constant LIMIT_ORDER_PRICE_CHECKER = 0xcfb9Bc9d2FA5D3Dd831304A0AE53C76ed5c64802;
  address public constant MILKMAN = 0x060373D064d0168931dE2AB8DDA7410923d06E88;
  address public constant BAD_ORACLE = 0x05225Cd708bCa9253789C1374e4337a019e99D56;

  address public constant COMPOSABLE_COW = 0xfdaFc9d1902f4e0b84f65F49f244b32b31013b74;
  address public constant TWAP_HANDLER = 0x6cF1e9cA41f7611dEf408122793c358a3d11E5a5;
  address public constant COW_RELAYER = 0xC92E8bdf79f0507f65a392b0ab4667716BFE0110;

  AaveSwapper public swaps;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 21185924);

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    swaps = new AaveSwapper(COMPOSABLE_COW);
    vm.stopPrank();
  }
}

contract Initialize is AaveSwapperTest {
  function test_revertsIf_alreadyInitialized() public {
    vm.expectRevert('Initializable: contract is already initialized');
    swaps.initialize();
  }
}

contract TransferOwnership is AaveSwapperTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('Ownable: caller is not the owner');
    swaps.transferOwnership(makeAddr('new-admin'));
  }

  function test_successful() public {
    address newAdmin = makeAddr('new-admin');
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    swaps.transferOwnership(newAdmin);
    vm.stopPrank();

    assertEq(newAdmin, swaps.owner());
  }
}

contract UpdateGuardian is AaveSwapperTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    swaps.updateGuardian(makeAddr('new-admin'));
  }

  function test_successful() public {
    address newManager = makeAddr('new-admin');
    vm.expectEmit();
    emit GuardianUpdated(swaps.guardian(), newManager);
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    swaps.updateGuardian(newManager);
    vm.stopPrank();

    assertEq(newManager, swaps.guardian());
  }
}

contract RemoveGuardian is AaveSwapperTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    swaps.updateGuardian(address(0));
  }

  function test_successful() public {
    vm.expectEmit();
    emit GuardianUpdated(swaps.guardian(), address(0));
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    swaps.updateGuardian(address(0));
    vm.stopPrank();

    assertEq(address(0), swaps.guardian());
  }
}

contract AaveSwapperSwap is AaveSwapperTest {
  function test_revertsIf_invalidCaller() public {
    uint256 amount = 1_000e18;
    vm.expectRevert('Ownable: caller is not the owner');
    swaps.swap(
      MILKMAN,
      CHAINLINK_PRICE_CHECKER,
      AaveV2EthereumAssets.WETH_UNDERLYING,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      address(0),
      AaveV2EthereumAssets.AAVE_ORACLE,
      address(AaveV2Ethereum.COLLECTOR),
      amount,
      200
    );
  }

  function test_revertsIf_amountIsZero() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    vm.expectRevert(IAaveSwapper.InvalidAmount.selector);
    swaps.swap(
      MILKMAN,
      CHAINLINK_PRICE_CHECKER,
      AaveV3EthereumAssets.WETH_UNDERLYING,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      AaveV3EthereumAssets.WETH_ORACLE,
      AaveV3EthereumAssets.AAVE_ORACLE,
      address(AaveV2Ethereum.COLLECTOR),
      0,
      200
    );
    vm.stopPrank();
  }

  function test_revertsIf_fromTokenIsZeroAddress() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    vm.expectRevert(IAaveSwapper.Invalid0xAddress.selector);
    swaps.swap(
      MILKMAN,
      CHAINLINK_PRICE_CHECKER,
      address(0),
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      AaveV3EthereumAssets.WETH_ORACLE,
      AaveV3EthereumAssets.AAVE_ORACLE,
      address(AaveV2Ethereum.COLLECTOR),
      1_000e18,
      200
    );
    vm.stopPrank();
  }

  function test_revertsIf_toTokenIsZeroAddress() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    vm.expectRevert(IAaveSwapper.Invalid0xAddress.selector);
    swaps.swap(
      MILKMAN,
      CHAINLINK_PRICE_CHECKER,
      AaveV3EthereumAssets.WETH_UNDERLYING,
      address(0),
      AaveV3EthereumAssets.WETH_ORACLE,
      AaveV3EthereumAssets.AAVE_ORACLE,
      address(AaveV2Ethereum.COLLECTOR),
      1_000e18,
      200
    );
    vm.stopPrank();
  }

  function test_revertsIf_invalidRecipient() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    vm.expectRevert(IAaveSwapper.InvalidRecipient.selector);
    swaps.swap(
      MILKMAN,
      CHAINLINK_PRICE_CHECKER,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      AaveV2EthereumAssets.AAVE_ORACLE,
      AaveV2EthereumAssets.USDC_ORACLE,
      address(0),
      1_000e18,
      200
    );
    vm.stopPrank();
  }

  function test_revertsIf_fromOracleNotSet() public {
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectRevert(AaveSwapper.OracleNotSet.selector);
    swaps.swap(
      MILKMAN,
      CHAINLINK_PRICE_CHECKER,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      address(0),
      AaveV2EthereumAssets.USDC_ORACLE,
      address(AaveV3Ethereum.COLLECTOR),
      1_000e18,
      200
    );
    vm.stopPrank();
  }

  function test_revertsIf_toOracleNotSet() public {
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectRevert(AaveSwapper.OracleNotSet.selector);
    swaps.swap(
      MILKMAN,
      CHAINLINK_PRICE_CHECKER,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      AaveV2EthereumAssets.AAVE_ORACLE,
      address(0),
      address(AaveV3Ethereum.COLLECTOR),
      1_000e18,
      200
    );
    vm.stopPrank();
  }

  function test_revertsIf_fromOracleIsInvalidNoDecimalsFunction() public {
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectRevert();
    swaps.swap(
      MILKMAN,
      CHAINLINK_PRICE_CHECKER,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      BAD_ORACLE,
      AaveV2EthereumAssets.USDC_ORACLE,
      address(AaveV3Ethereum.COLLECTOR),
      1_000e18,
      200
    );
    vm.stopPrank();
  }

  function test_revertsIf_toOracleIsInvalidNoDecimalsFunction() public {
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectRevert();
    swaps.swap(
      MILKMAN,
      CHAINLINK_PRICE_CHECKER,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      AaveV2EthereumAssets.AAVE_ORACLE,
      BAD_ORACLE,
      address(AaveV3Ethereum.COLLECTOR),
      1_000e18,
      200
    );
    vm.stopPrank();
  }

  function test_revertsIf_fromOracleIsInvalid() public {
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectRevert(AaveSwapper.InvalidOracle.selector);
    vm.mockCall(
      BAD_ORACLE,
      abi.encodeWithSelector(IAggregatorV3Interface.decimals.selector),
      abi.encode(uint8(0))
    );
    swaps.swap(
      MILKMAN,
      CHAINLINK_PRICE_CHECKER,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      BAD_ORACLE,
      AaveV2EthereumAssets.USDC_ORACLE,
      address(AaveV3Ethereum.COLLECTOR),
      1_000e18,
      200
    );
    vm.stopPrank();
  }

  function test_revertsIf_fromOracleIsInvalidWithFallbackFunction() public {
    address badOracle = address(new MockOracle());

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectRevert();
    swaps.swap(
      MILKMAN,
      CHAINLINK_PRICE_CHECKER,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      badOracle,
      AaveV2EthereumAssets.USDC_ORACLE,
      address(AaveV3Ethereum.COLLECTOR),
      1_000e18,
      200
    );
    vm.stopPrank();
  }

  function test_successful() public {
    deal(AaveV2EthereumAssets.AAVE_UNDERLYING, address(swaps), 1_000e18);
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    vm.expectEmit(true, true, true, true);
    emit SwapRequested(
      MILKMAN,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      AaveV2EthereumAssets.AAVE_ORACLE,
      AaveV2EthereumAssets.USDC_ORACLE,
      1_000e18,
      address(AaveV2Ethereum.COLLECTOR),
      200
    );
    swaps.swap(
      MILKMAN,
      CHAINLINK_PRICE_CHECKER,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      AaveV2EthereumAssets.AAVE_ORACLE,
      AaveV2EthereumAssets.USDC_ORACLE,
      address(AaveV2Ethereum.COLLECTOR),
      1_000e18,
      200
    );
    vm.stopPrank();
  }
}

contract CancelSwap is AaveSwapperTest {
  function test_revertsIf_invalidCaller() public {
    uint256 amount = 1_000e18;
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    swaps.cancelSwap(
      makeAddr('milkman-instance'),
      CHAINLINK_PRICE_CHECKER,
      AaveV2EthereumAssets.WETH_UNDERLYING,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      address(0),
      AaveV2EthereumAssets.AAVE_ORACLE,
      address(AaveV2Ethereum.COLLECTOR),
      amount,
      200
    );
  }

  function test_revertsIf_noMatchingTrade() public {
    deal(AaveV2EthereumAssets.AAVE_UNDERLYING, address(swaps), 1_000e18);
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    swaps.swap(
      MILKMAN,
      CHAINLINK_PRICE_CHECKER,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      AaveV2EthereumAssets.AAVE_ORACLE,
      AaveV2EthereumAssets.USDC_ORACLE,
      address(AaveV2Ethereum.COLLECTOR),
      1_000e18,
      200
    );

    vm.expectRevert();
    swaps.cancelSwap(
      makeAddr('not-milkman-instance'),
      CHAINLINK_PRICE_CHECKER,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      AaveV2EthereumAssets.AAVE_ORACLE,
      AaveV2EthereumAssets.USDC_ORACLE,
      address(AaveV2Ethereum.COLLECTOR),
      1_000e18,
      200
    );
    vm.stopPrank();
  }

  function test_successful() public {
    deal(AaveV2EthereumAssets.AAVE_UNDERLYING, address(swaps), 1_000e18);
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    vm.expectEmit(true, true, true, true, address(swaps));
    emit SwapRequested(
      MILKMAN,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      AaveV2EthereumAssets.AAVE_ORACLE,
      AaveV2EthereumAssets.USDC_ORACLE,
      1_000e18,
      address(AaveV2Ethereum.COLLECTOR),
      200
    );
    swaps.swap(
      MILKMAN,
      CHAINLINK_PRICE_CHECKER,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      AaveV2EthereumAssets.AAVE_ORACLE,
      AaveV2EthereumAssets.USDC_ORACLE,
      address(AaveV2Ethereum.COLLECTOR),
      1_000e18,
      200
    );

    vm.expectEmit(true, true, true, true, address(swaps));
    emit SwapCanceled(
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      1_000e18
    );
    swaps.cancelSwap(
      0xcd6b416C6bdF7B14C11cedcf9d61f02B28FB6fCB, // Address generated by tests
      CHAINLINK_PRICE_CHECKER,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      AaveV2EthereumAssets.AAVE_ORACLE,
      AaveV2EthereumAssets.USDC_ORACLE,
      address(AaveV2Ethereum.COLLECTOR),
      1_000e18,
      200
    );
    vm.stopPrank();
  }
}

contract EmergencyTokenTransfer is AaveSwapperTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert(IRescuable.OnlyRescueGuardian.selector);
    swaps.emergencyTokenTransfer(
      AaveV2EthereumAssets.BAL_UNDERLYING,
      address(AaveV2Ethereum.COLLECTOR),
      1_000e6
    );
  }

  function test_successful_governanceCaller() public {
    assertEq(IERC20(AaveV2EthereumAssets.AAVE_UNDERLYING).balanceOf(address(swaps)), 0);

    uint256 aaveAmount = 1_000e18;

    deal(AaveV2EthereumAssets.AAVE_UNDERLYING, address(swaps), aaveAmount);

    assertEq(IERC20(AaveV2EthereumAssets.AAVE_UNDERLYING).balanceOf(address(swaps)), aaveAmount);

    uint256 initialCollectorUsdcBalance = IERC20(AaveV2EthereumAssets.AAVE_UNDERLYING).balanceOf(
      address(AaveV2Ethereum.COLLECTOR)
    );

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    swaps.emergencyTokenTransfer(
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      address(AaveV2Ethereum.COLLECTOR),
      aaveAmount
    );
    vm.stopPrank();

    assertEq(
      IERC20(AaveV2EthereumAssets.AAVE_UNDERLYING).balanceOf(address(AaveV2Ethereum.COLLECTOR)),
      initialCollectorUsdcBalance + aaveAmount
    );
    assertEq(IERC20(AaveV2EthereumAssets.AAVE_UNDERLYING).balanceOf(address(swaps)), 0);
  }
}

contract GetExpectedOut is AaveSwapperTest {
  function test_revertsIf_fromOracleIsAddressZero() public {
    uint256 amount = 1e18;
    vm.expectRevert(IAaveSwapper.OracleNotSet.selector);
    swaps.getExpectedOut(
      CHAINLINK_PRICE_CHECKER,
      amount,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      address(0),
      AaveV2EthereumAssets.USDC_ORACLE
    );
  }

  function test_revertsIf_toOracleIsAddressZero() public {
    uint256 amount = 1e18;
    vm.expectRevert(IAaveSwapper.OracleNotSet.selector);
    swaps.getExpectedOut(
      CHAINLINK_PRICE_CHECKER,
      amount,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      AaveV2EthereumAssets.AAVE_ORACLE,
      address(0)
    );
  }

  function test_aaveToUsdc_withEthBasedOracles() public view {
    /* This test is only to show that oracles with the same base
     * will return the correct value for trading, or at least very
     * close to USD based oracles. Nonetheless, ETH based oracles
     * should not be used. Please ensure only USD based oracles are
     * set for trading.
     * Using different bases in a swap can lead to destructive results.
     */
    uint256 amount = 1e18;
    uint256 expected = swaps.getExpectedOut(
      CHAINLINK_PRICE_CHECKER,
      amount,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      AaveV2EthereumAssets.AAVE_ORACLE,
      AaveV2EthereumAssets.USDC_ORACLE
    );

    // November 14, 2024 AAVE/USD is around $170
    assertEq(expected / 1e4, 17270); // USDC is 6 decimals
  }

  function test_aaveToUsdc() public view {
    uint256 amount = 1e18;
    uint256 expected = swaps.getExpectedOut(
      CHAINLINK_PRICE_CHECKER,
      amount,
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      AaveV3EthereumAssets.USDC_UNDERLYING,
      AaveV3EthereumAssets.AAVE_ORACLE,
      AaveV3EthereumAssets.USDC_ORACLE
    );

    // November 14, 2024 AAVE/USD is around $170
    assertEq(expected / 1e4, 17001); // USDC is 6 decimals
  }

  function test_ethToDai() public view {
    uint256 amount = 1e18;
    uint256 expected = swaps.getExpectedOut(
      CHAINLINK_PRICE_CHECKER,
      amount,
      AaveV3EthereumAssets.WETH_UNDERLYING,
      AaveV3EthereumAssets.DAI_UNDERLYING,
      AaveV3EthereumAssets.WETH_ORACLE,
      AaveV3EthereumAssets.DAI_ORACLE
    );

    // November 14, 2024 ETH/USD is around $3,190
    assertEq(expected / 1e18, 3187); // WETH is 18 decimals
  }

  function test_ethToBal() public view {
    uint256 amount = 1e18;
    uint256 expected = swaps.getExpectedOut(
      CHAINLINK_PRICE_CHECKER,
      amount,
      AaveV3EthereumAssets.WETH_UNDERLYING,
      AaveV3EthereumAssets.BAL_UNDERLYING,
      AaveV3EthereumAssets.WETH_ORACLE,
      AaveV3EthereumAssets.BAL_ORACLE
    );

    // November 14, 2024 ETH/BAL is 1 ETH is around 1515 BAL tokens
    assertEq(expected / 1e18, 1515); // WETH and BAL are 18 decimals
  }

  function test_balTo80BAL20WETH() public view {
    uint256 amount = 100e18;
    uint256 expected = swaps.getExpectedOut(
      BPT_PRICE_CHECKER,
      amount,
      AaveV3EthereumAssets.BAL_UNDERLYING,
      BAL80WETH20,
      address(0),
      address(0)
    );

    // November 14, 2024 BAL/USD should be around 2,10 at 100 units traded, 27 units expected.
    assertEq(expected / 1e18, 27); // WETH and BAL are 18 decimals
  }
}

contract LimitSwap is AaveSwapperTest {
  function setUp() public override {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 18815161);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    swaps = new AaveSwapper(COMPOSABLE_COW);
    vm.stopPrank();
  }

  function test_revertsIf_invalidCaller() public {
    uint256 amount = 1_000e18;
    vm.expectRevert('Ownable: caller is not the owner');
    swaps.limitSwap(
      MILKMAN,
      LIMIT_ORDER_PRICE_CHECKER,
      AaveV2EthereumAssets.WETH_UNDERLYING,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      address(AaveV2Ethereum.COLLECTOR),
      amount,
      1_000e18
    );
  }

  function test_revertsIf_amountIsZero() public {
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectRevert(AaveSwapper.InvalidAmount.selector);
    swaps.limitSwap(
      MILKMAN,
      LIMIT_ORDER_PRICE_CHECKER,
      AaveV2EthereumAssets.WETH_UNDERLYING,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      address(AaveV2Ethereum.COLLECTOR),
      0,
      1_000e18
    );
    vm.stopPrank();
  }

  function test_revertsIf_fromTokenIsZeroAddress() public {
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectRevert(AaveSwapper.Invalid0xAddress.selector);
    swaps.limitSwap(
      MILKMAN,
      LIMIT_ORDER_PRICE_CHECKER,
      address(0),
      AaveV3EthereumAssets.AAVE_UNDERLYING,
      address(AaveV2Ethereum.COLLECTOR),
      1_000e18,
      1_000e18
    );
    vm.stopPrank();
  }

  function test_revertsIf_toTokenIsZeroAddress() public {
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectRevert(AaveSwapper.Invalid0xAddress.selector);
    swaps.limitSwap(
      MILKMAN,
      LIMIT_ORDER_PRICE_CHECKER,
      AaveV3EthereumAssets.WETH_UNDERLYING,
      address(0),
      address(AaveV2Ethereum.COLLECTOR),
      1_000e18,
      1_000e18
    );
    vm.stopPrank();
  }

  function test_revertsIf_invalidRecipient() public {
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    vm.expectRevert(AaveSwapper.InvalidRecipient.selector);
    swaps.limitSwap(
      MILKMAN,
      LIMIT_ORDER_PRICE_CHECKER,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      address(0),
      1_000e18,
      1_000e18
    );
    vm.stopPrank();
  }

  function test_successful() public {
    deal(AaveV2EthereumAssets.AAVE_UNDERLYING, address(swaps), 1_000e18);
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);

    vm.expectEmit(true, true, true, true);
    emit LimitSwapRequested(
      MILKMAN,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      1_000e18,
      address(AaveV2Ethereum.COLLECTOR),
      1_000e18
    );
    swaps.limitSwap(
      MILKMAN,
      LIMIT_ORDER_PRICE_CHECKER,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      address(AaveV2Ethereum.COLLECTOR),
      1_000e18,
      1_000e18
    );
    vm.stopPrank();
  }
}

contract CancelLimitSwap is AaveSwapperTest {
  function setUp() public override {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 18815161);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    swaps = new AaveSwapper(COMPOSABLE_COW);
    vm.stopPrank();
  }

  function test_revertsIf_invalidCaller() public {
    uint256 amount = 1_000e18;
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    swaps.cancelLimitSwap(
      makeAddr('milkman-instance'),
      LIMIT_ORDER_PRICE_CHECKER,
      AaveV2EthereumAssets.WETH_UNDERLYING,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      address(AaveV2Ethereum.COLLECTOR),
      amount,
      amount
    );
  }

  function test_revertsIf_noMatchingTrade() public {
    deal(AaveV2EthereumAssets.AAVE_UNDERLYING, address(swaps), 1_000e18);
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    swaps.limitSwap(
      MILKMAN,
      LIMIT_ORDER_PRICE_CHECKER,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      address(AaveV2Ethereum.COLLECTOR),
      1_000e18,
      1_000e18
    );

    vm.expectRevert();
    swaps.cancelLimitSwap(
      makeAddr('not-milkman-instance'),
      LIMIT_ORDER_PRICE_CHECKER,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      address(AaveV2Ethereum.COLLECTOR),
      1_000e18,
      1_000e18
    );
    vm.stopPrank();
  }

  function test_successful() public {
    deal(AaveV2EthereumAssets.AAVE_UNDERLYING, address(swaps), 1_000e18);
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);

    vm.expectEmit(true, true, true, true);
    emit LimitSwapRequested(
      MILKMAN,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      1_000e18,
      address(AaveV2Ethereum.COLLECTOR),
      1_000e18
    );
    swaps.limitSwap(
      MILKMAN,
      LIMIT_ORDER_PRICE_CHECKER,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      address(AaveV2Ethereum.COLLECTOR),
      1_000e18,
      1_000e18
    );

    vm.expectEmit();
    emit SwapCanceled(
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      1_000e18
    );
    swaps.cancelLimitSwap(
      0x524c7Dfc9fEd2C68fAcBfA2aBF8aD58fd6fdb408, // Address generated by tests
      LIMIT_ORDER_PRICE_CHECKER,
      AaveV2EthereumAssets.AAVE_UNDERLYING,
      AaveV2EthereumAssets.USDC_UNDERLYING,
      address(AaveV2Ethereum.COLLECTOR),
      1_000e18,
      1_000e18
    );
    vm.stopPrank();
  }
}

contract TWAPSwap is AaveSwapperTest {
  function setUp() public override {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 18928427);

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    swaps = new AaveSwapper(COMPOSABLE_COW);
    vm.stopPrank();
  }

  function test_revertsIf_invalidCaller() public {
    uint256 amount = 1_000e18;
    vm.expectRevert('Ownable: caller is not the owner');
    swaps.twapSwap(
      TWAP_HANDLER,
      COW_RELAYER,
      AaveV3EthereumAssets.USDC_UNDERLYING,
      AaveV3EthereumAssets.WETH_UNDERLYING,
      address(AaveV2Ethereum.COLLECTOR),
      amount,
      0.001 ether,
      block.timestamp,
      5,
      1 days,
      0
    );
  }

  function test_revertsIf_fromTokenAddressIsZeroAddress() public {
    vm.expectRevert(AaveSwapper.Invalid0xAddress.selector);
    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    swaps.twapSwap(
      TWAP_HANDLER,
      COW_RELAYER,
      address(0),
      AaveV3EthereumAssets.WETH_UNDERLYING,
      address(AaveV2Ethereum.COLLECTOR),
      1_000e18,
      0.001 ether,
      block.timestamp,
      5,
      1 days,
      0
    );
  }

  function test_revertsIf_toTokenAddressIsZeroAddress() public {
    vm.expectRevert(AaveSwapper.Invalid0xAddress.selector);
    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    swaps.twapSwap(
      TWAP_HANDLER,
      COW_RELAYER,
      AaveV3EthereumAssets.USDC_UNDERLYING,
      address(0),
      address(AaveV2Ethereum.COLLECTOR),
      1_000e18,
      0.001 ether,
      block.timestamp,
      5,
      1 days,
      0
    );
  }

  function test_revertsIf_recipientIsAddressZero() public {
    vm.expectRevert(AaveSwapper.InvalidRecipient.selector);
    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    swaps.twapSwap(
      TWAP_HANDLER,
      COW_RELAYER,
      AaveV3EthereumAssets.USDC_UNDERLYING,
      AaveV3EthereumAssets.WETH_UNDERLYING,
      address(0),
      1_000e18,
      0.001 ether,
      block.timestamp,
      5,
      1 days,
      0
    );
  }

  function test_revertsIf_amountIsZero() public {
    vm.expectRevert(AaveSwapper.InvalidAmount.selector);
    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    swaps.twapSwap(
      TWAP_HANDLER,
      COW_RELAYER,
      AaveV3EthereumAssets.USDC_UNDERLYING,
      AaveV3EthereumAssets.WETH_UNDERLYING,
      address(AaveV3Ethereum.COLLECTOR),
      0,
      0.001 ether,
      block.timestamp,
      5,
      1 days,
      0
    );
  }

  function test_revertsIf_numberOfPartsIsZero() public {
    vm.expectRevert(AaveSwapper.InvalidAmount.selector);
    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    swaps.twapSwap(
      TWAP_HANDLER,
      COW_RELAYER,
      AaveV3EthereumAssets.USDC_UNDERLYING,
      AaveV3EthereumAssets.WETH_UNDERLYING,
      address(AaveV3Ethereum.COLLECTOR),
      1_000e18,
      0.001 ether,
      block.timestamp,
      0,
      1 days,
      0
    );
  }

  function test_successful() public {
    uint256 amount = 1_000e6;
    uint256 numParts = 5;
    deal(AaveV3EthereumAssets.USDC_UNDERLYING, address(swaps), 100_000e6);
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    vm.expectEmit(true, true, true, true, address(swaps));
    emit TWAPSwapRequested(
      TWAP_HANDLER,
      AaveV3EthereumAssets.USDC_UNDERLYING,
      AaveV3EthereumAssets.WETH_UNDERLYING,
      address(AaveV2Ethereum.COLLECTOR),
      amount * numParts
    );
    swaps.twapSwap(
      TWAP_HANDLER,
      COW_RELAYER,
      AaveV3EthereumAssets.USDC_UNDERLYING,
      AaveV3EthereumAssets.WETH_UNDERLYING,
      address(AaveV2Ethereum.COLLECTOR),
      amount,
      0.001 ether,
      block.timestamp,
      numParts,
      1 days,
      0
    );
    vm.stopPrank();
  }
}

contract CancelTWAPSwap is AaveSwapperTest {
  function setUp() public override {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 18928427);

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    swaps = new AaveSwapper(COMPOSABLE_COW);
    vm.stopPrank();
  }

  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    swaps.cancelTwapSwap(
      TWAP_HANDLER,
      AaveV3EthereumAssets.USDC_UNDERLYING,
      AaveV3EthereumAssets.WETH_UNDERLYING,
      address(AaveV2Ethereum.COLLECTOR),
      1_000e18,
      0.001 ether,
      block.timestamp,
      5,
      1 days,
      0
    );
  }

  function test_successful() public {
    uint256 amount = 1_000e6;
    uint256 numParts = 5;
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    swaps.twapSwap(
      TWAP_HANDLER,
      COW_RELAYER,
      AaveV3EthereumAssets.USDC_UNDERLYING,
      AaveV3EthereumAssets.WETH_UNDERLYING,
      address(AaveV2Ethereum.COLLECTOR),
      amount,
      0.001 ether,
      block.timestamp,
      numParts,
      1 days,
      0
    );

    // Creating this order yields the following order hash:
    // 0xb4a52ecc4f17d0df0e10d5dfb8604b3bc238ae7ad2c74019b730b23b82a31539
    bool orderExists = IComposableCoW(COMPOSABLE_COW).singleOrders(address(swaps), 0xb4a52ecc4f17d0df0e10d5dfb8604b3bc238ae7ad2c74019b730b23b82a31539);

    assertTrue(orderExists, "Order does not exist");

    vm.expectEmit(true, true, true, true, address(swaps));
    emit TWAPSwapCanceled(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      AaveV3EthereumAssets.WETH_UNDERLYING,
      amount * numParts
    );

    swaps.cancelTwapSwap(
      TWAP_HANDLER,
      AaveV3EthereumAssets.USDC_UNDERLYING,
      AaveV3EthereumAssets.WETH_UNDERLYING,
      address(AaveV2Ethereum.COLLECTOR),
      amount,
      0.001 ether,
      block.timestamp,
      numParts,
      1 days,
      0
    );

    orderExists = IComposableCoW(COMPOSABLE_COW).singleOrders(address(swaps), 0xb4a52ecc4f17d0df0e10d5dfb8604b3bc238ae7ad2c74019b730b23b82a31539);
    assertFalse(orderExists, "Order exists after removing");
    vm.stopPrank();
  }
}
