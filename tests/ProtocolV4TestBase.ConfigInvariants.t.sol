// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {Strings} from 'openzeppelin-contracts/contracts/utils/Strings.sol';
import {ProtocolV4TestBaseEthereum} from '../src/v4-protocol-test/ProtocolV4TestBaseEthereum.sol';
import {ProtocolV4TestBaseAvalanche} from '../src/v4-protocol-test/ProtocolV4TestBaseAvalanche.sol';
import {ProtocolV4TestBaseBase} from '../src/v4-protocol-test/ProtocolV4TestBaseBase.sol';
import {ProtocolV4TestBaseArc} from '../src/v4-protocol-test/ProtocolV4TestBaseArc.sol';
import {Types} from 'src/dependencies/v4/Types.sol';

contract ProtocolV4TestConfigInvariants is Test, ProtocolV4TestBaseEthereum {
  address internal hub = makeAddr('hub');
  address internal spokeA = makeAddr('spokeA');
  address internal spokeB = makeAddr('spokeB');

  uint64 internal constant HF_FOR_MAX_BONUS = 0.99e18;

  function test_rptAboveMaxCollateralRiskPasses() public view {
    configInvariantsTest(_usdeSpoke(110_000));
  }

  function test_rptUnlimitedPasses() public view {
    configInvariantsTest(_usdeSpoke(type(uint24).max));
  }

  function test_rptEqualToMaxCollateralRiskReverts() public {
    vm.expectRevert(bytes(_rptError(spokeA, 'USDT')));
    this.configInvariantsTest(_usdeSpoke(16_50));
  }

  function test_rptBelowMaxCollateralRiskReverts() public {
    vm.expectRevert(bytes(_rptError(spokeA, 'USDT')));
    this.configInvariantsTest(_usdeSpoke(0));
  }

  function test_zeroCollateralRiskSkipsRpt() public view {
    Types.V4Snapshot memory snap = _usdeSpoke(0);
    snap.spokeReserves[0].collateralRisk = 0;
    configInvariantsTest(snap);
  }

  function test_notBorrowableSkipsRpt() public view {
    Types.V4Snapshot memory snap = _usdeSpoke(0);
    snap.spokeReserves[1].borrowable = false;
    configInvariantsTest(snap);
  }

  function test_zeroDrawCapSkipsRpt() public view {
    Types.V4Snapshot memory snap = _usdeSpoke(0);
    snap.spokeConfigs[1].drawCap = 0;
    configInvariantsTest(snap);
  }

  function test_missingSpokeConfigReverts() public {
    Types.V4Snapshot memory snap = _usdeSpoke(110_000);
    Types.SpokeConfigSnapshot[] memory configs = new Types.SpokeConfigSnapshot[](1);
    configs[0] = snap.spokeConfigs[0];
    snap.spokeConfigs = configs;
    vm.expectRevert(
      bytes(string.concat('CI_SPOKE_CONFIG_NOT_IN_SNAPSHOT ', Strings.toHexString(spokeA), ' USDT'))
    );
    this.configInvariantsTest(snap);
  }

  function test_collateralRiskWithoutCollateralFactorIgnored() public view {
    Types.V4Snapshot memory snap = _usdeSpoke(0);
    snap.spokeReserves[0].dynamicConfigs[0].collateralFactor = 0;
    configInvariantsTest(snap);
  }

  function test_historicalKeyCollateralFactorCountsTowardRisk() public {
    // current key has CF 0, an older key still carries CF > 0 for positions bound to it
    Types.V4Snapshot memory snap = _usdeSpoke(0);
    Types.DynamicConfigSnapshot[] memory keys = new Types.DynamicConfigSnapshot[](2);
    keys[0] = _key(0, 93_00, 102_00);
    keys[1] = _key(1, 0, 102_00);
    snap.spokeReserves[0].dynamicConfigs = keys;
    vm.expectRevert(bytes(_rptError(spokeA, 'USDT')));
    this.configInvariantsTest(snap);
  }

  function test_collateralRiskOnOtherSpokeIgnored() public view {
    Types.V4Snapshot memory snap = _usdeSpoke(110_000);
    snap.spokeReserves[0].spokeAddress = spokeB;
    snap.spokeConfigs[0].spokeAddress = spokeB;
    snap.spokeConfigs[1].riskPremiumThreshold = 0;
    configInvariantsTest(_withSecondLiquidationConfig(snap));
  }

  function test_liquidationBonusEqualToHfForMaxBonusPasses() public view {
    Types.V4Snapshot memory snap = _usdeSpoke(110_000);
    // 1.1 * 0.9 = 0.99
    snap.spokeReserves[0].dynamicConfigs[0] = _key(0, 90_00, 110_00);
    configInvariantsTest(snap);
  }

  function test_liquidationBonusAboveHfForMaxBonusReverts() public {
    Types.V4Snapshot memory snap = _usdeSpoke(110_000);
    snap.spokeReserves[0].dynamicConfigs[0] = _key(0, 90_00, 110_01);
    vm.expectRevert(bytes(_liquidationError(spokeA, 'USDE', 0)));
    this.configInvariantsTest(snap);
  }

  function test_historicalKeyLiquidationBonusChecked() public {
    Types.V4Snapshot memory snap = _usdeSpoke(110_000);
    Types.DynamicConfigSnapshot[] memory keys = new Types.DynamicConfigSnapshot[](2);
    keys[0] = _key(0, 95_00, 105_00);
    keys[1] = _key(1, 93_00, 102_00);
    snap.spokeReserves[0].dynamicConfigs = keys;
    vm.expectRevert(bytes(_liquidationError(spokeA, 'USDE', 0)));
    this.configInvariantsTest(snap);
  }

  /// @dev Ethena-style spoke: USDE collateral (CR 16.5%, CF 93%, max LB 102%), USDT borrowable.
  function _usdeSpoke(uint24 usdtRpt) internal view returns (Types.V4Snapshot memory snap) {
    snap.spokeLiquidationConfigs = new Types.SpokeLiquidationSnapshot[](1);
    snap.spokeLiquidationConfigs[0] = _liquidationConfig(spokeA);

    Types.DynamicConfigSnapshot[] memory usdeKeys = new Types.DynamicConfigSnapshot[](1);
    usdeKeys[0] = _key(0, 93_00, 102_00);
    Types.DynamicConfigSnapshot[] memory usdtKeys = new Types.DynamicConfigSnapshot[](1);
    usdtKeys[0] = _key(0, 0, 100_00);

    snap.spokeReserves = new Types.SpokeReserveSnapshot[](2);
    snap.spokeReserves[0] = _reserve(spokeA, 0, 'USDE', 16_50, false, usdeKeys);
    snap.spokeReserves[1] = _reserve(spokeA, 1, 'USDT', 0, true, usdtKeys);

    snap.spokeConfigs = new Types.SpokeConfigSnapshot[](2);
    snap.spokeConfigs[0] = _spokeConfig(spokeA, 0, 0, 0);
    snap.spokeConfigs[1] = _spokeConfig(spokeA, 1, 50_000_000, usdtRpt);
  }

  function _withSecondLiquidationConfig(
    Types.V4Snapshot memory snap
  ) internal view returns (Types.V4Snapshot memory) {
    Types.SpokeLiquidationSnapshot[] memory configs = new Types.SpokeLiquidationSnapshot[](2);
    configs[0] = snap.spokeLiquidationConfigs[0];
    configs[1] = _liquidationConfig(spokeB);
    snap.spokeLiquidationConfigs = configs;
    return snap;
  }

  function _liquidationConfig(
    address spoke
  ) internal pure returns (Types.SpokeLiquidationSnapshot memory) {
    return
      Types.SpokeLiquidationSnapshot({
        spokeAddress: spoke,
        targetHealthFactor: 1.0277e18,
        healthFactorForMaxBonus: HF_FOR_MAX_BONUS,
        liquidationBonusFactor: 100_00,
        maxUserReservesLimit: 0
      });
  }

  function _key(
    uint32 key,
    uint16 collateralFactor,
    uint32 maxLiquidationBonus
  ) internal pure returns (Types.DynamicConfigSnapshot memory) {
    return
      Types.DynamicConfigSnapshot({
        key: key,
        collateralFactor: collateralFactor,
        maxLiquidationBonus: maxLiquidationBonus,
        liquidationFee: 0
      });
  }

  function _reserve(
    address spoke,
    uint16 assetId,
    string memory symbol,
    uint24 collateralRisk,
    bool borrowable,
    Types.DynamicConfigSnapshot[] memory keys
  ) internal view returns (Types.SpokeReserveSnapshot memory reserve) {
    reserve.spokeAddress = spoke;
    reserve.reserveId = assetId;
    reserve.symbol = symbol;
    reserve.hub = hub;
    reserve.assetId = assetId;
    reserve.collateralRisk = collateralRisk;
    reserve.borrowable = borrowable;
    reserve.dynamicConfigKey = keys[keys.length - 1].key;
    reserve.dynamicConfigs = keys;
  }

  function _spokeConfig(
    address spoke,
    uint256 assetId,
    uint40 drawCap,
    uint24 riskPremiumThreshold
  ) internal view returns (Types.SpokeConfigSnapshot memory) {
    return
      Types.SpokeConfigSnapshot({
        hubAddress: hub,
        assetId: assetId,
        assetSymbol: 'X',
        spokeAddress: spoke,
        addCap: 0,
        drawCap: drawCap,
        riskPremiumThreshold: riskPremiumThreshold,
        active: true,
        halted: false
      });
  }

  function _rptError(address spoke, string memory symbol) internal pure returns (string memory) {
    return
      string.concat(
        'CI_RPT_NOT_ABOVE_MAX_COLLATERAL_RISK ',
        Strings.toHexString(spoke),
        ' ',
        symbol
      );
  }

  function _liquidationError(
    address spoke,
    string memory symbol,
    uint256 key
  ) internal pure returns (string memory) {
    return
      string.concat(
        'CI_LIQUIDATION_BONUS_ABOVE_HF_FOR_MAX_BONUS ',
        Strings.toHexString(spoke),
        ' ',
        symbol,
        ' key ',
        Strings.toString(key)
      );
  }
}

contract ProtocolV4TestConfigInvariantsEthereum is ProtocolV4TestBaseEthereum {
  function test_liveConfigPasses() public {
    vm.createSelectFork('mainnet');
    configInvariantsTest(_getSpokes());
  }
}

contract ProtocolV4TestConfigInvariantsAvalanche is ProtocolV4TestBaseAvalanche {
  function test_liveConfigPasses() public {
    vm.createSelectFork('avalanche');
    configInvariantsTest(_getSpokes());
  }
}

contract ProtocolV4TestConfigInvariantsBase is ProtocolV4TestBaseBase {
  function test_liveConfigPasses() public {
    vm.createSelectFork('base');
    configInvariantsTest(_getSpokes());
  }
}

contract ProtocolV4TestConfigInvariantsArc is ProtocolV4TestBaseArc {
  function test_liveConfigPasses() public {
    vm.createSelectFork('arc');
    configInvariantsTest(_getSpokes());
  }
}
