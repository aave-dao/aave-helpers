// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Vm} from 'forge-std/Vm.sol';
import {console2} from 'forge-std/console2.sol';
import {ChainIds} from './ChainIds.sol';
import {PayloadsControllerUtils, IGovernancePowerStrategy, IPayloadsControllerCore, IGovernanceCore} from 'aave-address-book/GovernanceV3.sol';

// import {AaveV3EthereumGovV3} from 'aave-address-book/AaveV3Ethereum.sol';
library AaveV3EthereumGovV3 {
  address constant PAYLOADS_CONTROLLER = address(0);
  IGovernanceCore constant GOVERNANCE = IGovernanceCore(address(0));
}

library AaveV3OptimismGovV3 {
  address constant PAYLOADS_CONTROLLER = address(0);
}

library AaveV3ArbitrumGovV3 {
  address constant PAYLOADS_CONTROLLER = address(0);
}

library AaveV3FantomGovV3 {
  address constant PAYLOADS_CONTROLLER = address(0);
}

library AaveV3MetisGovV3 {
  address constant PAYLOADS_CONTROLLER = address(0);
}

library AaveV3PolygonGovV3 {
  address constant PAYLOADS_CONTROLLER = address(0);
}

library AaveV3AvalancheGovV3 {
  address constant PAYLOADS_CONTROLLER = address(0);
}

library AaveV3BaseGovV3 {
  address constant PAYLOADS_CONTROLLER = address(0);
}

