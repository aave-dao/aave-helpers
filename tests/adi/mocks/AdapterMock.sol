// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IBaseAdapter} from 'aave-address-book/common/IBaseAdapter.sol';
import {ICrossChainController} from 'aave-address-book/common/ICrossChainController.sol';

/**
 * @title BaseAdapter
 * @author BGD Labs
 * @notice base contract implementing the method to route a bridged message to the CrossChainController contract.
 * @dev All bridge adapters must implement this contract
 */
abstract contract BaseAdapter is IBaseAdapter {
  /// @inheritdoc IBaseAdapter
  ICrossChainController public immutable CROSS_CHAIN_CONTROLLER;

  /// @inheritdoc IBaseAdapter
  uint256 public immutable BASE_GAS_LIMIT;

  // @dev this is the original address of the contract. Required to identify and prevent delegate calls.
  address private immutable _selfAddress;

  // (standard chain id -> origin forwarder address) saves for every chain the address that can forward messages to this adapter
  mapping(uint256 => address) internal _trustedRemotes;

  /// @inheritdoc IBaseAdapter
  string public adapterName;

  /**
   * @param crossChainController address of the CrossChainController the bridged messages will be routed to
   * @param providerGasLimit base gas limit used by the bridge adapter
   * @param name name of the bridge adapter contract
   * @param originConfigs pair of origin address and chain id that adapter is allowed to get messages from
   */
  constructor(
    address crossChainController,
    uint256 providerGasLimit,
    string memory name,
    TrustedRemotesConfig[] memory originConfigs
  ) {
    require(crossChainController != address(0), 'INVALID_BASE_ADAPTER_CROSS_CHAIN_CONTROLLER');
    CROSS_CHAIN_CONTROLLER = ICrossChainController(crossChainController);

    BASE_GAS_LIMIT = providerGasLimit;
    adapterName = name;

    _selfAddress = address(this);

    for (uint256 i = 0; i < originConfigs.length; i++) {
      TrustedRemotesConfig memory originConfig = originConfigs[i];
      require(originConfig.originForwarder != address(0), 'INVALID_TRUSTED_REMOTE');
      _trustedRemotes[originConfig.originChainId] = originConfig.originForwarder;
      emit SetTrustedRemote(originConfig.originChainId, originConfig.originForwarder);
    }
  }

  /// @inheritdoc IBaseAdapter
  function nativeToInfraChainId(uint256 nativeChainId) public view virtual returns (uint256);

  /// @inheritdoc IBaseAdapter
  function infraToNativeChainId(uint256 infraChainId) public view virtual returns (uint256);

  /// @inheritdoc IBaseAdapter
  function setupPayments() external virtual {}

  /// @inheritdoc IBaseAdapter
  function getTrustedRemoteByChainId(uint256 chainId) external view returns (address) {
    return _trustedRemotes[chainId];
  }
}

contract MockAdapter is BaseAdapter {
  address public immutable MOCK_ENDPOINT;

  /**
   * @param crossChainController address of the cross chain controller that will use this bridge adapter
   * @param mockEndpoint arbitrum entry point address
   * @param providerGasLimit base gas limit used by the bridge adapter
   * @param trustedRemotes list of remote configurations to set as trusted
   */
  constructor(
    address crossChainController,
    address mockEndpoint,
    uint256 providerGasLimit,
    TrustedRemotesConfig[] memory trustedRemotes
  ) BaseAdapter(crossChainController, providerGasLimit, 'Mock native adapter', trustedRemotes) {
    MOCK_ENDPOINT = mockEndpoint;
  }

  /// @inheritdoc IBaseAdapter
  function forwardMessage(
    address,
    uint256,
    uint256,
    bytes calldata
  ) external pure returns (address, uint256) {
    return (address(0), 0);
  }

  /// @inheritdoc IBaseAdapter
  function nativeToInfraChainId(uint256 nativeChainId) public pure override returns (uint256) {
    return nativeChainId;
  }

  /// @inheritdoc IBaseAdapter
  function infraToNativeChainId(uint256 infraChainId) public pure override returns (uint256) {
    return infraChainId;
  }
}
