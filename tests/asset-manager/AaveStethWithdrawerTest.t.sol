// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {stdStorage, StdStorage} from 'forge-std/Test.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';

import {AaveStethWithdrawer} from '../../src/asset-manager/AaveStethWithdrawer.sol';

contract AaveStethWithdrawerTest is Test {
  using stdStorage for StdStorage;

  event StartedWithdrawal(uint256[] amounts, uint256 index);

  event FinalizedWithdrawal(uint256 amount, uint256 index);

  address public constant EXECUTOR = GovernanceV3Ethereum.EXECUTOR_LVL_1;
  address public constant COLLECTOR = address(AaveV3Ethereum.COLLECTOR);
  IERC20 public constant WETH = IERC20(AaveV3EthereumAssets.WETH_UNDERLYING);
  IERC20 public constant WSTETH = IERC20(AaveV3EthereumAssets.wstETH_UNDERLYING);
  /// although it's an ERC721 we cast to IERC20 because we are only interested in balanceOf(address)
  IERC20 public UNSTETH;

  AaveStethWithdrawer public withdrawer;
  AaveStethWithdrawer public withdrawerReadyToWithdraw;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 20197457);
    
    withdrawer = new AaveStethWithdrawer(EXECUTOR);
    UNSTETH = IERC20(address(withdrawer.WSETH_WITHDRAWAL_QUEUE()));
    bytes memory code = address(withdrawer).code;

    /// At current block 0x3169db has an Lido withdrawal NFT
    ///   this NFT represents an 100 wei STETH withdrawal that
    ///   yields 115 wei of ETH when completed.
    /// Most importantly, this withdrawal is ready to be finalized.
    /// We etch our code into this to circumvent havign to mock
    ///   Lido's internal processes to allow native withdrawals.
    vm.etch(0x3169db715E8DE11B48a27B40bD80CbfF5d9620f4, code);
    withdrawerReadyToWithdraw = AaveStethWithdrawer(payable(0x3169db715E8DE11B48a27B40bD80CbfF5d9620f4));
    /// we also override owner(), as 0x3169db is a prev implementation of AaveStethWithdrawer
    /// that was used as a live proof of concept
    stdstore.target(address(withdrawerReadyToWithdraw)).sig('owner()').checked_write(
      EXECUTOR
    );
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

    vm.startPrank(EXECUTOR);
    AaveV3Ethereum.COLLECTOR.transfer(
      address(WSTETH), 
      address(withdrawer), 
      100
    );
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = 100;
    vm.expectEmit(address(withdrawer));
    emit StartedWithdrawal(amounts, 0);
    withdrawer.startWithdraw(amounts);
    vm.stopPrank();

    uint256 stEthBalanceAfter = WSTETH.balanceOf(address(withdrawer));
    uint256 lidoNftBalanceAfter = UNSTETH.balanceOf(address(withdrawer));

    assertEq(stEthBalanceAfter, 0);
    assertEq(lidoNftBalanceAfter, 1);
  }
}

contract FinalizeWithdrawal is AaveStethWithdrawerTest {
  function test_finalizeWithdrawal() public {
    uint256 collectorBalanceBefore = WETH.balanceOf(COLLECTOR);

    vm.startPrank(EXECUTOR);
    vm.expectEmit(address(withdrawerReadyToWithdraw));
    emit FinalizedWithdrawal(115, 0);
    withdrawerReadyToWithdraw.finalizeWithdraw(0);
    vm.stopPrank();

    uint256 collectorBalanceAfter = WETH.balanceOf(COLLECTOR);

    assertEq(collectorBalanceAfter, collectorBalanceBefore + 115);
  }
}

contract EmergencyTokenTransfer is AaveStethWithdrawerTest {
  function test_revertsIf_invalidCaller() public {
    deal(address(WSTETH), address(withdrawer), 100);
    vm.expectRevert('ONLY_RESCUE_GUARDIAN');
    withdrawer.emergencyTokenTransfer(
      address(WSTETH),
      COLLECTOR,
      100
    );
  }

  function test_successful_governanceCaller() public {
    uint256 initialCollectorBalance = WSTETH.balanceOf(COLLECTOR);
    deal(address(WSTETH), address(withdrawer), 100);
    vm.startPrank(EXECUTOR);
    withdrawer.emergencyTokenTransfer(
      address(WSTETH),
      COLLECTOR,
      100
    );
    vm.stopPrank();

    assertEq(
      WSTETH.balanceOf(COLLECTOR),
      initialCollectorBalance + 100
    );
    assertEq(WSTETH.balanceOf(address(withdrawer)), 0);
  }
}


// TODO after Rescuable721 is merged into bgd/solidity-utils
// contract Emergency721TokenTransfer is AaveStethWithdrawerTest {
//   function test_revertsIf_invalidCaller() public {
//     deal(address(WSTETH), address(withdrawer), 100);
//     vm.expectRevert('ONLY_RESCUE_GUARDIAN');
//     withdrawer.emergencyTokenTransfer(
//       address(WSTETH),
//       COLLECTOR,
//       100
//     );
//   }

//   function test_successful_governanceCaller() public {
//     uint256 initialCollectorBalance = WSTETH.balanceOf(COLLECTOR);
//     deal(address(WSTETH), address(withdrawer), 100);
//     vm.startPrank(EXECUTOR);
//     withdrawer.emergencyTokenTransfer(
//       address(WSTETH),
//       COLLECTOR,
//       100
//     );
//     vm.stopPrank();

//     assertEq(
//       WSTETH.balanceOf(COLLECTOR),
//       initialCollectorBalance + 100
//     );
//     assertEq(WSTETH.balanceOf(address(withdrawer)), 0);
//   }
// }
