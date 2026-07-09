// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISpoke, IHub, ITokenizationSpoke, ISpokeConfigurator, PositionManagers} from 'aave-address-book/AaveV4.sol';
import {AaveV4Avalanche, AaveV4AvalancheGetters} from 'aave-address-book/AaveV4Avalanche.sol';
import {ProtocolV4TestBase} from 'src/ProtocolV4TestBase.sol';

/// @title ProtocolV4TestBaseAvalanche
/// @notice Avalanche binding of the chain-agnostic ProtocolV4TestBase, sourcing every
///         network entity from the aave-address-book getters.
contract ProtocolV4TestBaseAvalanche is ProtocolV4TestBase {
  function _getHubs() internal view virtual override returns (IHub[] memory) {
    return AaveV4AvalancheGetters.getAllHubs();
  }

  function _getSpokes() internal view virtual override returns (ISpoke[] memory) {
    return AaveV4AvalancheGetters.getAllSpokes();
  }

  function _getTokenizationSpokes()
    internal
    view
    virtual
    override
    returns (ITokenizationSpoke[] memory)
  {
    return AaveV4AvalancheGetters.getAllTokenizationSpokes();
  }

  function _getPositionManagers() internal view virtual override returns (PositionManagers memory) {
    return AaveV4AvalancheGetters.getPositionManagers();
  }

  function _accessManager() internal view virtual override returns (address) {
    return address(AaveV4Avalanche.ACCESS_MANAGER);
  }

  function _spokeConfigurator() internal view virtual override returns (ISpokeConfigurator) {
    return AaveV4Avalanche.SPOKE_CONFIGURATOR;
  }
}
