// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV2Avalanche} from 'aave-address-book/AaveV2Avalanche.sol';
import './AaveV2PayloadBase.sol';

/**
 * @dev Base smart contract for an Aave v2 rates update on Avalanche.
 * @author BGD Labs
 */
// TODO: Add rates factory address after deploying
abstract contract AaveV2PayloadAvalanche is
  AaveV2PayloadBase(IEngine(AaveV2Avalanche.LISTING_ENGINE))
{
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Avalanche', networkAbbreviation: 'Ava'});
  }
}
