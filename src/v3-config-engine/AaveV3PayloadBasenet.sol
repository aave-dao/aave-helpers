// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Basenet} from 'aave-address-book/AaveV3Basenet.sol';
import './AaveV3PayloadBase.sol';

/**
 * @dev Base smart contract for an Aave v3.0.2 (compatible with 3.0.0) listing on v3 Basenet.
 * @author BGD Labs
 */
abstract contract AaveV3PayloadBasenet is AaveV3PayloadBase(IEngine(AaveV3Basenet.LISTING_ENGINE)) {
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Base', networkAbbreviation: 'Bas'});
  }
}
