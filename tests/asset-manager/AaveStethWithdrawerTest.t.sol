// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';

import {AaveStethWithdrawer} from '../../src/asset-manager/AaveStethWithdrawer.sol';

contract AaveStethWithdrawerTest is Test {

  event StartedWithdrawal(uint256[] amounts, uint256 indexed index);

  event FinalizedWithdrawal(uint256 amount, uint256 indexed index);
  
  /// at block #20334488 0xb9b...A93 already has a UNSTETH token representing a 100 wei withdrawal
  uint256 public constant EXISTING_UNSTETH_TOKENID = 46223;
  uint256 public constant WITHDRAWAL_AMOUNT = 100;
  uint256 public constant FINALIZED_WITHDRAWAL_AMOUNT = 116;
  address public constant EXECUTOR = GovernanceV3Ethereum.EXECUTOR_LVL_1;
  address public constant COLLECTOR = address(AaveV3Ethereum.COLLECTOR);
  IERC20 public constant WETH = IERC20(AaveV3EthereumAssets.WETH_UNDERLYING);
  IERC20 public constant WSTETH = IERC20(AaveV3EthereumAssets.wstETH_UNDERLYING);
  /// although it's an ERC721 we cast to IERC20 because we are only interested in balanceOf(address)
  IERC20 public UNSTETH;

  AaveStethWithdrawer public withdrawer;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 20334488);
    withdrawer = AaveStethWithdrawer(payable(0xb9b8F880dCF1bb34933fcDb375EEdE6252177A93));
    UNSTETH = IERC20(address(withdrawer.WSETH_WITHDRAWAL_QUEUE()));
  }
}

contract TransferOwnership is AaveStethWithdrawerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('Ownable: caller is not the owner');
    withdrawer.transferOwnership(makeAddr('new-admin'));
  }

  function test_successful() public {
    address newAdmin = makeAddr('new-admin');
    vm.startPrank(EXECUTOR);
    withdrawer.transferOwnership(newAdmin);
    vm.stopPrank();

    assertEq(newAdmin, withdrawer.owner());
  }
}

contract StartWithdrawal is AaveStethWithdrawerTest {
  function test_startWithdrawal() public {

    uint256 stEthBalanceBefore = WSTETH.balanceOf(address(withdrawer));
    uint256 lidoNftBalanceBefore = UNSTETH.balanceOf(address(withdrawer));
    uint256 nextIndex = withdrawer.nextIndex();

    vm.startPrank(EXECUTOR);
    AaveV3Ethereum.COLLECTOR.transfer(
      address(WSTETH), 
      address(withdrawer), 
      WITHDRAWAL_AMOUNT
    );
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = WITHDRAWAL_AMOUNT;
    vm.expectEmit(address(withdrawer));
    emit StartedWithdrawal(amounts, nextIndex);
    withdrawer.startWithdraw(amounts);
    vm.stopPrank();

    uint256 stEthBalanceAfter = WSTETH.balanceOf(address(withdrawer));
    uint256 lidoNftBalanceAfter = UNSTETH.balanceOf(address(withdrawer));

    assertEq(stEthBalanceAfter, stEthBalanceBefore);
    assertEq(lidoNftBalanceAfter, lidoNftBalanceBefore + 1);
  }
}

contract FinalizeWithdrawal is AaveStethWithdrawerTest {
  function test_finalizeWithdrawal() public {
    uint256 collectorBalanceBefore = WETH.balanceOf(COLLECTOR);

    vm.startPrank(EXECUTOR);
    vm.expectEmit(address(withdrawer));
    emit FinalizedWithdrawal(FINALIZED_WITHDRAWAL_AMOUNT, 0);
    withdrawer.finalizeWithdraw(0);
    vm.stopPrank();

    uint256 collectorBalanceAfter = WETH.balanceOf(COLLECTOR);

    assertEq(collectorBalanceAfter, collectorBalanceBefore + FINALIZED_WITHDRAWAL_AMOUNT);
  }
  
  function test_finalizeWithdrawalWithExtraFunds() public {
    uint256 collectorBalanceBefore = WETH.balanceOf(COLLECTOR);

    /// send 1 wei to withdrawer
    vm.deal(address(withdrawer), 1);

    vm.startPrank(EXECUTOR);
    vm.expectEmit(address(withdrawer));
    emit FinalizedWithdrawal(FINALIZED_WITHDRAWAL_AMOUNT + 1, 0);
    withdrawer.finalizeWithdraw(0);
    vm.stopPrank();

    uint256 collectorBalanceAfter = WETH.balanceOf(COLLECTOR);

    assertEq(collectorBalanceAfter, collectorBalanceBefore + FINALIZED_WITHDRAWAL_AMOUNT + 1);
  }
}

contract EmergencyTokenTransfer is AaveStethWithdrawerTest {
  function test_revertsIf_invalidCaller() public {
    deal(address(WSTETH), address(withdrawer), WITHDRAWAL_AMOUNT);
    vm.expectRevert('ONLY_RESCUE_GUARDIAN');
    withdrawer.emergencyTokenTransfer(
      address(WSTETH),
      COLLECTOR,
      WITHDRAWAL_AMOUNT
    );
  }

  function test_successful_governanceCaller() public {
    uint256 initialCollectorBalance = WSTETH.balanceOf(COLLECTOR);
    deal(address(WSTETH), address(withdrawer), WITHDRAWAL_AMOUNT);
    vm.startPrank(EXECUTOR);
    withdrawer.emergencyTokenTransfer(
      address(WSTETH),
      COLLECTOR,
      WITHDRAWAL_AMOUNT
    );
    vm.stopPrank();

    assertEq(
      WSTETH.balanceOf(COLLECTOR),
      initialCollectorBalance + WITHDRAWAL_AMOUNT
    );
    assertEq(WSTETH.balanceOf(address(withdrawer)), 0);
  }
}

contract Emergency721TokenTransfer is AaveStethWithdrawerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_RESCUE_GUARDIAN');
    withdrawer.emergency721TokenTransfer(
      address(UNSTETH),
      COLLECTOR,
      EXISTING_UNSTETH_TOKENID
    );
  }

  function test_successful_governanceCaller() public {
    uint256 lidoNftBalanceBefore = UNSTETH.balanceOf(address(withdrawer));
    vm.startPrank(EXECUTOR);
    withdrawer.emergency721TokenTransfer(
      address(UNSTETH),
      COLLECTOR,
      EXISTING_UNSTETH_TOKENID
    );
    vm.stopPrank();

    uint256 lidoNftBalanceAfter = UNSTETH.balanceOf(address(withdrawer));

    assertEq(
      UNSTETH.balanceOf(COLLECTOR),
      1
    );
    assertEq(lidoNftBalanceAfter, lidoNftBalanceBefore - 1);
  }
}
