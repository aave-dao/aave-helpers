// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Monad} from 'aave-address-book/AaveV3Monad.sol';
import 'aave-v3-origin/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Base smart contract for an Aave v3.7.0 listing on v3 Monad.
 * @author Aave Labs
 */
abstract contract AaveV3PayloadMonad is AaveV3Payload(IEngine(AaveV3Monad.CONFIG_ENGINE)) {
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Monad', networkAbbreviation: 'Mon'});
  }
}
