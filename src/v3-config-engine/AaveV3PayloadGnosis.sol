// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Gnosis} from 'aave-address-book/AaveV3Gnosis.sol';
import './AaveV3Payload.sol';

/**
 * @dev Base smart contract for an Aave v3.0.2 (compatible with 3.0.0) listing on v3 Gnosis.
 * @author BGD Labs
 */
abstract contract AaveV3PayloadGnosis is AaveV3Payload(IEngine(AaveV3Gnosis.CONFIG_ENGINE)) {
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Gnosis', networkAbbreviation: 'Gno'});
  }
}
