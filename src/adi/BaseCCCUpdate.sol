// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {TransparentUpgradeableProxy} from 'solidity-utils/contracts/transparent-proxy/TransparentUpgradeableProxy.sol';
import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';
import {ProxyAdmin} from 'solidity-utils/contracts/transparent-proxy/ProxyAdmin.sol';
import './BaseADIPayloadUpdate.sol';

/**
 * @param crossChainController address of the CCC of the network where payload will be deployed
 * @param newCCCImpl address of the new ccc implementation
 * @param proxyAdmin address of the proxy admin owner of ccc
 */
struct CCCUpdateArgs {
  address crossChainController;
  address crossChainControllerImpl;
  address proxyAdmin;
}

/**
 * @title Base payload to update CCC
 * @author BGD Labs @bgdlabs
 */
abstract contract BaseCCCUpdate is BaseADIPayloadUpdate {
  address public immutable NEW_CCC_IMPL;
  address public immutable PROXY_ADMIN;

  /*
   * @param cccUpdateArgs arguments necessary to update ccc implementation
   */
  constructor(
    CCCUpdateArgs memory cccUpdateArgs
  ) BaseADIPayloadUpdate(cccUpdateArgs.crossChainController) {
    NEW_CCC_IMPL = cccUpdateArgs.crossChainControllerImpl;
    PROXY_ADMIN = cccUpdateArgs.proxyAdmin;
  }

  function getInitializeSignature() public virtual returns (bytes memory);

  /// @inheritdoc IProposalGenericExecutor
  function execute() external virtual override {
    ProxyAdmin(PROXY_ADMIN).upgradeAndCall(
      TransparentUpgradeableProxy(payable(CROSS_CHAIN_CONTROLLER)),
      NEW_CCC_IMPL,
      getInitializeSignature()
    );
  }
}
