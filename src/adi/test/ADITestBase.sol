// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import 'forge-std/StdJson.sol';
import 'forge-std/Test.sol';
import {ICrossChainReceiver, ICrossChainForwarder} from 'aave-address-book/common/ICrossChainController.sol';
import {ChainIds} from '../../ChainIds.sol';
import {GovV3Helpers} from '../../GovV3Helpers.sol';

contract ADITestBase is Test {
  using stdJson for string;

  struct ReceiverConfigByChain {
    uint8 requiredConfirmations;
    uint256 chainId;
    uint256 validityTimestamp;
  }

  struct ReceiverAdaptersByChain {
    uint256 chainId;
    address[] receiverAdapters;
  }

  struct ForwarderAdaptersByChain {
    uint256 chainId;
    ICrossChainForwarder.ChainIdBridgeConfig[] forwarders;
  }

  struct CCCConfig {
    ReceiverConfigByChain[] receiverConfigs;
    ReceiverAdaptersByChain[] receiverAdaptersConfig;
    ForwarderAdaptersByChain[] forwarderAdaptersConfig;
  }

  function executePayload(Vm vm, address payload) internal {
    GovV3Helpers.executePayload(vm, payload);
  }

  /**
   * @dev generates the diff between two reports
   */
  function diffReports(string memory reportBefore, string memory reportAfter) internal {
    string memory outPath = string(
      abi.encodePacked('./diffs/', reportBefore, '_', reportAfter, '.md')
    );
    string memory beforePath = string(abi.encodePacked('./reports/', reportBefore, '.json'));
    string memory afterPath = string(abi.encodePacked('./reports/', reportAfter, '.json'));

    string[] memory inputs = new string[](7);
    inputs[0] = 'npx';
    inputs[1] = '@bgd-labs/aave-cli@^0.9.3';
    inputs[2] = 'diff-snapshots';
    inputs[3] = beforePath;
    inputs[4] = afterPath;
    inputs[5] = '-o';
    inputs[6] = outPath;
    vm.ffi(inputs);
  }

  function defaultTest(
    string memory reportName,
    address crossChainController,
    address payload,
    bool runE2E
  ) public returns (CCCConfig memory, CCCConfig memory) {
    string memory beforeString = string(abi.encodePacked('adi_', reportName, '_before'));
    CCCConfig memory configBefore = createConfigurationSnapshot(beforeString, crossChainController);

    executePayload(vm, payload);

    string memory afterString = string(abi.encodePacked('adi_', reportName, '_after'));
    CCCConfig memory configAfter = createConfigurationSnapshot(afterString, crossChainController);

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
  ) public returns (CCCConfig memory) {
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
    if (receiverConfigs) _writeReceiverConfigs(path, config);
    if (receiverAdapterConfigs) _writeReceiverAdapters(path, config);
    if (forwarderAdapterConfigs) _writeForwarderAdatpers(path, config);

    return config;
  }

  function _writeForwarderAdatpers(string memory path, CCCConfig memory config) internal {
    // keys for json stringification
    string memory forwarderAdaptersKey = 'forwarderAdapters';
    string memory content = '{}';
    vm.serializeJson(forwarderAdaptersKey, '{}');
    ForwarderAdaptersByChain[] memory forwarderConfig = config.forwarderAdaptersConfig;

    for (uint256 i = 0; i < forwarderConfig.length; i++) {
      uint256 chainId = forwarderConfig[i].chainId;
      string memory key = vm.toString(chainId);
      vm.serializeJson(key, '{}');
      string memory object;

      ICrossChainForwarder.ChainIdBridgeConfig[] memory forwarders = forwarderConfig[i].forwarders;
      for (uint256 j = 0; j < forwarders.length; j++) {
        if (j == forwarders.length - 1) {
          vm.serializeString(
            key,
            string.concat('origin_', vm.toString(j)),
            vm.toString(forwarders[j].currentChainBridgeAdapter)
          );
          object = vm.serializeString(
            key,
            string.concat('destination_', vm.toString(j)),
            vm.toString(forwarders[j].destinationBridgeAdapter)
          );
        } else {
          vm.serializeString(
            key,
            string.concat('origin_', vm.toString(j)),
            vm.toString(forwarders[j].currentChainBridgeAdapter)
          );
          vm.serializeString(
            key,
            string.concat('destination_', vm.toString(j)),
            vm.toString(forwarders[j].destinationBridgeAdapter)
          );
        }
      }
      content = vm.serializeString(forwarderAdaptersKey, key, object);
    }
    string memory output = vm.serializeString('root', 'forwarderAdaptersByChain', content);
    vm.writeJson(output, path);
  }

  function _writeReceiverAdapters(string memory path, CCCConfig memory config) internal {
    // keys for json stringification
    string memory receiverAdaptersKey = 'receiverAdapters';
    string memory content = '{}';
    vm.serializeJson(receiverAdaptersKey, '{}');
    ReceiverAdaptersByChain[] memory receiverConfig = config.receiverAdaptersConfig;

    for (uint256 i = 0; i < receiverConfig.length; i++) {
      uint256 chainId = receiverConfig[i].chainId;
      string memory key = vm.toString(chainId);
      vm.serializeJson(key, '{}');
      string memory object;

      for (uint256 j = 0; j < receiverConfig[i].receiverAdapters.length; j++) {
        if (j == receiverConfig[i].receiverAdapters.length - 1) {
          object = vm.serializeString(
            key,
            string.concat('receiver_', vm.toString(j)),
            vm.toString(receiverConfig[i].receiverAdapters[j])
          );
        } else {
          vm.serializeString(
            key,
            string.concat('receiver_', vm.toString(j)),
            vm.toString(receiverConfig[i].receiverAdapters[j])
          );
        }
      }
      content = vm.serializeString(receiverAdaptersKey, key, object);
    }
    string memory output = vm.serializeString('root', 'receiverAdaptersByChain', content);
    vm.writeJson(output, path);
  }

  function _writeReceiverConfigs(string memory path, CCCConfig memory configs) internal {
    // keys for json stringification
    string memory receiverConfigsKey = 'receiverConfigs';
    string memory content = '{}';
    vm.serializeJson(receiverConfigsKey, '{}');
    ReceiverConfigByChain[] memory receiverConfig = configs.receiverConfigs;
    for (uint256 i = 0; i < receiverConfig.length; i++) {
      uint256 chainId = receiverConfig[i].chainId;
      string memory key = vm.toString(chainId);
      vm.serializeJson(key, '{}');
      string memory object;
      vm.serializeString(
        key,
        'requiredConfirmations',
        vm.toString(receiverConfig[i].requiredConfirmations)
      );
      object = vm.serializeString(
        key,
        'validityTimestamp',
        vm.toString(receiverConfig[i].validityTimestamp)
      );

      content = vm.serializeString(receiverConfigsKey, key, object);
    }
    string memory output = vm.serializeString('root', 'receiverConfigs', content);
    vm.writeJson(output, path);
  }

  function _getCCCConfig(address ccc) internal returns (CCCConfig memory) {
    CCCConfig memory config;

    // get supported networks
    uint256[] memory receiverSupportedChains = ICrossChainReceiver(ccc).getSupportedChains();
    ReceiverConfigByChain[] memory receiverConfigs = new ReceiverConfigByChain[](
      receiverSupportedChains.length
    );
    ReceiverAdaptersByChain[] memory receiverAdaptersConfig = new ReceiverAdaptersByChain[](
      receiverSupportedChains.length
    );
    for (uint256 i = 0; i < receiverSupportedChains.length; i++) {
      uint256 chainId = receiverSupportedChains[i];
      ICrossChainReceiver.ReceiverConfiguration memory receiverConfig = ICrossChainReceiver(ccc)
        .getConfigurationByChain(chainId);
      receiverConfigs[i] = ReceiverConfigByChain({
        chainId: chainId,
        requiredConfirmations: receiverConfig.requiredConfirmation,
        validityTimestamp: receiverConfig.validityTimestamp
      });
      receiverAdaptersConfig[i] = ReceiverAdaptersByChain({
        chainId: chainId,
        receiverAdapters: ICrossChainReceiver(ccc).getReceiverBridgeAdaptersByChain(chainId)
      });
    }

    config.receiverAdaptersConfig = receiverAdaptersConfig;
    config.receiverConfigs = receiverConfigs;

    // get receiver configs by network
    uint256[] memory supportedForwardingNetworks = _getForwarderSupportedChainsByChainId(
      block.chainid
    );
    ForwarderAdaptersByChain[] memory forwardersByChain = new ForwarderAdaptersByChain[](
      supportedForwardingNetworks.length
    );
    for (uint256 i = 0; i < supportedForwardingNetworks.length; i++) {
      uint256 chainId = supportedForwardingNetworks[i];
      forwardersByChain[i] = ForwarderAdaptersByChain({
        chainId: chainId,
        forwarders: ICrossChainForwarder(ccc).getForwarderBridgeAdaptersByChain(chainId)
      });
    }
    config.forwarderAdaptersConfig = forwardersByChain;

    return config;
  }

  /// @dev Update when supporting new forwarding networks
  function _getForwarderSupportedChainsByChainId(
    uint256 chainId
  ) internal returns (uint256[] memory) {
    if (chainId == ChainIds.MAINNET) {
      uint256[] memory chainIds = new uint256[](11);
      chainIds[1] = ChainIds.MAINNET;
      chainIds[2] = ChainIds.POLYGON;
      chainIds[3] = ChainIds.AVALANCHE;
      chainIds[4] = ChainIds.BNB;
      chainIds[5] = ChainIds.GNOSIS;
      chainIds[6] = ChainIds.ARBITRUM;
      chainIds[7] = ChainIds.OPTIMISM;
      chainIds[8] = ChainIds.METIS;
      chainIds[9] = ChainIds.BASE;
      chainIds[10] = ChainIds.SCROLL;

      return chainIds;
    } else if (chainId == ChainIds.POLYGON) {
      uint256[] memory chainIds = new uint256[](1);
      chainIds[0] = ChainIds.MAINNET;

      return chainIds;
    } else if (chainId == ChainIds.AVALANCHE) {
      uint256[] memory chainIds = new uint256[](1);
      chainIds[0] = ChainIds.MAINNET;

      return chainIds;
    } else {
      return new uint256[](0);
    }
  }
}
