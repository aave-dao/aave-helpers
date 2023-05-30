// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../v3-config-engine/AaveV3PayloadEthereum.sol';

/**
 * @dev Smart contract for a mock caps update, for testing purposes
 * IMPORTANT Parameters are pseudo-random, DON'T USE THIS ANYHOW IN PRODUCTION
 * @author BGD Labs
 */
contract AaveV3EthereumEModeAssetUpdate is AaveV3PayloadBase {
  constructor(IEngine customEngine) AaveV3PayloadBase(customEngine) {}

  function eModeAssetsUpdates() public pure override returns (IEngine.EModeAssetUpdate[] memory) {
    IEngine.EModeAssetUpdate[] memory eModeUpdate = new IEngine.EModeAssetUpdate[](1);

    eModeUpdate[0] = IEngine.EModeAssetUpdate({
      asset: AaveV3EthereumAssets.AAVE_UNDERLYING,
      eModeCategory: 1
    });

    return eModeUpdate;
  }

  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Ethereum', networkAbbreviation: 'Eth'});
  }
}