// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../src/ScriptUtils.sol';
import {CapsPlusRiskSteward} from '../src/riskstewards/CapsPlusRiskSteward.sol';
import {IAaveV3ConfigEngine} from '../src/v3-config-engine/IAaveV3ConfigEngine.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3Polygon} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveV3Avalanche} from 'aave-address-book/AaveV3Avalanche.sol';
import {AaveV3Metis} from 'aave-address-book/AaveV3Metis.sol';
import {AaveV3Arbitrum} from 'aave-address-book/AaveV3Arbitrum.sol';
import {AaveV3Optimism} from 'aave-address-book/AaveV3Optimism.sol';

contract DeployEth is EthereumScript {
  function run() external broadcast {
    new CapsPlusRiskSteward(
      AaveV3Ethereum.AAVE_PROTOCOL_DATA_PROVIDER,
      IAaveV3ConfigEngine(AaveV3Ethereum.LISTING_ENGINE),
      0x47c71dFEB55Ebaa431Ae3fbF99Ea50e0D3d30fA8
    );
  }
}

contract DeployPol is PolygonScript {
  function run() external broadcast {
    new CapsPlusRiskSteward(
      AaveV3Polygon.AAVE_PROTOCOL_DATA_PROVIDER,
      IAaveV3ConfigEngine(AaveV3Polygon.LISTING_ENGINE),
      0x2C40FB1ACe63084fc0bB95F83C31B5854C6C4cB5
    );
  }
}

contract DeployOpt is OptimismScript {
  function run() external broadcast {
    new CapsPlusRiskSteward(
      AaveV3Optimism.AAVE_PROTOCOL_DATA_PROVIDER,
      IAaveV3ConfigEngine(AaveV3Optimism.LISTING_ENGINE),
      0xCb86256A994f0c505c5e15c75BF85fdFEa0F2a56
    );
  }
}

contract DeployArb is ArbitrumScript {
  function run() external broadcast {
    new CapsPlusRiskSteward(
      AaveV3Arbitrum.AAVE_PROTOCOL_DATA_PROVIDER,
      IAaveV3ConfigEngine(AaveV3Arbitrum.LISTING_ENGINE),
      0x3Be327F22eB4BD8042e6944073b8826dCf357Aa2
    );
  }
}

contract DeployMet is MetisScript {
  function run() external broadcast {
    new CapsPlusRiskSteward(
      AaveV3Metis.AAVE_PROTOCOL_DATA_PROVIDER,
      IAaveV3ConfigEngine(AaveV3Metis.LISTING_ENGINE),
      0x0f547846920C34E70FBE4F3d87E46452a3FeAFfa
    );
  }
}

contract DeployAva is AvalancheScript {
  function run() external broadcast {
    new CapsPlusRiskSteward(
      AaveV3Avalanche.AAVE_PROTOCOL_DATA_PROVIDER,
      IAaveV3ConfigEngine(AaveV3Avalanche.LISTING_ENGINE),
      0xCa66149425E7DC8f81276F6D80C4b486B9503D1a
    );
  }
}
