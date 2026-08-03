// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IAaveV4ConfigEngine} from 'aave-address-book/AaveV4.sol';
import {Roles} from 'aave-v4/deployments/utils/libraries/Roles.sol';
import {V4RoleWiring} from 'src/v4-config-engine/V4RoleWiring.sol';

contract V4RoleWiringTest is Test {
  address internal authority = makeAddr('ACCESS_MANAGER');
  address internal hub = makeAddr('HUB');
  address internal spoke = makeAddr('SPOKE');

  function test_hubWiring_rolesAndSelectors() public view {
    IAaveV4ConfigEngine.TargetFunctionRoleUpdate[] memory updates = V4RoleWiring.hubWiring(
      authority,
      hub
    );
    assertEq(updates.length, 3, 'updates length');
    _assertUpdate(
      updates[0],
      hub,
      Roles.HUB_CONFIGURATOR_ROLE,
      Roles.getHubConfiguratorRoleSelectors(),
      'configurator'
    );
    _assertUpdate(
      updates[1],
      hub,
      Roles.HUB_FEE_MINTER_ROLE,
      Roles.getHubFeeMinterRoleSelectors(),
      'feeMinter'
    );
    _assertUpdate(
      updates[2],
      hub,
      Roles.HUB_DEFICIT_ELIMINATOR_ROLE,
      Roles.getHubDeficitEliminatorRoleSelectors(),
      'deficitEliminator'
    );
  }

  function test_spokeWiring_rolesAndSelectors() public view {
    IAaveV4ConfigEngine.TargetFunctionRoleUpdate[] memory updates = V4RoleWiring.spokeWiring(
      authority,
      spoke
    );
    assertEq(updates.length, 2, 'updates length');
    _assertUpdate(
      updates[0],
      spoke,
      Roles.SPOKE_CONFIGURATOR_ROLE,
      Roles.getSpokeConfiguratorRoleSelectors(),
      'configurator'
    );
    _assertUpdate(
      updates[1],
      spoke,
      Roles.SPOKE_USER_POSITION_UPDATER_ROLE,
      Roles.getSpokePositionUpdaterRoleSelectors(),
      'positionUpdater'
    );
  }

  /// @dev A selector carrying two roles would make the wiring order-dependent on the AccessManager.
  function test_spokeWiring_roleSelectorsAreDisjoint() public view {
    IAaveV4ConfigEngine.TargetFunctionRoleUpdate[] memory updates = V4RoleWiring.spokeWiring(
      authority,
      spoke
    );
    for (uint256 i; i < updates[0].selectors.length; ++i) {
      for (uint256 j; j < updates[1].selectors.length; ++j) {
        assertTrue(updates[0].selectors[i] != updates[1].selectors[j], 'selector overlap');
      }
    }
  }

  function test_merge_concatenatesInOrder() public view {
    IAaveV4ConfigEngine.TargetFunctionRoleUpdate[] memory hubUpdates = V4RoleWiring.hubWiring(
      authority,
      hub
    );
    IAaveV4ConfigEngine.TargetFunctionRoleUpdate[] memory spokeUpdates = V4RoleWiring.spokeWiring(
      authority,
      spoke
    );
    IAaveV4ConfigEngine.TargetFunctionRoleUpdate[] memory merged = V4RoleWiring.merge(
      hubUpdates,
      spokeUpdates
    );

    assertEq(merged.length, hubUpdates.length + spokeUpdates.length, 'merged length');
    for (uint256 i; i < hubUpdates.length; ++i) {
      assertEq(merged[i].target, hubUpdates[i].target, 'hub target');
      assertEq(uint256(merged[i].roleId), uint256(hubUpdates[i].roleId), 'hub roleId');
    }
    for (uint256 i; i < spokeUpdates.length; ++i) {
      assertEq(merged[hubUpdates.length + i].target, spokeUpdates[i].target, 'spoke target');
      assertEq(
        uint256(merged[hubUpdates.length + i].roleId),
        uint256(spokeUpdates[i].roleId),
        'spoke roleId'
      );
    }
  }

  /// @dev A spoke-only payload merges an empty hub wiring, so both empty sides must work.
  function test_merge_withEmptySides() public view {
    IAaveV4ConfigEngine.TargetFunctionRoleUpdate[] memory empty;
    IAaveV4ConfigEngine.TargetFunctionRoleUpdate[] memory spokeUpdates = V4RoleWiring.spokeWiring(
      authority,
      spoke
    );

    assertEq(V4RoleWiring.merge(empty, spokeUpdates).length, spokeUpdates.length, 'empty first');
    assertEq(V4RoleWiring.merge(spokeUpdates, empty).length, spokeUpdates.length, 'empty second');
    assertEq(V4RoleWiring.merge(empty, empty).length, 0, 'both empty');
  }

  function _assertUpdate(
    IAaveV4ConfigEngine.TargetFunctionRoleUpdate memory update,
    address expectedTarget,
    uint64 expectedRoleId,
    bytes4[] memory expectedSelectors,
    string memory label
  ) internal view {
    assertEq(update.authority, authority, string.concat(label, ' authority'));
    assertEq(update.target, expectedTarget, string.concat(label, ' target'));
    assertEq(uint256(update.roleId), uint256(expectedRoleId), string.concat(label, ' roleId'));
    assertEq(
      update.selectors.length,
      expectedSelectors.length,
      string.concat(label, ' selectors length')
    );
    for (uint256 i; i < expectedSelectors.length; ++i) {
      assertEq(
        uint32(update.selectors[i]),
        uint32(expectedSelectors[i]),
        string.concat(label, ' selector ', vm.toString(i))
      );
    }
  }
}
