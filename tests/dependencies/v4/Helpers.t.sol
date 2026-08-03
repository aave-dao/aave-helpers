// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IHub} from 'aave-address-book/AaveV4.sol';
import {Helpers} from 'src/dependencies/v4/Helpers.sol';
import {MockHub, MockSpoke, MockTokenizationSpoke, MockOwnable, MockERC20Symbol} from 'tests/mocks/v4/V4Mocks.sol';

contract HelpersTest is Test, Helpers {
  MockHub internal hub;
  MockERC20Symbol internal underlying;

  function setUp() public {
    hub = new MockHub();
    underlying = new MockERC20Symbol('USDC');
    _addAsset(address(underlying));
  }

  function test_findTokenizationSpoke_returnsZeroWhenNoneRegistered() public {
    _registerSpoke(address(new MockSpoke()));

    assertEq(_findTokenizationSpoke(IHub(address(hub)), address(underlying)), address(0));
  }

  function test_findTokenizationSpoke_returnsZeroWhenAssetHasNoSpokes() public view {
    assertEq(_findTokenizationSpoke(IHub(address(hub)), address(underlying)), address(0));
  }

  /// @dev Non-tokenization spokes revert on `asset()` and must be skipped, not propagated.
  function test_findTokenizationSpoke_skipsSpokesWithoutAssetGetter() public {
    _registerSpoke(address(new MockSpoke()));
    address tokenizationSpoke = address(new MockTokenizationSpoke(address(underlying)));
    _registerSpoke(tokenizationSpoke);
    _registerSpoke(address(new MockSpoke()));

    assertEq(_findTokenizationSpoke(IHub(address(hub)), address(underlying)), tokenizationSpoke);
  }

  /// @dev A wrapper of a different asset registered on this one must not match.
  function test_findTokenizationSpoke_ignoresMismatchedAsset() public {
    _registerSpoke(address(new MockTokenizationSpoke(makeAddr('OTHER_UNDERLYING'))));

    assertEq(_findTokenizationSpoke(IHub(address(hub)), address(underlying)), address(0));
  }

  /// @dev The backwards scan returns the most recently registered wrapper, which is the one a
  /// payload just deployed when a listing replaces an existing wrapper.
  function test_findTokenizationSpoke_returnsMostRecentlyRegistered() public {
    _registerSpoke(address(new MockTokenizationSpoke(address(underlying))));
    address newest = address(new MockTokenizationSpoke(address(underlying)));
    _registerSpoke(newest);

    assertEq(_findTokenizationSpoke(IHub(address(hub)), address(underlying)), newest);
  }

  function test_proxyAdminOwner() public {
    address expectedOwner = makeAddr('PROXY_ADMIN_OWNER');
    address proxyAdmin = address(new MockOwnable(expectedOwner));
    address proxy = makeAddr('PROXY');
    vm.store(proxy, ERC1967_ADMIN_SLOT, bytes32(uint256(uint160(proxyAdmin))));

    assertEq(_proxyAdminOwner(proxy), expectedOwner);
  }

  /// @dev Pins the slot against the ERC-1967 spec value: keccak256('eip1967.proxy.admin') - 1.
  function test_erc1967AdminSlot() public pure {
    assertEq(ERC1967_ADMIN_SLOT, bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
  }

  function _addAsset(address assetUnderlying) internal {
    IHub.Asset memory asset;
    asset.underlying = assetUnderlying;
    asset.decimals = 6;
    hub.addAsset(
      asset,
      IHub.AssetConfig({
        feeReceiver: address(0),
        liquidityFee: 0,
        irStrategy: address(0),
        reinvestmentController: address(0)
      })
    );
  }

  function _registerSpoke(address spoke) internal {
    hub.addSpokeConfig(
      hub.getAssetId(address(underlying)),
      spoke,
      IHub.SpokeConfig({
        addCap: 0,
        drawCap: 0,
        riskPremiumThreshold: 0,
        active: true,
        halted: false
      })
    );
  }
}
