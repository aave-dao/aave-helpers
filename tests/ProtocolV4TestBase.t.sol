// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {ProtocolV4TestBase} from '../src/ProtocolV4TestBase.sol';
import {ISpoke, ITokenizationSpoke, ISpokeConfigurator} from 'aave-address-book/AaveV4.sol';
import {
  AaveV4Ethereum,
  AaveV4EthereumSpokes,
  AaveV4EthereumHubs,
  AaveV4EthereumTokenizationSpokes,
  AaveV4EthereumPositionManagers
} from 'aave-address-book/AaveV4Ethereum.sol';
import {
  AaveV4EthereumHubHelpers,
  AaveV4EthereumSpokeHelpers,
  AaveV4EthereumTokenizationSpokeHelpers
} from 'src/dependencies/v4/AaveV4EthereumHelpers.sol';
import {Types} from 'src/dependencies/v4/Types.sol';
import {PayloadWithEmit} from './mocks/PayloadWithEmit.sol';
import {PayloadWithStorage} from './mocks/PayloadWithStorage.sol';

contract ProtocolV4TestBaseTest is ProtocolV4TestBase {
  uint256 public constant BLOCK_NUMBER = 24829000;

  function setUp() public {
    vm.createSelectFork('mainnet', BLOCK_NUMBER);
  }

  modifier gasless() {
    vm.pauseGasMetering();
    _;
    vm.resumeGasMetering();
  }

  function _mockAccessManager() internal {
    vm.mockCall(
      address(AaveV4Ethereum.ACCESS_MANAGER),
      abi.encodeWithSelector(bytes4(keccak256('canCall(address,address,bytes4)'))),
      abi.encode(true, uint32(0))
    );
  }

  function _updatePaused(address spoke, uint256 reserveId, bool paused) internal {
    _mockAccessManager();
    AaveV4Ethereum.SPOKE_CONFIGURATOR.updatePaused({
      spoke: spoke,
      reserveId: reserveId,
      paused: paused
    });
    vm.clearMockedCalls();
  }

  function _updateFrozen(address spoke, uint256 reserveId, bool frozen) internal {
    _mockAccessManager();
    AaveV4Ethereum.SPOKE_CONFIGURATOR.updateFrozen({
      spoke: spoke,
      reserveId: reserveId,
      frozen: frozen
    });
    vm.clearMockedCalls();
  }

  function _cleanupArtifacts(string memory reportName) internal {
    string memory beforePath = string.concat('./reports/', reportName, '_before.json');
    string memory afterPath = string.concat('./reports/', reportName, '_after.json');
    string memory diffPath = string.concat(
      './diffs/',
      reportName,
      '_before_',
      reportName,
      '_after.md'
    );
    if (vm.exists(beforePath)) {
      vm.removeFile(beforePath);
    }
    if (vm.exists(afterPath)) {
      vm.removeFile(afterPath);
    }
    if (vm.exists(diffPath)) {
      vm.removeFile(diffPath);
    }
  }
}

contract ProtocolV4TestE2ESingleSpoke is ProtocolV4TestBaseTest {
  function test_e2eMainSpoke() public gasless {
    e2eTestSpoke({spoke: AaveV4EthereumSpokes.MAIN_SPOKE});
  }
}

contract ProtocolV4TestE2EDistinctSpokes is ProtocolV4TestBaseTest {
  function test_e2eBluechipSpoke() public gasless {
    e2eTestSpoke({spoke: AaveV4EthereumSpokes.BLUECHIP_SPOKE});
  }

  function test_e2eEthenaCorrelatedSpoke() public gasless {
    e2eTestSpoke({spoke: AaveV4EthereumSpokes.ETHENA_CORRELATED_SPOKE});
  }

  function test_e2eLombardBtcSpoke() public gasless {
    e2eTestSpoke({spoke: AaveV4EthereumSpokes.LOMBARD_BTC_SPOKE});
  }
}

contract ProtocolV4TestE2EAllSpokes is ProtocolV4TestBaseTest {
  function test_e2eAllSpokes() public gasless {
    e2eTestAllSpokes({
      spokes: AaveV4EthereumSpokeHelpers.getUserSpokes(),
      testPositionManagers: true
    });
  }
}

contract ProtocolV4TestE2ETokenizationSpokes is ProtocolV4TestBaseTest {
  function test_e2eSingleTokenizationSpoke() public gasless {
    e2eTestTokenizationSpoke(AaveV4EthereumTokenizationSpokes.CORE_WETH_TOKENIZATION_SPOKE);
  }

  function test_e2eAllTokenizationSpokes() public gasless {
    e2eTestAllTokenizationSpokes({
      tokenizationSpokes: AaveV4EthereumTokenizationSpokeHelpers.getTokenizationSpokes()
    });
  }
}

