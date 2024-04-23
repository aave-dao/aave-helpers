// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import 'forge-std/StdJson.sol';
import 'forge-std/Test.sol';
import {ICrossChainReceiver, ICrossChainForwarder} from 'aave-address-book/common/ICrossChainController.sol';
import {ChainIds, ChainHelpers} from '../../ChainIds.sol';
import {GovV3Helpers} from '../../GovV3Helpers.sol';
import {IBaseAdaptersUpdate} from '../interfaces/IBaseAdaptersUpdate.sol';

import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {GovernanceV3Polygon} from 'aave-address-book/GovernanceV3Polygon.sol';
import {GovernanceV3Avalanche} from 'aave-address-book/GovernanceV3Avalanche.sol';
import {GovernanceV3Optimism} from 'aave-address-book/GovernanceV3Optimism.sol';
import {GovernanceV3BNB} from 'aave-address-book/GovernanceV3BNB.sol';
import {GovernanceV3Metis} from 'aave-address-book/GovernanceV3Metis.sol';
import {GovernanceV3Base} from 'aave-address-book/GovernanceV3Base.sol';
import {GovernanceV3Arbitrum} from 'aave-address-book/GovernanceV3Arbitrum.sol';
import {GovernanceV3Gnosis} from 'aave-address-book/GovernanceV3Gnosis.sol';
import {GovernanceV3Scroll} from 'aave-address-book/GovernanceV3Scroll.sol';
import {IBaseAdapter} from 'aave-address-book/common/IBaseAdapter.sol';

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

  struct ForwarderAdapters {
    ICrossChainForwarder.ChainIdBridgeConfig[] adapters;
    uint256 chainId;
  }

  struct AdaptersByChain {
    address[] adapters;
    uint256 chainId;
  }

  struct DestinationPayload {
    uint256 chainId;
    bytes payloadCode;
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
    inputs[1] = '@bgd-labs/aave-cli@^0.12.0';
    inputs[2] = 'adi-diff-snapshots';
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

    uint256 snapshotId = vm.snapshot();

    executePayload(vm, payload);

    string memory afterString = string(abi.encodePacked('adi_', reportName, '_after'));
    CCCConfig memory configAfter = createConfigurationSnapshot(afterString, crossChainController);

    diffReports(beforeString, afterString);

    vm.revertTo(snapshotId);
    if (runE2E) e2eTest(payload, crossChainController);

    return (configBefore, configAfter);
  }

  function e2eTest(address payload, address crossChainController) public {
    // test receivers
    ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[]
      memory receiversToAllow = IBaseAdaptersUpdate(payload).getReceiverBridgeAdaptersToAllow();
    if (receiversToAllow.length != 0) {
      _testCorrectReceiverAdaptersConfiguration(payload, receiversToAllow, crossChainController);
      _testCorrectTrustedRemotes(receiversToAllow);
    }
    ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[]
      memory receiversToRemove = IBaseAdaptersUpdate(payload).getReceiverBridgeAdaptersToRemove();
    if (receiversToRemove.length != 0) {
      _testOnlyRemovedSpecifiedReceiverAdapters(payload, receiversToRemove, crossChainController);
    }

    // test forwarders
    ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[]
      memory forwardersToEnable = IBaseAdaptersUpdate(payload).getForwarderBridgeAdaptersToEnable();
    if (forwardersToEnable.length != 0) {
      _testCorrectForwarderAdaptersConfiguration(payload, crossChainController, forwardersToEnable);
      _testDestinationAdapterIsRegistered(payload, crossChainController, forwardersToEnable);
    }
    ICrossChainForwarder.BridgeAdapterToDisable[] memory forwardersToRemove = IBaseAdaptersUpdate(
      payload
    ).getForwarderBridgeAdaptersToRemove();
    if (forwardersToRemove.length != 0) {
      _testOnlyRemovedSpecificForwarderAdapters(payload, crossChainController, forwardersToRemove);
    }
  }

  function getDestinationPayloadsByChain()
    public
    view
    virtual
    returns (DestinationPayload[] memory)
  {
    return new DestinationPayload[](0);
  }

  function _testDestinationAdapterIsRegistered(
    address payload,
    address crossChainController,
    ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[] memory forwardersToEnable
  ) internal {
    DestinationPayload[] memory destinationPayloads = getDestinationPayloadsByChain();
    bytes memory empty;

    for (uint256 i = 0; i < forwardersToEnable.length; i++) {
      uint256 currentChainId = block.chainid;
      // change fork to destination network
      (uint256 previousFork, ) = ChainHelpers.selectChain(
        vm,
        forwardersToEnable[i].destinationChainId
      );
      address destinationCCC = getCCCByChainId(block.chainid);
      if (destinationPayloads.length > 0) {
        for (uint256 j = 0; j < destinationPayloads.length; j++) {
          if (destinationPayloads[j].chainId == forwardersToEnable[i].destinationChainId) {
            if (keccak256(destinationPayloads[j].payloadCode) != keccak256(empty)) {
              address destinationPayload = GovV3Helpers.deployDeterministic(
                destinationPayloads[j].payloadCode
              );

              executePayload(vm, destinationPayload);
              // check that adapter is registered
              assertEq(
                ICrossChainReceiver(destinationCCC).isReceiverBridgeAdapterAllowed(
                  forwardersToEnable[i].destinationBridgeAdapter,
                  currentChainId
                ),
                true
              );
              break;
            }
          }
        }
      } else {
        assertEq(
          ICrossChainReceiver(destinationCCC).isReceiverBridgeAdapterAllowed(
            forwardersToEnable[i].destinationBridgeAdapter,
            currentChainId
          ),
          true
        );
      }
      vm.selectFork(previousFork);
    }
  }

  function _testOnlyRemovedSpecificForwarderAdapters(
    address payload,
    address crossChainController,
    ICrossChainForwarder.BridgeAdapterToDisable[] memory adaptersToRemove
  ) internal {
    ForwarderAdapters[]
      memory forwardersBridgeAdaptersByChainBefore = _getCurrentForwarderAdaptersByChain(
        crossChainController,
        block.chainid
      );

    executePayload(vm, payload);

    ForwarderAdapters[]
      memory forwardersBridgeAdaptersByChainAfter = _getCurrentForwarderAdaptersByChain(
        crossChainController,
        block.chainid
      );

    for (uint256 l = 0; l < forwardersBridgeAdaptersByChainBefore.length; l++) {
      for (uint256 j = 0; j < forwardersBridgeAdaptersByChainAfter.length; j++) {
        if (
          forwardersBridgeAdaptersByChainBefore[l].chainId ==
          forwardersBridgeAdaptersByChainAfter[j].chainId
        ) {
          for (uint256 i = 0; i < forwardersBridgeAdaptersByChainBefore[l].adapters.length; i++) {
            bool forwarderFound;
            for (uint256 m = 0; m < forwardersBridgeAdaptersByChainAfter[j].adapters.length; m++) {
              if (
                forwardersBridgeAdaptersByChainBefore[l].adapters[i].destinationBridgeAdapter ==
                forwardersBridgeAdaptersByChainAfter[j].adapters[m].destinationBridgeAdapter &&
                forwardersBridgeAdaptersByChainBefore[l].adapters[i].currentChainBridgeAdapter ==
                forwardersBridgeAdaptersByChainAfter[j].adapters[m].currentChainBridgeAdapter
              ) {
                forwarderFound = true;
                break;
              }
            }
            if (!forwarderFound) {
              bool isAdapterToBeRemoved;
              for (uint256 k = 0; k < adaptersToRemove.length; k++) {
                if (
                  forwardersBridgeAdaptersByChainBefore[l].adapters[i].currentChainBridgeAdapter ==
                  adaptersToRemove[k].bridgeAdapter
                ) {
                  for (uint256 n = 0; n < adaptersToRemove[k].chainIds.length; n++) {
                    if (
                      forwardersBridgeAdaptersByChainBefore[l].chainId ==
                      adaptersToRemove[k].chainIds[n]
                    ) {
                      isAdapterToBeRemoved = true;
                      break;
                    }
                  }
                }
              }
              assertEq(isAdapterToBeRemoved, true);
            }
          }
        }
      }
    }
  }

  function _testCorrectForwarderAdaptersConfiguration(
    address payload,
    address crossChainController,
    ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[] memory forwardersToEnable
  ) internal {
    executePayload(vm, payload);

    for (uint256 i = 0; i < forwardersToEnable.length; i++) {
      ICrossChainForwarder.ChainIdBridgeConfig[]
        memory forwardersBridgeAdaptersByChain = ICrossChainForwarder(crossChainController)
          .getForwarderBridgeAdaptersByChain(forwardersToEnable[i].destinationChainId);
      bool newAdapterFound;
      for (uint256 j = 0; j < forwardersBridgeAdaptersByChain.length; j++) {
        if (
          forwardersBridgeAdaptersByChain[j].destinationBridgeAdapter ==
          forwardersToEnable[i].destinationBridgeAdapter &&
          forwardersBridgeAdaptersByChain[j].currentChainBridgeAdapter ==
          forwardersToEnable[i].currentChainBridgeAdapter
        ) {
          newAdapterFound = true;
          break;
        }
      }
      assertEq(newAdapterFound, true);
    }
  }

  function _testCorrectTrustedRemotes(
    ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[] memory receiversToAllow
  ) internal {
    for (uint256 i = 0; i < receiversToAllow.length; i++) {
      for (uint256 j = 0; j < receiversToAllow[i].chainIds.length; j++) {
        address trustedRemote = IBaseAdapter(receiversToAllow[i].bridgeAdapter)
          .getTrustedRemoteByChainId(receiversToAllow[i].chainIds[j]);
        assertEq(trustedRemote, getCCCByChainId(receiversToAllow[i].chainIds[j]));
      }
    }
  }

  function _testOnlyRemovedSpecifiedReceiverAdapters(
    address payload,
    ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[] memory adaptersToRemove,
    address crossChainController
  ) internal {
    AdaptersByChain[] memory adaptersBefore = _getCurrentReceiverAdaptersByChain(
      crossChainController
    );

    executePayload(vm, payload);

    for (uint256 i = 0; i < adaptersBefore.length; i++) {
      for (uint256 j = 0; j < adaptersToRemove.length; j++) {
        for (uint256 x = 0; x < adaptersToRemove[j].chainIds.length; x++) {
          if (adaptersToRemove[j].chainIds[x] == adaptersBefore[i].chainId) {
            for (uint256 k = 0; k < adaptersBefore[i].adapters.length; k++) {
              if (adaptersBefore[i].adapters[k] == adaptersToRemove[j].bridgeAdapter) {
                assertEq(
                  ICrossChainReceiver(crossChainController).isReceiverBridgeAdapterAllowed(
                    adaptersToRemove[j].bridgeAdapter,
                    adaptersBefore[i].chainId
                  ),
                  false
                );
              } else {
                assertEq(
                  ICrossChainReceiver(crossChainController).isReceiverBridgeAdapterAllowed(
                    adaptersBefore[i].adapters[k],
                    adaptersBefore[i].chainId
                  ),
                  true
                );
              }
            }
          }
        }
      }
    }
  }

  function _testCorrectReceiverAdaptersConfiguration(
    address payload,
    ICrossChainReceiver.ReceiverBridgeAdapterConfigInput[] memory receiversToAllow,
    address crossChainController
  ) internal {
    for (uint256 i = 0; i < receiversToAllow.length; i++) {
      for (uint256 j = 0; j < receiversToAllow[i].chainIds.length; j++) {
        assertEq(
          ICrossChainReceiver(crossChainController).isReceiverBridgeAdapterAllowed(
            receiversToAllow[i].bridgeAdapter,
            receiversToAllow[i].chainIds[j]
          ),
          false
        );
      }
    }

    executePayload(vm, payload);

    for (uint256 i = 0; i < receiversToAllow.length; i++) {
      for (uint256 j = 0; j < receiversToAllow[i].chainIds.length; j++) {
        assertEq(
          ICrossChainReceiver(crossChainController).isReceiverBridgeAdapterAllowed(
            receiversToAllow[i].bridgeAdapter,
            receiversToAllow[i].chainIds[j]
          ),
          true
        );
      }
    }
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
          object = vm.serializeString(
            key,
            vm.toString(forwarders[j].currentChainBridgeAdapter),
            vm.toString(forwarders[j].destinationBridgeAdapter)
          );
        } else {
          vm.serializeString(
            key,
            vm.toString(forwarders[j].currentChainBridgeAdapter),
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
            vm.toString(receiverConfig[i].receiverAdapters[j]),
            vm.toString(true)
          );
        } else {
          vm.serializeString(
            key,
            vm.toString(receiverConfig[i].receiverAdapters[j]),
            vm.toString(true)
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

  function _getCCCConfig(address ccc) internal view returns (CCCConfig memory) {
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
  ) internal pure returns (uint256[] memory) {
    if (chainId == ChainIds.MAINNET) {
      uint256[] memory chainIds = new uint256[](10);
      chainIds[0] = ChainIds.MAINNET;
      chainIds[1] = ChainIds.POLYGON;
      chainIds[2] = ChainIds.AVALANCHE;
      chainIds[3] = ChainIds.BNB;
      chainIds[4] = ChainIds.GNOSIS;
      chainIds[5] = ChainIds.ARBITRUM;
      chainIds[6] = ChainIds.OPTIMISM;
      chainIds[7] = ChainIds.METIS;
      chainIds[8] = ChainIds.BASE;
      chainIds[9] = ChainIds.SCROLL;

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

  function _getCurrentForwarderAdaptersByChain(
    address crossChainController,
    uint256 chainId
  ) internal view returns (ForwarderAdapters[] memory) {
    uint256[] memory supportedChains = _getForwarderSupportedChainsByChainId(chainId);

    ForwarderAdapters[] memory forwarderAdapters = new ForwarderAdapters[](supportedChains.length);

    for (uint256 i = 0; i < supportedChains.length; i++) {
      ICrossChainForwarder.ChainIdBridgeConfig[] memory forwarders = ICrossChainForwarder(
        crossChainController
      ).getForwarderBridgeAdaptersByChain(supportedChains[i]);

      forwarderAdapters[i] = ForwarderAdapters({adapters: forwarders, chainId: supportedChains[i]});
    }
    return forwarderAdapters;
  }

  function _getCurrentReceiverAdaptersByChain(
    address crossChainController
  ) internal view returns (AdaptersByChain[] memory) {
    uint256[] memory supportedChains = ICrossChainReceiver(crossChainController)
      .getSupportedChains();

    AdaptersByChain[] memory receiverAdapters = new AdaptersByChain[](supportedChains.length);

    for (uint256 i = 0; i < supportedChains.length; i++) {
      address[] memory receivers = ICrossChainReceiver(crossChainController)
        .getReceiverBridgeAdaptersByChain(supportedChains[i]);

      receiverAdapters[i] = AdaptersByChain({adapters: receivers, chainId: supportedChains[i]});
    }

    return receiverAdapters;
  }

  /// @dev add new chains t
  function getCCCByChainId(uint256 chainId) public pure returns (address) {
    if (chainId == ChainIds.MAINNET) {
      return GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER;
    } else if (chainId == ChainIds.POLYGON) {
      return GovernanceV3Polygon.CROSS_CHAIN_CONTROLLER;
    } else if (chainId == ChainIds.AVALANCHE) {
      return GovernanceV3Avalanche.CROSS_CHAIN_CONTROLLER;
    } else if (chainId == ChainIds.OPTIMISM) {
      return GovernanceV3Optimism.CROSS_CHAIN_CONTROLLER;
    } else if (chainId == ChainIds.BNB) {
      return GovernanceV3BNB.CROSS_CHAIN_CONTROLLER;
    } else if (chainId == ChainIds.METIS) {
      return GovernanceV3Metis.CROSS_CHAIN_CONTROLLER;
    } else if (chainId == ChainIds.BASE) {
      return GovernanceV3Base.CROSS_CHAIN_CONTROLLER;
    } else if (chainId == ChainIds.ARBITRUM) {
      return GovernanceV3Arbitrum.CROSS_CHAIN_CONTROLLER;
    } else if (chainId == ChainIds.GNOSIS) {
      return GovernanceV3Gnosis.CROSS_CHAIN_CONTROLLER;
    } else if (chainId == ChainIds.SCROLL) {
      return GovernanceV3Scroll.CROSS_CHAIN_CONTROLLER;
    }
    revert();
  }
}
