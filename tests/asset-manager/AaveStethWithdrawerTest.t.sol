// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';

import {AaveStethWithdrawer} from '../../src/asset-manager/AaveStethWithdrawer.sol';

contract AaveStethWithdrawerTest is Test {
  event DepositedIntoV2(address indexed token, uint256 amount);
  event DepositedIntoV3(address indexed token, uint256 amount);
  event GuardianUpdated(address oldGuardian, address newGuardian);
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
  event TokenUpdated(address indexed token, bool allowed);

  address public constant BAL80WETH20 = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
  address public constant BPT_PRICE_CHECKER = 0xBeA6AAC5bDCe0206A9f909d80a467C93A7D6Da7c;
  address public constant CHAINLINK_PRICE_CHECKER = 0xe80a1C615F75AFF7Ed8F08c9F21f9d00982D666c;
  address public constant MILKMAN = 0x11C76AD590ABDFFCD980afEC9ad951B160F02797;

  address public constant EXECUTOR = GovernanceV3Ethereum.EXECUTOR_LVL_1;

  AaveStethWithdrawer public withdrawer;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 20190643);
    /// TODO deal some steth to bob
    /// etch withdrawer into first deploy address and use checkpoint to try to withdraw
    // etch requestIds and lastindex too
    withdrawer = new AaveStethWithdrawer(EXECUTOR);
  }
}

// contract Initialize is AaveSwapperTest {
//   function test_revertsIf_alreadyInitialized() public {
//     vm.expectRevert('Initializable: contract is already initialized');
//     swaps.initialize();
//   }
// }

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

contract StartWithdraw is AaveStethWithdrawerTest {
  function test_startWithdrawal() public {
    
  }
}


// contract UpdateGuardian is AaveStethWithdrawerTest {
//   function test_revertsIf_invalidCaller() public {
//     vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
//     withdrawer.updateGuardian(makeAddr('new-admin'));
//   }

//   function test_successful() public {
//     address newManager = makeAddr('new-admin');
//     vm.expectEmit();
//     emit GuardianUpdated(withdrawer.guardian(), newManager);
//     vm.startPrank(EXECUTOR);
//     withdrawer.updateGuardian(newManager);
//     vm.stopPrank();

//     assertEq(newManager, withdrawer.guardian());
//   }
// }

// contract RemoveGuardian is AaveStethWithdrawerTest {
//   function test_revertsIf_invalidCaller() public {
//     vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
//     withdrawer.updateGuardian(address(0));
//   }

//   function test_successful() public {
//     vm.expectEmit();
//     emit GuardianUpdated(withdrawer.guardian(), address(0));
//     vm.startPrank(EXECUTOR);
//     withdrawer.updateGuardian(address(0));
//     vm.stopPrank();

//     assertEq(address(0), withdrawer.guardian());
//   }
// }

// contract AaveWithdrawerWithdraw is AaveStethWithdrawerTest {
//   function test_revertsIf_invalidCaller() public {
//     uint256 amount = 1_000e18;
//     vm.expectRevert('Ownable: caller is not the owner');
//     swaps.swap(
//       MILKMAN,
//       CHAINLINK_PRICE_CHECKER,
//       AaveV2EthereumAssets.WETH_UNDERLYING,
//       AaveV2EthereumAssets.AAVE_UNDERLYING,
//       address(0),
//       AaveV2EthereumAssets.AAVE_ORACLE,
//       address(AaveV2Ethereum.COLLECTOR),
//       amount,
//       200
//     );
//   }

//   function test_revertsIf_amountIsZero() public {
//     vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
//     vm.expectRevert(AaveSwapper.InvalidAmount.selector);
//     swaps.swap(
//       MILKMAN,
//       CHAINLINK_PRICE_CHECKER,
//       AaveV2EthereumAssets.WETH_UNDERLYING,
//       AaveV2EthereumAssets.AAVE_UNDERLYING,
//       address(0),
//       AaveV2EthereumAssets.AAVE_ORACLE,
//       address(AaveV2Ethereum.COLLECTOR),
//       0,
//       200
//     );
//     vm.stopPrank();
//   }

