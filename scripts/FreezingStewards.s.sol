// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'solidity-utils/contracts/utils/ScriptUtils.sol';
import {FreezingSteward} from '../src/riskstewards/FreezingSteward.sol';
import {AaveV3BNB} from 'aave-address-book/AaveV3BNB.sol';
import {AaveV3Gnosis} from 'aave-address-book/AaveV3Gnosis.sol';
import {AaveV3Scroll} from 'aave-address-book/AaveV3Scroll.sol';

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

contract DeployScroll is ScrollScript {
  function run() external broadcast {
    new FreezingSteward(AaveV3Scroll.ACL_MANAGER, AaveV3Scroll.POOL_CONFIGURATOR);
  }
}
