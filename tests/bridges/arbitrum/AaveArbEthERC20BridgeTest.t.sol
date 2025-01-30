// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3Arbitrum, AaveV3ArbitrumAssets} from 'aave-address-book/AaveV3Arbitrum.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {GovernanceV3Arbitrum} from 'aave-address-book/GovernanceV3Arbitrum.sol';
import {IRescuable} from 'solidity-utils/contracts/utils/Rescuable.sol';

import {AaveArbEthERC20Bridge} from '../../../src/bridges/arbitrum/AaveArbEthERC20Bridge.sol';
import {IAaveArbEthERC20Bridge} from '../../../src/bridges/arbitrum/IAaveArbEthERC20Bridge.sol';
import {ArbSysMock} from './ArbSysMock.sol';

/**
 * @dev Tests for AaveArbEthERC20Bridge
 */
contract AaveArbEthERC20BridgeTest is Test {
  event Bridge(address indexed token, uint256 amount);
  event Exit(
    address l2sender,
    address to,
    uint256 l2block,
    uint256 l1block,
    uint256 value,
    bytes data
  );

  AaveArbEthERC20Bridge bridgeMainnet;
  AaveArbEthERC20Bridge bridgeArbitrum;
  uint256 mainnetFork;
  uint256 arbitrumFork;

  address USDC_WHALE = 0xb874005cbEa25C357b31C62145b3AEF219d105CF;
  address USDC_WHALE_MAINNET = 0xcEe284F754E854890e311e3280b767F80797180d;

  function setUp() public {
    bytes32 salt = keccak256(abi.encode(tx.origin, uint256(0)));

    mainnetFork = vm.createSelectFork(vm.rpcUrl('mainnet'), 18531022);
    bridgeMainnet = new AaveArbEthERC20Bridge{salt: salt}(address(this));

    arbitrumFork = vm.createSelectFork(vm.rpcUrl('arbitrum'), 148530087);
    bridgeArbitrum = new AaveArbEthERC20Bridge{salt: salt}(address(this));
  }
}

contract BridgeTest is AaveArbEthERC20BridgeTest {
  address public constant USDC_GATEWAY = 0x096760F208390250649E3e8763348E783AEF5562;
  address public constant ARB_SYS = 0x0000000000000000000000000000000000000064; // pre-compiled

  function test_revertsIf_invalidChain() public {
    vm.selectFork(mainnetFork);

    vm.expectRevert(IAaveArbEthERC20Bridge.InvalidChain.selector);
    bridgeArbitrum.bridge(
      AaveV3ArbitrumAssets.USDC_UNDERLYING,
      AaveV3EthereumAssets.USDC_UNDERLYING,
      USDC_GATEWAY,
      1_000e6
    );
  }

  function test_revertsIf_notOwner() public {
    vm.selectFork(arbitrumFork);

    uint256 amount = 1_000e6;

    vm.startPrank(USDC_WHALE);
    IERC20(AaveV3ArbitrumAssets.USDC_UNDERLYING).transfer(address(bridgeArbitrum), amount);
    vm.stopPrank();

    bridgeArbitrum.transferOwnership(GovernanceV3Arbitrum.EXECUTOR_LVL_1);

    vm.expectRevert(
      abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this))
    );
    bridgeArbitrum.bridge(
      AaveV3ArbitrumAssets.USDC_UNDERLYING,
      AaveV3EthereumAssets.USDC_UNDERLYING,
      USDC_GATEWAY,
      amount
    );
  }

  function test_successful_arbitrumBridge() public {
    vm.selectFork(arbitrumFork);

    uint256 amount = 1_000e6;

    vm.startPrank(USDC_WHALE);
    IERC20(AaveV3ArbitrumAssets.USDC_UNDERLYING).transfer(address(bridgeArbitrum), amount);
    vm.stopPrank();

    bridgeArbitrum.transferOwnership(GovernanceV3Arbitrum.EXECUTOR_LVL_1);

    vm.startPrank(GovernanceV3Arbitrum.EXECUTOR_LVL_1);

    ArbSysMock arbsys = new ArbSysMock();
    vm.etch(address(0x0000000000000000000000000000000000000064), address(arbsys).code);

    vm.expectEmit();
    emit Bridge(AaveV3ArbitrumAssets.USDC_UNDERLYING, amount);

    bridgeArbitrum.bridge(
      AaveV3ArbitrumAssets.USDC_UNDERLYING,
      AaveV3EthereumAssets.USDC_UNDERLYING,
      USDC_GATEWAY,
      amount
    );
    vm.stopPrank();
  }
}

