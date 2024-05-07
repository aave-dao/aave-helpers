// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MockAdapter, IBaseAdapter} from './AdapterMock.sol';

library MockAdapterDeploymentHelper {
  struct BaseAdapterArgs {
    address crossChainController;
    uint256 providerGasLimit;
    IBaseAdapter.TrustedRemotesConfig[] trustedRemotes;
    bool isTestnet;
  }

  struct MockAdapterArgs {
    BaseAdapterArgs baseArgs;
    address mockEndpoint;
  }

  function getAdapterCode(MockAdapterArgs memory mockArgs) internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        type(MockAdapter).creationCode,
        abi.encode(
          mockArgs.mockEndpoint,
          mockArgs.baseArgs.crossChainController,
          mockArgs.baseArgs.providerGasLimit,
          mockArgs.baseArgs.trustedRemotes
        )
      );
  }
}
