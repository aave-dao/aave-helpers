// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IAccessControl} from 'openzeppelin-contracts/contracts/access/IAccessControl.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets, ICollector, IPool} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets, ILendingPool} from 'aave-address-book/AaveV2Ethereum.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {AaveV4EthereumTokenizationSpokes, ITokenizationSpoke} from 'aave-address-book/AaveV4Ethereum.sol';

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
  ITokenizationSpoke public constant SPOKE =
    AaveV4EthereumTokenizationSpokes.CORE_USDC_TOKENIZATION_SPOKE;

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

  function testWithdrawAllCollectorFundsFromV3() public {
    _genericWithdrawAllCollectorFundsToReceiver(
      address(V3_POOL),
      A_TOKEN_V3,
      CollectorUtils.withdrawFromV3,
      true
    );
  }

  function testWithdrawAllCollectorFundsFromV2() public {
    _genericWithdrawAllCollectorFundsToReceiver(
      address(V2_POOL),
      A_TOKEN_V2,
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
    assumeNotForgeAddress(milkman);
    assumeNotForgeAddress(priceChecker);
    assumeNotForgeAddress(toUnderlying);
    assumeNotForgeAddress(fromUnderlyingPriceFeed);
    assumeNotForgeAddress(toUnderlyingPriceFeed);
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
      assertApproxEqAbs(aTokenBalanceOfCollectorAfter, aTokenBalanceOfCollectorBefore - amount, 2);
    }
  }

  function _genericWithdrawAllCollectorFundsToReceiver(
    address pool,
    IERC20 aToken,
    function(ICollector, CollectorUtils.IOInput memory, address) returns (uint256) withdraw,
    bool withATokenCheck
  ) internal {
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
    // because we mint to treasury straight away on v2, hard to check the final amount we expect
    if (withATokenCheck) {
      assertApproxEqAbs(aToken.balanceOf(address(COLLECTOR)), 0, 2);
    }
  }

  function testDepositCollectorFundsToV4(uint128 amount) public {
    uint256 underlyingBalanceOfCollectorBefore = UNDERLYING.balanceOf(address(COLLECTOR));
    amount = uint128(bound(amount, 2, underlyingBalanceOfCollectorBefore));
    uint256 sharesOfCollectorBefore = SPOKE.balanceOf(address(COLLECTOR));
    uint256 expectedShares = SPOKE.previewDeposit(amount);

    uint256 shares = COLLECTOR.depositToV4(address(SPOKE), amount);

    assertEq(shares, expectedShares);
    assertEq(UNDERLYING.balanceOf(address(COLLECTOR)), underlyingBalanceOfCollectorBefore - amount);
    assertEq(SPOKE.balanceOf(address(COLLECTOR)), sharesOfCollectorBefore + shares);
    assertEq(UNDERLYING.allowance(address(this), address(SPOKE)), 0);
  }

  function testDepositAllCollectorFundsToV4() public {
    uint256 underlyingBalanceOfCollectorBefore = UNDERLYING.balanceOf(address(COLLECTOR));

    uint256 shares = COLLECTOR.depositToV4(address(SPOKE), type(uint256).max);

    assertEq(UNDERLYING.balanceOf(address(COLLECTOR)), 0);
    assertApproxEqAbs(SPOKE.convertToAssets(shares), underlyingBalanceOfCollectorBefore, 1);
  }

  function testDepositToV4RevertsOnZeroAmount() public {
    vm.expectRevert(CollectorUtils.InvalidZeroAmount.selector);
    this.depositToV4External(0);
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
    this.withdrawFromV4External(0);
  }

  function testStreamRevertsOnZeroAmount() public {
    vm.expectRevert(CollectorUtils.InvalidZeroAmount.selector);
    this.streamExternal(0);
  }

  function testSwapRevertsOnZeroAmount() public {
    vm.expectRevert(CollectorUtils.InvalidZeroAmount.selector);
    this.swapExternal(0);
  }

  function testWithdrawCollectorFundsFromV4(uint128 amount) public {
    COLLECTOR.depositToV4(address(SPOKE), type(uint256).max);
    uint256 sharesOfCollectorBefore = SPOKE.balanceOf(address(COLLECTOR));
    amount = uint128(bound(amount, 1, SPOKE.maxWithdraw(address(COLLECTOR))));
    uint256 underlyingBalanceOfReceiverBefore = UNDERLYING.balanceOf(testReceiver);
    uint256 expectedShares = SPOKE.previewWithdraw(amount);

    uint256 withdrawnAmount = COLLECTOR.withdrawFromV4(address(SPOKE), amount, testReceiver);

    assertEq(withdrawnAmount, amount);
    assertEq(UNDERLYING.balanceOf(testReceiver), underlyingBalanceOfReceiverBefore + amount);
    assertEq(SPOKE.balanceOf(address(COLLECTOR)), sharesOfCollectorBefore - expectedShares);
    assertEq(SPOKE.balanceOf(address(this)), 0);
  }

  function testWithdrawAllCollectorFundsFromV4() public {
    COLLECTOR.depositToV4(address(SPOKE), type(uint256).max);
    uint256 maxWithdrawBefore = SPOKE.maxWithdraw(address(COLLECTOR));
    uint256 underlyingBalanceOfReceiverBefore = UNDERLYING.balanceOf(testReceiver);

    uint256 withdrawnAmount = COLLECTOR.withdrawFromV4(
      address(SPOKE),
      type(uint256).max,
      testReceiver
    );

    assertEq(withdrawnAmount, maxWithdrawBefore);
    assertEq(
      UNDERLYING.balanceOf(testReceiver),
      underlyingBalanceOfReceiverBefore + withdrawnAmount
    );
    assertEq(SPOKE.maxWithdraw(address(COLLECTOR)), 0);
    assertEq(SPOKE.balanceOf(address(this)), 0);
  }

  function depositToV4External(uint256 amount) external {
    COLLECTOR.depositToV4(address(SPOKE), amount);
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

  function withdrawFromV4External(uint256 amount) external {
    COLLECTOR.withdrawFromV4(address(SPOKE), amount, testReceiver);
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