contract EmergencyTokenTransfer is AaveArbEthERC20BridgeTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert(IRescuable.OnlyRescueGuardian.selector);
    vm.startPrank(makeAddr('random-caller'));
    bridgeArbitrum.emergencyTokenTransfer(
      AaveV3ArbitrumAssets.LINK_UNDERLYING,
      address(AaveV3Arbitrum.COLLECTOR),
      1_000e6
    );
    vm.stopPrank();
  }

  function test_successful_governanceCaller() public {
    address LINK_WHALE = 0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530;

    assertEq(IERC20(AaveV3ArbitrumAssets.LINK_UNDERLYING).balanceOf(address(bridgeArbitrum)), 0);

    uint256 balAmount = 1_000e18;

    vm.startPrank(LINK_WHALE);
    IERC20(AaveV3ArbitrumAssets.LINK_UNDERLYING).transfer(address(bridgeArbitrum), balAmount);
    vm.stopPrank();

    assertEq(
      IERC20(AaveV3ArbitrumAssets.LINK_UNDERLYING).balanceOf(address(bridgeArbitrum)),
      balAmount
    );

    uint256 initialCollectorBalBalance = IERC20(AaveV3ArbitrumAssets.LINK_UNDERLYING).balanceOf(
      address(AaveV3Arbitrum.COLLECTOR)
    );

    bridgeArbitrum.emergencyTokenTransfer(
      AaveV3ArbitrumAssets.LINK_UNDERLYING,
      address(AaveV3Arbitrum.COLLECTOR),
      balAmount
    );

    assertEq(
      IERC20(AaveV3ArbitrumAssets.LINK_UNDERLYING).balanceOf(address(AaveV3Arbitrum.COLLECTOR)),
      initialCollectorBalBalance + balAmount
    );
    assertEq(IERC20(AaveV3ArbitrumAssets.LINK_UNDERLYING).balanceOf(address(bridgeArbitrum)), 0);
  }
}

/*
 * No good way of testing the full flow as proof is generated via API ~7 days after the
 * bridge() function is called on Arbitrum.
 */
