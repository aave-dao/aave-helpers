// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Linea} from 'aave-address-book/AaveV3Linea.sol';
import 'aave-v3-origin/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Base smart contract for an Aave v3.2.0 listing on v3 Linea.
 * @author BGD Labs
 */
abstract contract AaveV3PayloadLinea is AaveV3Payload(IEngine(AaveV3Linea.CONFIG_ENGINE)) {
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Linea', networkAbbreviation: 'Lin'});
  }
}
