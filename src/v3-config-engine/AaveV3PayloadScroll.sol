// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Scroll} from 'aave-address-book/AaveV3Scroll.sol';
import 'aave-v3-origin/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Base smart contract for an Aave v3.1.0 listing on v3 Scroll.
 * @author BGD Labs
 */
abstract contract AaveV3PayloadScroll is AaveV3Payload(IEngine(AaveV3Scroll.CONFIG_ENGINE)) {
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Scroll', networkAbbreviation: 'Scr'});
  }
}
