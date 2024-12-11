// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
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
import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {ICollector} from 'collector-upgrade-rev6/lib/aave-v3-origin/src/contracts/treasury/ICollector.sol';
import {Collector} from 'collector-upgrade-rev6/lib/aave-v3-origin/src/contracts/treasury/Collector.sol';
import {IAccessControl} from 'aave-v3-origin/core/contracts/dependencies/openzeppelin/contracts/IAccessControl.sol';

/**
 * @dev Test for Finance Steward contract
 * command: make test-poolv3-steward
 */
contract PoolV3FinSteward_Test is Test {
  event MinimumTokenBalanceUpdated(address indexed token, uint newAmount);
  event Upgraded(address indexed impl);
  event AddedV3Pool(address indexed V3Pool);
  event AddedV2Pool(address indexed V2Pool);

  address public constant guardian = address(82);
  PoolV3FinSteward public steward;

  address public alice = address(43);

  address public constant USDC_PRICE_FEED = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
  address public constant AAVE_PRICE_FEED = 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9;
  address public constant EXECUTOR = 0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A;
  address public constant PROXY_ADMIN = 0xD3cF979e676265e4f6379749DECe4708B9A22476;
  address public constant ACL_MANAGER = 0xc2aaCf6553D20d1e9d78E365AAba8032af9c85b0;
  TransparentUpgradeableProxy public constant COLLECTOR_PROXY =
    TransparentUpgradeableProxy(payable(0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c));
  bytes32 public constant FUNDS_ADMIN_ROLE = 'FUNDS_ADMIN';

  ICollector collector = ICollector(address(COLLECTOR_PROXY));

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 21244865);
    steward = new PoolV3FinSteward(GovernanceV3Ethereum.EXECUTOR_LVL_1, guardian);

    Collector new_collector_impl = new Collector(ACL_MANAGER);

    vm.label(0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c, 'Collector');
    vm.label(alice, 'alice');
    vm.label(guardian, 'guardian');
    vm.label(EXECUTOR, 'EXECUTOR');
    vm.label(address(steward), 'PoolV3FinSteward');

    vm.startPrank(EXECUTOR);

    uint256 streamID = collector.getNextStreamId();

    ProxyAdmin(PROXY_ADMIN).upgrade(COLLECTOR_PROXY, address(new_collector_impl));

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
      address(AaveV3Ethereum.POOL),
      AaveV3EthereumAssets.USDC_UNDERLYING,
      1_000e6
    );
    vm.stopPrank();
  }

  function test_resvertsIf_zeroAmount() public {
    vm.startPrank(guardian);

    vm.expectRevert(IPoolV3FinSteward.InvalidZeroAmount.selector);
    steward.migrateV2toV3(address(AaveV3Ethereum.POOL), AaveV3EthereumAssets.USDC_UNDERLYING, 0);
    vm.stopPrank();
  }

  function test_resvertsIf_minimumBalanceShield() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    steward.setMinimumBalanceShield(AaveV2EthereumAssets.USDC_A_TOKEN, 1_000e6);

    vm.startPrank(guardian);

    uint256 currentBalance = IERC20(AaveV2EthereumAssets.USDC_A_TOKEN).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    vm.expectRevert(
      abi.encodeWithSelector(IPoolV3FinSteward.MinimumBalanceShield.selector, 1_000e6)
    );
    steward.migrateV2toV3(
      address(AaveV3Ethereum.POOL),
      AaveV3EthereumAssets.USDC_UNDERLYING,
      currentBalance - 999e6
    );
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

  function test_fuzz(uint256 amount_, uint256 min_) public {
    uint256 balanceV2Before = IERC20(AaveV2EthereumAssets.USDC_A_TOKEN).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );
    uint256 balanceV3Before = IERC20(AaveV3EthereumAssets.USDC_A_TOKEN).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );
    min_ = bound(min_, 1, balanceV2Before);
    if (min_ > 0) {
      vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
      steward.setMinimumBalanceShield(AaveV2EthereumAssets.USDC_A_TOKEN, min_);
    }

    amount_ = bound(amount_, 1, 1e36);
    if (amount_ + min_ > balanceV2Before) {
      vm.expectRevert(
        abi.encodeWithSelector(IPoolV3FinSteward.MinimumBalanceShield.selector, min_)
      );
      vm.startPrank(guardian);
      steward.migrateV2toV3(
        address(AaveV3Ethereum.POOL),
        AaveV3EthereumAssets.USDC_UNDERLYING,
        amount_
      );
    } else {
      vm.startPrank(guardian);
      steward.migrateV2toV3(
        address(AaveV3Ethereum.POOL),
        AaveV3EthereumAssets.USDC_UNDERLYING,
        amount_
      );

      assertGt(
        IERC20(AaveV3EthereumAssets.USDC_A_TOKEN).balanceOf(address(AaveV3Ethereum.COLLECTOR)),
        balanceV3Before
      );

      assertApproxEqAbs(
        IERC20(AaveV3EthereumAssets.USDC_A_TOKEN).balanceOf(address(AaveV3Ethereum.COLLECTOR)),
        balanceV3Before + amount_,
        2
      );
    }
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

  function test_resvertsIf_minimumBalanceShield() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    steward.setMinimumBalanceShield(AaveV3EthereumAssets.USDC_A_TOKEN, 1_000e6);

    vm.startPrank(guardian);

    uint256 currentBalance = IERC20(AaveV3EthereumAssets.USDC_A_TOKEN).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    vm.expectRevert(
      abi.encodeWithSelector(IPoolV3FinSteward.MinimumBalanceShield.selector, 1_000e6)
    );
    steward.withdrawV3(
      address(AaveV3Ethereum.POOL),
      AaveV3EthereumAssets.USDC_UNDERLYING,
      currentBalance
    );
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

  function test_fuzz(uint256 amount_, uint256 min_) public {
    uint256 balanceV3Before = IERC20(AaveV3EthereumAssets.USDC_A_TOKEN).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );
    uint256 balanceUSDCBefore = IERC20(AaveV3EthereumAssets.USDC_UNDERLYING).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );
    min_ = bound(min_, 1, balanceV3Before);
    if (min_ > 0) {
      vm.prank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
      steward.setMinimumBalanceShield(AaveV3EthereumAssets.USDC_A_TOKEN, min_);
    }

    amount_ = bound(amount_, 1, 1e36);
    if (amount_ + min_ > balanceV3Before) {
      vm.expectRevert(
        abi.encodeWithSelector(IPoolV3FinSteward.MinimumBalanceShield.selector, min_)
      );
      vm.startPrank(guardian);
      steward.withdrawV3(
        address(AaveV3Ethereum.POOL),
        AaveV3EthereumAssets.USDC_UNDERLYING,
        amount_
      );
    } else {
      vm.startPrank(guardian);
      steward.withdrawV3(
        address(AaveV3Ethereum.POOL),
        AaveV3EthereumAssets.USDC_UNDERLYING,
        amount_
      );

      assertLt(
        IERC20(AaveV3EthereumAssets.USDC_A_TOKEN).balanceOf(address(AaveV3Ethereum.COLLECTOR)),
        balanceV3Before
      );

      assertApproxEqAbs(
        IERC20(AaveV3EthereumAssets.USDC_UNDERLYING).balanceOf(address(AaveV3Ethereum.COLLECTOR)),
        balanceUSDCBefore + amount_,
        2
      );
    }
    vm.stopPrank();
  }
}

