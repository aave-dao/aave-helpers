// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3Optimism, AaveV3OptimismAssets} from 'aave-address-book/AaveV3Optimism.sol';
import {GovernanceV3Optimism} from 'aave-address-book/GovernanceV3Optimism.sol';
import {IRescuable} from 'solidity-utils/contracts/utils/Rescuable.sol';

import {AaveOpEthERC20Bridge} from 'src/bridges/optimism/AaveOpEthERC20Bridge.sol';
import {IAaveOpEthERC20Bridge} from 'src/bridges/optimism/IAaveOpEthERC20Bridge.sol';

contract AaveOpEthERC20BridgeTest is Test {
  event Bridge(
    address indexed token,
    address indexed l1token,
    uint256 amount,
    address indexed to,
    uint256 nonce
  );

  address public constant WHALE = 0xe7804c37c13166fF0b37F5aE0BB07A3aEbb6e245;

  AaveOpEthERC20Bridge bridge;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('optimism'), 121507518);

    bytes32 salt = keccak256(abi.encode(tx.origin, uint256(0)));
    bridge = new AaveOpEthERC20Bridge{salt: salt}(address(this));
  }
}

contract BridgeTest is AaveOpEthERC20BridgeTest {
  function test_revertsIf_invalidChain() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 20110401);
    bytes32 salt = keccak256(abi.encode(tx.origin, uint256(0)));
    AaveOpEthERC20Bridge mainnetBridge = new AaveOpEthERC20Bridge{salt: salt}(address(this));

    vm.expectRevert(IAaveOpEthERC20Bridge.InvalidChain.selector);
    mainnetBridge.bridge(
      AaveV3OptimismAssets.USDC_UNDERLYING,
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6
    );
  }

  function test_revertsIf_notOwner() public {
    uint256 amount = 1_000e6;

    deal(AaveV3OptimismAssets.USDC_UNDERLYING, address(bridge), amount);

    bridge.transferOwnership(GovernanceV3Optimism.EXECUTOR_LVL_1);

    vm.expectRevert(
      abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this))
    );
    bridge.bridge(
      AaveV3OptimismAssets.USDC_UNDERLYING,
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6
    );
  }

  function test_successful() public {
    uint256 amount = 1_000e6;

    deal(AaveV3OptimismAssets.USDC_UNDERLYING, address(bridge), amount);

    bridge.transferOwnership(GovernanceV3Optimism.EXECUTOR_LVL_1);

    vm.startPrank(GovernanceV3Optimism.EXECUTOR_LVL_1);
    vm.expectEmit();
    emit Bridge(
      AaveV3OptimismAssets.USDC_UNDERLYING,
      AaveV3EthereumAssets.USDC_UNDERLYING,
      amount,
      address(AaveV3Ethereum.COLLECTOR),
      0
    );
    bridge.bridge(
      AaveV3OptimismAssets.USDC_UNDERLYING,
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6
    );
    vm.stopPrank();
  }
}

contract TransferOwnership is AaveOpEthERC20BridgeTest {
  function test_revertsIf_invalidCaller() public {
    address addr = makeAddr('random-caller');
    vm.startPrank(addr);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, addr));
    bridge.transferOwnership(makeAddr('new-admin'));
    vm.stopPrank();
  }

  function test_successful() public {
    address newAdmin = GovernanceV3Optimism.EXECUTOR_LVL_1;
    bridge.transferOwnership(newAdmin);

    assertEq(newAdmin, bridge.owner());
  }
}

contract EmergencyTokenTransfer is AaveOpEthERC20BridgeTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert(IRescuable.OnlyRescueGuardian.selector);
    vm.startPrank(makeAddr('random-caller'));
    bridge.emergencyTokenTransfer(
      AaveV3OptimismAssets.USDC_UNDERLYING,
      address(AaveV3Optimism.COLLECTOR),
      1_000e6
    );
    vm.stopPrank();
  }

  function test_successful_governanceCaller() public {
    assertEq(IERC20(AaveV3OptimismAssets.USDC_UNDERLYING).balanceOf(address(bridge)), 0);

    uint256 usdcAmount = 1_000e18;

    deal(AaveV3OptimismAssets.USDC_UNDERLYING, address(bridge), usdcAmount);

    assertEq(IERC20(AaveV3OptimismAssets.USDC_UNDERLYING).balanceOf(address(bridge)), usdcAmount);

    uint256 initialCollectorBalBalance = IERC20(AaveV3OptimismAssets.USDC_UNDERLYING).balanceOf(
      address(AaveV3Optimism.COLLECTOR)
    );

    bridge.emergencyTokenTransfer(
      AaveV3OptimismAssets.USDC_UNDERLYING,
      address(AaveV3Optimism.COLLECTOR),
      usdcAmount
    );

    assertEq(
      IERC20(AaveV3OptimismAssets.USDC_UNDERLYING).balanceOf(address(AaveV3Optimism.COLLECTOR)),
      initialCollectorBalBalance + usdcAmount
    );
    assertEq(IERC20(AaveV3OptimismAssets.USDC_UNDERLYING).balanceOf(address(bridge)), 0);
  }
}
