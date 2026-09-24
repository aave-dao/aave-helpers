// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {CommonTestBase} from '../src/CommonTestBase.sol';
import {AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV3GnosisAssets} from 'aave-address-book/AaveV3Gnosis.sol';
import {AaveV4BaseAssets} from 'aave-address-book/AaveV4Base.sol';
import {IB20} from '../src/interfaces/IB20.sol';
import {IB20Factory} from '../src/interfaces/IB20Factory.sol';

contract CommonTestBaseTest is CommonTestBase {
  function setUp() public {
    vm.createSelectFork('mainnet', 18572478);
  }

  function call() external view returns (address) {
    return msg.sender;
  }

  function test_deal2_shouldMaintainCurrentCaller() public {
    assertEq(this.call(), address(this));
    deal2(AaveV2EthereumAssets.USDC_UNDERLYING, address(this), 100e6);
    assertEq(this.call(), address(this));
  }
}

contract CommonTestBaseGnosisTest is CommonTestBase {
  function setUp() public {
    vm.createSelectFork('gnosis');
  }

  function test_deal2_EURe() public {
    deal2(AaveV3GnosisAssets.EURe_UNDERLYING, address(this), 100e18);
    assertEq(IERC20(AaveV3GnosisAssets.EURe_UNDERLYING).balanceOf(address(this)), 100e18);
  }
}

/**
 * @dev Runs on forge's Base EVM (nightly), which executes the B20 precompiles. The fork block is on the
 *      Beryl upgrade; switch to base:cobalt if the fork moves past 1790791200 (2026-09-30T10:00Z).
 *      Isolation is off because isolated top-level calls are charged the L1 data fee and revert for
 *      0-ETH pranked callers (foundry-rs/foundry#17010).
 * forge-config: default.networks.network = "base"
 * forge-config: default.hardfork = "base:beryl"
 * forge-config: default.isolate = false
 */
contract CommonTestBaseBaseTest is CommonTestBase {
  function setUp() public {
    vm.createSelectFork('base', 51605828);
  }

  // The factory is a precompile: it returns data only when forge runs the Base EVM.
  function _factoryExecutable() internal view returns (bool) {
    (, bytes memory ret) = B20_FACTORY.staticcall(
      abi.encodeCall(IB20Factory.isB20, (AaveV4BaseAssets.AAPLc_UNDERLYING))
    );
    return ret.length == 32;
  }

  function test_deal2_b20_detectedViaFactoryAndMinted() public {
    vm.skip(!_factoryExecutable(), 'requires forge with the Base EVM');
    assertTrue(_isB20(AaveV4BaseAssets.AAPLc_UNDERLYING));
    deal2(AaveV4BaseAssets.AAPLc_UNDERLYING, address(this), 100e8);
    assertEq(IERC20(AaveV4BaseAssets.AAPLc_UNDERLYING).balanceOf(address(this)), 100e8);
  }

  function test_deal2_b20_revertsWhenSupplyManagerLacksMintRole() public {
    vm.skip(!_factoryExecutable(), 'requires forge with the Base EVM');
    address asset = AaveV4BaseAssets.AAPLc_UNDERLYING;
    vm.mockCall(
      asset,
      abi.encodeCall(IB20.hasRole, (IB20(asset).MINT_ROLE(), B20_SUPPLY_MANAGER)),
      abi.encode(false)
    );
    vm.expectRevert(
      bytes(string(abi.encodePacked('B20 ', vm.toString(asset), ': no known MINT_ROLE holder')))
    );
    this.dealExternal(asset, address(this), 1e8);
  }

  function test_deal2_usdc_isNotB20AndTakesDealPath() public {
    assertFalse(_isB20(AaveV4BaseAssets.USDC_UNDERLYING));
    deal2(AaveV4BaseAssets.USDC_UNDERLYING, address(this), 100e6);
    assertEq(IERC20(AaveV4BaseAssets.USDC_UNDERLYING).balanceOf(address(this)), 100e6);
  }

  function test_knownEquities_areInitialisedB20sMintableBySupplyManager() public {
    vm.skip(!_factoryExecutable(), 'requires forge with the Base EVM');
    address[7] memory equities = [
      AaveV4BaseAssets.AAPLc_UNDERLYING,
      AaveV4BaseAssets.AMZNc_UNDERLYING,
      AaveV4BaseAssets.GOOGLc_UNDERLYING,
      AaveV4BaseAssets.METAc_UNDERLYING,
      AaveV4BaseAssets.MSFTc_UNDERLYING,
      AaveV4BaseAssets.NVDAc_UNDERLYING,
      AaveV4BaseAssets.TSLAc_UNDERLYING
    ];
    IB20Factory factory = IB20Factory(B20_FACTORY);
    for (uint256 i; i < equities.length; i++) {
      assertTrue(factory.isB20(equities[i]), vm.toString(equities[i]));
      assertTrue(factory.isB20Initialized(equities[i]), vm.toString(equities[i]));
      assertTrue(
        IB20(equities[i]).hasRole(IB20(equities[i]).MINT_ROLE(), B20_SUPPLY_MANAGER),
        vm.toString(equities[i])
      );
    }
    assertFalse(factory.isB20(AaveV4BaseAssets.USDC_UNDERLYING));
  }

  function dealExternal(address asset, address user, uint256 amount) external {
    deal2(asset, user, amount);
  }
}
