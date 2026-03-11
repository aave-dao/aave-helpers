// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {ProtocolV2TestBase, ReserveConfig} from '../src/ProtocolV2TestBase.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV2EthereumAMM} from 'aave-address-book/AaveV2EthereumAMM.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {PayloadWithEmit} from './mocks/PayloadWithEmit.sol';
import {PayloadWithStorage} from './mocks/PayloadWithStorage.sol';

contract ProtocolV2TestBaseTest is ProtocolV2TestBase {
  function setUp() public {
    vm.createSelectFork('mainnet', 17627440);
  }

  // function testSnpashot() public {
  //   createConfigurationSnapshot('v2-report', AaveV2Ethereum.POOL);
  // }

  function testE2E() public {
    e2eTest(AaveV2Ethereum.POOL);
  }
}

contract ProtocolV2TestE2ETestAsset is ProtocolV2TestBase {
  function setUp() public {
    vm.createSelectFork('mainnet', 18572478);
  }

  function test_e2eTestAssetUSDT() public {
    ReserveConfig[] memory configs = _getReservesConfigs(AaveV2Ethereum.POOL);
    e2eTestAsset(
      AaveV2Ethereum.POOL,
      _findReserveConfig(configs, AaveV2EthereumAssets.DAI_UNDERLYING),
      _findReserveConfig(configs, AaveV2EthereumAssets.USDT_UNDERLYING)
    );
  }

  function test_defaultTest() public {
    defaultTest('AMMTEST', AaveV2EthereumAMM.POOL, address(new PayloadWithEmit()), false, false);
  }
}

contract ProtocolV2TestStorageValidation is ProtocolV2TestBase {
  function test_noStorageSlots_passes() public {
    // PayloadWithEmit has no state variables — should pass silently.
    _validateNoPayloadStorageSlots(address(new PayloadWithEmit()));
  }

  function test_withStorageSlots_reverts() public {
    address payload = address(new PayloadWithStorage());
    // PayloadWithStorage declares `uint256 internal _randomStorageVariable` — must be rejected.
    vm.expectRevert();
    _validateNoPayloadStorageSlots(payload);
  }

  function test_unknownArtifact_logsWarning() public {
    // makeAddr produces an address with no deployed code; getArtifactPathByDeployedCode
    // cannot resolve it, so the function vm.getArtifactPathByDeployedCode reverts
    vm.expectRevert();
    _validateNoPayloadStorageSlots(makeAddr('unknownPayload'));
  }
}
