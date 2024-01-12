// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../src/ScriptUtils.sol';
import {FreezingSteward} from '../src/riskstewards/FreezingSteward.sol';
import {AaveV3BNB} from 'aave-address-book/AaveV3BNB.sol';
import {AaveV3PolygonZkEvm} from 'aave-address-book/AaveV3PolygonZkEvm.sol';
import {AaveV3Gnosis} from 'aave-address-book/AaveV3Gnosis.sol';

contract DeployGno is GnosisScript {
  function run() external broadcast {
    new FreezingSteward(AaveV3Gnosis.ACL_MANAGER, AaveV3Gnosis.POOL_CONFIGURATOR);
  }
}

contract DeployBnb is BNBScript {
  function run() external broadcast {
    new FreezingSteward(AaveV3BNB.ACL_MANAGER, AaveV3BNB.POOL_CONFIGURATOR);
  }
}

contract DeployZkEvm is PolygonZkEvmScript {
  function run() external broadcast {
    new FreezingSteward(AaveV3PolygonZkEvm.ACL_MANAGER, AaveV3PolygonZkEvm.POOL_CONFIGURATOR);
  }
}
