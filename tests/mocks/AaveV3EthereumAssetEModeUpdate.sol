// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../src/v3-config-engine/AaveV3PayloadEthereum.sol';

/**
 * @dev Smart contract for a mock asset e-mode update, for testing purposes
 * IMPORTANT Parameters are pseudo-random, DON'T USE THIS ANYHOW IN PRODUCTION
 * @author BGD Labs
 */
contract AaveV3EthereumAssetEModeUpdate is AaveV3PayloadBase {
  constructor(IEngine customEngine) AaveV3PayloadBase(customEngine) {}

  function assetsEModeUpdates() public pure override returns (IEngine.AssetEModeUpdate[] memory) {
    IEngine.AssetEModeUpdate[] memory eModeUpdate = new IEngine.AssetEModeUpdate[](1);

    eModeUpdate[0] = IEngine.AssetEModeUpdate({
      asset: AaveV3EthereumAssets.rETH_UNDERLYING,
      eModeCategory: 1
    });

    return eModeUpdate;
  }

  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Ethereum', networkAbbreviation: 'Eth'});
  }
}