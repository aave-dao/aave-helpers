// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Sonic} from 'aave-address-book/AaveV3Sonic.sol';
import 'aave-v3-origin/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Base smart contract for an Aave v3.3.0 listing on v3 Sonic.
 * @author BGD Labs
 */
abstract contract AaveV3PayloadSonic is AaveV3Payload(IEngine(AaveV3Sonic.CONFIG_ENGINE)) {
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Sonic', networkAbbreviation: 'Son'});
  }
}
