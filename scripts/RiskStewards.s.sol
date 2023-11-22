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
import {AaveV3Base} from 'aave-address-book/AaveV3Base.sol';
import {AaveV3Gnosis} from 'aave-address-book/AaveV3Gnosis.sol';
import {AaveV3Bnb} from 'aave-address-book/AaveV3Bnb.sol';

contract DeployEth is EthereumScript {
  function run() external broadcast {
    new CapsPlusRiskSteward(
      AaveV3Ethereum.AAVE_PROTOCOL_DATA_PROVIDER,
      IAaveV3ConfigEngine(AaveV3Ethereum.CONFIG_ENGINE),
      0x47c71dFEB55Ebaa431Ae3fbF99Ea50e0D3d30fA8
    );
  }
}

contract DeployPol is PolygonScript {
  function run() external broadcast {
    new CapsPlusRiskSteward(
      AaveV3Polygon.AAVE_PROTOCOL_DATA_PROVIDER,
      IAaveV3ConfigEngine(AaveV3Polygon.CONFIG_ENGINE),
      0x2C40FB1ACe63084fc0bB95F83C31B5854C6C4cB5
    );
  }
}

contract DeployOpt is OptimismScript {
  function run() external broadcast {
    new CapsPlusRiskSteward(
      AaveV3Optimism.AAVE_PROTOCOL_DATA_PROVIDER,
      IAaveV3ConfigEngine(AaveV3Optimism.CONFIG_ENGINE),
      0xCb86256A994f0c505c5e15c75BF85fdFEa0F2a56
    );
  }
}

contract DeployArb is ArbitrumScript {
  function run() external broadcast {
    new CapsPlusRiskSteward(
      AaveV3Arbitrum.AAVE_PROTOCOL_DATA_PROVIDER,
      IAaveV3ConfigEngine(AaveV3Arbitrum.CONFIG_ENGINE),
      0x3Be327F22eB4BD8042e6944073b8826dCf357Aa2
    );
  }
}

contract DeployMet is MetisScript {
  function run() external broadcast {
    new CapsPlusRiskSteward(
      AaveV3Metis.AAVE_PROTOCOL_DATA_PROVIDER,
      IAaveV3ConfigEngine(AaveV3Metis.CONFIG_ENGINE),
      0x0f547846920C34E70FBE4F3d87E46452a3FeAFfa
    );
  }
}

contract DeployAva is AvalancheScript {
  function run() external broadcast {
    new CapsPlusRiskSteward(
      AaveV3Avalanche.AAVE_PROTOCOL_DATA_PROVIDER,
      IAaveV3ConfigEngine(AaveV3Avalanche.CONFIG_ENGINE),
      0xCa66149425E7DC8f81276F6D80C4b486B9503D1a
    );
  }
}

contract DeployBas is BaseScript {
  function run() external broadcast {
    new CapsPlusRiskSteward(
      AaveV3Base.AAVE_PROTOCOL_DATA_PROVIDER,
      IAaveV3ConfigEngine(AaveV3Base.CONFIG_ENGINE),
      0xfbeB4AcB31340bA4de9C87B11dfBf7e2bc8C0bF1
    );
  }
}

contract DeployGno is GnosisScript {
  function run() external broadcast {
    new CapsPlusRiskSteward(
      AaveV3Gnosis.AAVE_PROTOCOL_DATA_PROVIDER,
      IAaveV3ConfigEngine(AaveV3Gnosis.CONFIG_ENGINE),
      0xF221B08dD10e0C68D74F035764931Baa3b030481
    );
  }
}

contract DeployBnb is BNBScript {
  function run() external broadcast {
    new CapsPlusRiskSteward(
      AaveV3Bnb.AAVE_PROTOCOL_DATA_PROVIDER,
      IAaveV3ConfigEngine(AaveV3Bnb.CONFIG_ENGINE),
      0x126dc589cc75f17385dD95516F3F1788d862E7bc
    );
  }
}