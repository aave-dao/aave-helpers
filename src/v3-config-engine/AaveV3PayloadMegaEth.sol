// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3MegaEth} from 'aave-address-book/AaveV3MegaEth.sol';
import 'aave-v3-origin/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Base smart contract for an Aave v3.6.0 listing on v3 MegaEth.
 * @author BGD Labs
 */
abstract contract AaveV3PayloadMegaEth is AaveV3Payload(IEngine(AaveV3MegaEth.CONFIG_ENGINE)) {
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'MegaEth', networkAbbreviation: 'Meg'});
  }
}
