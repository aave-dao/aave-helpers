// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LayerZeroAdapter, IBaseAdapter} from './mainnet/LayerZeroAdapter/src/contracts/adapters/layerZero/LayerZeroAdapter.sol';

library LZAdapterDeploymentHelper {
  struct BaseAdapterArgs {
    address crossChainController;
    uint256 providerGasLimit;
    IBaseAdapter.TrustedRemotesConfig[] trustedRemotes;
    bool isTestnet;
  }

  function getAdapterCode(
    BaseAdapterArgs memory baseArgs,
    address lzEndpoint
  ) internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        type(LayerZeroAdapter).creationCode,
        abi.encode(
          lzEndpoint,
          baseArgs.crossChainController,
          baseArgs.providerGasLimit,
          baseArgs.trustedRemotes
        )
      );
  }
}
