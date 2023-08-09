// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../../src/v3-config-engine/AaveV3PayloadBase.sol';
import {IV3RateStrategyFactory} from '../../../src/v3-config-engine/IV3RateStrategyFactory.sol';
import {AaveV3Polygon, AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';

/**
 * @dev Payload for the initial rates update defined here on:
 * https://snapshot.org/#/aave.eth/proposal/0xbda28d65ca4d64005e6019948ed52d9d62c9e73e356ab1013aa2d4829f40c735
 * @author BGD Labs (risk recommendations by Gauntlet)
 */
contract AaveV3PolygonRatesUpdates070322 is AaveV3PayloadBase {
  constructor(IEngine customEngine) AaveV3PayloadBase(customEngine) {}

  function rateStrategiesUpdates()
    public
    view
    override
    returns (IEngine.RateStrategyUpdate[] memory)
  {
    IEngine.RateStrategyUpdate[] memory ratesUpdate = new IEngine.RateStrategyUpdate[](5);

    Rates.RateStrategyParams memory usdt = IV3RateStrategyFactory(AaveV3Polygon.RATES_FACTORY)
      .getStrategyDataOfAsset(AaveV3PolygonAssets.USDT_UNDERLYING);
    usdt.optimalUsageRatio = _bpsToRay(80_00);
    usdt.variableRateSlope2 = _bpsToRay(75_00);
    usdt.stableRateSlope2 = _bpsToRay(75_00);

    Rates.RateStrategyParams memory eurs = IV3RateStrategyFactory(AaveV3Polygon.RATES_FACTORY)
      .getStrategyDataOfAsset(AaveV3PolygonAssets.EURS_UNDERLYING);
    eurs.optimalUsageRatio = _bpsToRay(80_00);
    eurs.variableRateSlope2 = _bpsToRay(75_00);
    eurs.stableRateSlope2 = _bpsToRay(75_00);

    Rates.RateStrategyParams memory mai = IV3RateStrategyFactory(AaveV3Polygon.RATES_FACTORY)
      .getStrategyDataOfAsset(AaveV3PolygonAssets.miMATIC_UNDERLYING);
    mai.optimalUsageRatio = _bpsToRay(80_00);
    mai.variableRateSlope2 = _bpsToRay(75_00);
    mai.stableRateSlope2 = _bpsToRay(75_00);

    Rates.RateStrategyParams memory ageur = IV3RateStrategyFactory(AaveV3Polygon.RATES_FACTORY)
      .getStrategyDataOfAsset(AaveV3PolygonAssets.agEUR_UNDERLYING);
    ageur.optimalUsageRatio = _bpsToRay(80_00);
    ageur.variableRateSlope2 = _bpsToRay(75_00);
    ageur.stableRateSlope2 = _bpsToRay(75_00);

    ratesUpdate[0] = IEngine.RateStrategyUpdate({
      asset: AaveV3PolygonAssets.USDT_UNDERLYING,
      params: usdt
    });
    ratesUpdate[1] = IEngine.RateStrategyUpdate({
      asset: AaveV3PolygonAssets.EURS_UNDERLYING,
      params: eurs
    });
    ratesUpdate[2] = IEngine.RateStrategyUpdate({
      asset: AaveV3PolygonAssets.miMATIC_UNDERLYING,
      params: mai
    });
    ratesUpdate[3] = IEngine.RateStrategyUpdate({
      asset: AaveV3PolygonAssets.agEUR_UNDERLYING,
      params: ageur
    });
    ratesUpdate[4] = IEngine.RateStrategyUpdate({
      asset: AaveV3PolygonAssets.WETH_UNDERLYING,
      params: Rates.RateStrategyParams({
        optimalUsageRatio: _bpsToRay(80_00),
        baseVariableBorrowRate: _bpsToRay(1_00),
        variableRateSlope1: _bpsToRay(3_80),
        variableRateSlope2: _bpsToRay(80_00),
        stableRateSlope1: _bpsToRay(4_00),
        stableRateSlope2: _bpsToRay(80_00),
        baseStableRateOffset: _bpsToRay(3_00),
        stableRateExcessOffset: EngineFlags.KEEP_CURRENT,
        optimalStableToTotalDebtRatio: EngineFlags.KEEP_CURRENT
      })
    });

    return ratesUpdate;
  }

  function borrowsUpdates() public pure override returns (IEngine.BorrowUpdate[] memory) {
    IEngine.BorrowUpdate[] memory borrowsUpdate = new IEngine.BorrowUpdate[](4);

    borrowsUpdate[0] = IEngine.BorrowUpdate({
      asset: AaveV3PolygonAssets.miMATIC_UNDERLYING,
      reserveFactor: 20_00,
      enabledToBorrow: EngineFlags.KEEP_CURRENT,
      flashloanable: EngineFlags.KEEP_CURRENT,
      stableRateModeEnabled: EngineFlags.KEEP_CURRENT,
      borrowableInIsolation: EngineFlags.KEEP_CURRENT,
      withSiloedBorrowing: EngineFlags.KEEP_CURRENT
    });
    borrowsUpdate[1] = IEngine.BorrowUpdate({
      asset: AaveV3PolygonAssets.WETH_UNDERLYING,
      reserveFactor: 15_00,
      enabledToBorrow: EngineFlags.KEEP_CURRENT,
      flashloanable: EngineFlags.KEEP_CURRENT,
      stableRateModeEnabled: EngineFlags.KEEP_CURRENT,
      borrowableInIsolation: EngineFlags.KEEP_CURRENT,
      withSiloedBorrowing: EngineFlags.KEEP_CURRENT
    });
    borrowsUpdate[2] = IEngine.BorrowUpdate({
      asset: AaveV3PolygonAssets.GHST_UNDERLYING,
      reserveFactor: 35_00,
      enabledToBorrow: EngineFlags.KEEP_CURRENT,
      flashloanable: EngineFlags.KEEP_CURRENT,
      stableRateModeEnabled: EngineFlags.KEEP_CURRENT,
      borrowableInIsolation: EngineFlags.KEEP_CURRENT,
      withSiloedBorrowing: EngineFlags.KEEP_CURRENT
    });
    borrowsUpdate[3] = IEngine.BorrowUpdate({
      asset: AaveV3PolygonAssets.DPI_UNDERLYING,
      reserveFactor: 35_00,
      enabledToBorrow: EngineFlags.KEEP_CURRENT,
      flashloanable: EngineFlags.KEEP_CURRENT,
      stableRateModeEnabled: EngineFlags.KEEP_CURRENT,
      borrowableInIsolation: EngineFlags.KEEP_CURRENT,
      withSiloedBorrowing: EngineFlags.KEEP_CURRENT
    });

    return borrowsUpdate;
  }

  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Polygon', networkAbbreviation: 'Pol'});
  }
}
