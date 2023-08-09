// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {ProtocolV2TestBase, ReserveConfig} from '../src/ProtocolV2TestBase.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';

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
    vm.createSelectFork('mainnet', 17627440);
  }

  function test_e2eTestAssetUSDT() public {
    ReserveConfig[] memory configs = _getReservesConfigs(AaveV2Ethereum.POOL);
    e2eTestAsset(
      AaveV2Ethereum.POOL,
      _findReserveConfig(configs, AaveV2EthereumAssets.DAI_UNDERLYING),
      _findReserveConfig(configs, AaveV2EthereumAssets.USDT_UNDERLYING)
    );
  }
}
