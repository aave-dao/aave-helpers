// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IACLManager, IPoolConfigurator, IPoolDataProvider} from 'aave-address-book/AaveV3.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {CapsPlusRiskSteward, CapsPlusRiskStewardErrors} from '../../src/riskstewards/CapsPlusRiskSteward.sol';
import {IAaveV3ConfigEngine} from 'aave-v3-origin/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol';
import {EngineFlags} from 'aave-v3-origin/contracts/extensions/v3-config-engine/EngineFlags.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';

contract CapsPlusRiskSteward_Test is Test {
  address public constant user = address(42);
  CapsPlusRiskSteward public steward;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 23089053);
    steward = new CapsPlusRiskSteward(
      AaveV3Ethereum.AAVE_PROTOCOL_DATA_PROVIDER,
      IAaveV3ConfigEngine(AaveV3Ethereum.CONFIG_ENGINE),
      user,
      5 days
    );
    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    AaveV3Ethereum.ACL_MANAGER.addRiskAdmin(address(steward));
    vm.stopPrank();
  }

  function test_increaseCapsMax() public {
    (uint256 daiBorrowCapBefore, uint256 daiSupplyCapBefore) = AaveV3Ethereum
      .AAVE_PROTOCOL_DATA_PROVIDER
      .getReserveCaps(AaveV3EthereumAssets.DAI_UNDERLYING);

    IAaveV3ConfigEngine.CapsUpdate[] memory capUpdates = new IAaveV3ConfigEngine.CapsUpdate[](1);
    capUpdates[0] = IAaveV3ConfigEngine.CapsUpdate(
      AaveV3EthereumAssets.DAI_UNDERLYING,
      daiSupplyCapBefore * 2,
      daiBorrowCapBefore * 2
    );

    vm.startPrank(user);
    steward.updateCaps(capUpdates);

    (uint256 daiBorrowCapAfter, uint256 daiSupplyCapAfter) = AaveV3Ethereum
      .AAVE_PROTOCOL_DATA_PROVIDER
      .getReserveCaps(AaveV3EthereumAssets.DAI_UNDERLYING);

    CapsPlusRiskSteward.Debounce memory lastUpdated = steward.getTimelock(
      AaveV3EthereumAssets.DAI_UNDERLYING
    );
    assertEq(daiBorrowCapAfter, capUpdates[0].borrowCap);
    assertEq(daiSupplyCapAfter, capUpdates[0].supplyCap);
    assertEq(lastUpdated.supplyCapLastUpdated, block.timestamp);
    assertEq(lastUpdated.borrowCapLastUpdated, block.timestamp);
  }

  function test_keepCurrent() public {
    (uint256 daiBorrowCapBefore, uint256 daiSupplyCapBefore) = AaveV3Ethereum
      .AAVE_PROTOCOL_DATA_PROVIDER
      .getReserveCaps(AaveV3EthereumAssets.DAI_UNDERLYING);

    IAaveV3ConfigEngine.CapsUpdate[] memory capUpdates = new IAaveV3ConfigEngine.CapsUpdate[](1);
    capUpdates[0] = IAaveV3ConfigEngine.CapsUpdate(
      AaveV3EthereumAssets.DAI_UNDERLYING,
      EngineFlags.KEEP_CURRENT,
      EngineFlags.KEEP_CURRENT
    );

    vm.startPrank(user);
    steward.updateCaps(capUpdates);

    (uint256 daiBorrowCapAfter, uint256 daiSupplyCapAfter) = AaveV3Ethereum
      .AAVE_PROTOCOL_DATA_PROVIDER
      .getReserveCaps(AaveV3EthereumAssets.DAI_UNDERLYING);

    CapsPlusRiskSteward.Debounce memory lastUpdated = steward.getTimelock(
      AaveV3EthereumAssets.DAI_UNDERLYING
    );
    assertEq(daiBorrowCapAfter, daiBorrowCapBefore);
    assertEq(daiSupplyCapAfter, daiSupplyCapBefore);
    assertEq(lastUpdated.supplyCapLastUpdated, 0);
    assertEq(lastUpdated.borrowCapLastUpdated, 0);
  }

  function test_invalidCaller() public {
    IAaveV3ConfigEngine.CapsUpdate[] memory capUpdates = new IAaveV3ConfigEngine.CapsUpdate[](1);
    capUpdates[0] = IAaveV3ConfigEngine.CapsUpdate(
      AaveV3EthereumAssets.DAI_UNDERLYING,
      EngineFlags.KEEP_CURRENT,
      EngineFlags.KEEP_CURRENT
    );

    try steward.updateCaps(capUpdates) {
      require(false, 'MUST_FAIL');
    } catch Error(string memory reason) {
      require(
        keccak256(bytes(reason)) == keccak256(bytes(CapsPlusRiskStewardErrors.INVALID_CALLER))
      );
    }
  }

  function test_updateSupplyCapBiggerMax() public {
    (, uint256 daiSupplyCapBefore) = AaveV3Ethereum.AAVE_PROTOCOL_DATA_PROVIDER.getReserveCaps(
      AaveV3EthereumAssets.DAI_UNDERLYING
    );
    IAaveV3ConfigEngine.CapsUpdate[] memory capUpdates = new IAaveV3ConfigEngine.CapsUpdate[](1);
    capUpdates[0] = IAaveV3ConfigEngine.CapsUpdate(
      AaveV3EthereumAssets.DAI_UNDERLYING,
      (daiSupplyCapBefore * 2) + 1,
      EngineFlags.KEEP_CURRENT
    );

    vm.startPrank(user);
    try steward.updateCaps(capUpdates) {
      require(false, 'MUST_FAIL');
    } catch Error(string memory reason) {
      require(
        keccak256(bytes(reason)) == keccak256(bytes(CapsPlusRiskStewardErrors.UPDATE_ABOVE_MAX))
      );
    }
  }

  function test_updateBorrowCapBiggerMax() public {
    (uint256 daiBorrowCapBefore, ) = AaveV3Ethereum.AAVE_PROTOCOL_DATA_PROVIDER.getReserveCaps(
      AaveV3EthereumAssets.DAI_UNDERLYING
    );
    IAaveV3ConfigEngine.CapsUpdate[] memory capUpdates = new IAaveV3ConfigEngine.CapsUpdate[](1);
    capUpdates[0] = IAaveV3ConfigEngine.CapsUpdate(
      AaveV3EthereumAssets.DAI_UNDERLYING,
      EngineFlags.KEEP_CURRENT,
      (daiBorrowCapBefore * 2) + 1
    );

    vm.startPrank(user);
    try steward.updateCaps(capUpdates) {
      require(false, 'MUST_FAIL');
    } catch Error(string memory reason) {
      require(
        keccak256(bytes(reason)) == keccak256(bytes(CapsPlusRiskStewardErrors.UPDATE_ABOVE_MAX))
      );
    }
  }

  function test_updateSupplyCapNotStrictlyHigher() public {
    (, uint256 daiSupplyCapBefore) = AaveV3Ethereum.AAVE_PROTOCOL_DATA_PROVIDER.getReserveCaps(
      AaveV3EthereumAssets.DAI_UNDERLYING
    );
    IAaveV3ConfigEngine.CapsUpdate[] memory capUpdates = new IAaveV3ConfigEngine.CapsUpdate[](1);
    capUpdates[0] = IAaveV3ConfigEngine.CapsUpdate(
      AaveV3EthereumAssets.DAI_UNDERLYING,
      daiSupplyCapBefore,
      EngineFlags.KEEP_CURRENT
    );

    vm.startPrank(user);
    // should fail when cap is equal current value
    try steward.updateCaps(capUpdates) {
      require(false, 'MUST_FAIL');
    } catch Error(string memory reason) {
      require(
        keccak256(bytes(reason)) == keccak256(bytes(CapsPlusRiskStewardErrors.NOT_STRICTLY_HIGHER))
      );
    }

    // should also fail when lower
    capUpdates[0].supplyCap -= 1;
    try steward.updateCaps(capUpdates) {
      require(false, 'MUST_FAIL');
    } catch Error(string memory reason) {
      require(
        keccak256(bytes(reason)) == keccak256(bytes(CapsPlusRiskStewardErrors.NOT_STRICTLY_HIGHER))
      );
    }
  }

  function test_updateBorrowCapNotStrictlyHigher() public {
    (uint256 daiBorrowCapBefore, ) = AaveV3Ethereum.AAVE_PROTOCOL_DATA_PROVIDER.getReserveCaps(
      AaveV3EthereumAssets.DAI_UNDERLYING
    );
    IAaveV3ConfigEngine.CapsUpdate[] memory capUpdates = new IAaveV3ConfigEngine.CapsUpdate[](1);
    capUpdates[0] = IAaveV3ConfigEngine.CapsUpdate(
      AaveV3EthereumAssets.DAI_UNDERLYING,
      EngineFlags.KEEP_CURRENT,
      daiBorrowCapBefore
    );

    vm.startPrank(user);
    // should fail when cap is equal current value
    try steward.updateCaps(capUpdates) {
      require(false, 'MUST_FAIL');
    } catch Error(string memory reason) {
      require(
        keccak256(bytes(reason)) == keccak256(bytes(CapsPlusRiskStewardErrors.NOT_STRICTLY_HIGHER))
      );
    }

    // should also fail when lower
    capUpdates[0].borrowCap -= 1;
    try steward.updateCaps(capUpdates) {
      require(false, 'MUST_FAIL');
    } catch Error(string memory reason) {
      require(
        keccak256(bytes(reason)) == keccak256(bytes(CapsPlusRiskStewardErrors.NOT_STRICTLY_HIGHER))
      );
    }
  }

  function test_debounce() public {
    (uint256 daiBorrowCapBefore, ) = AaveV3Ethereum.AAVE_PROTOCOL_DATA_PROVIDER.getReserveCaps(
      AaveV3EthereumAssets.DAI_UNDERLYING
    );

    IAaveV3ConfigEngine.CapsUpdate[] memory capUpdates = new IAaveV3ConfigEngine.CapsUpdate[](1);
    capUpdates[0] = IAaveV3ConfigEngine.CapsUpdate(
      AaveV3EthereumAssets.DAI_UNDERLYING,
      EngineFlags.KEEP_CURRENT,
      daiBorrowCapBefore + 1
    );

    vm.startPrank(user);
    steward.updateCaps(capUpdates);

    capUpdates[0].borrowCap += 1;
    try steward.updateCaps(capUpdates) {
      require(false, 'MUST_FAIL');
    } catch Error(string memory reason) {
      require(
        keccak256(bytes(reason)) ==
          keccak256(bytes(CapsPlusRiskStewardErrors.DEBOUNCE_NOT_RESPECTED))
      );
    }

    vm.warp(block.timestamp + steward.MINIMUM_DELAY() + 1);
    steward.updateCaps(capUpdates);
  }

  function test_unlisted() public {
    address unlistedAsset = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84; // stETH

    IAaveV3ConfigEngine.CapsUpdate[] memory capUpdates = new IAaveV3ConfigEngine.CapsUpdate[](1);
    capUpdates[0] = IAaveV3ConfigEngine.CapsUpdate(unlistedAsset, 100, 100);

    vm.startPrank(user);

    try steward.updateCaps(capUpdates) {
      require(false, 'MUST_FAIL');
    } catch Error(string memory reason) {
      require(
        keccak256(bytes(reason)) == keccak256(bytes(CapsPlusRiskStewardErrors.NO_CAP_INITIALIZE))
      );
    }
  }
}
