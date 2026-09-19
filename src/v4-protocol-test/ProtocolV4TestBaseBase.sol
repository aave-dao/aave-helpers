// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISpoke, IHub, ITokenizationSpoke, ISpokeConfigurator, PositionManagers} from 'aave-address-book/AaveV4.sol';
import {AaveV4Base, AaveV4BaseGetters} from 'aave-address-book/AaveV4Base.sol';
import {ProtocolV4TestBase} from 'src/ProtocolV4TestBase.sol';

/// @title ProtocolV4TestBaseBase
/// @notice Base binding of the chain-agnostic ProtocolV4TestBase, sourcing every
///         network entity from the aave-address-book getters.
contract ProtocolV4TestBaseBase is ProtocolV4TestBase {
  function _getHubs() internal view virtual override returns (IHub[] memory) {
    return AaveV4BaseGetters.getAllHubs();
  }

  function _getSpokes() internal view virtual override returns (ISpoke[] memory) {
    return AaveV4BaseGetters.getAllSpokes();
  }

  function _getTokenizationSpokes()
    internal
    view
    virtual
    override
    returns (ITokenizationSpoke[] memory)
  {
    return AaveV4BaseGetters.getAllTokenizationSpokes();
  }

  function _getPositionManagers() internal view virtual override returns (PositionManagers memory) {
    return AaveV4BaseGetters.getPositionManagers();
  }

  function _accessManager() internal view virtual override returns (address) {
    return address(AaveV4Base.ACCESS_MANAGER);
  }

  function _spokeConfigurator() internal view virtual override returns (ISpokeConfigurator) {
    return AaveV4Base.SPOKE_CONFIGURATOR;
  }
}