//   function test_revertsIf_fromTokenIsZeroAddress() public {
//     vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
//     vm.expectRevert(AaveSwapper.Invalid0xAddress.selector);
//     swaps.swap(
//       MILKMAN,
//       CHAINLINK_PRICE_CHECKER,
//       address(0),
//       AaveV2EthereumAssets.AAVE_UNDERLYING,
//       address(0),
//       AaveV2EthereumAssets.AAVE_ORACLE,
//       address(AaveV2Ethereum.COLLECTOR),
//       1_000e18,
//       200
//     );
//     vm.stopPrank();
//   }

//   function test_revertsIf_toTokenIsZeroAddress() public {
//     vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
//     vm.expectRevert(AaveSwapper.Invalid0xAddress.selector);
//     swaps.swap(
//       MILKMAN,
//       CHAINLINK_PRICE_CHECKER,
//       AaveV2EthereumAssets.WETH_UNDERLYING,
//       address(0),
//       address(0),
//       AaveV2EthereumAssets.AAVE_ORACLE,
//       address(AaveV2Ethereum.COLLECTOR),
//       1_000e18,
//       200
//     );
//     vm.stopPrank();
//   }

//   function test_revertsIf_invalidRecipient() public {
//     vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
//     vm.expectRevert(AaveSwapper.InvalidRecipient.selector);
//     swaps.swap(
//       MILKMAN,
//       CHAINLINK_PRICE_CHECKER,
//       AaveV2EthereumAssets.AAVE_UNDERLYING,
//       AaveV2EthereumAssets.USDC_UNDERLYING,
//       AaveV2EthereumAssets.AAVE_ORACLE,
//       AaveV2EthereumAssets.USDC_ORACLE,
//       address(0),
//       1_000e18,
//       200
//     );
//     vm.stopPrank();
//   }

//   function test_successful() public {
//     deal(AaveV2EthereumAssets.AAVE_UNDERLYING, address(swaps), 1_000e18);
//     vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);

//     vm.expectEmit(true, true, true, true);
//     emit SwapRequested(
//       MILKMAN,
//       AaveV2EthereumAssets.AAVE_UNDERLYING,
//       AaveV2EthereumAssets.USDC_UNDERLYING,
//       AaveV2EthereumAssets.AAVE_ORACLE,
//       AaveV2EthereumAssets.USDC_ORACLE,
//       1_000e18,
//       address(AaveV2Ethereum.COLLECTOR),
//       200
//     );
//     swaps.swap(
//       MILKMAN,
//       CHAINLINK_PRICE_CHECKER,
//       AaveV2EthereumAssets.AAVE_UNDERLYING,
//       AaveV2EthereumAssets.USDC_UNDERLYING,
//       AaveV2EthereumAssets.AAVE_ORACLE,
//       AaveV2EthereumAssets.USDC_ORACLE,
//       address(AaveV2Ethereum.COLLECTOR),
//       1_000e18,
//       200
//     );
//     vm.stopPrank();
//   }
// }

// contract CancelSwap is AaveSwapperTest {
//   function test_revertsIf_invalidCaller() public {
//     uint256 amount = 1_000e18;
//     vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
//     swaps.cancelSwap(
//       makeAddr('milkman-instance'),
//       CHAINLINK_PRICE_CHECKER,
//       AaveV2EthereumAssets.WETH_UNDERLYING,
//       AaveV2EthereumAssets.AAVE_UNDERLYING,
//       address(0),
//       AaveV2EthereumAssets.AAVE_ORACLE,
//       address(AaveV2Ethereum.COLLECTOR),
//       amount,
//       200
//     );
//   }

//   function test_revertsIf_noMatchingTrade() public {
//     deal(AaveV2EthereumAssets.AAVE_UNDERLYING, address(swaps), 1_000e18);
//     vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
//     swaps.swap(
//       MILKMAN,
//       CHAINLINK_PRICE_CHECKER,
//       AaveV2EthereumAssets.AAVE_UNDERLYING,
//       AaveV2EthereumAssets.USDC_UNDERLYING,
//       AaveV2EthereumAssets.AAVE_ORACLE,
//       AaveV2EthereumAssets.USDC_ORACLE,
//       address(AaveV2Ethereum.COLLECTOR),
//       1_000e18,
//       200
//     );

//     vm.expectRevert();
//     swaps.cancelSwap(
//       makeAddr('not-milkman-instance'),
//       CHAINLINK_PRICE_CHECKER,
//       AaveV2EthereumAssets.AAVE_UNDERLYING,
//       AaveV2EthereumAssets.USDC_UNDERLYING,
//       AaveV2EthereumAssets.AAVE_ORACLE,
//       AaveV2EthereumAssets.USDC_ORACLE,
//       address(AaveV2Ethereum.COLLECTOR),
//       1_000e18,
//       200
//     );
//     vm.stopPrank();
//   }

