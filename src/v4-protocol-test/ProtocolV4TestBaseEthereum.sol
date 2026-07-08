// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISpoke, IHub, ITokenizationSpoke, ISpokeConfigurator, PositionManagers} from 'aave-address-book/AaveV4.sol';
import {AaveV4Ethereum, AaveV4EthereumGetters} from 'aave-address-book/AaveV4Ethereum.sol';
import {ProtocolV4TestBase} from 'src/ProtocolV4TestBase.sol';

/// @title ProtocolV4TestBaseEthereum
/// @notice Ethereum binding of the chain-agnostic ProtocolV4TestBase, sourcing every
///         network entity from the aave-address-book getters.
contract ProtocolV4TestBaseEthereum is ProtocolV4TestBase {
  function _getHubs() internal view override returns (IHub[] memory) {
    return AaveV4EthereumGetters.getAllHubs();
  }

  function _getSpokes() internal view override returns (ISpoke[] memory) {
    return AaveV4EthereumGetters.getAllSpokes();
  }

  function _getTokenizationSpokes() internal view override returns (ITokenizationSpoke[] memory) {
    return AaveV4EthereumGetters.getAllTokenizationSpokes();
  }

  function _getPositionManagers() internal view override returns (PositionManagers memory) {
    return AaveV4EthereumGetters.getPositionManagers();
  }

  function _accessManager() internal view override returns (address) {
    return address(AaveV4Ethereum.ACCESS_MANAGER);
  }

  function _spokeConfigurator() internal view override returns (ISpokeConfigurator) {
    return AaveV4Ethereum.SPOKE_CONFIGURATOR;
  }
}
