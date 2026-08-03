// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAaveV4ConfigEngine} from 'aave-address-book/AaveV4.sol';
import {Roles} from 'aave-v4/deployments/utils/libraries/Roles.sol';

/// @title V4RoleWiring
/// @notice Builds the AccessManager role updates a freshly deployed Hub or Spoke needs, since a new
///         entity ships with its restricted selectors ungated on the shared AccessManager.
/// @author Aave Labs
library V4RoleWiring {
  /// @notice Role updates gating a new Hub's restricted selectors.
  /// @param authority The AccessManager governing the hub.
  /// @param hub The hub to wire.
  /// @return The three role updates to pass to `accessManagerTargetFunctionRoleUpdates`.
  function hubWiring(
    address authority,
    address hub
  ) internal pure returns (IAaveV4ConfigEngine.TargetFunctionRoleUpdate[] memory) {
    IAaveV4ConfigEngine.TargetFunctionRoleUpdate[]
      memory updates = new IAaveV4ConfigEngine.TargetFunctionRoleUpdate[](3);
    updates[0] = IAaveV4ConfigEngine.TargetFunctionRoleUpdate({
      authority: authority,
      target: hub,
      selectors: Roles.getHubConfiguratorRoleSelectors(),
      roleId: Roles.HUB_CONFIGURATOR_ROLE
    });
    updates[1] = IAaveV4ConfigEngine.TargetFunctionRoleUpdate({
      authority: authority,
      target: hub,
      selectors: Roles.getHubFeeMinterRoleSelectors(),
      roleId: Roles.HUB_FEE_MINTER_ROLE
    });
    updates[2] = IAaveV4ConfigEngine.TargetFunctionRoleUpdate({
      authority: authority,
      target: hub,
      selectors: Roles.getHubDeficitEliminatorRoleSelectors(),
      roleId: Roles.HUB_DEFICIT_ELIMINATOR_ROLE
    });
    return updates;
  }

  /// @notice Role updates gating a new Spoke's restricted selectors.
  /// @param authority The AccessManager governing the spoke.
  /// @param spoke The spoke to wire.
  /// @return The two role updates to pass to `accessManagerTargetFunctionRoleUpdates`.
  function spokeWiring(
    address authority,
    address spoke
  ) internal pure returns (IAaveV4ConfigEngine.TargetFunctionRoleUpdate[] memory) {
    IAaveV4ConfigEngine.TargetFunctionRoleUpdate[]
      memory updates = new IAaveV4ConfigEngine.TargetFunctionRoleUpdate[](2);
    updates[0] = IAaveV4ConfigEngine.TargetFunctionRoleUpdate({
      authority: authority,
      target: spoke,
      selectors: Roles.getSpokeConfiguratorRoleSelectors(),
      roleId: Roles.SPOKE_CONFIGURATOR_ROLE
    });
    updates[1] = IAaveV4ConfigEngine.TargetFunctionRoleUpdate({
      authority: authority,
      target: spoke,
      selectors: Roles.getSpokePositionUpdaterRoleSelectors(),
      roleId: Roles.SPOKE_USER_POSITION_UPDATER_ROLE
    });
    return updates;
  }

  /// @notice Concatenate two role update arrays into the single array the engine consumes.
  /// @param a The updates to place first.
  /// @param b The updates to append.
  /// @return The concatenation of `a` and `b`.
  function merge(
    IAaveV4ConfigEngine.TargetFunctionRoleUpdate[] memory a,
    IAaveV4ConfigEngine.TargetFunctionRoleUpdate[] memory b
  ) internal pure returns (IAaveV4ConfigEngine.TargetFunctionRoleUpdate[] memory) {
    IAaveV4ConfigEngine.TargetFunctionRoleUpdate[]
      memory merged = new IAaveV4ConfigEngine.TargetFunctionRoleUpdate[](a.length + b.length);
    uint256 index;
    for (uint256 i; i < a.length; ++i) {
      merged[index++] = a[i];
    }
    for (uint256 i; i < b.length; ++i) {
      merged[index++] = b[i];
    }
    return merged;
  }
}
