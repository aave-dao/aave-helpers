// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5 <0.9.0;

import 'forge-std/StdJson.sol';
import 'forge-std/Test.sol';
import {VmSafe} from 'forge-std/Vm.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV3OptimismAssets} from 'aave-address-book/AaveV3Optimism.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';
import {AaveV3AvalancheAssets} from 'aave-address-book/AaveV3Avalanche.sol';
import {AaveV3MonadAssets} from 'aave-address-book/AaveV3Monad.sol';
import {AaveV3ArbitrumAssets} from 'aave-address-book/AaveV3Arbitrum.sol';
import {AaveV3GnosisAssets} from 'aave-address-book/AaveV3Gnosis.sol';
import {AaveV3BaseAssets} from 'aave-address-book/AaveV3Base.sol';
import {AaveV4ArcAssets} from 'aave-address-book/AaveV4Arc.sol';
import {IB20} from './interfaces/IB20.sol';
import {IB20Factory} from './interfaces/IB20Factory.sol';
import {ChainIds} from 'solidity-utils/contracts/utils/ChainHelpers.sol';
import {IPool} from 'aave-address-book/AaveV3.sol';
import {IPayloadsControllerCore} from 'aave-address-book/GovernanceV3.sol';
import {GovV3Helpers} from './GovV3Helpers.sol';

struct ReserveTokens {
  address aToken;
  address stableDebtToken;
  address variableDebtToken;
}

