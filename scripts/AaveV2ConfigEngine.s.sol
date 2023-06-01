// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV2ConfigEngine} from '../src/v2-config-engine/AaveV2ConfigEngine.sol';
import {IV2RateStrategyFactory} from '../src/v2-config-engine/IV2RateStrategyFactory.sol';
import '../src/ScriptUtils.sol';

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
    DeployV2EngineEthLib.deploy(address(0)); // TODO
  }
}

contract DeployV2EngineEthAMM is EthereumScript {
  function run() external broadcast {
    DeployV2EngineEthAMMLib.deploy(address(0)); // TODO
  }
}

contract DeployV2EnginePol is PolygonScript {
  function run() external broadcast {
    DeployV2EnginePolLib.deploy(address(0)); // TODO
  }
}

contract DeployV2EngineAva is AvalancheScript {
  function run() external broadcast {
    DeployV2EngineAvaLib.deploy(address(0)); // TODO
  }
}
