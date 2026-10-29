// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IAccessControl} from 'openzeppelin-contracts/contracts/access/IAccessControl.sol';
import {IERC20Metadata} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets, ICollector, IPool} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets, ILendingPool} from 'aave-address-book/AaveV2Ethereum.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {AaveV4Ethereum, AaveV4EthereumTokenizationSpokes, IHub, ITokenizationSpoke} from 'aave-address-book/AaveV4Ethereum.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {IHubBase} from 'aave-v4/hub/interfaces/IHubBase.sol';
import {IERC4626} from 'aave-v4/dependencies/openzeppelin/IERC4626.sol';
import {IERC20Errors} from 'aave-v4/dependencies/openzeppelin/draft-IERC6093.sol';

import {CollectorUtils, IERC20, AaveSwapper, IChainlinkAggregator} from '../src/CollectorUtils.sol';
import {GovV3Helpers} from '../src/GovV3Helpers.sol';

contract CollectorUtilsTest is Test {
  using CollectorUtils for ICollector;
  using SafeERC20 for IERC20;

  ICollector public constant COLLECTOR = AaveV3Ethereum.COLLECTOR;
  IERC20 public constant UNDERLYING = IERC20(AaveV3EthereumAssets.USDC_UNDERLYING);
  IERC20 public constant A_TOKEN_V2 = IERC20(AaveV2EthereumAssets.USDC_A_TOKEN);
  IERC20 public constant A_TOKEN_V3 = IERC20(AaveV3EthereumAssets.USDC_A_TOKEN);
  IPool public constant V3_POOL = AaveV3Ethereum.POOL;
  ILendingPool public constant V2_POOL = AaveV2Ethereum.POOL;
  address public constant SWAPPER = MiscEthereum.AAVE_SWAPPER;
  ITokenizationSpoke public constant USDC_TOKENIZATION_SPOKE =
    AaveV4EthereumTokenizationSpokes.CORE_USDC_TOKENIZATION_SPOKE;
  ITokenizationSpoke public constant WETH_TOKENIZATION_SPOKE =
    AaveV4EthereumTokenizationSpokes.CORE_WETH_TOKENIZATION_SPOKE;
  ITokenizationSpoke public constant GHO_TOKENIZATION_SPOKE =
    AaveV4EthereumTokenizationSpokes.CORE_GHO_TOKENIZATION_SPOKE;
  ITokenizationSpoke public constant WBTC_TOKENIZATION_SPOKE =
    AaveV4EthereumTokenizationSpokes.CORE_WBTC_TOKENIZATION_SPOKE;
  ITokenizationSpoke public constant USDT_TOKENIZATION_SPOKE =
    AaveV4EthereumTokenizationSpokes.CORE_USDT_TOKENIZATION_SPOKE;

  // using static address instead of fuzz address as it's slow on a non anvil fork
  address testReceiver = address(0xB0B);

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 26134500);

    vm.prank(AaveV3Ethereum.ACL_ADMIN);
    IAccessControl(address(COLLECTOR)).grantRole('FUNDS_ADMIN', address(this));
  }

  function testDepositCollectorFundsToV3(uint128 amount) public {
    uint256 underlyingBalanceOfCollectorBefore = UNDERLYING.balanceOf(address(COLLECTOR));
    // @note due to roundings 1 can be rounded to 0 => revert
    vm.assume(amount <= underlyingBalanceOfCollectorBefore && amount > 1);
    uint256 aTokenBalanceOfCollectorBefore = A_TOKEN_V3.balanceOf(address(COLLECTOR));

    COLLECTOR.depositToV3(
      CollectorUtils.IOInput({
        amount: amount,
        underlying: address(UNDERLYING),
        pool: address(V3_POOL)
      })
    );
    uint256 underlyingBalanceOfCollectorAfter = UNDERLYING.balanceOf(address(COLLECTOR));
    uint256 aTokenBalanceOfCollectorAfter = A_TOKEN_V3.balanceOf(address(COLLECTOR));

    assertEq(underlyingBalanceOfCollectorAfter, underlyingBalanceOfCollectorBefore - amount);
    assertApproxEqAbs(aTokenBalanceOfCollectorAfter, aTokenBalanceOfCollectorBefore + amount, 2);
  }

  function testDepositAllCollectorFundsToV3() public {
    uint256 amount = type(uint256).max;

    uint256 underlyingBalanceOfCollectorBefore = UNDERLYING.balanceOf(address(COLLECTOR));
    uint256 aTokenBalanceOfCollectorBefore = A_TOKEN_V3.balanceOf(address(COLLECTOR));

    COLLECTOR.depositToV3(
      CollectorUtils.IOInput({
        amount: amount,
        underlying: address(UNDERLYING),
        pool: address(V3_POOL)
      })
    );
    uint256 underlyingBalanceOfCollectorAfter = UNDERLYING.balanceOf(address(COLLECTOR));
    uint256 aTokenBalanceOfCollectorAfter = A_TOKEN_V3.balanceOf(address(COLLECTOR));

    assertEq(underlyingBalanceOfCollectorAfter, 0);
    assertApproxEqAbs(
      aTokenBalanceOfCollectorAfter,
      aTokenBalanceOfCollectorBefore + underlyingBalanceOfCollectorBefore,
      2
    );
  }

  function testWithdrawCollectorFundsFromV3(uint128 amount) public {
    _genericWithdrawCollectorFundsToReceiver({
      pool: address(V3_POOL),
      aToken: A_TOKEN_V3,
      amount: amount,
      receiver: testReceiver,
      withdraw: CollectorUtils.withdrawFromV3,
      withATokenCheck: true
    });
  }

  function testWithdrawCollectorFundsFromV2(uint128 amount) public {
    _genericWithdrawCollectorFundsToReceiver({
      pool: address(V2_POOL),
      aToken: A_TOKEN_V2,
      amount: amount,
      receiver: testReceiver,
      withdraw: CollectorUtils.withdrawFromV2,
      withATokenCheck: false
    });
  }

  function testWithdrawAllCollectorFundsFromV3() public {
    _genericWithdrawAllCollectorFundsToReceiver({
      pool: address(V3_POOL),
      aToken: A_TOKEN_V3,
      withdraw: CollectorUtils.withdrawFromV3,
      withATokenCheck: true,
      seedExecutor: false
    });
  }

  function testWithdrawAllCollectorFundsFromV3WithSeededExecutor() public {
    _genericWithdrawAllCollectorFundsToReceiver({
      pool: address(V3_POOL),
      aToken: A_TOKEN_V3,
      withdraw: CollectorUtils.withdrawFromV3,
      withATokenCheck: true,
      seedExecutor: true
    });
  }

  function testWithdrawAllCollectorFundsFromV2() public {
    _genericWithdrawAllCollectorFundsToReceiver({
      pool: address(V2_POOL),
      aToken: A_TOKEN_V2,
      withdraw: CollectorUtils.withdrawFromV2,
      withATokenCheck: false,
      seedExecutor: false
    });
  }

  function testWithdrawAllCollectorFundsFromV2WithSeededExecutor() public {
    _genericWithdrawAllCollectorFundsToReceiver({
      pool: address(V2_POOL),
      aToken: A_TOKEN_V2,
      withdraw: CollectorUtils.withdrawFromV2,
      withATokenCheck: false,
      seedExecutor: true
    });
  }

  function testStream(uint128 amount) public {
    uint256 underlyingBalanceOfCollectorBefore = UNDERLYING.balanceOf(address(COLLECTOR));
    amount = uint128(bound(amount, 1 days, underlyingBalanceOfCollectorBefore)); // otherwise actual amount is rounded to 0
    uint256 underlyingBalanceOfReceiverBefore = UNDERLYING.balanceOf(address(testReceiver));

    uint256 nextStreamId = AaveV3Ethereum.COLLECTOR.getNextStreamId();
    vm.expectRevert();
    AaveV3Ethereum.COLLECTOR.getStream(nextStreamId);

    uint256 actualAmount = CollectorUtils.stream(
      COLLECTOR,
      CollectorUtils.CreateStreamInput({
        underlying: address(UNDERLYING),
        receiver: testReceiver,
        amount: amount,
        start: block.timestamp,
        duration: 1 days
      })
    );

    vm.warp(block.timestamp + 2 days);
    vm.prank(testReceiver);
    COLLECTOR.withdrawFromStream(nextStreamId, actualAmount);

    uint256 underlyingBalanceOfCollectorAfter = UNDERLYING.balanceOf(address(COLLECTOR));
    uint256 underlyingBalanceOfReceiverAfter = UNDERLYING.balanceOf(address(testReceiver));

    assertEq(underlyingBalanceOfCollectorAfter, underlyingBalanceOfCollectorBefore - actualAmount);
    assertEq(underlyingBalanceOfReceiverAfter, underlyingBalanceOfReceiverBefore + actualAmount);
  }

  function testSwap(
    address milkman,
    address priceChecker,
    address toUnderlying,
    address fromUnderlyingPriceFeed,
    address toUnderlyingPriceFeed,
    uint256 amount,
    uint256 slippage
  ) public {
    assumeNotForgeAddress(milkman);
    assumeNotForgeAddress(priceChecker);
    assumeNotForgeAddress(toUnderlying);
    assumeNotForgeAddress(fromUnderlyingPriceFeed);
    assumeNotForgeAddress(toUnderlyingPriceFeed);
    uint256 balance = UNDERLYING.balanceOf(address(COLLECTOR));
    vm.assume(amount <= balance && amount != 0);

    _testSwap(
      CollectorUtils.SwapInput({
        milkman: milkman,
        priceChecker: priceChecker,
        fromUnderlying: address(UNDERLYING),
        toUnderlying: toUnderlying,
        fromUnderlyingPriceFeed: fromUnderlyingPriceFeed,
        toUnderlyingPriceFeed: toUnderlyingPriceFeed,
        amount: amount,
        slippage: slippage
      }),
      false
    );
  }

  function testSwapAllCollectorFunds() public {
    _testSwap(_swapInput(UNDERLYING.balanceOf(address(COLLECTOR))), true);
  }

  function testSwapFullCollectorBalance() public {
    _testSwap(_swapInput(UNDERLYING.balanceOf(address(COLLECTOR))), false);
  }

  function _swapInput(uint256 amount) internal returns (CollectorUtils.SwapInput memory) {
    return
      CollectorUtils.SwapInput({
        milkman: makeAddr('milkman'),
        priceChecker: makeAddr('priceChecker'),
        fromUnderlying: address(UNDERLYING),
        toUnderlying: AaveV3EthereumAssets.USDT_UNDERLYING,
        fromUnderlyingPriceFeed: makeAddr('fromUnderlyingPriceFeed'),
        toUnderlyingPriceFeed: makeAddr('toUnderlyingPriceFeed'),
        amount: amount,
        slippage: 100
      });
  }

  function _testSwap(CollectorUtils.SwapInput memory input, bool useMaxSentinel) internal {
    uint256 balanceOfSwapperBefore = UNDERLYING.balanceOf(SWAPPER);
    uint256 balanceOfCollectorBefore = UNDERLYING.balanceOf(address(COLLECTOR));
    bytes memory expectedSwapCall = abi.encodeCall(
      AaveSwapper.swap,
      (
        input.milkman,
        input.priceChecker,
        input.fromUnderlying,
        input.toUnderlying,
        input.fromUnderlyingPriceFeed,
        input.toUnderlyingPriceFeed,
        address(COLLECTOR),
        input.amount,
        input.slippage
      )
    );

    vm.expectCall(SWAPPER, expectedSwapCall);
    vm.mockCall(SWAPPER, expectedSwapCall, bytes('0'));
    vm.mockCall(
      input.fromUnderlyingPriceFeed,
      abi.encodeCall(IChainlinkAggregator.decimals, ()),
      abi.encode(18)
    );
    vm.mockCall(
      input.toUnderlyingPriceFeed,
      abi.encodeCall(IChainlinkAggregator.decimals, ()),
      abi.encode(18)
    );

    uint256 expectedAmount = input.amount;
    if (useMaxSentinel) {
      input.amount = type(uint256).max;
    }
    COLLECTOR.swap(SWAPPER, input);

    assertEq(UNDERLYING.balanceOf(SWAPPER), balanceOfSwapperBefore + expectedAmount);
    assertEq(UNDERLYING.balanceOf(address(COLLECTOR)), balanceOfCollectorBefore - expectedAmount);
  }

  function _genericWithdrawCollectorFundsToReceiver(
    address pool,
    IERC20 aToken,
    uint256 amount,
    address receiver,
    function(ICollector, CollectorUtils.IOInput memory, address) returns (uint256) withdraw,
    bool withATokenCheck
  ) internal {
    uint256 aTokenBalanceOfCollectorBefore = aToken.balanceOf(address(COLLECTOR));
    amount = bound(amount, 1, aTokenBalanceOfCollectorBefore);
    uint256 underlyingBalanceOfReceiverBefore = UNDERLYING.balanceOf(address(receiver));

    uint256 withdrawnAmount = withdraw(
      COLLECTOR,
      CollectorUtils.IOInput({amount: amount, underlying: address(UNDERLYING), pool: pool}),
      receiver
    );
    uint256 underlyingBalanceOfReceiverAfter = UNDERLYING.balanceOf(address(receiver));
    uint256 aTokenBalanceOfCollectorAfter = aToken.balanceOf(address(COLLECTOR));

    assertApproxEqAbs(
      underlyingBalanceOfReceiverAfter,
      underlyingBalanceOfReceiverBefore + amount,
      1
    );
    assertApproxEqAbs(withdrawnAmount, amount, 1);

    // because we mint to treasury straight away on v2, hard to check the final amount we expect
    if (withATokenCheck) {
      assertApproxEqAbs(aTokenBalanceOfCollectorAfter, aTokenBalanceOfCollectorBefore - amount, 2);
    }
  }

  function _genericWithdrawAllCollectorFundsToReceiver(
    address pool,
    IERC20 aToken,
    function(ICollector, CollectorUtils.IOInput memory, address) returns (uint256) withdraw,
    bool withATokenCheck,
    bool seedExecutor
  ) internal {
    if (seedExecutor) {
      uint256 executorSeed = 10 ** IERC20Metadata(address(aToken)).decimals();
      COLLECTOR.transfer(aToken, address(this), executorSeed);
      deal(address(UNDERLYING), address(this), executorSeed);
    }
    uint256 aTokenBalanceOfExecutorBefore = aToken.balanceOf(address(this));
    uint256 underlyingBalanceOfExecutorBefore = UNDERLYING.balanceOf(address(this));
    uint256 aTokenBalanceOfCollectorBefore = aToken.balanceOf(address(COLLECTOR));
    uint256 underlyingBalanceOfReceiverBefore = UNDERLYING.balanceOf(testReceiver);

    uint256 withdrawnAmount = withdraw(
      COLLECTOR,
      CollectorUtils.IOInput({
        amount: type(uint256).max,
        underlying: address(UNDERLYING),
        pool: pool
      }),
      testReceiver
    );

    assertApproxEqAbs(withdrawnAmount, aTokenBalanceOfCollectorBefore, 2);
    assertEq(
      UNDERLYING.balanceOf(testReceiver),
      underlyingBalanceOfReceiverBefore + withdrawnAmount
    );
    if (seedExecutor) {
      // the balance-diff in __withdraw can move an executor's own aTokens by 1 wei
      assertApproxEqAbs(aToken.balanceOf(address(this)), aTokenBalanceOfExecutorBefore, 1);
    } else {
      assertEq(aToken.balanceOf(address(this)), 0);
    }
    assertEq(UNDERLYING.balanceOf(address(this)), underlyingBalanceOfExecutorBefore);
    // because we mint to treasury straight away on v2, hard to check the final amount we expect
    if (withATokenCheck) {
      assertEq(aToken.balanceOf(address(COLLECTOR)), 0);
    }
  }

  function testDepositToV4RevertsOnZeroAmount() public {
    vm.expectRevert(CollectorUtils.InvalidZeroAmount.selector);
    this.depositToV4External(address(USDC_TOKENIZATION_SPOKE), 0);
  }

  function testDepositToV3RevertsOnZeroAmount() public {
    vm.expectRevert(CollectorUtils.InvalidZeroAmount.selector);
    this.depositToV3External(0);
  }

  function testWithdrawFromV3RevertsOnZeroAmount() public {
    vm.expectRevert(CollectorUtils.InvalidZeroAmount.selector);
    this.withdrawFromV3External(0);
  }

  function testWithdrawFromV2RevertsOnZeroAmount() public {
    vm.expectRevert(CollectorUtils.InvalidZeroAmount.selector);
    this.withdrawFromV2External(0);
  }

  function testWithdrawFromV4RevertsOnZeroAmount() public {
    vm.expectRevert(CollectorUtils.InvalidZeroAmount.selector);
    this.withdrawFromV4External(address(USDC_TOKENIZATION_SPOKE), 0);
  }

  function testStreamRevertsOnZeroAmount() public {
    vm.expectRevert(CollectorUtils.InvalidZeroAmount.selector);
    this.streamExternal(0);
  }

  function testSwapRevertsOnZeroAmount() public {
    vm.expectRevert(CollectorUtils.InvalidZeroAmount.selector);
    this.swapExternal(0);
  }

  function testDepositCollectorFundsToV4Usdc(uint128 amount) public {
    _testDepositToV4({
      spoke: USDC_TOKENIZATION_SPOKE,
      amount: amount,
      depositAll: false,
      useMaxSentinel: false
    });
  }

  function testDepositAllCollectorFundsToV4Usdc(uint128 amount) public {
    _testDepositToV4({
      spoke: USDC_TOKENIZATION_SPOKE,
      amount: amount,
      depositAll: true,
      useMaxSentinel: true
    });
  }

  function testDepositFullBalanceToV4Usdc() public {
    _testDepositToV4({
      spoke: USDC_TOKENIZATION_SPOKE,
      amount: 100_000e6,
      depositAll: true,
      useMaxSentinel: false
    });
  }

  function testWithdrawCollectorFundsFromV4Usdc(uint128 amount) public {
    _testWithdrawFromV4({
      spoke: USDC_TOKENIZATION_SPOKE,
      depositAmount: 100_000e6,
      withdrawAmount: amount,
      withdrawAll: false,
      useMaxSentinel: false
    });
  }

  function testWithdrawAllCollectorFundsFromV4Usdc() public {
    _testWithdrawFromV4({
      spoke: USDC_TOKENIZATION_SPOKE,
      depositAmount: 100_000e6,
      withdrawAmount: 0,
      withdrawAll: true,
      useMaxSentinel: true
    });
  }

  function testWithdrawFullBalanceFromV4Usdc() public {
    _testWithdrawFromV4({
      spoke: USDC_TOKENIZATION_SPOKE,
      depositAmount: 100_000e6,
      withdrawAmount: 0,
      withdrawAll: true,
      useMaxSentinel: false
    });
  }

  function testDepositCollectorFundsToV4Weth(uint128 amount) public {
    _testDepositToV4({
      spoke: WETH_TOKENIZATION_SPOKE,
      amount: amount,
      depositAll: false,
      useMaxSentinel: false
    });
  }

  function testDepositAllCollectorFundsToV4Weth(uint128 amount) public {
    _testDepositToV4({
      spoke: WETH_TOKENIZATION_SPOKE,
      amount: amount,
      depositAll: true,
      useMaxSentinel: true
    });
  }

  function testDepositFullBalanceToV4Weth() public {
    _testDepositToV4({
      spoke: WETH_TOKENIZATION_SPOKE,
      amount: 100e18,
      depositAll: true,
      useMaxSentinel: false
    });
  }

  function testWithdrawCollectorFundsFromV4Weth(uint128 amount) public {
    _testWithdrawFromV4({
      spoke: WETH_TOKENIZATION_SPOKE,
      depositAmount: 100e18,
      withdrawAmount: amount,
      withdrawAll: false,
      useMaxSentinel: false
    });
  }

  function testWithdrawAllCollectorFundsFromV4Weth() public {
    _testWithdrawFromV4({
      spoke: WETH_TOKENIZATION_SPOKE,
      depositAmount: 100e18,
      withdrawAmount: 0,
      withdrawAll: true,
      useMaxSentinel: true
    });
  }

  function testWithdrawFullBalanceFromV4Weth() public {
    _testWithdrawFromV4({
      spoke: WETH_TOKENIZATION_SPOKE,
      depositAmount: 100e18,
      withdrawAmount: 0,
      withdrawAll: true,
      useMaxSentinel: false
    });
  }

  function testDepositCollectorFundsToV4Gho(uint128 amount) public {
    _testDepositToV4({
      spoke: GHO_TOKENIZATION_SPOKE,
      amount: amount,
      depositAll: false,
      useMaxSentinel: false
    });
  }

  function testDepositAllCollectorFundsToV4Gho(uint128 amount) public {
    _testDepositToV4({
      spoke: GHO_TOKENIZATION_SPOKE,
      amount: amount,
      depositAll: true,
      useMaxSentinel: true
    });
  }

  function testDepositFullBalanceToV4Gho() public {
    _testDepositToV4({
      spoke: GHO_TOKENIZATION_SPOKE,
      amount: 50_000e18,
      depositAll: true,
      useMaxSentinel: false
    });
  }

  function testWithdrawCollectorFundsFromV4Gho(uint128 amount) public {
    _testWithdrawFromV4({
      spoke: GHO_TOKENIZATION_SPOKE,
      depositAmount: 50_000e18,
      withdrawAmount: amount,
      withdrawAll: false,
      useMaxSentinel: false
    });
  }

  function testWithdrawAllCollectorFundsFromV4Gho() public {
    _testWithdrawFromV4({
      spoke: GHO_TOKENIZATION_SPOKE,
      depositAmount: 50_000e18,
      withdrawAmount: 0,
      withdrawAll: true,
      useMaxSentinel: true
    });
  }

  function testWithdrawFullBalanceFromV4Gho() public {
    _testWithdrawFromV4({
      spoke: GHO_TOKENIZATION_SPOKE,
      depositAmount: 50_000e18,
      withdrawAmount: 0,
      withdrawAll: true,
      useMaxSentinel: false
    });
  }

  function testDepositCollectorFundsToV4Wbtc(uint128 amount) public {
    _setAddCap(WBTC_TOKENIZATION_SPOKE, 100);
    _testDepositToV4({
      spoke: WBTC_TOKENIZATION_SPOKE,
      amount: amount,
      depositAll: false,
      useMaxSentinel: false
    });
  }

  function testDepositAllCollectorFundsToV4Wbtc(uint128 amount) public {
    _setAddCap(WBTC_TOKENIZATION_SPOKE, 100);
    _testDepositToV4({
      spoke: WBTC_TOKENIZATION_SPOKE,
      amount: amount,
      depositAll: true,
      useMaxSentinel: true
    });
  }

  function testDepositFullBalanceToV4Wbtc() public {
    _setAddCap(WBTC_TOKENIZATION_SPOKE, 100);
    _testDepositToV4({
      spoke: WBTC_TOKENIZATION_SPOKE,
      amount: 10e8,
      depositAll: true,
      useMaxSentinel: false
    });
  }

  function testWithdrawCollectorFundsFromV4Wbtc(uint128 amount) public {
    _setAddCap(WBTC_TOKENIZATION_SPOKE, 100);
    _testWithdrawFromV4({
      spoke: WBTC_TOKENIZATION_SPOKE,
      depositAmount: 10e8,
      withdrawAmount: amount,
      withdrawAll: false,
      useMaxSentinel: false
    });
  }

  function testWithdrawAllCollectorFundsFromV4Wbtc() public {
    _setAddCap(WBTC_TOKENIZATION_SPOKE, 100);
    _testWithdrawFromV4({
      spoke: WBTC_TOKENIZATION_SPOKE,
      depositAmount: 10e8,
      withdrawAmount: 0,
      withdrawAll: true,
      useMaxSentinel: true
    });
  }

  function testWithdrawFullBalanceFromV4Wbtc() public {
    _setAddCap(WBTC_TOKENIZATION_SPOKE, 100);
    _testWithdrawFromV4({
      spoke: WBTC_TOKENIZATION_SPOKE,
      depositAmount: 10e8,
      withdrawAmount: 0,
      withdrawAll: true,
      useMaxSentinel: false
    });
  }

  function testDepositAndWithdrawSequenceV4Usdc() public {
    uint256 totalWithdrawnAmount = _testDepositAndWithdrawSequenceV4({
      spoke: USDC_TOKENIZATION_SPOKE,
      depositAmount: 100_000e6,
      partialWithdrawAmount: 50_000e6
    });

    assertEq(USDC_TOKENIZATION_SPOKE.asset(), AaveV3EthereumAssets.USDC_UNDERLYING);
    assertEq(USDC_TOKENIZATION_SPOKE.decimals(), 6);
    assertGt(totalWithdrawnAmount, 100_000e6);
  }

  function testDepositAndWithdrawSequenceV4Weth() public {
    uint256 totalWithdrawnAmount = _testDepositAndWithdrawSequenceV4({
      spoke: WETH_TOKENIZATION_SPOKE,
      depositAmount: 100e18,
      partialWithdrawAmount: 50e18
    });

    assertEq(WETH_TOKENIZATION_SPOKE.asset(), AaveV3EthereumAssets.WETH_UNDERLYING);
    assertEq(WETH_TOKENIZATION_SPOKE.decimals(), 18);
    assertGt(totalWithdrawnAmount, 100e18);
  }

  function testDepositAndWithdrawSequenceV4Gho() public {
    uint256 totalWithdrawnAmount = _testDepositAndWithdrawSequenceV4({
      spoke: GHO_TOKENIZATION_SPOKE,
      depositAmount: 50_000e18,
      partialWithdrawAmount: 25_000e18
    });

    assertEq(GHO_TOKENIZATION_SPOKE.asset(), AaveV3EthereumAssets.GHO_UNDERLYING);
    assertEq(GHO_TOKENIZATION_SPOKE.decimals(), 18);
    assertGt(totalWithdrawnAmount, 50_000e18);
  }

  function testDepositAndWithdrawSequenceV4Wbtc() public {
    _setAddCap(WBTC_TOKENIZATION_SPOKE, 100);
    uint256 totalWithdrawnAmount = _testDepositAndWithdrawSequenceV4({
      spoke: WBTC_TOKENIZATION_SPOKE,
      depositAmount: 10e8,
      partialWithdrawAmount: 5e8
    });

    assertEq(WBTC_TOKENIZATION_SPOKE.asset(), AaveV3EthereumAssets.WBTC_UNDERLYING);
    assertEq(WBTC_TOKENIZATION_SPOKE.decimals(), 8);
    assertGt(totalWithdrawnAmount, 10e8);
  }

  function testDepositCollectorFundsToV4Usdt(uint128 amount) public {
    _testDepositToV4({
      spoke: USDT_TOKENIZATION_SPOKE,
      amount: amount,
      depositAll: false,
      useMaxSentinel: false
    });
  }

  function testDepositAllCollectorFundsToV4Usdt(uint128 amount) public {
    _testDepositToV4({
      spoke: USDT_TOKENIZATION_SPOKE,
      amount: amount,
      depositAll: true,
      useMaxSentinel: true
    });
  }

  function testDepositFullBalanceToV4Usdt() public {
    _testDepositToV4({
      spoke: USDT_TOKENIZATION_SPOKE,
      amount: 100_000e6,
      depositAll: true,
      useMaxSentinel: false
    });
  }

  function testWithdrawCollectorFundsFromV4Usdt(uint128 amount) public {
    _testWithdrawFromV4({
      spoke: USDT_TOKENIZATION_SPOKE,
      depositAmount: 100_000e6,
      withdrawAmount: amount,
      withdrawAll: false,
      useMaxSentinel: false
    });
  }

  function testWithdrawAllCollectorFundsFromV4Usdt() public {
    _testWithdrawFromV4({
      spoke: USDT_TOKENIZATION_SPOKE,
      depositAmount: 100_000e6,
      withdrawAmount: 0,
      withdrawAll: true,
      useMaxSentinel: true
    });
  }

  function testWithdrawFullBalanceFromV4Usdt() public {
    _testWithdrawFromV4({
      spoke: USDT_TOKENIZATION_SPOKE,
      depositAmount: 100_000e6,
      withdrawAmount: 0,
      withdrawAll: true,
      useMaxSentinel: false
    });
  }

  function testDepositAndWithdrawSequenceV4Usdt() public {
    uint256 totalWithdrawnAmount = _testDepositAndWithdrawSequenceV4({
      spoke: USDT_TOKENIZATION_SPOKE,
      depositAmount: 100_000e6,
      partialWithdrawAmount: 50_000e6
    });

    assertEq(USDT_TOKENIZATION_SPOKE.asset(), AaveV3EthereumAssets.USDT_UNDERLYING);
    assertEq(USDT_TOKENIZATION_SPOKE.decimals(), 6);
    assertGt(totalWithdrawnAmount, 100_000e6);
  }

  function testWithdrawAllCollectorFundsFromV4IncludesInterest() public {
    _depositCollectorFundsToV4(USDC_TOKENIZATION_SPOKE, 100_000e6);
    uint256 maxWithdrawBefore = USDC_TOKENIZATION_SPOKE.maxWithdraw(address(COLLECTOR));
    skip(30 days);
    uint256 maxWithdrawAfter = USDC_TOKENIZATION_SPOKE.maxWithdraw(address(COLLECTOR));
    assertGt(maxWithdrawAfter, maxWithdrawBefore);
    uint256 underlyingBalanceOfReceiverBefore = UNDERLYING.balanceOf(testReceiver);

    uint256 withdrawnAmount = COLLECTOR.withdrawFromV4({
      tokenizationSpoke: address(USDC_TOKENIZATION_SPOKE),
      amount: type(uint256).max,
      receiver: testReceiver
    });

    assertEq(withdrawnAmount, maxWithdrawAfter);
    assertEq(
      UNDERLYING.balanceOf(testReceiver),
      underlyingBalanceOfReceiverBefore + maxWithdrawAfter
    );
  }

  function testWithdrawAllCollectorFundsFromV4CappedByLiquidity() public {
    _depositCollectorFundsToV4(USDC_TOKENIZATION_SPOKE, 100_000e6);
    uint256 sharesOfCollectorBefore = USDC_TOKENIZATION_SPOKE.balanceOf(address(COLLECTOR));
    uint256 assetsOfCollectorBefore = USDC_TOKENIZATION_SPOKE.convertToAssets(
      sharesOfCollectorBefore
    );
    uint256 liquidity = 40_000e6;
    uint256 expectedShares = USDC_TOKENIZATION_SPOKE.previewWithdraw(liquidity);
    vm.mockCall(
      USDC_TOKENIZATION_SPOKE.hub(),
      abi.encodeWithSelector(
        IHubBase.getAssetLiquidity.selector,
        USDC_TOKENIZATION_SPOKE.assetId()
      ),
      abi.encode(liquidity)
    );
    uint256 underlyingBalanceOfReceiverBefore = UNDERLYING.balanceOf(testReceiver);

    uint256 withdrawnAmount = COLLECTOR.withdrawFromV4({
      tokenizationSpoke: address(USDC_TOKENIZATION_SPOKE),
      amount: type(uint256).max,
      receiver: testReceiver
    });

    assertEq(withdrawnAmount, liquidity);
    assertEq(UNDERLYING.balanceOf(testReceiver), underlyingBalanceOfReceiverBefore + liquidity);
    assertEq(
      USDC_TOKENIZATION_SPOKE.balanceOf(address(COLLECTOR)),
      sharesOfCollectorBefore - expectedShares
    );
    assertApproxEqAbs(
      USDC_TOKENIZATION_SPOKE.convertToAssets(
        USDC_TOKENIZATION_SPOKE.balanceOf(address(COLLECTOR))
      ),
      assetsOfCollectorBefore - liquidity,
      1
    );
  }

  function testDepositToV4RevertsOnAddCapExceeded() public {
    deal(WBTC_TOKENIZATION_SPOKE.asset(), address(COLLECTOR), 1e8);
    vm.expectRevert(abi.encodeWithSelector(IHub.AddCapExceeded.selector, uint256(0)));
    this.depositToV4External(address(WBTC_TOKENIZATION_SPOKE), 1e8);
  }

  function testDepositToV4RevertsOnInvalidShares() public {
    vm.expectRevert(IHub.InvalidShares.selector);
    this.depositToV4External(address(USDC_TOKENIZATION_SPOKE), 1);
  }

  function testWithdrawFromV4RevertsOnInsufficientShares() public {
    _depositCollectorFundsToV4(USDC_TOKENIZATION_SPOKE, 1_000e6);
    uint256 collectorShares = USDC_TOKENIZATION_SPOKE.balanceOf(address(COLLECTOR));
    uint256 amount = USDC_TOKENIZATION_SPOKE.maxWithdraw(address(COLLECTOR)) + 1_000e6;

    vm.expectRevert(
      abi.encodeWithSelector(
        IERC20Errors.ERC20InsufficientBalance.selector,
        address(COLLECTOR),
        collectorShares,
        USDC_TOKENIZATION_SPOKE.previewWithdraw(amount)
      )
    );
    this.withdrawFromV4External(address(USDC_TOKENIZATION_SPOKE), amount);
  }

  function testDepositToV4RevertsWhenSpokeHalted() public {
    _setSpokeHalted(USDC_TOKENIZATION_SPOKE);
    vm.expectRevert(IHub.SpokeHalted.selector);
    this.depositToV4External(address(USDC_TOKENIZATION_SPOKE), 1_000e6);
  }

  function testWithdrawFromV4RevertsWhenSpokeHalted() public {
    _depositCollectorFundsToV4(USDC_TOKENIZATION_SPOKE, 1_000e6);
    _setSpokeHalted(USDC_TOKENIZATION_SPOKE);
    vm.expectRevert(IHub.SpokeHalted.selector);
    this.withdrawFromV4External(address(USDC_TOKENIZATION_SPOKE), 500e6);
  }

  function testDepositToV4RevertsWhenSpokeNotActive() public {
    _setSpokeInactive(USDC_TOKENIZATION_SPOKE);
    vm.expectRevert(IHub.SpokeNotActive.selector);
    this.depositToV4External(address(USDC_TOKENIZATION_SPOKE), 1_000e6);
  }

  function testWithdrawFromV4RevertsWhenSpokeNotActive() public {
    _depositCollectorFundsToV4(USDC_TOKENIZATION_SPOKE, 1_000e6);
    _setSpokeInactive(USDC_TOKENIZATION_SPOKE);
    vm.expectRevert(IHub.SpokeNotActive.selector);
    this.withdrawFromV4External(address(USDC_TOKENIZATION_SPOKE), 500e6);
  }

  function testDepositAllToV4RevertsOnZeroCollectorBalance() public {
    deal(address(UNDERLYING), address(COLLECTOR), 0);
    vm.expectRevert(IHub.InvalidAmount.selector);
    this.depositToV4External(address(USDC_TOKENIZATION_SPOKE), type(uint256).max);
  }

  function testDepositToV4RevertsOnInsufficientCollectorBalance() public {
    deal(address(UNDERLYING), address(COLLECTOR), 1_000e6);
    vm.expectRevert(bytes('ERC20: transfer amount exceeds balance'));
    this.depositToV4External(address(USDC_TOKENIZATION_SPOKE), 1_000e6 + 1);
  }

  function testWithdrawAllFromV4RevertsOnZeroShares() public {
    assertEq(USDC_TOKENIZATION_SPOKE.balanceOf(address(COLLECTOR)), 0);
    vm.expectRevert(IHub.InvalidAmount.selector);
    this.withdrawFromV4External(address(USDC_TOKENIZATION_SPOKE), type(uint256).max);
  }

  function testWithdrawAllFromV4RevertsWhenSpokeHalted() public {
    _depositCollectorFundsToV4(USDC_TOKENIZATION_SPOKE, 1_000e6);
    _setSpokeHalted(USDC_TOKENIZATION_SPOKE);
    // maxWithdraw returns 0 on a halted spoke, so this reverts with InvalidAmount, not SpokeHalted
    vm.expectRevert(IHub.InvalidAmount.selector);
    this.withdrawFromV4External(address(USDC_TOKENIZATION_SPOKE), type(uint256).max);
  }

  function testDepositAndWithdrawV4ViaPayload() public {
    address executor = GovernanceV3Ethereum.EXECUTOR_LVL_1;
    uint256 underlyingBalanceOfCollectorBefore = UNDERLYING.balanceOf(address(COLLECTOR));
    uint256 underlyingBalanceOfReceiverBefore = UNDERLYING.balanceOf(testReceiver);
    uint256 underlyingBalanceOfExecutorBefore = UNDERLYING.balanceOf(executor);
    uint256 sharesOfExecutorBefore = USDC_TOKENIZATION_SPOKE.balanceOf(executor);
    uint256 sharesOfCollectorBefore = USDC_TOKENIZATION_SPOKE.balanceOf(address(COLLECTOR));
    uint256 expectedSharesOfCollector = sharesOfCollectorBefore +
      USDC_TOKENIZATION_SPOKE.previewDeposit(10_000e6) -
      USDC_TOKENIZATION_SPOKE.previewWithdraw(5_000e6);
    CollectorUtilsV4Payload payload = new CollectorUtilsV4Payload({
      tokenizationSpoke: address(USDC_TOKENIZATION_SPOKE),
      receiver: testReceiver,
      depositAmount: 10_000e6,
      withdrawAmount: 5_000e6
    });

    GovV3Helpers.executePayload(vm, address(payload));

    assertEq(
      UNDERLYING.balanceOf(address(COLLECTOR)),
      underlyingBalanceOfCollectorBefore - 10_000e6
    );
    assertEq(UNDERLYING.balanceOf(testReceiver), underlyingBalanceOfReceiverBefore + 5_000e6);
    assertEq(UNDERLYING.balanceOf(executor), underlyingBalanceOfExecutorBefore);
    assertEq(USDC_TOKENIZATION_SPOKE.balanceOf(executor), sharesOfExecutorBefore);
    assertEq(UNDERLYING.allowance(executor, address(USDC_TOKENIZATION_SPOKE)), 0);
    assertEq(USDC_TOKENIZATION_SPOKE.balanceOf(address(COLLECTOR)), expectedSharesOfCollector);
  }

  function _testDepositToV4(
    ITokenizationSpoke spoke,
    uint256 amount,
    bool depositAll,
    bool useMaxSentinel
  ) internal {
    IERC20 underlying = IERC20(spoke.asset());
    (uint256 executorUnderlying, uint256 executorShares) = _seedExecutor(spoke);
    amount = bound(amount, 2, spoke.maxDeposit(address(COLLECTOR)));
    uint256 extra = depositAll ? 0 : 10 ** spoke.decimals();
    deal(address(underlying), address(COLLECTOR), amount + extra);
    uint256 sharesOfCollectorBefore = spoke.balanceOf(address(COLLECTOR));
    uint256 expectedShares = spoke.previewDeposit(amount);

    vm.expectEmit(true, true, true, true, address(spoke));
    emit IERC4626.Deposit(address(this), address(COLLECTOR), amount, expectedShares);
    // called through the external wrapper so expectEmit checks the whole library call
    uint256 shares = this.depositToV4External(
      address(spoke),
      depositAll && useMaxSentinel ? type(uint256).max : amount
    );

    assertEq(shares, expectedShares);
    assertEq(underlying.balanceOf(address(COLLECTOR)), extra);
    assertEq(spoke.balanceOf(address(COLLECTOR)), sharesOfCollectorBefore + shares);
    _assertExecutorUntouched(spoke, executorUnderlying, executorShares);
  }

  function _testWithdrawFromV4(
    ITokenizationSpoke spoke,
    uint256 depositAmount,
    uint256 withdrawAmount,
    bool withdrawAll,
    bool useMaxSentinel
  ) internal {
    IERC20 underlying = IERC20(spoke.asset());
    _depositCollectorFundsToV4(spoke, depositAmount);
    skip(30 days);
    (uint256 executorUnderlying, uint256 executorShares) = _seedExecutor(spoke);

    uint256 maxWithdrawBefore = spoke.maxWithdraw(address(COLLECTOR));
    uint256 expectedAmount = withdrawAll
      ? maxWithdrawBefore
      : bound(withdrawAmount, 1, maxWithdrawBefore);
    uint256 expectedShares = spoke.previewWithdraw(expectedAmount);
    uint256 sharesOfCollectorBefore = spoke.balanceOf(address(COLLECTOR));
    uint256 underlyingBalanceOfReceiverBefore = underlying.balanceOf(testReceiver);

    _expectWithdrawEvent(spoke, expectedAmount, expectedShares);
    // called through the external wrapper so expectEmit checks the whole library call
    uint256 withdrawnAmount = this.withdrawFromV4External(
      address(spoke),
      withdrawAll && useMaxSentinel ? type(uint256).max : expectedAmount
    );

    assertEq(withdrawnAmount, expectedAmount);
    assertEq(
      underlying.balanceOf(testReceiver),
      underlyingBalanceOfReceiverBefore + expectedAmount
    );
    assertEq(spoke.balanceOf(address(COLLECTOR)), sharesOfCollectorBefore - expectedShares);
    if (expectedAmount == maxWithdrawBefore) {
      assertEq(spoke.balanceOf(address(COLLECTOR)), 0);
    }
    _assertExecutorUntouched(spoke, executorUnderlying, executorShares);
  }

  function _testDepositAndWithdrawSequenceV4(
    ITokenizationSpoke spoke,
    uint256 depositAmount,
    uint256 partialWithdrawAmount
  ) internal returns (uint256) {
    IERC20 underlying = IERC20(spoke.asset());
    uint256 underlyingBalanceOfReceiverBefore = underlying.balanceOf(testReceiver);
    _depositCollectorFundsToV4(spoke, depositAmount);

    skip(30 days);
    uint256 partialWithdrawnAmount = COLLECTOR.withdrawFromV4({
      tokenizationSpoke: address(spoke),
      amount: partialWithdrawAmount,
      receiver: testReceiver
    });

    skip(30 days);
    uint256 remainingAmount = spoke.maxWithdraw(address(COLLECTOR));
    uint256 remainingWithdrawnAmount = COLLECTOR.withdrawFromV4({
      tokenizationSpoke: address(spoke),
      amount: type(uint256).max,
      receiver: testReceiver
    });

    assertEq(partialWithdrawnAmount, partialWithdrawAmount);
    assertEq(remainingWithdrawnAmount, remainingAmount);
    assertEq(spoke.balanceOf(address(COLLECTOR)), 0);
    assertEq(
      underlying.balanceOf(testReceiver),
      underlyingBalanceOfReceiverBefore + partialWithdrawAmount + remainingAmount
    );
    return partialWithdrawAmount + remainingAmount;
  }

  function _expectWithdrawEvent(ITokenizationSpoke spoke, uint256 assets, uint256 shares) internal {
    vm.expectEmit(true, true, true, true, address(spoke));
    emit IERC4626.Withdraw(address(this), testReceiver, address(this), assets, shares);
  }

  function _depositCollectorFundsToV4(ITokenizationSpoke spoke, uint256 amount) internal {
    deal(spoke.asset(), address(COLLECTOR), amount);
    COLLECTOR.depositToV4(address(spoke), amount);
  }

  function _seedExecutor(
    ITokenizationSpoke spoke
  ) internal returns (uint256 underlyingBalance, uint256 shares) {
    IERC20 underlying = IERC20(spoke.asset());
    uint256 seed = 10 ** spoke.decimals();
    deal(address(underlying), address(this), 2 * seed);
    underlying.forceApprove(address(spoke), seed);
    spoke.deposit(seed, address(this));
    return (underlying.balanceOf(address(this)), spoke.balanceOf(address(this)));
  }

  function _assertExecutorUntouched(
    ITokenizationSpoke spoke,
    uint256 underlyingBalance,
    uint256 shares
  ) internal view {
    assertEq(IERC20(spoke.asset()).balanceOf(address(this)), underlyingBalance);
    assertEq(spoke.balanceOf(address(this)), shares);
    assertEq(IERC20(spoke.asset()).allowance(address(this), address(spoke)), 0);
  }

  function _setAddCap(ITokenizationSpoke spoke, uint256 addCap) internal {
    address hub = spoke.hub();
    uint256 assetId = spoke.assetId();
    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    AaveV4Ethereum.HUB_CONFIGURATOR.updateSpokeAddCap({
      hub: hub,
      assetId: assetId,
      spoke: address(spoke),
      addCap: addCap
    });
  }

  function _setSpokeHalted(ITokenizationSpoke spoke) internal {
    address hub = spoke.hub();
    uint256 assetId = spoke.assetId();
    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    AaveV4Ethereum.HUB_CONFIGURATOR.updateSpokeHalted({
      hub: hub,
      assetId: assetId,
      spoke: address(spoke),
      halted: true
    });
  }

  function _setSpokeInactive(ITokenizationSpoke spoke) internal {
    address hub = spoke.hub();
    uint256 assetId = spoke.assetId();
    vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    AaveV4Ethereum.HUB_CONFIGURATOR.updateSpokeActive({
      hub: hub,
      assetId: assetId,
      spoke: address(spoke),
      active: false
    });
  }

  function depositToV4External(address spoke, uint256 amount) external returns (uint256) {
    return COLLECTOR.depositToV4(spoke, amount);
  }

  function depositToV3External(uint256 amount) external {
    COLLECTOR.depositToV3(
      CollectorUtils.IOInput({
        amount: amount,
        underlying: address(UNDERLYING),
        pool: address(V3_POOL)
      })
    );
  }

  function withdrawFromV3External(uint256 amount) external {
    COLLECTOR.withdrawFromV3(
      CollectorUtils.IOInput({
        amount: amount,
        underlying: address(UNDERLYING),
        pool: address(V3_POOL)
      }),
      testReceiver
    );
  }

  function withdrawFromV2External(uint256 amount) external {
    COLLECTOR.withdrawFromV2(
      CollectorUtils.IOInput({
        amount: amount,
        underlying: address(UNDERLYING),
        pool: address(V2_POOL)
      }),
      testReceiver
    );
  }

  function withdrawFromV4External(address spoke, uint256 amount) external returns (uint256) {
    return
      COLLECTOR.withdrawFromV4({tokenizationSpoke: spoke, amount: amount, receiver: testReceiver});
  }

  function streamExternal(uint256 amount) external {
    COLLECTOR.stream(
      CollectorUtils.CreateStreamInput({
        underlying: address(UNDERLYING),
        receiver: testReceiver,
        amount: amount,
        start: block.timestamp,
        duration: 1 days
      })
    );
  }

  function swapExternal(uint256 amount) external {
    COLLECTOR.swap(
      SWAPPER,
      CollectorUtils.SwapInput({
        milkman: address(0),
        priceChecker: address(0),
        fromUnderlying: address(UNDERLYING),
        toUnderlying: AaveV3EthereumAssets.USDT_UNDERLYING,
        fromUnderlyingPriceFeed: address(0),
        toUnderlyingPriceFeed: address(0),
        amount: amount,
        slippage: 0
      })
    );
  }
}

contract CollectorUtilsV4Payload {
  using CollectorUtils for ICollector;

  address public immutable TOKENIZATION_SPOKE;
  address public immutable RECEIVER;
  uint256 public immutable DEPOSIT_AMOUNT;
  uint256 public immutable WITHDRAW_AMOUNT;

  constructor(
    address tokenizationSpoke,
    address receiver,
    uint256 depositAmount,
    uint256 withdrawAmount
  ) {
    TOKENIZATION_SPOKE = tokenizationSpoke;
    RECEIVER = receiver;
    DEPOSIT_AMOUNT = depositAmount;
    WITHDRAW_AMOUNT = withdrawAmount;
  }

  function execute() external {
    AaveV3Ethereum.COLLECTOR.depositToV4(TOKENIZATION_SPOKE, DEPOSIT_AMOUNT);
    AaveV3Ethereum.COLLECTOR.withdrawFromV4({
      tokenizationSpoke: TOKENIZATION_SPOKE,
      amount: WITHDRAW_AMOUNT,
      receiver: RECEIVER
    });
  }
}
