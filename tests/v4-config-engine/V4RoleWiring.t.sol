// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IAaveV4ConfigEngine} from 'aave-address-book/AaveV4.sol';
import {Roles} from 'aave-v4/deployments/utils/libraries/Roles.sol';
import {AaveV4HubRolesProcedure} from 'aave-v4/deployments/procedures/roles/AaveV4HubRolesProcedure.sol';
import {AaveV4SpokeRolesProcedure} from 'aave-v4/deployments/procedures/roles/AaveV4SpokeRolesProcedure.sol';
import {V4RoleWiring} from 'src/v4-config-engine/V4RoleWiring.sol';
import {MockRecordingAccessManager} from 'tests/mocks/v4/V4Mocks.sol';

contract V4RoleWiringTest is Test {
  MockRecordingAccessManager internal accessManager;

  address internal hub = makeAddr('HUB');
  address internal spoke = makeAddr('SPOKE');

  function setUp() public {
    accessManager = new MockRecordingAccessManager();
  }

  /// @dev Asserting the library against `Roles` would be tautological, since that is where it reads
  /// its selectors from: a role added upstream would leave such a test green while the library
  /// under-wires. Compare against the deployment procedure instead, the source of truth for what a
  /// deployed hub gets wired with.
  function test_hubWiring_matchesDeploymentProcedure() public {
    AaveV4HubRolesProcedure.setupHubAllRoles(address(accessManager), hub);

    _assertWiringMatchesProcedure(V4RoleWiring.hubWiring(address(accessManager), hub), hub);
  }

  function test_spokeWiring_matchesDeploymentProcedure() public {
    AaveV4SpokeRolesProcedure.setupSpokeAllRoles(address(accessManager), spoke);

    _assertWiringMatchesProcedure(V4RoleWiring.spokeWiring(address(accessManager), spoke), spoke);
  }

  /// @dev A selector carried by two roles would make the wiring order-dependent, since the last
  /// `setTargetFunctionRole` for it wins on the AccessManager.
  function test_wiring_selectorsAreUniqueAcrossRoles() public view {
    _assertSelectorsUnique(V4RoleWiring.hubWiring(address(accessManager), hub), 'hub');
    _assertSelectorsUnique(V4RoleWiring.spokeWiring(address(accessManager), spoke), 'spoke');
  }

  function test_merge_concatenatesInOrder() public view {
    IAaveV4ConfigEngine.TargetFunctionRoleUpdate[] memory hubUpdates = V4RoleWiring.hubWiring(
      address(accessManager),
      hub
    );
    IAaveV4ConfigEngine.TargetFunctionRoleUpdate[] memory spokeUpdates = V4RoleWiring.spokeWiring(
      address(accessManager),
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
      address(accessManager),
      spoke
    );

    assertEq(V4RoleWiring.merge(empty, spokeUpdates).length, spokeUpdates.length, 'empty first');
    assertEq(V4RoleWiring.merge(spokeUpdates, empty).length, spokeUpdates.length, 'empty second');
    assertEq(V4RoleWiring.merge(empty, empty).length, 0, 'both empty');
  }

  /// @dev Guards the equivalence assertion itself: it must fail when the wiring is short a role.
  function test_assertWiringMatchesProcedure_catchesMissingRole() public {
    AaveV4HubRolesProcedure.setupHubAllRoles(address(accessManager), hub);
    IAaveV4ConfigEngine.TargetFunctionRoleUpdate[] memory full = V4RoleWiring.hubWiring(
      address(accessManager),
      hub
    );

    IAaveV4ConfigEngine.TargetFunctionRoleUpdate[]
      memory truncated = new IAaveV4ConfigEngine.TargetFunctionRoleUpdate[](full.length - 1);
    for (uint256 i; i < truncated.length; ++i) {
      truncated[i] = full[i];
    }

    vm.expectRevert();
    this.assertWiringMatchesProcedure(truncated, hub);
  }

  /// @dev External wrapper so the negative case above can catch the assertion failure.
  function assertWiringMatchesProcedure(
    IAaveV4ConfigEngine.TargetFunctionRoleUpdate[] memory updates,
    address expectedTarget
  ) public view {
    _assertWiringMatchesProcedure(updates, expectedTarget);
  }

  /// @dev Every wired selector must carry the role the procedure assigned it, and the two must cover
  /// the same number of selectors so an upstream addition cannot slip through unwired.
  function _assertWiringMatchesProcedure(
    IAaveV4ConfigEngine.TargetFunctionRoleUpdate[] memory updates,
    address expectedTarget
  ) internal view {
    uint256 wiredSelectors;
    for (uint256 i; i < updates.length; ++i) {
      assertEq(updates[i].authority, address(accessManager), 'authority');
      assertEq(updates[i].target, expectedTarget, 'target');
      assertGt(updates[i].selectors.length, 0, 'role wired with no selectors');

      for (uint256 j; j < updates[i].selectors.length; ++j) {
        assertEq(
          uint256(accessManager.getTargetFunctionRole(updates[i].target, updates[i].selectors[j])),
          uint256(updates[i].roleId),
          'selector role differs from the deployment procedure'
        );
        ++wiredSelectors;
      }
    }

    assertEq(
      wiredSelectors,
      accessManager.assignmentCount(),
      'wiring covers a different selector count than the deployment procedure'
    );
  }

  function _assertSelectorsUnique(
    IAaveV4ConfigEngine.TargetFunctionRoleUpdate[] memory updates,
    string memory label
  ) internal pure {
    for (uint256 i; i < updates.length; ++i) {
      for (uint256 j; j < updates[i].selectors.length; ++j) {
        for (uint256 k = i; k < updates.length; ++k) {
          for (uint256 l = (k == i ? j + 1 : 0); l < updates[k].selectors.length; ++l) {
            assertTrue(
              updates[i].selectors[j] != updates[k].selectors[l],
              string.concat(label, ' selector wired twice')
            );
          }
        }
      }
    }
  }
}
