// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {ProtocolV3TestBase, ReserveConfig} from '../src/ProtocolV3TestBase.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3Polygon, AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveV3Optimism, AaveV3OptimismAssets} from 'aave-address-book/AaveV3Optimism.sol';
import {AaveV3Arbitrum, AaveV3ArbitrumAssets} from 'aave-address-book/AaveV3Arbitrum.sol';
import {AaveV3Avalanche, AaveV3AvalancheAssets} from 'aave-address-book/AaveV3Avalanche.sol';
import {AaveV3Metis} from 'aave-address-book/AaveV3Metis.sol';
import {AaveV3MegaEth} from 'aave-address-book/AaveV3MegaEth.sol';
import {AaveV3Mantle} from 'aave-address-book/AaveV3Mantle.sol';
import {AaveV3Fantom} from 'aave-address-book/AaveV3Fantom.sol';
import {PayloadWithEmit} from './mocks/PayloadWithEmit.sol';
import {PayloadWithStorage} from './mocks/PayloadWithStorage.sol';

contract ProtocolV3TestBaseTest is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('polygon', 74909955);
  }

  function test_e2eTestDPI() public {
    ReserveConfig[] memory configs = _getReservesConfigs(AaveV3Optimism.POOL);
    e2eTestAsset(
      AaveV3Optimism.POOL,
      _findReserveConfig(configs, AaveV3PolygonAssets.WPOL_UNDERLYING),
      _findReserveConfig(configs, AaveV3PolygonAssets.WETH_UNDERLYING)
    );
  }

  function test_e2eTestWithBigTestAssetPrice() public {
    ReserveConfig[] memory configs = _getReservesConfigs(AaveV3Optimism.POOL);

    ReserveConfig memory collateralConfig = _findReserveConfig(
      configs,
      AaveV3PolygonAssets.WETH_UNDERLYING
    );
    ReserveConfig memory testAssetConfig = _findReserveConfig(
      configs,
      AaveV3PolygonAssets.WETH_UNDERLYING
    );

    _changeAssetPrice(AaveV3Optimism.POOL, testAssetConfig, 1000_00); // price increases to 1'000%

    e2eTestAsset(AaveV3Optimism.POOL, collateralConfig, testAssetConfig);
  }

  // function testSnpashot() public {
  //   this.createConfigurationSnapshot('pre-x', AaveV3Polygon.POOL);
  //   // do sth
  //   // this.createConfigurationSnapshot('post-x', AaveV3Polygon.POOL);

  //   // requires --ffi
  //   // diffReports('pre-x', 'post-x');
  // }

  // commented out as it is insanely slow with public rpcs
}

contract ProtocolV3TestE2ETestAsset is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('optimism', 139484866);
  }

  function test_e2eTestAssetMAI() public {
    ReserveConfig[] memory configs = _getReservesConfigs(AaveV3Optimism.POOL);
    e2eTestAsset(
      AaveV3Optimism.POOL,
      _findReserveConfig(configs, AaveV3OptimismAssets.DAI_UNDERLYING),
      _findReserveConfig(configs, AaveV3OptimismAssets.LINK_UNDERLYING)
    );
  }

  function test_e2eTestAssetUSDC() public {
    ReserveConfig[] memory configs = _getReservesConfigs(AaveV3Optimism.POOL);
    e2eTestAsset(
      AaveV3Optimism.POOL,
      _findReserveConfig(configs, AaveV3OptimismAssets.DAI_UNDERLYING),
      _findReserveConfig(configs, AaveV3OptimismAssets.USDC_UNDERLYING)
    );
  }
}

contract ProtocolV3TestE2ETestOptimismAll is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('optimism', 139484866);
  }

  function test_e2e() public {
    e2eTest(AaveV3Optimism.POOL);
  }
}

contract ProtocolV3TestE2ETestMetisAll is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('metis', 20957736);
  }

  function test_e2e() public {
    e2eTest(AaveV3Metis.POOL);
  }
}

contract ProtocolV3TestE2ETestAvalancheAll is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('avalanche', 66702537);
  }

  function test_e2e() public {
    e2eTest(AaveV3Avalanche.POOL);
  }

  function test_deal() public {
    deal2(AaveV3AvalancheAssets.USDC_UNDERLYING, address(this), 1000);
  }
}

contract ProtocolV3TestE2ETestArbitrumAll is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('arbitrum', 365906782);
  }

  function test_e2e() public {
    e2eTest(AaveV3Arbitrum.POOL);
  }

  function test_deal() public {
    deal2(AaveV3ArbitrumAssets.USDCn_UNDERLYING, address(this), 1000);
  }
}

contract ProtocolV3TestE2ETestAllMainnet is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('mainnet', 23438415);
  }

  function test_e2e() public {
    e2eTest(AaveV3Ethereum.POOL);
  }
}

contract ProtocolV3TestOptimismSnapshot is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('optimism', 139484866);
  }

  function test_snapshotState() public {
    createConfigurationSnapshot('snapshot', AaveV3Optimism.POOL, true, false, false, false);
  }
}

contract ProtocolV3TestMegaEthSnapshot is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('megaeth', 7862955);
  }

  function test_snapshotState() public {
    defaultTest(
      'megaeth',
      AaveV3MegaEth.POOL,
      0x3a0A755D940283cD96D69F88645BeaA2bAfBC0bb,
      false,
      false
    );
  }
}

contract ProtocolV3TestMantleSnapshot is ProtocolV3TestBase {
  function setUp() public {
    vm.createSelectFork('mantle', 91335553);
  }

  function test_snapshotState() public {
    defaultTest(
      'mantle',
      AaveV3Mantle.POOL,
      0x6F5b52c16886775395129dB05117D65420863250,
      false,
      false
    );
  }

  // overriding the storage slot check as payload artifacts does not exists
  function _validateNoPayloadStorageSlots(address payload) internal view override {}
}

contract ProtocolV3TestStorageValidation is ProtocolV3TestBase {
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
