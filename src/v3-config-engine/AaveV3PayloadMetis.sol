// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Metis, AaveV3MetisAssets} from 'aave-address-book/AaveV3Metis.sol';
import './AaveV3PayloadBase.sol';

/**
 * @dev Base smart contract for an Aave v3.0.2 (compatible with 3.0.0) listing on v3 Metis.
 * @author BGD Labs
 */
abstract contract AaveV3PayloadMetis is AaveV3PayloadBase(IEngine(AaveV3Metis.LISTING_ENGINE)) {
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Metis', networkAbbreviation: 'Met'});
  }
}
