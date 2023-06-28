// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../src/v3-config-engine/AaveV3PayloadEthereum.sol';

/**
 * @dev Smart contract for a mock caps update, for testing purposes
 * IMPORTANT Parameters are pseudo-random, DON'T USE THIS ANYHOW IN PRODUCTION
 * @author BGD Labs
 */
contract AaveV3EthereumMockCustomListing is AaveV3PayloadBase {
  constructor(IEngine customEngine) AaveV3PayloadBase(customEngine) {}

  function newListingsCustom()
    public
    view
    override
    returns (IEngine.ListingWithCustomImpl[] memory)
  {
    IEngine.ListingWithCustomImpl[] memory listingsCustom = new IEngine.ListingWithCustomImpl[](1);

    listingsCustom[0] = IEngine.ListingWithCustomImpl(
      IEngine.Listing({
        asset: 0x111111111117dC0aa78b770fA6A738034120C302,
        assetSymbol: '1INCH',
        priceFeed: 0x72AFAECF99C9d9C8215fF44C77B94B99C28741e8,
        rateStrategyParams: LISTING_ENGINE.RATE_STRATEGIES_FACTORY().getStrategyDataOfAsset(
          AaveV3EthereumAssets.AAVE_UNDERLYING
        ), // Quite common case, of setting the same rate strategy as an already listed asset
        enabledToBorrow: EngineFlags.ENABLED,
        stableRateModeEnabled: EngineFlags.ENABLED,
        borrowableInIsolation: EngineFlags.DISABLED,
        withSiloedBorrowing: EngineFlags.DISABLED,
        flashloanable: EngineFlags.DISABLED,
        ltv: 82_50,
        liqThreshold: 86_00,
        liqBonus: 5_00,
        reserveFactor: 10_00,
        supplyCap: 85_000,
        borrowCap: 60_000,
        debtCeiling: 0,
        liqProtocolFee: 10_00,
        eModeCategory: 0
      }),
      IEngine.TokenImplementations({
        aToken: AaveV3Ethereum.DEFAULT_A_TOKEN_IMPL_REV_1,
        vToken: AaveV3Ethereum.DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1,
        sToken: AaveV3Ethereum.DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1
      })
    );

    return listingsCustom;
  }

  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Ethereum', networkAbbreviation: 'Eth'});
  }
}