contract ProtocolV4TestPositionManagers is ProtocolV4TestBaseTest {
  function test_e2eGatewaysMainSpoke() public gasless {
    e2eTestGateways({spoke: AaveV4EthereumSpokes.MAIN_SPOKE});
  }

  function test_e2eRegularPositionManagers() public gasless {
    e2eTestRegularPositionManagers({spoke: AaveV4EthereumSpokes.MAIN_SPOKE});
  }

  function test_e2ePositionManagersBluechip() public gasless {
    e2eTestPositionManagers({spoke: AaveV4EthereumSpokes.BLUECHIP_SPOKE});
  }
}

contract ProtocolV4TestPausedFrozenAssets is ProtocolV4TestBaseTest {
  function test_pausedAssetReverts() public gasless {
    ISpoke spoke = AaveV4EthereumSpokes.MAIN_SPOKE;
    Types.ReserveInfo[] memory reserves = _getReserveInfo(spoke);
    require(reserves.length > 0, 'No reserves found');

    // Find first non-paused reserve
    uint256 targetIdx;
    bool found;
    for (uint256 i; i < reserves.length; i++) {
      if (!reserves[i].paused) {
        targetIdx = i;
        found = true;
        break;
      }
    }
    require(found, 'No non-paused reserve found');

    _updatePaused({spoke: address(spoke), reserveId: reserves[targetIdx].reserveId, paused: true});

    // Update the reserve info to reflect paused state
    reserves[targetIdx].paused = true;

    e2eTestPausedAsset({spoke: spoke, pausedAsset: reserves[targetIdx]});
  }

  function test_frozenAssetReverts() public gasless {
    ISpoke spoke = AaveV4EthereumSpokes.MAIN_SPOKE;
    Types.ReserveInfo[] memory reserves = _getReserveInfo(spoke);
    require(reserves.length > 0, 'No reserves found');

    // Find first non-frozen, non-paused reserve
    uint256 targetIdx;
    bool found;
    for (uint256 i; i < reserves.length; i++) {
      if (!reserves[i].frozen && !reserves[i].paused) {
        targetIdx = i;
        found = true;
        break;
      }
    }
    require(found, 'No non-frozen reserve found');

    _updateFrozen({spoke: address(spoke), reserveId: reserves[targetIdx].reserveId, frozen: true});

    // Update the reserve info to reflect frozen state
    reserves[targetIdx].frozen = true;

    e2eTestFrozenAsset({spoke: spoke, frozenAsset: reserves[targetIdx]});
  }
}

contract ProtocolV4TestSnapshot is ProtocolV4TestBaseTest {
  function test_snapshotState() public {
    string memory name = 'v4_snapshot';
    Types.V4Snapshot memory snapshot = createV4Snapshot({
      spokes: AaveV4EthereumSpokeHelpers.getUserSpokes(),
      hubs: AaveV4EthereumHubHelpers.getHubs()
    });
    writeV4SnapshotJson({name: name, snap: snapshot});
    vm.removeFile(string.concat('./reports/', name, '.json'));
  }
}

contract ProtocolV4TestDefaultTest is ProtocolV4TestBaseTest {
  function test_defaultTestWithPayload() public {
    string memory name = 'v4_emit_payload';
    defaultTest({
      reportName: name,
      spokes: AaveV4EthereumSpokeHelpers.getUserSpokes(),
      tokenizationSpokes: AaveV4EthereumTokenizationSpokeHelpers.getTokenizationSpokes(),
      payload: address(new PayloadWithEmit())
    });
    _cleanupArtifacts(name);
  }

  function test_defaultTestNoE2E() public {
    string memory name = 'v4_no_e2e';
    defaultTest({
      reportName: name,
      spokes: AaveV4EthereumSpokeHelpers.getUserSpokes(),
      tokenizationSpokes: AaveV4EthereumTokenizationSpokeHelpers.getTokenizationSpokes(),
      payload: address(new PayloadWithEmit()),
      runE2E: false,
      testPositionManagers: false
    });
    _cleanupArtifacts(name);
  }
}

contract ProtocolV4TestStorageValidation is ProtocolV4TestBaseTest {
  function test_noExecutorStorageChange_passes() public {
    string memory name = 'v4_storage_pass';
    defaultTest({
      reportName: name,
      spokes: AaveV4EthereumSpokeHelpers.getUserSpokes(),
      tokenizationSpokes: AaveV4EthereumTokenizationSpokeHelpers.getTokenizationSpokes(),
      payload: address(new PayloadWithEmit()),
      runE2E: false,
      testPositionManagers: false
    });
    _cleanupArtifacts(name);
  }

  function test_executorStorageChange_reverts() public {
    string memory name = 'v4_storage_fail';
    address payload = address(new PayloadWithStorage());
    vm.expectRevert();
    this.defaultTest({
      reportName: name,
      spokes: AaveV4EthereumSpokeHelpers.getUserSpokes(),
      tokenizationSpokes: AaveV4EthereumTokenizationSpokeHelpers.getTokenizationSpokes(),
      payload: payload,
      runE2E: false,
      testPositionManagers: false
    });
    // filesystem writes persist through EVM reverts, so clean up manually
    _cleanupArtifacts(name);
  }
}
