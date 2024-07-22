// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, stdStorage, StdStorage} from 'forge-std/Test.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';

import {AaveWstethWithdrawer} from '../../src/asset-manager/AaveWstethWithdrawer.sol';

contract AaveWstethWithdrawerTest is Test {
  using stdStorage for StdStorage;
  
  event StartedWithdrawal(uint256[] amounts, uint256 indexed index);

  event FinalizedWithdrawal(uint256 amount, uint256 indexed index);
  
  uint256 public constant EXISTING_UNSTETH_TOKENID = 46283;
  uint256 public constant WITHDRAWAL_AMOUNT = 999999999900;
  uint256 public constant FINALIZED_WITHDRAWAL_AMOUNT = 1173102309960;
  address public constant OWNER = GovernanceV3Ethereum.EXECUTOR_LVL_1;
  address public constant GUARDIAN = 0x2cc1ADE245020FC5AAE66Ad443e1F66e01c54Df1;
  address public constant COLLECTOR = address(AaveV3Ethereum.COLLECTOR);
  /// at block #20362610 0xb9b...A93 already has a UNSTETH token representing a 999999999900 wei withdrawal
  address public constant UNSTETH_OWNER = 0xb9b8F880dCF1bb34933fcDb375EEdE6252177A93;
  IERC20 public constant WETH = IERC20(AaveV3EthereumAssets.WETH_UNDERLYING);
  IERC20 public constant WSTETH = IERC20(AaveV3EthereumAssets.wstETH_UNDERLYING);
  /// although it's an ERC721 we cast to IERC20 because we are only interested in balanceOf(address)
  IERC20 public UNSTETH;

  AaveWstethWithdrawer public withdrawer;


  /// At current block oldWithdrawer (UNSTETH_OWNER) has an Lido withdrawal NFT
  ///   this NFT represents an WITHDRAWAL_AMOUNT of STETH that
  ///   yields FINALIZED_WITHDRAWAL_AMOUNT of ETH when completed.
  /// Most importantly, this withdrawal is ready to be finalized.
  /// We transfer the NFT to the withdrawer, and etch the resquestIds
  ///   into withdrawer at nextIndex to allow finalization.
  modifier withUnsteth() {
    vm.startPrank(OWNER);
    /// transfer the unSTETH to withdrawer
    AaveWstethWithdrawer(payable(UNSTETH_OWNER)).emergency721TokenTransfer(
      address(UNSTETH),
      address(withdrawer),
      46283
    );
    
    /// start an withdrawal to create the storage slot
    AaveV3Ethereum.COLLECTOR.transfer(
      address(WSTETH), 
      address(withdrawer), 
      WITHDRAWAL_AMOUNT
    );
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = WITHDRAWAL_AMOUNT;
    withdrawer.startWithdraw(amounts);
    vm.stopPrank();
    
    /// override the storage slot to the requestId respective to the unSTETH NFT 
    /// and the minCheckpointIndex
    AaveWstethWithdrawer oldWithdrawer = AaveWstethWithdrawer(payable(UNSTETH_OWNER));
    uint256 key = 0;
    uint256 reqId = 46283;
    uint256 minIndex = 429;
    stdstore
      .target(address(withdrawer))
      .sig('requestIds(uint256,uint256)')
      .with_key(key)
      .with_key(key)
      .checked_write(reqId);

    stdstore
      .target(address(withdrawer))
      .sig('minCheckpointIndex()')
      .checked_write(minIndex);
    _;
  }

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 20363790);
    withdrawer = AaveWstethWithdrawer(payable(0x9f489554d5909F372d80C88229E83dcB6629827a));
    UNSTETH = IERC20(address(withdrawer.WSETH_WITHDRAWAL_QUEUE()));
  }
}

contract TransferOwnership is AaveWstethWithdrawerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('Ownable: caller is not the owner');
    withdrawer.transferOwnership(makeAddr('new-admin'));
  }

  function test_successful() public {
    address newAdmin = makeAddr('new-admin');
    vm.startPrank(OWNER);
    withdrawer.transferOwnership(newAdmin);
    vm.stopPrank();

    assertEq(newAdmin, withdrawer.owner());
  }
}

contract UpdateGuardian is AaveWstethWithdrawerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    withdrawer.updateGuardian(makeAddr('new-admin'));
  }

  function test_successful() public {
    address newManager = makeAddr('new-admin');
    vm.startPrank(OWNER);
    withdrawer.updateGuardian(newManager);
    vm.stopPrank();

    assertEq(newManager, withdrawer.guardian());
  }
}

