// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISpoke, IHub, ITokenizationSpoke, ISpokeConfigurator, PositionManagers} from 'aave-address-book/AaveV4.sol';
import {AaveV4EthereumSentoraCurated, AaveV4EthereumSentoraCuratedGetters} from 'aave-address-book/AaveV4EthereumSentoraCurated.sol';
import {ProtocolV4TestBase} from 'src/ProtocolV4TestBase.sol';

/// @title ProtocolV4TestBaseEthereumSentoraCurated
/// @notice Ethereum Sentora curated market binding of the chain-agnostic ProtocolV4TestBase,
///         sourcing every network entity from the aave-address-book getters.
contract ProtocolV4TestBaseEthereumSentoraCurated is ProtocolV4TestBase {
  function _getHubs() internal view virtual override returns (IHub[] memory) {
    return AaveV4EthereumSentoraCuratedGetters.getAllHubs();
  }

  function _getSpokes() internal view virtual override returns (ISpoke[] memory) {
    return AaveV4EthereumSentoraCuratedGetters.getAllSpokes();
  }

  function _getTokenizationSpokes()
    internal
    view
    virtual
    override
    returns (ITokenizationSpoke[] memory)
  {
    return new ITokenizationSpoke[](0);
  }

  function _getPositionManagers() internal view virtual override returns (PositionManagers memory) {
    return AaveV4EthereumSentoraCuratedGetters.getPositionManagers();
  }

  function _accessManager() internal view virtual override returns (address) {
    return address(AaveV4EthereumSentoraCurated.ACCESS_MANAGER);
  }

  function _spokeConfigurator() internal view virtual override returns (ISpokeConfigurator) {
    return AaveV4EthereumSentoraCurated.SPOKE_CONFIGURATOR;
  }
}
