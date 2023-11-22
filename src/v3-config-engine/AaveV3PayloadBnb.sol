// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Bnb} from 'aave-address-book/AaveV3Bnb.sol';
import './AaveV3Payload.sol';

/**
 * @dev Base smart contract for an Aave v3.0.2 (compatible with 3.0.0) listing on v3 Bnb.
 * @author BGD Labs
 */
abstract contract AaveV3PayloadBnb is AaveV3Payload(IEngine(AaveV3Bnb.CONFIG_ENGINE)) {
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'BNB Smart Chain', networkAbbreviation: 'Bnb'});
  }
}
