// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3ZkSync} from 'aave-address-book/AaveV3ZkSync.sol';
import 'aave-v3-origin/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Base smart contract for an Aave v3.1.0 listing on v3 ZkSync.
 * @author BGD Labs
 */
abstract contract AaveV3PayloadZkSync is AaveV3Payload(IEngine(AaveV3ZkSync.CONFIG_ENGINE)) {
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'ZkSync', networkAbbreviation: 'Zks'});
  }
}
