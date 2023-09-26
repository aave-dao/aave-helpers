// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../src/v3-config-engine/AaveV3PayloadAvalanche.sol';
import {AaveV3AvalancheAssets} from 'aave-address-book/AaveV3Avalanche.sol';

/**
 * @dev Smart contract for a mock collateral update with no changes, for testing purposes
 * IMPORTANT Parameters are pseudo-random, DON'T USE THIS ANYHOW IN PRODUCTION
 * @author BGD Labs
 */
contract AaveV3AvalancheCollateralUpdateNoChange is AaveV3Payload {
  constructor(IEngine customEngine) AaveV3Payload(customEngine) {}

  function collateralsUpdates() public pure override returns (IEngine.CollateralUpdate[] memory) {
    IEngine.CollateralUpdate[] memory collateralsUpdate = new IEngine.CollateralUpdate[](1);

    collateralsUpdate[0] = IEngine.CollateralUpdate({
      asset: AaveV3AvalancheAssets.AAVEe_UNDERLYING,
      ltv: EngineFlags.KEEP_CURRENT,
      liqThreshold: EngineFlags.KEEP_CURRENT,
      liqBonus: EngineFlags.KEEP_CURRENT,
      debtCeiling: EngineFlags.KEEP_CURRENT,
      liqProtocolFee: EngineFlags.KEEP_CURRENT
    });

    return collateralsUpdate;
  }

  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Avalanche', networkAbbreviation: 'Ava'});
  }
}
