// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {AaveV3Ethereum, AaveV3EthereumAssets, ICollector, IPool} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets, ILendingPool} from 'aave-address-book/AaveV2Ethereum.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';

import {CollectorUtils, IERC20, AaveSwapper, IChainlinkAggregator} from '../src/CollectorUtils.sol';

contract CollectorUtilsTest is Test {
  using CollectorUtils for ICollector;

  ICollector public constant COLLECTOR = AaveV3Ethereum.COLLECTOR;
  IERC20 public constant UNDERLYING = IERC20(AaveV3EthereumAssets.USDC_UNDERLYING);
  IERC20 public constant A_TOKEN_V2 = IERC20(AaveV2EthereumAssets.USDC_A_TOKEN);
  IERC20 public constant A_TOKEN_V3 = IERC20(AaveV3EthereumAssets.USDC_A_TOKEN);
  IPool public constant V3_POOL = AaveV3Ethereum.POOL;
  ILendingPool public constant V2_POOL = AaveV2Ethereum.POOL;
  address public constant SWAPPER = MiscEthereum.AAVE_SWAPPER;

  // using static address instead of fuzz address as it's slow on a non anvil fork
  address testReceiver = address(0xB0B);

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 20420006);

    vm.prank(COLLECTOR.getFundsAdmin());
    COLLECTOR.setFundsAdmin(address(this));
  }

  function testDepositCollectorFundsToV3(uint128 amount) public {
    uint256 underlyingBalanceOfCollectorBefore = UNDERLYING.balanceOf(address(COLLECTOR));
    vm.assume(amount <= underlyingBalanceOfCollectorBefore && amount != 0);
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
    assertApproxEqAbs(aTokenBalanceOfCollectorAfter, aTokenBalanceOfCollectorBefore + amount, 1);
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
      1
    );
  }

  function testWithdrawCollectorFundsFromV3(uint128 amount) public {
    _genericWithdrawCollectorFundsToReceiver(
      address(V3_POOL),
      A_TOKEN_V3,
      amount,
      testReceiver,
      CollectorUtils.withdrawFromV3,
      true
    );
  }

  function testWithdrawCollectorFundsFromV2(uint128 amount) public {
    _genericWithdrawCollectorFundsToReceiver(
      address(V2_POOL),
      A_TOKEN_V2,
      amount,
      testReceiver,
      CollectorUtils.withdrawFromV2,
      false
    );
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
    uint256 balance = UNDERLYING.balanceOf(address(COLLECTOR));
    vm.assume(amount <= balance && amount != 0);

    CollectorUtils.SwapInput memory input = CollectorUtils.SwapInput({
      milkman: milkman,
      priceChecker: priceChecker,
      fromUnderlying: address(UNDERLYING),
      toUnderlying: toUnderlying,
      fromUnderlyingPriceFeed: fromUnderlyingPriceFeed,
      toUnderlyingPriceFeed: toUnderlyingPriceFeed,
      amount: amount,
      slippage: slippage
    });

    uint256 balanceOfSwapperBefore = IERC20(input.fromUnderlying).balanceOf(SWAPPER);

    vm.expectCall(
      SWAPPER,
      abi.encodeCall(
        AaveSwapper.swap,
        (
          input.milkman,
          input.priceChecker,
          input.fromUnderlying,
          input.toUnderlying,
          input.fromUnderlyingPriceFeed,
          input.toUnderlyingPriceFeed,
          address(COLLECTOR),
          amount,
          input.slippage
        )
      )
    );
    vm.mockCall(
      SWAPPER,
      abi.encodeCall(
        AaveSwapper.swap,
        (
          input.milkman,
          input.priceChecker,
          input.fromUnderlying,
          input.toUnderlying,
          input.fromUnderlyingPriceFeed,
          input.toUnderlyingPriceFeed,
          address(COLLECTOR),
          amount,
          input.slippage
        )
      ),
      bytes('0')
    );
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
    COLLECTOR.swap(SWAPPER, input);
    uint256 balanceOfSwapperAfter = UNDERLYING.balanceOf(SWAPPER);

    assertEq(balanceOfSwapperAfter, balanceOfSwapperBefore + amount);
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
      assertApproxEqAbs(aTokenBalanceOfCollectorAfter, aTokenBalanceOfCollectorBefore - amount, 1);
    }
  }
}
