// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Celo} from 'aave-address-book/AaveV3Celo.sol';
import 'aave-v3-origin/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Base smart contract for an Aave v3.3.0 listing on v3 Celo.
 * @author BGD Labs
 */
abstract contract AaveV3PayloadCelo is AaveV3Payload(IEngine(AaveV3Celo.CONFIG_ENGINE)) {
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Celo', networkAbbreviation: 'Cel'});
  }
}