//   function test_successful() public {
//     deal(AaveV2EthereumAssets.AAVE_UNDERLYING, address(swaps), 1_000e18);
//     vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);

//     vm.expectEmit(true, true, true, true);
//     emit SwapRequested(
//       MILKMAN,
//       AaveV2EthereumAssets.AAVE_UNDERLYING,
//       AaveV2EthereumAssets.USDC_UNDERLYING,
//       AaveV2EthereumAssets.AAVE_ORACLE,
//       AaveV2EthereumAssets.USDC_ORACLE,
//       1_000e18,
//       address(AaveV2Ethereum.COLLECTOR),
//       200
//     );
//     swaps.swap(
//       MILKMAN,
//       CHAINLINK_PRICE_CHECKER,
//       AaveV2EthereumAssets.AAVE_UNDERLYING,
//       AaveV2EthereumAssets.USDC_UNDERLYING,
//       AaveV2EthereumAssets.AAVE_ORACLE,
//       AaveV2EthereumAssets.USDC_ORACLE,
//       address(AaveV2Ethereum.COLLECTOR),
//       1_000e18,
//       200
//     );

//     vm.expectEmit();
//     emit SwapCanceled(
//       AaveV2EthereumAssets.AAVE_UNDERLYING,
//       AaveV2EthereumAssets.USDC_UNDERLYING,
//       1_000e18
//     );
//     swaps.cancelSwap(
//       0x7e05Cf4Ba19B4DF16d1c37845cF925e3Ba1f190b, // Address generated by tests
//       CHAINLINK_PRICE_CHECKER,
//       AaveV2EthereumAssets.AAVE_UNDERLYING,
//       AaveV2EthereumAssets.USDC_UNDERLYING,
//       AaveV2EthereumAssets.AAVE_ORACLE,
//       AaveV2EthereumAssets.USDC_ORACLE,
//       address(AaveV2Ethereum.COLLECTOR),
//       1_000e18,
//       200
//     );
//     vm.stopPrank();
//   }
// }

// contract EmergencyTokenTransfer is AaveSwapperTest {
//   function test_revertsIf_invalidCaller() public {
//     vm.expectRevert('ONLY_RESCUE_GUARDIAN');
//     swaps.emergencyTokenTransfer(
//       AaveV2EthereumAssets.BAL_UNDERLYING,
//       address(AaveV2Ethereum.COLLECTOR),
//       1_000e6
//     );
//   }

//   function test_successful_governanceCaller() public {
//     address AAVE_WHALE = 0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8;

//     assertEq(IERC20(AaveV2EthereumAssets.AAVE_UNDERLYING).balanceOf(address(swaps)), 0);

//     uint256 aaveAmount = 1_000e18;

//     vm.startPrank(AAVE_WHALE);
//     IERC20(AaveV2EthereumAssets.AAVE_UNDERLYING).transfer(address(swaps), aaveAmount);
//     vm.stopPrank();

//     assertEq(IERC20(AaveV2EthereumAssets.AAVE_UNDERLYING).balanceOf(address(swaps)), aaveAmount);

//     uint256 initialCollectorUsdcBalance = IERC20(AaveV2EthereumAssets.AAVE_UNDERLYING).balanceOf(
//       address(AaveV2Ethereum.COLLECTOR)
//     );

//     vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
//     swaps.emergencyTokenTransfer(
//       AaveV2EthereumAssets.AAVE_UNDERLYING,
//       address(AaveV2Ethereum.COLLECTOR),
//       aaveAmount
//     );
//     vm.stopPrank();

//     assertEq(
//       IERC20(AaveV2EthereumAssets.AAVE_UNDERLYING).balanceOf(address(AaveV2Ethereum.COLLECTOR)),
//       initialCollectorUsdcBalance + aaveAmount
//     );
//     assertEq(IERC20(AaveV2EthereumAssets.AAVE_UNDERLYING).balanceOf(address(swaps)), 0);
//   }
// }

