// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {PoolV3FinSteward, IPoolV3FinSteward} from 'src/financestewards/PoolV3FinSteward.sol';
import {AggregatorInterface} from 'src/financestewards/AggregatorInterface.sol';
import {CollectorUtils} from 'src/CollectorUtils.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import {ITransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol'; 
import {ICollector} from 'collector-upgrade-rev6/lib/aave-v3-origin/src/contracts/treasury/ICollector.sol';
import {Collector} from 'collector-upgrade-rev6/lib/aave-v3-origin/src/contracts/treasury/Collector.sol';
import {IAccessControl} from 'openzeppelin-contracts/contracts/access/AccessControl.sol';

/**
 * @dev Test for Finance Steward contract
 * command: make test-poolv3-steward
 */
contract PoolV3FinSteward_Test is Test {
  event MinimumTokenBalanceUpdated(address indexed token, uint newAmount);
  event Upgraded(address indexed impl);
  event ApprovedPool(address indexed pool);
  event RevokedPool(address indexed pool);

  address public constant guardian = address(82);
  PoolV3FinSteward public steward;

  address public alice = address(43);

  address public constant USDC_PRICE_FEED = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
  address public constant AAVE_PRICE_FEED = 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9;
  address public constant EXECUTOR = 0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A;
  address public constant PROXY_ADMIN = 0xD3cF979e676265e4f6379749DECe4708B9A22476;
  address public constant ACL_MANAGER = 0xc2aaCf6553D20d1e9d78E365AAba8032af9c85b0;
  ITransparentUpgradeableProxy public constant COLLECTOR_PROXY =
    ITransparentUpgradeableProxy(payable(0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c));
  bytes32 public constant FUNDS_ADMIN_ROLE = 'FUNDS_ADMIN';

  ICollector collector = ICollector(address(COLLECTOR_PROXY));

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 21244865);

    address[] memory v2Pools = new address[](1);
    v2Pools[0] = address(AaveV2Ethereum.POOL);
    address[] memory v3Pools = new address[](3);
    v3Pools[0] = address(AaveV3Ethereum.POOL);
    v3Pools[1] = 0x0AA97c284e98396202b6A04024F5E2c65026F3c0;
    v3Pools[2] = 0x4e033931ad43597d96D6bcc25c280717730B58B1;
    steward = new PoolV3FinSteward(GovernanceV3Ethereum.EXECUTOR_LVL_1, guardian,address(collector), v2Pools, v3Pools);

    Collector new_collector_impl = new Collector(ACL_MANAGER);

    vm.label(0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c, 'Collector');
    vm.label(alice, 'alice');
    vm.label(guardian, 'guardian');
    vm.label(EXECUTOR, 'EXECUTOR');
    vm.label(address(steward), 'PoolV3FinSteward');

    vm.startPrank(EXECUTOR);

    uint256 streamID = collector.getNextStreamId();

    ProxyAdmin(PROXY_ADMIN).upgradeAndCall(COLLECTOR_PROXY, address(new_collector_impl), '');

    IAccessControl(ACL_MANAGER).grantRole(FUNDS_ADMIN_ROLE, address(steward));
    IAccessControl(ACL_MANAGER).grantRole(FUNDS_ADMIN_ROLE, EXECUTOR);

    collector.initialize(streamID);

    vm.stopPrank();

    vm.prank(0x4B16c5dE96EB2117bBE5fd171E4d203624B014aa); //RANDOM USDC HOLDER
    IERC20(AaveV3EthereumAssets.USDC_UNDERLYING).transfer(
      address(AaveV3Ethereum.COLLECTOR),
      1_000_000e6
    );

    vm.prank(EXECUTOR);
    Ownable(MiscEthereum.AAVE_SWAPPER).transferOwnership(address(steward));
  }
}