contract CommonTestBase is Test {
  using stdJson for string;

  address public constant ETH_MOCK_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  address public constant EOA = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;

  address public constant B20_FACTORY = 0xB20f000000000000000000000000000000000000;

  // Coinbase supply manager, MINT_ROLE holder of the Coinbase equity B20s
  address public constant B20_SUPPLY_MANAGER = 0xD1Ca4dAcdf3231011D175351f1f02D15C7c5664C;

  function executePayload(Vm vm, address payload) internal virtual {
    GovV3Helpers.executePayload(vm, payload);
  }

  function executePayload(Vm vm, address payload, IPool pool) internal virtual {
    executePayload(vm, payload, GovV3Helpers.getPayloadsController(pool, block.chainid));
  }

  /**
   * @dev executes the payload via an explicit payloadsController, for cases where the controller
   * cannot be derived from the pool — e.g. a payload touching DAO-owned contracts on a chain where
   * the only market is a whitelabel instance.
   */
  function executePayload(
    Vm vm,
    address payload,
    IPayloadsControllerCore payloadsController
  ) internal virtual {
    GovV3Helpers.executePayload(vm, payload, address(payloadsController));
  }

  function _getMaxPayloadGas() internal view virtual returns (uint256) {
    if (
      block.chainid == ChainIds.MANTLE ||
      block.chainid == ChainIds.MONAD ||
      block.chainid == ChainIds.MEGAETH
    ) return 30_000_000;
    return 16_777_216;
  }

  function _assertPayloadGasWithinLimit(uint256 gasUsed) internal {
    _requireIsolation();
    assertLt(gasUsed, (_getMaxPayloadGas() * 95) / 100, 'TX_GAS_LIMIT_EXCEEDED'); // 5% is kept as a buffer
  }

  // The gas check is only meaningful under isolation (cold storage + tx intrinsic), and there is no
  // cheatcode to query or enable it. Detect it instead: under isolation a top-level call is metered as
  // a transaction (>= 21000 intrinsic gas), otherwise ~0. Fail loudly rather than silently under-count.
  function _requireIsolation() internal {
    (bool success, ) = address(0).call('');
    success;
    require(vm.lastCallGas().gasTotalUsed >= 21_000, 'PAYLOAD_GAS_CHECK_REQUIRES_ISOLATION');
  }

  /**
   * @notice deal doesn't support amounts stored in a script right now.
   * This function patches deal to mock and transfer funds instead.
   * @param asset the asset to deal
   * @param user the user to deal to
   * @param amount the amount to deal
   * @return bool true if the caller has changed due to prank usage
   */
  function _patchedDeal(
    address asset,
    address user,
    uint256 amount
  ) internal virtual returns (bool) {
    if (block.chainid == ChainIds.MAINNET) {
      // FXS
      if (asset == 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0) {
        vm.prank(0xF977814e90dA44bFA03b6295A0616a897441aceC);
        IERC20(asset).transfer(user, amount);
        return true;
      }
      // GUSD
      if (asset == AaveV2EthereumAssets.GUSD_UNDERLYING) {
        vm.prank(0x22FFDA6813f4F34C520bf36E5Ea01167bC9DF159);
        IERC20(asset).transfer(user, amount);
        return true;
      }
      // SNX
      if (asset == AaveV2EthereumAssets.SNX_UNDERLYING) {
        vm.prank(0x5Fd79D46EBA7F351fe49BFF9E87cdeA6c821eF9f);
        IERC20(asset).transfer(user, amount);
        return true;
      }
      // sUSD
      if (asset == AaveV2EthereumAssets.sUSD_UNDERLYING) {
        vm.prank(0x99F4176EE457afedFfCB1839c7aB7A030a5e4A92);
        IERC20(asset).transfer(user, amount);
        return true;
      }
      // stETH
      if (asset == AaveV2EthereumAssets.stETH_UNDERLYING) {
        vm.prank(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
        IERC20(asset).transfer(user, amount);
        return true;
      }
      // LDO
      if (asset == AaveV3EthereumAssets.LDO_UNDERLYING) {
        vm.prank(0x3e40D73EB977Dc6a537aF587D48316feE66E9C8c);
        IERC20(asset).transfer(user, amount);
        return true;
      }
      // AAVE
      if (asset == AaveV3EthereumAssets.AAVE_UNDERLYING) {
        vm.prank(MiscEthereum.ECOSYSTEM_RESERVE);
        IERC20(asset).transfer(user, amount);
        return true;
      }
    }
    if (block.chainid == ChainIds.OPTIMISM) {
      // sUSD
      if (asset == AaveV3OptimismAssets.sUSD_UNDERLYING) {
        deal(
          0x92bAc115d89cA17fd02Ed9357CEcA32842ACB4c2,
          0xf2107A85d8b79CBd2c5b2Bb63CA73Fd068040b67,
          amount
        );

        vm.prank(0xf2107A85d8b79CBd2c5b2Bb63CA73Fd068040b67);
        IERC20(asset).transfer(user, amount);
        return true;
      }
    }
    if (block.chainid == ChainIds.GNOSIS) {
      if (asset == AaveV3GnosisAssets.EURe_UNDERLYING) {
        vm.prank(0x93b7a3d164585B52f096F6eAE1EC42ee267878E1);
        IERC20(asset).transfer(user, amount);
        return true;
      }
    }
    if (block.chainid == ChainIds.AVALANCHE) {
      // AUSD
      if (asset == AaveV3AvalancheAssets.AUSD_UNDERLYING) {
        vm.prank(0x12A0d0F4Ea75A01C69eD6bfD20aa7d1ef1550458);
        IERC20(asset).transfer(user, amount);
        return true;
      }
    }
    if (block.chainid == ChainIds.MONAD) {
      // AUSD
      if (asset == AaveV3MonadAssets.AUSD_UNDERLYING) {
        vm.prank(0xBA3d60f5000f472aef947FB8020a3E6319F9a0B7);
        IERC20(asset).transfer(user, amount);
        return true;
      }
    }
    if (block.chainid == ChainIds.CELO) {
      // CELO
      if (asset == 0x471EcE3750Da237f93B8E339c536989b8978a438) {
        vm.deal(user, amount);
        return true;
      }
    }
    if (block.chainid == ChainIds.ARC) {
      // USDC is the native coin: the ERC20 reports account.balance / 1e12
      if (asset == AaveV4ArcAssets.USDC_UNDERLYING) {
        vm.deal(user, amount * 1e12);
        return true;
      }
    }
    if (block.chainid == ChainIds.BASE) {
      // B20 tokens are node-native with balances outside EVM storage, so `deal` cannot find a slot.
      // Mint from the MINT_ROLE holder instead; only executable under forge with `--network base`.
      if (_isB20(asset)) {
        require(
          IB20(asset).hasRole(IB20(asset).MINT_ROLE(), B20_SUPPLY_MANAGER),
          string(abi.encodePacked('B20 ', vm.toString(asset), ': no known MINT_ROLE holder'))
        );
        // Upstream forge charges the L1 data fee of a B20 write to msg.sender, so the minter needs ETH.
        vm.deal(B20_SUPPLY_MANAGER, 1 ether);
        vm.prank(B20_SUPPLY_MANAGER);
        IB20(asset).mint(user, amount);
        return true;
      }
    }
    return false;
  }

  /**
   * @dev Asks the B20 factory precompile whether `asset` is an initialized B20. The factory is itself a
   * precompile: under stock forge its account is empty and the call returns no data, which is treated
   * as "not a B20" so `deal` proceeds exactly as on any other chain. Account code 0xef is not a
   * substitute, other Base precompiles carry the same byte.
   */
  function _isB20(address asset) internal view returns (bool) {
    return
      _b20FactoryAnswersTrue(abi.encodeCall(IB20Factory.isB20, (asset))) &&
      _b20FactoryAnswersTrue(abi.encodeCall(IB20Factory.isB20Initialized, (asset)));
  }

  function _b20FactoryAnswersTrue(bytes memory query) private view returns (bool) {
    (bool ok, bytes memory ret) = B20_FACTORY.staticcall(query);
    return ok && ret.length == 32 && abi.decode(ret, (bool));
  }

  /**
   * Patched version of deal
   * @param asset to deal
   * @param user to deal to
   * @param amount to deal
   */
  function deal2(address asset, address user, uint256 amount) internal virtual {
    (VmSafe.CallerMode mode, address oldSender, ) = vm.readCallers();
    if (mode != VmSafe.CallerMode.None) vm.stopPrank();
    bool patched = _patchedDeal(asset, user, amount);
    if (!patched) {
      deal(asset, user, amount);
    }
    if (mode != VmSafe.CallerMode.None) vm.startPrank(oldSender);
  }
}
