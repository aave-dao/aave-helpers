// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'solidity-utils/contracts/utils/ScriptUtils.sol';
import {AaveV2Ethereum} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV2EthereumAMM} from 'aave-address-book/AaveV2EthereumAMM.sol';
import {AaveV2Polygon} from 'aave-address-book/AaveV2Polygon.sol';
import {AaveV2Avalanche} from 'aave-address-book/AaveV2Avalanche.sol';

import {AaveV2ConfigEngine} from '../src/v2-config-engine/AaveV2ConfigEngine.sol';
import {IV2RateStrategyFactory} from '../src/v2-config-engine/IV2RateStrategyFactory.sol';

library DeployV2EngineEthLib {
  function deploy(address ratesFactory) internal returns (address) {
    return
      address(
        new AaveV2ConfigEngine(
          AaveV2Ethereum.POOL_CONFIGURATOR,
          IV2RateStrategyFactory(ratesFactory)
        )
      );
  }
}

library DeployV2EngineEthAMMLib {
  function deploy(address ratesFactory) internal returns (address) {
    return
      address(
        new AaveV2ConfigEngine(
          AaveV2EthereumAMM.POOL_CONFIGURATOR,
          IV2RateStrategyFactory(ratesFactory)
        )
      );
  }
}

library DeployV2EnginePolLib {
  function deploy(address ratesFactory) internal returns (address) {
    return
      address(
        new AaveV2ConfigEngine(
          AaveV2Polygon.POOL_CONFIGURATOR,
          IV2RateStrategyFactory(ratesFactory)
        )
      );
  }
}

library DeployV2EngineAvaLib {
  function deploy(address ratesFactory) internal returns (address) {
    return
      address(
        new AaveV2ConfigEngine(
          AaveV2Avalanche.POOL_CONFIGURATOR,
          IV2RateStrategyFactory(ratesFactory)
        )
      );
  }
}

contract DeployV2EngineEth is EthereumScript {
  function run() external broadcast {
    DeployV2EngineEthLib.deploy(0xbD37610BBB1ddc2a22797F7e3f531B59902b7bA7);
  }
}

contract DeployV2EngineEthAMM is EthereumScript {
  function run() external broadcast {
    DeployV2EngineEthAMMLib.deploy(0x6e4D068105052C3877116DCF86f5FF36B7eCa2B8);
  }
}

contract DeployV2EnginePol is PolygonScript {
  function run() external broadcast {
    DeployV2EnginePolLib.deploy(0xD05003a24A17d9117B11eC04cF9743b050779c08);
  }
}

contract DeployV2EngineAva is AvalancheScript {
  function run() external broadcast {
    DeployV2EngineAvaLib.deploy(0x6e66E50870A93691C1b953788A3219e01fDdeDD7);
  }
}
