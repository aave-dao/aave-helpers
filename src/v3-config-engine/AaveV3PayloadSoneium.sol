// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Soneium} from 'aave-address-book/AaveV3Soneium.sol';
import 'aave-v3-origin/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Base smart contract for an Aave v3.3.0 listing on v3 Soneium.
 * @author BGD Labs
 */
abstract contract AaveV3PayloadSoneium is AaveV3Payload(IEngine(AaveV3Soneium.CONFIG_ENGINE)) {
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Soneium', networkAbbreviation: 'Sone'});
  }
}