contract ExitTest is AaveArbEthERC20BridgeTest {
  function test_revertsIf_invalidChain() public {
    vm.selectFork(arbitrumFork);

    bytes32[] memory proof = new bytes32[](17);
    proof[0] = bytes32(0x8f2413401b9e655775aad826103c53ff5ca1ee7ad724eb8c79e9c6daa53a42c1);
    proof[1] = bytes32(0x28d6fb477c18b08c0fecd8ffbcd6c866388eeebf2cd2c09eb2a6d8a4400b643b);
    proof[2] = bytes32(0xb1435f7e1cb4a5953e89746da1288a039ffb4f24cacccf315732838e53d6f060);
    proof[3] = bytes32(0x61db0210d82c6a3a982db41752ab66966ef66f4587bd093dbcc86c79d571f2e2);
    proof[4] = bytes32(0x89e093bdddd365d65e23655f220d5d106445b3ae37e6371f4d666f3101228c56);
    proof[5] = bytes32(0x09796038b06aa218c3a098a19c2fe62db5ae65150180256775126c6cc0a7944b);
    proof[6] = bytes32(0x09e8d829b211a96087ec9e1553d962c7095ea2a516ac5e3d3fc9dfb0883437df);
    proof[7] = bytes32(0xeb8a59e232457e7992da6dada364130ac0355abd6a3e2de11994cc87dd48e2fd);
    proof[8] = bytes32(0x7f895c7d5e604507e11dcef280b63fbb176470934d655b9774850e7b4e8a2437);
    proof[9] = bytes32(0xaa028b33592259e6362db13faf07aad33f79b39ec93c86798e374c1306c622f3);
    proof[10] = bytes32(0xb6fa41cd3de57f0ba7f178fa0ce164c9f3fd14d9af481bcdee844f1a48b083ed);
    proof[11] = bytes32(0x5e293ff63182ef6620cdd6aa4f35a1a3fe0d8da195a674f11dafc06043d06719);
    proof[12] = bytes32(0x0000000000000000000000000000000000000000000000000000000000000000);
    proof[13] = bytes32(0x0000000000000000000000000000000000000000000000000000000000000000);
    proof[14] = bytes32(0x0000000000000000000000000000000000000000000000000000000000000000);
    proof[15] = bytes32(0xc0425084107ea9f7a4118f5ed1e3566cda4e90b550363fc804df1e52ed5f2386);
    proof[16] = bytes32(0xb43a6b28077d49f37d58c87aec0b51f7bce13b648143f3295385f3b3d5ac3b9b);

    vm.expectRevert(IAaveArbEthERC20Bridge.InvalidChain.selector);
    bridgeMainnet.exit(
      proof,
      101373,
      0x09e9222E96E7B4AE2a407B98d48e330053351EEe,
      0xa3A7B6F88361F48403514059F1F16C8E78d60EeC,
      162707774,
      18843894,
      1703278527,
      0,
      hex'2e567b36000000000000000000000000514910771af9ca656af840dff83e8264ecf986ca0000000000000000000000000e6bb71856c5c821d1b83f2c6a9a59a78d5e0712000000000000000000000000464c71f6c2f760dda6093dcb91c24c39e5d6e18c0000000000000000000000000000000000000000000000000031f025da53473500000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000003c7300000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000'
    );
  }

  function test_successful_exitsLink() public {
    // This test uses a valid proof utilized in a test which can be found here:
    // https://etherscan.io/tx/0xa34c3725cc95773eedf96b03e9672ad77940b27fc5b1b94441e6587dec014ecd
    // Setting block number to one prior to the real exit TX
    vm.createSelectFork(vm.rpcUrl('mainnet'), 18894550);
    bridgeMainnet = new AaveArbEthERC20Bridge{salt: keccak256(abi.encode(tx.origin, uint256(0)))}(
      address(this)
    );

    uint256 balanceBefore = IERC20(AaveV3EthereumAssets.LINK_UNDERLYING).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );

    bytes32[] memory proof = new bytes32[](17);
    proof[0] = bytes32(0x8f2413401b9e655775aad826103c53ff5ca1ee7ad724eb8c79e9c6daa53a42c1);
    proof[1] = bytes32(0x28d6fb477c18b08c0fecd8ffbcd6c866388eeebf2cd2c09eb2a6d8a4400b643b);
    proof[2] = bytes32(0xb1435f7e1cb4a5953e89746da1288a039ffb4f24cacccf315732838e53d6f060);
    proof[3] = bytes32(0x61db0210d82c6a3a982db41752ab66966ef66f4587bd093dbcc86c79d571f2e2);
    proof[4] = bytes32(0x89e093bdddd365d65e23655f220d5d106445b3ae37e6371f4d666f3101228c56);
    proof[5] = bytes32(0x09796038b06aa218c3a098a19c2fe62db5ae65150180256775126c6cc0a7944b);
    proof[6] = bytes32(0x09e8d829b211a96087ec9e1553d962c7095ea2a516ac5e3d3fc9dfb0883437df);
    proof[7] = bytes32(0xeb8a59e232457e7992da6dada364130ac0355abd6a3e2de11994cc87dd48e2fd);
    proof[8] = bytes32(0x7f895c7d5e604507e11dcef280b63fbb176470934d655b9774850e7b4e8a2437);
    proof[9] = bytes32(0xaa028b33592259e6362db13faf07aad33f79b39ec93c86798e374c1306c622f3);
    proof[10] = bytes32(0xb6fa41cd3de57f0ba7f178fa0ce164c9f3fd14d9af481bcdee844f1a48b083ed);
    proof[11] = bytes32(0x5e293ff63182ef6620cdd6aa4f35a1a3fe0d8da195a674f11dafc06043d06719);
    proof[12] = bytes32(0x0000000000000000000000000000000000000000000000000000000000000000);
    proof[13] = bytes32(0x0000000000000000000000000000000000000000000000000000000000000000);
    proof[14] = bytes32(0x0000000000000000000000000000000000000000000000000000000000000000);
    proof[15] = bytes32(0xc0425084107ea9f7a4118f5ed1e3566cda4e90b550363fc804df1e52ed5f2386);
    proof[16] = bytes32(0xb43a6b28077d49f37d58c87aec0b51f7bce13b648143f3295385f3b3d5ac3b9b);

    vm.expectEmit();
    emit Exit(
      0x09e9222E96E7B4AE2a407B98d48e330053351EEe,
      0xa3A7B6F88361F48403514059F1F16C8E78d60EeC,
      162707774,
      18843894,
      0,
      hex'2e567b36000000000000000000000000514910771af9ca656af840dff83e8264ecf986ca0000000000000000000000000e6bb71856c5c821d1b83f2c6a9a59a78d5e0712000000000000000000000000464c71f6c2f760dda6093dcb91c24c39e5d6e18c0000000000000000000000000000000000000000000000000031f025da53473500000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000003c7300000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000'
    );

    bridgeMainnet.exit(
      proof,
      101373,
      0x09e9222E96E7B4AE2a407B98d48e330053351EEe,
      0xa3A7B6F88361F48403514059F1F16C8E78d60EeC,
      162707774,
      18843894,
      1703278527,
      0,
      hex'2e567b36000000000000000000000000514910771af9ca656af840dff83e8264ecf986ca0000000000000000000000000e6bb71856c5c821d1b83f2c6a9a59a78d5e0712000000000000000000000000464c71f6c2f760dda6093dcb91c24c39e5d6e18c0000000000000000000000000000000000000000000000000031f025da53473500000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000003c7300000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000'
    );

    assertGt(
      IERC20(AaveV3EthereumAssets.LINK_UNDERLYING).balanceOf(address(AaveV3Ethereum.COLLECTOR)),
      balanceBefore
    );
  }
}

contract TransferOwnership is AaveArbEthERC20BridgeTest {
  function test_revertsIf_invalidCaller() public {
    address addr = makeAddr('random-caller');
    vm.startPrank(addr);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, addr));
    bridgeMainnet.transferOwnership(makeAddr('new-admin'));
    vm.stopPrank();
  }

  function test_successful() public {
    address newAdmin = GovernanceV3Ethereum.EXECUTOR_LVL_1;
    bridgeMainnet.transferOwnership(newAdmin);

    assertEq(newAdmin, bridgeMainnet.owner());
  }
}