contract Function_withdrawV2 is PoolV3FinSteward_Test {
  function test_revertsIf_notOwnerOrQuardian() public {
    vm.startPrank(alice);

    vm.expectRevert('ONLY_BY_OWNER_OR_GUARDIAN');
    steward.withdrawV2(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);
    vm.stopPrank();
  }

  function test_resvertsIf_zeroAmount() public {
    vm.startPrank(guardian);

    vm.expectRevert(IPoolV3FinSteward.InvalidZeroAmount.selector);
    steward.withdrawV2(AaveV3EthereumAssets.USDC_UNDERLYING, 0);
    vm.stopPrank();
  }

  function test_resvertsIf_minimumBalanceShield() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    steward.setMinimumBalanceShield(AaveV2EthereumAssets.USDC_A_TOKEN, 1_000e6);

    vm.startPrank(guardian);

    uint256 currentBalance = IERC20(AaveV2EthereumAssets.USDC_A_TOKEN).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    vm.expectRevert(
      abi.encodeWithSelector(IPoolV3FinSteward.MinimumBalanceShield.selector, 1_000e6)
    );
    steward.withdrawV2(AaveV3EthereumAssets.USDC_UNDERLYING, currentBalance - 1_00e6);
    vm.stopPrank();
  }

  function test_success() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    steward.setMinimumBalanceShield(AaveV2EthereumAssets.USDC_A_TOKEN, 1_000e6);

    vm.startPrank(guardian);

    uint256 balanceV3Before = IERC20(AaveV2EthereumAssets.USDC_A_TOKEN).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    vm.startPrank(guardian);
    steward.withdrawV2(AaveV2EthereumAssets.USDC_UNDERLYING, balanceV3Before - 2_000e6);

    assertLt(
      IERC20(AaveV2EthereumAssets.USDC_A_TOKEN).balanceOf(address(AaveV3Ethereum.COLLECTOR)),
      balanceV3Before
    );
    vm.stopPrank();
  }
}