contract Function_depositV3 is PoolV3FinSteward_Test {
  function test_revertsIf_notOwnerOrQuardian() public {
    vm.startPrank(alice);

    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    steward.depositV3(address(AaveV3Ethereum.POOL), AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);
    vm.stopPrank();
  }

  function test_resvertsIf_zeroAmount() public {
    vm.startPrank(guardian);

    vm.expectRevert(CollectorUtils.InvalidZeroAmount.selector);
    steward.depositV3(address(AaveV3Ethereum.POOL), AaveV3EthereumAssets.USDC_UNDERLYING, 0);
    vm.stopPrank();
  }

  function test_success() public {
    uint256 balanceBefore = IERC20(AaveV3EthereumAssets.USDC_A_TOKEN).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );
    vm.startPrank(guardian);

    steward.depositV3(address(AaveV3Ethereum.POOL), AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);

    assertGt(
      IERC20(AaveV3EthereumAssets.USDC_A_TOKEN).balanceOf(address(AaveV3Ethereum.COLLECTOR)),
      balanceBefore
    );
    vm.stopPrank();
  }
}

contract Function_migrateV2toV3 is PoolV3FinSteward_Test {
  function test_revertsIf_notOwnerOrQuardian() public {
    vm.startPrank(alice);

    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    steward.migrateV2toV3(
       address(AaveV2Ethereum.POOL),
      address(AaveV3Ethereum.POOL),
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6
    );
    vm.stopPrank();
  }

  function test_resvertsIf_zeroAmount() public {
    vm.startPrank(guardian);

    vm.expectRevert(IPoolV3FinSteward.InvalidZeroAmount.selector);
    steward.migrateV2toV3(address(AaveV3Ethereum.POOL), address(AaveV2Ethereum.POOL), AaveV3EthereumAssets.USDC_UNDERLYING, 0);
    vm.stopPrank();
  }

  function test_success() public {
    uint256 balanceV2Before = IERC20(AaveV2EthereumAssets.USDC_A_TOKEN).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );
    uint256 balanceV3Before = IERC20(AaveV3EthereumAssets.USDC_A_TOKEN).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    vm.startPrank(guardian);

    steward.migrateV2toV3(
       address(AaveV2Ethereum.POOL),
      address(AaveV3Ethereum.POOL),
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6
    );

    assertLt(
      IERC20(AaveV2EthereumAssets.USDC_A_TOKEN).balanceOf(address(AaveV3Ethereum.COLLECTOR)),
      balanceV2Before
    );
    assertGt(
      IERC20(AaveV3EthereumAssets.USDC_A_TOKEN).balanceOf(address(AaveV3Ethereum.COLLECTOR)),
      balanceV3Before
    );
    vm.stopPrank();
  }

}

contract Function_migrateBetweenV3 is PoolV3FinSteward_Test {
  function test_revertsIf_notOwnerOrQuardian() public {
    vm.startPrank(alice);

    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    steward.migrateBetweenV3(
       address(AaveV3Ethereum.POOL),
      address(AaveV3Ethereum.POOL),
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6
    );
    vm.stopPrank();
  }

  function test_resvertsIf_zeroAmount() public {
    vm.startPrank(guardian);

    vm.expectRevert(IPoolV3FinSteward.InvalidZeroAmount.selector);
    steward.migrateBetweenV3(
       address(AaveV3Ethereum.POOL),
      address(AaveV3Ethereum.POOL),
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6
    );
    vm.stopPrank();
  }

  function test_success() public {

    uint256 balanceBefore = IERC20(AaveV3EthereumAssets.WETH_A_TOKEN).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    vm.startPrank(guardian);

    steward.migrateBetweenV3(
      address(AaveV3Ethereum.POOL),
      address(0x0AA97c284e98396202b6A04024F5E2c65026F3c0),
      AaveV3EthereumAssets.WETH_A_TOKEN,
      1_000e6
    );

     assertGt(
      IERC20(AaveV3EthereumAssets.WETH_A_TOKEN).balanceOf(address(AaveV3Ethereum.COLLECTOR)),
      balanceBefore
    );
    vm.stopPrank();
  }

}

