// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3InkWhitelabel} from 'aave-address-book/AaveV3InkWhitelabel.sol';
import 'aave-v3-origin/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Base smart contract for an Aave v3.5.0 listing on v3 Ink Whitelabel.
 * @author BGD Labs
 */
abstract contract AaveV3PayloadInkWhitelabel is
  AaveV3Payload(IEngine(AaveV3InkWhitelabel.CONFIG_ENGINE))
{
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'InkWhitelabel', networkAbbreviation: 'InkWl'});
  }
}
