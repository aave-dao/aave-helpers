// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import 'forge-std/StdJson.sol';
import 'forge-std/Test.sol';

contract ADITestBase is Test {
  using stdJson for string;

  struct ReceiverConfigByChain {
    uint8 requiredConfirmations;
    uint256 chainId;
    uint256 invalidationTimestamp;
  }

  struct ReceiverAdaptersByChain {
    uint256 chainId;
    address[] receiverAdapters;
  }

  struct ForwarderPath {
    address originAdapter;
    address destinationAdapter;
  }

  struct ForwarderAdaptersByChain {
    uint256 chainId;
    ForwarderPath[] forwarders;
  }

  struct CCCConfig {
    ReceiverConfigByChain[] receiverConfigs;
    ReceiverAdaptersByChain[] receiverAdaptersConfig;
    ForwarderAdaptersByChain[] forwarderAdaptersConfig;
  }

  function executePayload(Vm vm, address payload) internal {
    GovV3Helpers.executePayload(vm, payload);
  }

  function defaultTest(
    string memory reportName,
    address crossChainController,
    address payload,
    bool runE2E
  ) public returns (CCCConfig[] memory, CCCConfig[] memory) {
    string memory beforeString = string(abi.encodePacked('adi_', reportName, '_before'));
    CCCConfig[] memory configBefore = createConfigurationSnapshot(beforeString, pool);

    executePayload(vm, payload);

    string memory afterString = string(abi.encodePacked('adi_', reportName, '_after'));
    CCCConfig[] memory configAfter = createConfigurationSnapshot(afterString, pool);

    diffReports(beforeString, afterString);

    //    configChangePlausibilityTest(configBefore, configAfter);
    //
    //    if (runE2E) e2eTest(pool);
    return (configBefore, configAfter);
  }

  /**
   * @dev Generates a markdown compatible snapshot of the whole CrossChainController configuration into `/reports`.
   * @param reportName filename suffix for the generated reports.
   * @param crossChainController the ccc to be snapshot
   * @return ReserveConfig[] list of configs
   */
  function createConfigurationSnapshot(
    string memory reportName,
    address crossChainController
  ) public returns (CCCConfig[] memory) {
    return createConfigurationSnapshot(reportName, crossChainController, true, true, true);
  }

  function createConfigurationSnapshot(
    string memory reportName,
    address crossChainController,
    bool receiverConfigs,
    bool receiverAdapterConfigs,
    bool forwarderAdapterConfigs
  ) public returns (CCCConfig memory) {
    string memory path = string(abi.encodePacked('./reports/', reportName, '.json'));
    // overwrite with empty json to later be extended
    vm.writeFile(
      path,
      '{ "receiverConfigsByChain": {}, "receiverAdaptersByChain": {}, "forwarderAdaptersByChain": {}}'
    );
    vm.serializeUint('root', 'chainId', block.chainid);
    CCCConfig memory config = _getCCCConfig(crossChainController);
    if (receiverConfigs) _writeReserveConfigs(path, configs, pool);
    if (receiverAdapterConfigs) _writeStrategyConfigs(path, configs);
    if (forwarderAdapterConfigs) _writeEModeConfigs(path, configs, pool);

    return configs;
  }
}