contract Function_setMinimumBalanceShield is PoolV3FinSteward_Test {
  function test_revertsIf_notOwner() public {
    vm.startPrank(alice);

    vm.expectRevert('Ownable: caller is not the owner');
    steward.setMinimumBalanceShield(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);
    vm.stopPrank();
  }

  function test_success() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    vm.expectEmit(true, true, true, true, address(steward));
    emit MinimumTokenBalanceUpdated(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);
    steward.setMinimumBalanceShield(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);
    vm.stopPrank();
  }
}

contract Function_setV3Pool is PoolV3FinSteward_Test {
  function test_revertsIf_notOwner() public {
    vm.startPrank(alice);

    vm.expectRevert('Ownable: caller is not the owner');
    steward.setV3Pool(address(50));
    vm.stopPrank();
  }

  function test_revertsIf_invalidZeroAddress() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    vm.expectRevert(IPoolV3FinSteward.InvalidZeroAddress.selector);
    steward.setV3Pool(address(0));
    vm.stopPrank();
  }

  function test_success() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    vm.expectEmit(true, true, true, true, address(steward));
    emit AddedV3Pool(address(50));
    steward.setV3Pool(address(50));
    vm.stopPrank();
  }
}

contract Function_setV2Pool is PoolV3FinSteward_Test {
  function test_revertsIf_notOwner() public {
    vm.startPrank(alice);

    vm.expectRevert('Ownable: caller is not the owner');
    steward.setV2Pool(address(50));
    vm.stopPrank();
  }

  function test_revertsIf_invalidZeroAddress() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    vm.expectRevert(IPoolV3FinSteward.InvalidZeroAddress.selector);
    steward.setV2Pool(address(0));
    vm.stopPrank();
  }

  function test_success() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);

    vm.expectEmit(true, true, true, true, address(steward));
    emit AddedV2Pool(address(50));
    steward.setV2Pool(address(50));
    vm.stopPrank();
  }
}

contract Function_validateAmount is PoolV3FinSteward_Test {
    function test_resvertsIf_minimumBalanceShield() public {
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    steward.setMinimumBalanceShield(AaveV2EthereumAssets.USDC_A_TOKEN, 1_000e6);

    vm.startPrank(guardian);

    uint256 currentBalance = IERC20(AaveV2EthereumAssets.USDC_A_TOKEN).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    vm.expectRevert(
      abi.encodeWithSelector(IPoolV3FinSteward.MinimumBalanceShield.selector, 1_000e6)
    );
    steward.validateAmount(
      AaveV2EthereumAssets.USDC_A_TOKEN,
      currentBalance
    );
    vm.stopPrank();
  }

  function test_successful_amountGreaterThanBalance() public {
    uint256 currentBalance = IERC20(AaveV2EthereumAssets.USDC_A_TOKEN).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    steward.validateAmount(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      currentBalance + 1
    );
  }

  function test_successful_amountLowerThanBalance() public {
    uint256 currentBalance = IERC20(AaveV2EthereumAssets.USDC_A_TOKEN).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    steward.validateAmount(
      AaveV3EthereumAssets.USDC_UNDERLYING,
      currentBalance - 1
    );
  }
}

contract Function_validateV3Pool is PoolV3FinSteward_Test {
  function test_revertsIf_v3PoolIsNotSet() public {
    vm.expectRevert(IPoolV3FinSteward.UnrecognizedV3Pool.selector);
    steward.validateV3Pool(makeAddr('v3-pool'));
  }

  function test_successful() public {
    steward.validateV3Pool(address(AaveV3Ethereum.POOL));
  }
}
