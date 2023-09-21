// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Base} from 'aave-address-book/AaveV3Base.sol';
import './AaveV3Payload.sol';

/**
 * @dev Base smart contract for an Aave v3.0.2 (compatible with 3.0.0) listing on v3 Base.
 * @author BGD Labs
 */
abstract contract AaveV3PayloadBase is AaveV3Payload(IEngine(AaveV3Base.LISTING_ENGINE)) {
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Base', networkAbbreviation: 'Bas'});
  }
}