// contract GetExpectedOut is AaveSwapperTest {
//   function test_revertsIf_fromOracleIsAddressZero() public {
//     uint256 amount = 1e18;
//     vm.expectRevert(AaveSwapper.OracleNotSet.selector);
//     swaps.getExpectedOut(
//       CHAINLINK_PRICE_CHECKER,
//       amount,
//       AaveV2EthereumAssets.AAVE_UNDERLYING,
//       AaveV2EthereumAssets.USDC_UNDERLYING,
//       address(0),
//       AaveV2EthereumAssets.USDC_ORACLE
//     );
//   }

//   function test_revertsIf_toOracleIsAddressZero() public {
//     uint256 amount = 1e18;
//     vm.expectRevert(AaveSwapper.OracleNotSet.selector);
//     swaps.getExpectedOut(
//       CHAINLINK_PRICE_CHECKER,
//       amount,
//       AaveV2EthereumAssets.AAVE_UNDERLYING,
//       AaveV2EthereumAssets.USDC_UNDERLYING,
//       AaveV2EthereumAssets.AAVE_ORACLE,
//       address(0)
//     );
//   }

//   function test_aaveToUsdc_withEthBasedOracles() public {
//     /* This test is only to show that oracles with the same base
//      * will return the correct value for trading, or at least very
//      * close to USD based oracles. Nonetheless, ETH based oracles
//      * should not be used. Please ensure only USD based oracles are
//      * set for trading.
//      * Using different bases in a swap can lead to destructive results.
//      */
//     uint256 amount = 1e18;
//     uint256 expected = swaps.getExpectedOut(
//       CHAINLINK_PRICE_CHECKER,
//       amount,
//       AaveV2EthereumAssets.AAVE_UNDERLYING,
//       AaveV2EthereumAssets.USDC_UNDERLYING,
//       AaveV2EthereumAssets.AAVE_ORACLE,
//       AaveV2EthereumAssets.USDC_ORACLE
//     );

//     // April 25, 2024 AAVE/USD is around $90
//     assertEq(expected / 1e4, 8941); // USDC is 6 decimals
//   }

//   function test_aaveToUsdc() public {
//     uint256 amount = 1e18;
//     uint256 expected = swaps.getExpectedOut(
//       CHAINLINK_PRICE_CHECKER,
//       amount,
//       AaveV3EthereumAssets.AAVE_UNDERLYING,
//       AaveV3EthereumAssets.USDC_UNDERLYING,
//       AaveV3EthereumAssets.AAVE_ORACLE,
//       AaveV3EthereumAssets.USDC_ORACLE
//     );

//     // April 25, 2024 AAVE/USD is around $90
//     assertEq(expected / 1e4, 9002); // USDC is 6 decimals
//   }

//   function test_ethToDai() public {
//     uint256 amount = 1e18;
//     uint256 expected = swaps.getExpectedOut(
//       CHAINLINK_PRICE_CHECKER,
//       amount,
//       AaveV3EthereumAssets.WETH_UNDERLYING,
//       AaveV3EthereumAssets.DAI_UNDERLYING,
//       AaveV3EthereumAssets.WETH_ORACLE,
//       AaveV3EthereumAssets.DAI_ORACLE
//     );

//     // April 25, 2024 ETH/USD is around $3,122
//     assertEq(expected / 1e18, 3122); // WETH is 18 decimals
//   }

//   function test_ethToBal() public {
//     uint256 amount = 1e18;
//     uint256 expected = swaps.getExpectedOut(
//       CHAINLINK_PRICE_CHECKER,
//       amount,
//       AaveV3EthereumAssets.WETH_UNDERLYING,
//       AaveV3EthereumAssets.BAL_UNDERLYING,
//       AaveV3EthereumAssets.WETH_ORACLE,
//       AaveV3EthereumAssets.BAL_ORACLE
//     );

//     // April 25, 2024 ETH/BAL is 1 ETH is around 823 BAL tokens
//     assertEq(expected / 1e18, 823); // WETH and BAL are 18 decimals
//   }

//   function test_balTo80BAL20WETH() public {
//     uint256 amount = 100e18;
//     uint256 expected = swaps.getExpectedOut(
//       BPT_PRICE_CHECKER,
//       amount,
//       AaveV3EthereumAssets.BAL_UNDERLYING,
//       BAL80WETH20,
//       address(0),
//       address(0)
//     );

//     // April 25, 2024 BAL/USD should be around 0.30 at 100 units traded, 30 units expected.
//     assertEq(expected / 1e18, 30); // WETH and BAL are 18 decimals
//   }
// }