contract Function_withdrawV3 is PoolV3FinSteward_Test {
  function test_revertsIf_notOwnerOrQuardian() public {
    vm.startPrank(alice);

    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    steward.withdrawV3(address(AaveV3Ethereum.POOL), AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);
    vm.stopPrank();
  }

  function test_resvertsIf_zeroAmount() public {
    vm.startPrank(guardian);

    vm.expectRevert(IPoolV3FinSteward.InvalidZeroAmount.selector);
    steward.withdrawV3(address(AaveV3Ethereum.POOL), AaveV3EthereumAssets.USDC_UNDERLYING, 0);
    vm.stopPrank();
  }

  function test_success() public {
    uint256 balanceV3Before = IERC20(AaveV3EthereumAssets.USDC_A_TOKEN).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    vm.startPrank(guardian);
    steward.withdrawV3(address(AaveV3Ethereum.POOL), AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);

    assertLt(
      IERC20(AaveV3EthereumAssets.USDC_A_TOKEN).balanceOf(address(AaveV3Ethereum.COLLECTOR)),
      balanceV3Before
    );
    vm.stopPrank();
  }

}

contract Function_withdrawV2 is PoolV3FinSteward_Test {
  function test_revertsIf_notOwnerOrQuardian() public {
    vm.startPrank(alice);

    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    steward.withdrawV2(address(AaveV2Ethereum.POOL), AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);
    vm.stopPrank();
  }

  function test_resvertsIf_zeroAmount() public {
    vm.startPrank(guardian);

    vm.expectRevert(IPoolV3FinSteward.InvalidZeroAmount.selector);
    steward.withdrawV2(address(AaveV2Ethereum.POOL), AaveV3EthereumAssets.USDC_UNDERLYING, 0);
    vm.stopPrank();
  }


  function test_success() public {
 
    vm.startPrank(guardian);

    uint256 balanceV3Before = IERC20(AaveV2EthereumAssets.USDC_A_TOKEN).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    vm.startPrank(guardian);
    steward.withdrawV2(address(AaveV2Ethereum.POOL), AaveV2EthereumAssets.USDC_UNDERLYING, balanceV3Before - 2_000e6);

    assertLt(
      IERC20(AaveV2EthereumAssets.USDC_A_TOKEN).balanceOf(address(AaveV3Ethereum.COLLECTOR)),
      balanceV3Before
    );
    vm.stopPrank();
  }
}

contract Function_approvePool is PoolV3FinSteward_Test {
  function test_revertsIf_notOwner() public {
    vm.startPrank(alice);

    vm.expectRevert('Ownable: caller is not the owner');
    steward.approvePool(address(AaveV3Ethereum.POOL), true);
    vm.stopPrank();
  }

  function test_revertsIf_invalidZeroAddress() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    vm.expectRevert(IPoolV3FinSteward.InvalidZeroAddress.selector);
    steward.revokePool(address(0), true);
    vm.stopPrank();
  }

  function test_success() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    vm.expectEmit(true, true, true, true, address(steward));
    emit ApprovedPool(address(50));
    steward.revokePool(address(50), true);


    vm.expectEmit(true, true, true, true, address(steward));
    emit ApprovedPool(address(51));
    steward.revokePool(address(51), false);
    vm.stopPrank();
  }
}

contract Function_revokePool is PoolV3FinSteward_Test {
  function test_revertsIf_notOwner() public {
    vm.startPrank(alice);

    vm.expectRevert('Ownable: caller is not the owner');
    steward.revokePool(address(AaveV3Ethereum.POOL), true);
    vm.stopPrank();
  }

  function test_revertsIf_invalidZeroAddress() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    vm.expectRevert(IPoolV3FinSteward.InvalidZeroAddress.selector);
    steward.revokePool(address(0), true);
    vm.stopPrank();
  }

  function test_success() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    vm.expectEmit(true, true, true, true, address(steward));
    emit RevokedPool(address(AaveV3Ethereum.POOL));
    steward.revokePool(address(AaveV3Ethereum.POOL), true);
    vm.stopPrank();
  }
}