contract StartWithdrawal is AaveWstethWithdrawerTest {
  function test_revertsIf_invalidCaller() public {
    vm.prank(OWNER);
    AaveV3Ethereum.COLLECTOR.transfer(
      address(WSTETH), 
      address(withdrawer), 
      WITHDRAWAL_AMOUNT
    );
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = WITHDRAWAL_AMOUNT;
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    withdrawer.startWithdraw(amounts);
  }

  function test_startWithdrawalOwner() public {
    uint256 stEthBalanceBefore = WSTETH.balanceOf(address(withdrawer));
    uint256 lidoNftBalanceBefore = UNSTETH.balanceOf(address(withdrawer));
    uint256 nextIndex = withdrawer.nextIndex();

    vm.startPrank(OWNER);
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

  function test_startWithdrawalGuardian() public {
    uint256 stEthBalanceBefore = WSTETH.balanceOf(address(withdrawer));
    uint256 lidoNftBalanceBefore = UNSTETH.balanceOf(address(withdrawer));
    uint256 nextIndex = withdrawer.nextIndex();

    vm.prank(OWNER);
    AaveV3Ethereum.COLLECTOR.transfer(
      address(WSTETH), 
      address(withdrawer), 
      WITHDRAWAL_AMOUNT
    );
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = WITHDRAWAL_AMOUNT;
    vm.expectEmit(address(withdrawer));
    emit StartedWithdrawal(amounts, nextIndex);
    vm.prank(GUARDIAN);
    withdrawer.startWithdraw(amounts);

    uint256 stEthBalanceAfter = WSTETH.balanceOf(address(withdrawer));
    uint256 lidoNftBalanceAfter = UNSTETH.balanceOf(address(withdrawer));

    assertEq(stEthBalanceAfter, stEthBalanceBefore);
    assertEq(lidoNftBalanceAfter, lidoNftBalanceBefore + 1);
  }
}

contract FinalizeWithdrawal is AaveWstethWithdrawerTest {
  function test_finalizeWithdrawalGuardian() public withUnsteth {
    uint256 collectorBalanceBefore = WETH.balanceOf(COLLECTOR);
    vm.startPrank(GUARDIAN);
    vm.expectEmit(address(withdrawer));
    emit FinalizedWithdrawal(FINALIZED_WITHDRAWAL_AMOUNT, 0);
    withdrawer.finalizeWithdraw(0);
    vm.stopPrank();

    uint256 collectorBalanceAfter = WETH.balanceOf(COLLECTOR);

    assertEq(collectorBalanceAfter, collectorBalanceBefore + FINALIZED_WITHDRAWAL_AMOUNT);
  }

  function test_finalizeWithdrawalOwner() public withUnsteth {
    uint256 collectorBalanceBefore = WETH.balanceOf(COLLECTOR);
    vm.startPrank(OWNER);
    vm.expectEmit(address(withdrawer));
    emit FinalizedWithdrawal(FINALIZED_WITHDRAWAL_AMOUNT, 0);
    withdrawer.finalizeWithdraw(0);
    vm.stopPrank();

    uint256 collectorBalanceAfter = WETH.balanceOf(COLLECTOR);

    assertEq(collectorBalanceAfter, collectorBalanceBefore + FINALIZED_WITHDRAWAL_AMOUNT);
  }
  
  function test_finalizeWithdrawalWithExtraFunds() public withUnsteth {
    uint256 collectorBalanceBefore = WETH.balanceOf(COLLECTOR);

    /// send 1 wei to withdrawer
    vm.deal(address(withdrawer), 1);

    vm.startPrank(OWNER);
    vm.expectEmit(address(withdrawer));
    emit FinalizedWithdrawal(FINALIZED_WITHDRAWAL_AMOUNT + 1, 0);
    withdrawer.finalizeWithdraw(0);
    vm.stopPrank();

    uint256 collectorBalanceAfter = WETH.balanceOf(COLLECTOR);

    assertEq(collectorBalanceAfter, collectorBalanceBefore + FINALIZED_WITHDRAWAL_AMOUNT + 1);
  }
}

contract EmergencyTokenTransfer is AaveWstethWithdrawerTest {
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
    vm.startPrank(OWNER);
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

contract Emergency721TokenTransfer is AaveWstethWithdrawerTest {
  function test_revertsIf_invalidCaller() public withUnsteth {
    vm.expectRevert('ONLY_RESCUE_GUARDIAN');
    withdrawer.emergency721TokenTransfer(
      address(UNSTETH),
      COLLECTOR,
      EXISTING_UNSTETH_TOKENID
    );
  }

  function test_successful_governanceCaller() public withUnsteth {
    uint256 lidoNftBalanceBefore = UNSTETH.balanceOf(address(withdrawer));
    vm.startPrank(OWNER);
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