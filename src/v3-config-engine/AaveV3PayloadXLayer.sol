// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3XLayer} from 'aave-address-book/AaveV3XLayer.sol';
import 'aave-v3-origin/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Base smart contract for an Aave v3.6.0 listing on v3 XLayer.
 * @author BGD Labs
 */
abstract contract AaveV3PayloadXLayer is AaveV3Payload(IEngine(AaveV3XLayer.CONFIG_ENGINE)) {
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'XLayer', networkAbbreviation: 'Xlr'});
  }
}
