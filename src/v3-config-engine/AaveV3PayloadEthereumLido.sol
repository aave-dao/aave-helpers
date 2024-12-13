// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3EthereumLido} from 'aave-address-book/AaveV3EthereumLido.sol';
import 'aave-v3-origin/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Base smart contract for an Aave v3.1.0 listing on v3 Ethereum Lido.
 * @author BGD Labs
 */
abstract contract AaveV3PayloadEthereumLido is
  AaveV3Payload(IEngine(AaveV3EthereumLido.CONFIG_ENGINE))
{
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Ethereum Lido', networkAbbreviation: 'EthLido'});
  }
}
