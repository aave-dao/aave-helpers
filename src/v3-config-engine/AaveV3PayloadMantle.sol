// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Mantle} from 'aave-address-book/AaveV3Mantle.sol';
import 'aave-v3-origin/contracts/extensions/v3-config-engine/AaveV3Payload.sol';

/**
 * @dev Base smart contract for an Aave v3.3.0 listing on v3 Mantle.
 * @author BGD Labs
 */
abstract contract AaveV3PayloadMantle is AaveV3Payload(IEngine(AaveV3Mantle.CONFIG_ENGINE)) {
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Mantle', networkAbbreviation: 'Man'});
  }
}
