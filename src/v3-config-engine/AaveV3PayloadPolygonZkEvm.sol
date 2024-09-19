// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3PolygonZkEvm} from 'aave-address-book/AaveV3PolygonZkEvm.sol';
import 'aave-v3-origin/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Base smart contract for an Aave v3.1.0 listing on v3 Polygon ZkEvm.
 * @author BGD Labs
 */
abstract contract AaveV3PayloadPolygonZkEvm is
  AaveV3Payload(IEngine(AaveV3PolygonZkEvm.CONFIG_ENGINE))
{
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'PolygonZkEvm', networkAbbreviation: 'PolZkEvm'});
  }
}
