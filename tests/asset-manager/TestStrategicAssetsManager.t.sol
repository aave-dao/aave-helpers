// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {AaveV2Ethereum} from 'aave-address-book/AaveV2Ethereum.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';

import {StrategicAssetsManager} from '../../src/asset-manager/StrategicAssetsManager.sol';
import {VeTokenManager} from '../../src/asset-manager/VeTokenManager.sol';
import {Common} from '../../src/asset-manager/Common.sol';

contract StrategicAssetsManagerTest is Test {
  event GuardianUpdated(address oldGuardian, address newGuardian);
  event WithdrawalERC20(address indexed _token, uint256 _amount);

  // VeToken
  address public constant B_80BAL_20WETH = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;

  StrategicAssetsManager public strategicAssets;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 17523941);

    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets = new StrategicAssetsManager();
    vm.stopPrank();
  }
}

contract Initialize is StrategicAssetsManagerTest {
  function test_revertsIf_alreadyInitialized() public {
    vm.expectRevert('Initializable: contract is already initialized');
    strategicAssets.initialize();
  }
}

contract TransferOwnership is StrategicAssetsManagerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('Ownable: caller is not the owner');
    strategicAssets.transferOwnership(makeAddr('new-admin'));
  }

  function test_successful() public {
    address newAdmin = makeAddr('new-admin');
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.transferOwnership(newAdmin);
    vm.stopPrank();

    assertEq(newAdmin, strategicAssets.owner());
  }
}

contract SetStrategicAssetManager is StrategicAssetsManagerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    strategicAssets.updateGuardian(makeAddr('new-admin'));
  }

  function test_successful() public {
    address newManager = makeAddr('new-admin');
    vm.expectEmit();
    emit GuardianUpdated(strategicAssets.guardian(), newManager);
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.updateGuardian(newManager);
    vm.stopPrank();

    assertEq(newManager, strategicAssets.guardian());
  }
}

contract RemoveStrategicAssetManager is StrategicAssetsManagerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    strategicAssets.updateGuardian(address(0));
  }

  function test_successful() public {
    vm.expectEmit();
    emit GuardianUpdated(strategicAssets.guardian(), address(0));
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.updateGuardian(address(0));
    vm.stopPrank();

    assertEq(address(0), strategicAssets.guardian());
  }
}

contract WithdrawERC20 is StrategicAssetsManagerTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('Ownable: caller is not the owner');
    strategicAssets.withdrawERC20(B_80BAL_20WETH, 1e18);
  }

  function test_revertsIf_insufficientBalance() public {
    vm.expectRevert('BAL#406');
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.withdrawERC20(B_80BAL_20WETH, 1e18);
    vm.stopPrank();
  }

  function test_successful() public {
    uint256 amount = 1e18;
    deal(B_80BAL_20WETH, address(strategicAssets), 10e18);
    uint256 balanceManagerBefore = IERC20(B_80BAL_20WETH).balanceOf(address(strategicAssets));
    uint256 balanceCollectorBefore = IERC20(B_80BAL_20WETH).balanceOf(
      address(AaveV2Ethereum.COLLECTOR)
    );

    vm.expectEmit();
    emit WithdrawalERC20(B_80BAL_20WETH, amount);
    vm.startPrank(AaveGovernanceV2.SHORT_EXECUTOR);
    strategicAssets.withdrawERC20(B_80BAL_20WETH, amount);
    vm.stopPrank();

    uint256 balanceManagerAfter = IERC20(B_80BAL_20WETH).balanceOf(address(strategicAssets));
    uint256 balanceCollectorAfter = IERC20(B_80BAL_20WETH).balanceOf(
      address(AaveV2Ethereum.COLLECTOR)
    );

    assertEq(balanceManagerBefore - amount, balanceManagerAfter);
    assertEq(balanceCollectorBefore + amount, balanceCollectorAfter);
  }
}
