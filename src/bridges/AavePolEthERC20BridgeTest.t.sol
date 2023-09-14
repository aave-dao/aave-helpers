// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV2Polygon, AaveV2PolygonAssets} from 'aave-address-book/AaveV2Polygon.sol';
import {AaveV3Polygon, AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';

import {AavePolEthERC20Bridge} from './AavePolEthERC20Bridge.sol';

/**
 * @dev Tests for AavePolEthERC20Bridge
 */
contract AavePolEthERC20BridgeTest is Test {
  event Exit();
  event Bridge(address token, uint256 amount);
  event WithdrawToCollector(address token, uint256 amount);

  AavePolEthERC20Bridge bridgeMainnet;
  AavePolEthERC20Bridge bridgePolygon;
  uint256 mainnetFork;
  uint256 polygonFork;

  address USDC_WHALE = 0xF977814e90dA44bFA03b6295A0616a897441aceC;
  address USDC_WHALE_MAINNET = 0xcEe284F754E854890e311e3280b767F80797180d;

  function setUp() public {
    bytes32 salt = keccak256(abi.encode(tx.origin, uint256(0)));

    mainnetFork = vm.createSelectFork(vm.rpcUrl('mainnet'), 17921144);
    bridgeMainnet = new AavePolEthERC20Bridge{salt: salt}(address(this));

    polygonFork = vm.createSelectFork(vm.rpcUrl('polygon'), 46340897);
    bridgePolygon = new AavePolEthERC20Bridge{salt: salt}(address(this));
  }
}

contract BridgeTest is AavePolEthERC20BridgeTest {
  function test_revertsIf_invalidChain() public {
    vm.selectFork(mainnetFork);

    vm.expectRevert(AavePolEthERC20Bridge.InvalidChain.selector);
    bridgePolygon.bridge(AaveV3EthereumAssets.USDC_UNDERLYING, 1_000e6);
  }

  function test_revertsIf_notOwner() public {
    vm.selectFork(polygonFork);

    uint256 amount = 1_000e6;

    vm.startPrank(USDC_WHALE);
    IERC20(AaveV3PolygonAssets.USDC_UNDERLYING).transfer(address(bridgePolygon), amount);
    vm.stopPrank();

    bridgePolygon.transferOwnership(AaveGovernanceV2.POLYGON_BRIDGE_EXECUTOR);

    vm.expectRevert('Ownable: caller is not the owner');
    bridgePolygon.bridge(AaveV3PolygonAssets.USDC_UNDERLYING, amount);
  }

  function test_successful() public {
    vm.selectFork(polygonFork);

    uint256 amount = 1_000e6;

    vm.startPrank(USDC_WHALE);
    IERC20(AaveV3PolygonAssets.USDC_UNDERLYING).transfer(address(bridgePolygon), amount);
    vm.stopPrank();

    bridgePolygon.transferOwnership(AaveGovernanceV2.POLYGON_BRIDGE_EXECUTOR);

    vm.startPrank(AaveGovernanceV2.POLYGON_BRIDGE_EXECUTOR);
    vm.expectEmit();
    emit Bridge(AaveV3PolygonAssets.USDC_UNDERLYING, amount);
    bridgePolygon.bridge(AaveV3PolygonAssets.USDC_UNDERLYING, amount);
    vm.stopPrank();
  }
}

contract EmergencyTokenTransfer is AavePolEthERC20BridgeTest {
  function test_revertsIf_invalidCaller() public {
    vm.expectRevert('ONLY_RESCUE_GUARDIAN');
    vm.startPrank(makeAddr('random-caller'));
    bridgePolygon.emergencyTokenTransfer(
      AaveV2PolygonAssets.BAL_UNDERLYING,
      address(AaveV2Polygon.COLLECTOR),
      1_000e6
    );
    vm.stopPrank();
  }

  function test_successful_governanceCaller() public {
    address BAL_WHALE = 0x7Ba7f4773fa7890BaD57879F0a1Faa0eDffB3520;

    assertEq(IERC20(AaveV2PolygonAssets.BAL_UNDERLYING).balanceOf(address(bridgePolygon)), 0);

    uint256 balAmount = 1_000e18;

    vm.startPrank(BAL_WHALE);
    IERC20(AaveV2PolygonAssets.BAL_UNDERLYING).transfer(address(bridgePolygon), balAmount);
    vm.stopPrank();

    assertEq(IERC20(AaveV2PolygonAssets.BAL_UNDERLYING).balanceOf(address(bridgePolygon)), balAmount);

    uint256 initialCollectorBalBalance = IERC20(AaveV2PolygonAssets.BAL_UNDERLYING).balanceOf(
      address(AaveV2Polygon.COLLECTOR)
    );

    bridgePolygon.emergencyTokenTransfer(
      AaveV2PolygonAssets.BAL_UNDERLYING,
      address(AaveV2Polygon.COLLECTOR),
      balAmount
    );

    assertEq(
      IERC20(AaveV2PolygonAssets.BAL_UNDERLYING).balanceOf(address(AaveV2Polygon.COLLECTOR)),
      initialCollectorBalBalance + balAmount
    );
    assertEq(IERC20(AaveV2PolygonAssets.BAL_UNDERLYING).balanceOf(address(bridgePolygon)), 0);
  }
}

contract WithdrawToCollectorTest is AavePolEthERC20BridgeTest {
  function test_revertsIf_invalidChain() public {
    vm.selectFork(polygonFork);

    vm.expectRevert(AavePolEthERC20Bridge.InvalidChain.selector);
    bridgeMainnet.withdrawToCollector(AaveV3EthereumAssets.USDC_UNDERLYING);
  }

  function test_successful() public {
    vm.selectFork(mainnetFork);

    uint256 amount = 1_000e6;

    vm.startPrank(USDC_WHALE_MAINNET);
    IERC20(AaveV3EthereumAssets.USDC_UNDERLYING).transfer(address(bridgeMainnet), amount);
    vm.stopPrank();

    uint256 balanceCollectorBefore = IERC20(AaveV3EthereumAssets.USDC_UNDERLYING).balanceOf(
      address(AaveV3Ethereum.COLLECTOR)
    );
    uint256 balanceBridgeBefore = IERC20(AaveV3EthereumAssets.USDC_UNDERLYING).balanceOf(
      address(bridgeMainnet)
    );

    assertEq(balanceBridgeBefore, amount);

    bridgeMainnet.withdrawToCollector(AaveV3EthereumAssets.USDC_UNDERLYING);

    assertEq(
      IERC20(AaveV3EthereumAssets.USDC_UNDERLYING).balanceOf(address(AaveV3Ethereum.COLLECTOR)),
      balanceCollectorBefore + amount
    );
    assertEq(IERC20(AaveV3EthereumAssets.USDC_UNDERLYING).balanceOf(address(bridgeMainnet)), 0);
  }
}

/*
 * No good way of testing the full flow as proof is generated via API 30-90 minutes after the
 * bridge() function is called on Polygon.
 */
contract ExitTest is AavePolEthERC20BridgeTest {
  function test_revertsIf_invalidChain() public {
    vm.selectFork(polygonFork);

    vm.expectRevert(AavePolEthERC20Bridge.InvalidChain.selector);
    bridgeMainnet.exit(new bytes(0));
  }

  function test_revertsIf_proofAlreadyProcessed() public {
    vm.selectFork(mainnetFork);

    bytes
      memory burnProof = hex'f90b7f841d64b820b901605a3ebbdce0b458c848c75ece30aebdc7f404de9f42a1a1d2fff616f4681f8239a5727c70050724191597596befd50c2db26c8c13cc424292fb8dca25990eec222a5378609f41effc1b6f8370a2fa3bff9c1701b0d63108094bc6255a69ffbdd28cdc2237e927128485372aaad7d4164d37669d61d82add0bcb6b8fb1ab7726d81a766ee748222e6253d91038cb42b06614c20fda1f61ede914ee3971321a91ba9674397ca6114056014024786d3b74639d792036e10be9fcca25cc63df3e90e9ce68a4c38ebdd54385ed78e7003995b50975ea080eac5178729d59ffe8c39ba44dce41d776560d9f83de07337ba28cf16a69f99c3be4c8f5001825b11a3e49fb966bcc41e4b74e001be2248c2e7d8319fddb180775cdf18660fa475f8b84db41cefad4e508c098b9a7e1d8feb19955fb02ba9675585078710969d3440f5054e030e0542044c7c3e032f92fdf59c763bff5ec2b5c0b34323fff644d44074033f18402bf7ab28464d3b68aa0cb3e23ec4a01a3517fdb7d985bbcd704d8d243c4b6baac426457e5e2b9febad1a01ab4bd6b4a9aef048d60e20a15ad53347c92418591ac1bcafc493834c0b0bc37b9036802f9036401840184b1b4b9010000000200000000000000000008000000000000000000000000100000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000040008000000800000000000000000000100000000000000000000020000000000000000000800000000000000000180000010000004001041000000040000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000080000000000000000000004000000002000000000801000000000004000000000000000000120000000020000000008000000000000000000000000001000000000000200000000800100000f90258f89b942791bca1f2de4661ed88a30c99a7a9449aa84174f863a0ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3efa0000000000000000000000000ca807a3e47684caee82fda347729788639ab9ee8a00000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000f4240f87994ca807a3e47684caee82fda347729788639ab9ee8e1a0884edad9ce6fa2440d8a54cc123490eb96d2768479d49ff9c7366125a9424364b8400000000000000000000000002791bca1f2de4661ed88a30c99a7a9449aa8417400000000000000000000000000000000000000000000000000000000000f4240f9013d940000000000000000000000000000000000001010f884a04dfe1bbbcf077ddc3e01291eea2d5c70c2b422b415d95645b9adcfd678cb1d63a00000000000000000000000000000000000000000000000000000000000001010a00000000000000000000000002fb7d6beb9ad75c1ffd392681cc68171b8551107a00000000000000000000000009ead03f7136fc6b4bdb0780b00a1c14ae5a8b6d0b8a000000000000000000000000000000000000000000000000000047f88eb62fdf8000000000000000000000000000000000000000000000000f6299bdc7ee7898c000000000000000000000000000000000000000000000231bb90e991a999704a000000000000000000000000000000000000000000000000f6251c5393848b94000000000000000000000000000000000000000000000231bb95691a94fc6e42b90659f90656f8d1a0edd856137974cc770c8ff2f0ae9691f6c343a5c3ea042cf43226064241cb4b48a060098e59303c6f97eb4ee11a31d7ff224886f7ee97e47046ffc12ae2cb345607a08c1c9ddcde956a2188fecf78ac3ffe88c5300e39016cedbc726eaa480528f2d9a0af1a8f4ebb2c2f62619a683563a51fcf38e82d6213ad60506a1f4472145a3d52a06a5a57546f33675a2827617483ba12e200a7666f107115010549cc72ce933a5c808080a04b654e084485e25f10ab6e63905b7b0320f3da65ed062eee77511204089557af8080808080808080f90211a0d18ede4a1807a43ea2daf1f43d94127479f5a5406ba4d9e1e1820b9fabc23f1ca0ae8d8894a06c033da2ef24d0e4b7f4d985fea9e4a808d0616a93e17c7d5ca556a08a42f3eed60ecb787277f3534c848ac3e881be498993840a4c550764414c45e7a0db5ed558b0871c5828866ff7ff1cdb6b7b28cce715c74837c704308e4e85d8d8a0e00d8c69aee0605693c270aa8bd5e4c156bf6782952df288e8f3002963ad51d1a06568d90c67a2972365abd5f2606aa2529d39cb7bc23eb0a130d673080697d715a0747a3b807241f10bee3360edb4345a815328fb885c8e8f693e1af88503c41bc4a01767769f78e7f63f7142b0468c85a7a98aad577dd31044167c60e4d77e5d5ad2a09e8fddbe949014bb311de991cb543da9fb3104cf4db4f87e4e800911c1d99f7da0de90b23b0cf3a2685afd3b221a1660d8655212ca01c82c5680a81f807e2b3aada0281f75fda5226a1f34390b09765843e2af5a3644ba577a555431b7f2dcef2c86a094065d6acf8901d70605b0c198b0ff5df364efc232f6c536c7df5a7632b4a7bea0a32affd2aad98f44bce23eed618177c1a51cdd617ef72ec8be8d55bda90bf59fa099a19c0a99d4913f691877ce52612a1da389b99ab2a51c471346ee07575f0780a0b948b78e59be6f2a016c545d93ae7efdf615bf212bbdc1fa568bc2c96752c044a09e07bfdc8af384b3f2f1a65561bfd28ebd85d3f2abbfba13108d25a38a25a1cd80f9036c20b9036802f9036401840184b1b4b9010000000200000000000000000008000000000000000000000000100000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000040008000000800000000000000000000100000000000000000000020000000000000000000800000000000000000180000010000004001041000000040000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000080000000000000000000004000000002000000000801000000000004000000000000000000120000000020000000008000000000000000000000000001000000000000200000000800100000f90258f89b942791bca1f2de4661ed88a30c99a7a9449aa84174f863a0ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3efa0000000000000000000000000ca807a3e47684caee82fda347729788639ab9ee8a00000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000f4240f87994ca807a3e47684caee82fda347729788639ab9ee8e1a0884edad9ce6fa2440d8a54cc123490eb96d2768479d49ff9c7366125a9424364b8400000000000000000000000002791bca1f2de4661ed88a30c99a7a9449aa8417400000000000000000000000000000000000000000000000000000000000f4240f9013d940000000000000000000000000000000000001010f884a04dfe1bbbcf077ddc3e01291eea2d5c70c2b422b415d95645b9adcfd678cb1d63a00000000000000000000000000000000000000000000000000000000000001010a00000000000000000000000002fb7d6beb9ad75c1ffd392681cc68171b8551107a00000000000000000000000009ead03f7136fc6b4bdb0780b00a1c14ae5a8b6d0b8a000000000000000000000000000000000000000000000000000047f88eb62fdf8000000000000000000000000000000000000000000000000f6299bdc7ee7898c000000000000000000000000000000000000000000000231bb90e991a999704a000000000000000000000000000000000000000000000000f6251c5393848b94000000000000000000000000000000000000000000000231bb95691a94fc6e4282003580';

    vm.expectRevert('RootChainManager: EXIT_ALREADY_PROCESSED');
    bridgeMainnet.exit(burnProof);
  }
}

contract TransferOwnership is AavePolEthERC20BridgeTest {
  function test_revertsIf_invalidCaller() public {
    vm.startPrank(makeAddr('random-caller'));
    vm.expectRevert('Ownable: caller is not the owner');
    bridgeMainnet.transferOwnership(makeAddr('new-admin'));
    vm.stopPrank();
  }

  function test_successful() public {
    address newAdmin = AaveGovernanceV2.SHORT_EXECUTOR;
    bridgeMainnet.transferOwnership(newAdmin);

    assertEq(newAdmin, bridgeMainnet.owner());
  }
}
