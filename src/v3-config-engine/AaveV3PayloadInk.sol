// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Ink} from 'aave-address-book/AaveV3Ink.sol';
import 'aave-v3-origin/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Base smart contract for an Aave v3.2.0 listing on v3 Ink.
 * @author BGD Labs
 */
abstract contract AaveV3PayloadInk is AaveV3Payload(IEngine(AaveV3Ink.CONFIG_ENGINE)) {
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Ink', networkAbbreviation: 'Ink'});
  }
}
