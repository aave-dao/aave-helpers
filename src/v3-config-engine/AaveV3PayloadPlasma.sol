// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Plasma} from 'aave-address-book/AaveV3Plasma.sol';
import 'aave-v3-origin/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Base smart contract for an Aave v3.5.0 listing on v3 Plasma.
 * @author BGD Labs
 */
abstract contract AaveV3PayloadPlasma is AaveV3Payload(IEngine(AaveV3Plasma.CONFIG_ENGINE)) {
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Plasma', networkAbbreviation: 'Pla'});
  }
}