library GovV3Helpers {
  error ExecutorNotFound();
  error LongBytesNotSupportedYet();

  function ipfsHashFile(Vm vm, string memory filePath, bool upload) internal returns (bytes32) {
    string[] memory inputs = new string[](8);
    inputs[0] = 'npx';
    inputs[1] = '--yes';
    inputs[2] = '-s';
    inputs[3] = '@bgd-labs/aave-cli';
    inputs[4] = 'ipfs';
    inputs[5] = filePath;
    inputs[6] = '-u';
    inputs[7] = vm.toString(upload);
    bytes memory bs58Hash = vm.ffi(inputs);
    // currenty there is no better way as ffi silently fails
    // revisit once https://github.com/foundry-rs/foundry/pull/4908 progresses
    require(
      bs58Hash.length != 0,
      'CALCULATED_HASH_IS_ZERO_CHECK_IF_YARN_DEPENDENCIES_ARE_INSTALLED'
    );
    console2.logString('Info: This preview will only work when the file has been uploaded to ipfs');
    console2.logString(
      string(
        abi.encodePacked(
          'Preview: https://app.aave.com/governance/ipfs-preview/?ipfsHash=',
          vm.toString(bs58Hash)
        )
      )
    );
    return bytes32(bs58Hash);
  }

  function ipfsHashFile(Vm vm, string memory filePath) internal returns (bytes32) {
    return ipfsHashFile(vm, filePath, false);
  }

  function buildAction(
    address payloadAddress,
    PayloadsControllerUtils.AccessControl accessLevel
  ) internal returns (IPayloadsControllerCore.ExecutionAction memory) {
    address payloadsController = _getPayloadsController(block.chainid);
    require(payloadsController != address(0), 'INVALID CHAIN ID');
    require(payloadAddress != address(0), 'INVALID PAYLOAD ADDRESS');
    require(
      accessLevel != PayloadsControllerUtils.AccessControl.Level_null,
      'INVALID ACCESS LEVEL'
    );

    return
      IPayloadsControllerCore.ExecutionAction({
        target: payloadAddress,
        withDelegateCall: true,
        accessLevel: accessLevel,
        value: 0,
        signature: 'execute()',
        callData: ''
      });
  }

  function createPayload(
    IPayloadsControllerCore.ExecutionAction[] memory actions,
    PayloadsControllerUtils.AccessControl accessLevel
  ) internal returns (uint256) {
    address payloadsController = _getPayloadsController(block.chainid);
    require(payloadsController != address(0), 'INVALID CHAIN ID');
    require(actions.length > 0, 'INVALID ACTIONS');

    return IPayloadsControllerCore(payloadsController).createPayload(actions);
  }

  function buildMainnet(
    uint40 payloadId,
    PayloadsControllerUtils.AccessControl accessLevel
  ) internal pure returns (PayloadsControllerUtils.Payload memory) {
    require(
      accessLevel > PayloadsControllerUtils.AccessControl.Level_null,
      'INCORRECT ACCESS LEVEL'
    );
    return
      _buildPayload(
        AaveV3EthereumGovV3.PAYLOADS_CONTROLLER,
        ChainIds.MAINNET,
        accessLevel,
        payloadId
      );
  }

  function buildArbitrum(
    uint40 payloadId,
    PayloadsControllerUtils.AccessControl accessLevel
  ) internal pure returns (PayloadsControllerUtils.Payload memory) {
    require(
      accessLevel > PayloadsControllerUtils.AccessControl.Level_null,
      'INCORRECT ACCESS LEVEL'
    );
    return
      _buildPayload(
        AaveV3ArbitrumGovV3.PAYLOADS_CONTROLLER,
        ChainIds.ARBITRUM,
        accessLevel,
        payloadId
      );
  }

  function buildPolygon(
    uint40 payloadId,
    PayloadsControllerUtils.AccessControl accessLevel
  ) internal pure returns (PayloadsControllerUtils.Payload memory) {
    require(
      accessLevel > PayloadsControllerUtils.AccessControl.Level_null,
      'INCORRECT ACCESS LEVEL'
    );
    return
      _buildPayload(
        AaveV3PolygonGovV3.PAYLOADS_CONTROLLER,
        ChainIds.POLYGON,
        accessLevel,
        payloadId
      );
  }

  function buildMetis(
    uint40 payloadId,
    PayloadsControllerUtils.AccessControl accessLevel
  ) internal pure returns (PayloadsControllerUtils.Payload memory) {
    require(
      accessLevel > PayloadsControllerUtils.AccessControl.Level_null,
      'INCORRECT ACCESS LEVEL'
    );
    return
      _buildPayload(AaveV3MetisGovV3.PAYLOADS_CONTROLLER, ChainIds.METIS, accessLevel, payloadId);
  }

  function buildBase(
    uint40 payloadId,
    PayloadsControllerUtils.AccessControl accessLevel
  ) internal pure returns (PayloadsControllerUtils.Payload memory) {
    require(
      accessLevel > PayloadsControllerUtils.AccessControl.Level_null,
      'INCORRECT ACCESS LEVEL'
    );
    return
      _buildPayload(AaveV3BaseGovV3.PAYLOADS_CONTROLLER, ChainIds.BASE, accessLevel, payloadId);
  }

  function buildAvalanche(
    uint40 payloadId,
    PayloadsControllerUtils.AccessControl accessLevel
  ) internal pure returns (PayloadsControllerUtils.Payload memory) {
    require(
      accessLevel > PayloadsControllerUtils.AccessControl.Level_null,
      'INCORRECT ACCESS LEVEL'
    );
    return
      _buildPayload(
        AaveV3AvalancheGovV3.PAYLOADS_CONTROLLER,
        ChainIds.AVALANCHE,
        accessLevel,
        payloadId
      );
  }

  function buildOptimism(
    uint40 payloadId,
    PayloadsControllerUtils.AccessControl accessLevel
  ) internal pure returns (PayloadsControllerUtils.Payload memory) {
    require(
      accessLevel > PayloadsControllerUtils.AccessControl.Level_null,
      'INCORRECT ACCESS LEVEL'
    );
    return
      _buildPayload(
        AaveV3OptimismGovV3.PAYLOADS_CONTROLLER,
        ChainIds.OPTIMISM,
        accessLevel,
        payloadId
      );
  }

  function _buildPayload(
    address payloadsController,
    uint256 chainId,
    PayloadsControllerUtils.AccessControl accessLevel,
    uint40 payloadId
  ) internal pure returns (PayloadsControllerUtils.Payload memory) {
    return
      PayloadsControllerUtils.Payload({
        chain: chainId,
        accessLevel: accessLevel,
        payloadsController: payloadsController,
        payloadId: payloadId
      });
  }

  function createProposal(
    PayloadsControllerUtils.Payload[] memory payloads,
    address votingPortal,
    bytes32 ipfsHash
  ) internal returns (uint256) {
    return _createProposal(payloads, ipfsHash, votingPortal, false);
  }

  function createProposal(
    PayloadsControllerUtils.Payload[] memory payloads,
    address votingPortal,
    bytes32 ipfsHash,
    bool emitLog
  ) internal returns (uint256) {
    return _createProposal(payloads, ipfsHash, votingPortal, emitLog);
  }

  function _createProposal(
    PayloadsControllerUtils.Payload[] memory payloads,
    bytes32 ipfsHash,
    address votingPortal,
    bool emitLog
  ) private returns (uint256) {
    require(block.chainid == ChainIds.MAINNET, 'MAINNET_ONLY');
    require(payloads.length != 0, 'MINIMUM_ONE_PAYLOAD');
    require(ipfsHash != bytes32(0), 'NON_ZERO_IPFS_HASH');
    require(votingPortal != address(0), 'INVALID_VOTING_PORTAL');

    if (emitLog) {
      console2.logBytes(
        abi.encodeWithSelector(
          AaveV3EthereumGovV3.GOVERNANCE.createProposal.selector,
          payloads,
          votingPortal,
          ipfsHash
        )
      );
    }
    return
      IGovernanceCore(AaveV3EthereumGovV3.GOVERNANCE).createProposal(
        payloads,
        votingPortal,
        ipfsHash
      );
  }

  function executePayload(Vm vm, uint40 payloadId) internal {
    address payloadsController = _getPayloadsController(block.chainid);
    require(payloadsController != address(0), 'INVALID CHAIN ID');

    IPayloadsControllerCore.Payload memory payload = IPayloadsControllerCore(payloadsController)
      .getPayloadById(payloadId);
    require(
      payload.state == IPayloadsControllerCore.PayloadState.Created,
      'PAYLOAD DOES NOT EXIST'
    );

    // override storage so payload can be executed
    //    payload.state = PayloadState.Queued;
    // StdStorage memory stdstore;
    // stdstore
    //   .target(address(payloadsController))
    //   .sig('_payloads(uint40)')
    //   .with_key(uint40(payloadId))
    //   .depth(2)
    //   .checked_write(uint8(IPayloadsControllerCore.PayloadState.Queued));

    // //    payload.queuedAt = uint40(block.timestamp);
    // stdStorage
    //   .target(address(payloadsController))
    //   .sig('_payloads(uint40)')
    //   .with_key(uint40(payloadId))
    //   .depth(4)
    //   .checked_write(block.timestamp);

    // skip to after queue delay
    // skip(payload.delay + 1);

    IPayloadsControllerCore(payloadsController).executePayload(payloadId);
  }

  function _getPayloadsController(uint256 chainId) internal pure returns (address) {
    if (chainId == ChainIds.MAINNET) {
      return AaveV3EthereumGovV3.PAYLOADS_CONTROLLER;
    } else if (chainId == ChainIds.POLYGON) {
      return AaveV3PolygonGovV3.PAYLOADS_CONTROLLER;
    } else if (chainId == ChainIds.AVALANCHE) {
      return AaveV3AvalancheGovV3.PAYLOADS_CONTROLLER;
    } else if (chainId == ChainIds.OPTIMISM) {
      return AaveV3OptimismGovV3.PAYLOADS_CONTROLLER;
    } else if (chainId == ChainIds.ARBITRUM) {
      return AaveV3ArbitrumGovV3.PAYLOADS_CONTROLLER;
    } else if (chainId == ChainIds.METIS) {
      return AaveV3MetisGovV3.PAYLOADS_CONTROLLER;
    } else if (chainId == ChainIds.BASE) {
      return AaveV3BaseGovV3.PAYLOADS_CONTROLLER;
    }

    return address(0);
  }
}
