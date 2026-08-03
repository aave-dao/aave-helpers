// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAaveV4ConfigEngine} from 'aave-address-book/AaveV4.sol';
import {IAssetInterestRateStrategy} from 'aave-v4/hub/interfaces/IAssetInterestRateStrategy.sol';

/// @title V4EngineDefaults
/// @notice Conventional presets for Aave V4 config engine listing inputs.
/// @author Aave Labs
library V4EngineDefaults {
  /// @notice Highest optimal usage ratio an asset interest rate strategy accepts, in BPS.
  /// @dev Mirrors `AssetInterestRateStrategy.MAX_OPTIMAL_RATIO`, not importable as a constant.
  uint16 internal constant MAX_OPTIMAL_USAGE_RATIO = 99_00;

  /// @notice Interest rate data for an asset listed as collateral only, holding the drawn rate at 0.
  /// @dev The optimal ratio cannot be 0: the strategy only accepts it within
  ///      [`MIN_OPTIMAL_RATIO`, `MAX_OPTIMAL_RATIO`], and a flat curve makes the value inert.
  /// @return The interest rate data to pass as `AssetListing.irData`.
  function nonBorrowableIRData()
    internal
    pure
    returns (IAssetInterestRateStrategy.InterestRateData memory)
  {
    return
      IAssetInterestRateStrategy.InterestRateData({
        optimalUsageRatio: MAX_OPTIMAL_USAGE_RATIO,
        baseDrawnRate: 0,
        rateGrowthBeforeOptimal: 0,
        rateGrowthAfterOptimal: 0
      });
  }

  /// @notice Tokenization config listing an asset on a hub without an ERC4626 wrapper.
  /// @dev The engine skips the deployment only when every field is unset; a partial config reverts.
  /// @return The tokenization config to pass as `AssetListing.tokenization`.
  function noTokenization()
    internal
    pure
    returns (IAaveV4ConfigEngine.TokenizationSpokeConfig memory)
  {
    return
      IAaveV4ConfigEngine.TokenizationSpokeConfig({
        addCap: 0,
        proxyAdminOwner: address(0),
        name: '',
        symbol: ''
      });
  }
}
