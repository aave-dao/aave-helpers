// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../src/ScriptUtils.sol';
import {FreezingSteward} from '../src/riskstewards/FreezingSteward.sol';
import {AaveV3Gnosis} from 'aave-address-book/AaveV3Gnosis.sol';

contract DeployGno is GnosisScript {
  function run() external broadcast {
    new FreezingSteward(
      AaveV3Gnosis.ACL_MANAGER,
      AaveV3Gnosis.POOL_CONFIGURATOR
    );
  }
}
