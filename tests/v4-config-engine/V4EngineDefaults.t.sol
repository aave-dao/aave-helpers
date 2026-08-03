// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IAaveV4ConfigEngine} from 'aave-address-book/AaveV4.sol';
import {AssetInterestRateStrategy} from 'aave-v4/hub/AssetInterestRateStrategy.sol';
import {IAssetInterestRateStrategy} from 'aave-v4/hub/interfaces/IAssetInterestRateStrategy.sol';
import {IBasicInterestRateStrategy} from 'aave-v4/hub/interfaces/IBasicInterestRateStrategy.sol';
import {V4EngineDefaults} from 'src/v4-config-engine/V4EngineDefaults.sol';

contract V4EngineDefaultsTest is Test {
  uint256 internal constant ASSET_ID = 0;

  /// @dev Deployed with this test as the hub, so `setInterestRateData` is callable directly.
  AssetInterestRateStrategy internal strategy;

  function setUp() public {
    strategy = new AssetInterestRateStrategy(address(this));
  }

  /// @dev `MAX_OPTIMAL_USAGE_RATIO` mirrors a contract constant Solidity cannot import, so it can
  /// silently drift on an aave-v4 bump. Pin it against the real value.
  function test_maxOptimalUsageRatio_matchesStrategy() public view {
    assertEq(
      uint256(V4EngineDefaults.MAX_OPTIMAL_USAGE_RATIO),
      strategy.MAX_OPTIMAL_RATIO(),
      'MAX_OPTIMAL_USAGE_RATIO drifted from AssetInterestRateStrategy.MAX_OPTIMAL_RATIO'
    );
  }

  function test_nonBorrowableIRData_fields() public pure {
    IAssetInterestRateStrategy.InterestRateData memory data = V4EngineDefaults
      .nonBorrowableIRData();
    assertEq(
      uint256(data.optimalUsageRatio),
      uint256(V4EngineDefaults.MAX_OPTIMAL_USAGE_RATIO),
      'optimalUsageRatio'
    );
    assertEq(uint256(data.baseDrawnRate), 0, 'baseDrawnRate');
    assertEq(uint256(data.rateGrowthBeforeOptimal), 0, 'rateGrowthBeforeOptimal');
    assertEq(uint256(data.rateGrowthAfterOptimal), 0, 'rateGrowthAfterOptimal');
  }

  function test_nonBorrowableIRData_acceptedByStrategy() public {
    _setNonBorrowableData();

    IAssetInterestRateStrategy.InterestRateData memory stored = strategy.getInterestRateData(
      ASSET_ID
    );
    assertEq(
      uint256(stored.optimalUsageRatio),
      uint256(V4EngineDefaults.MAX_OPTIMAL_USAGE_RATIO),
      'optimalUsageRatio'
    );
    assertEq(uint256(stored.baseDrawnRate), 0, 'baseDrawnRate');
    assertEq(uint256(stored.rateGrowthBeforeOptimal), 0, 'rateGrowthBeforeOptimal');
    assertEq(uint256(stored.rateGrowthAfterOptimal), 0, 'rateGrowthAfterOptimal');
    assertEq(strategy.getMaxDrawnRate(ASSET_ID), 0, 'maxDrawnRate');
  }

  /// @dev The preset's reason to exist: no borrow interest accrues at any utilisation.
  function testFuzz_nonBorrowableIRData_zeroRateAtAnyUtilisation(
    uint128 liquidity,
    uint128 drawn
  ) public {
    vm.assume(uint256(liquidity) + uint256(drawn) > 0);
    _setNonBorrowableData();

    assertEq(
      IBasicInterestRateStrategy(address(strategy)).calculateInterestRate({
        assetId: ASSET_ID,
        liquidity: liquidity,
        drawn: drawn,
        deficit: 0,
        swept: 0
      }),
      0,
      'drawn rate must stay 0'
    );
  }

  /// @dev The strategy rejects a zeroed optimal ratio outright, which is why the preset maxes it out
  /// instead of zeroing every field.
  function test_zeroOptimalUsageRatio_rejectedByStrategy() public {
    IAssetInterestRateStrategy.InterestRateData memory data = V4EngineDefaults
      .nonBorrowableIRData();
    data.optimalUsageRatio = 0;

    vm.expectRevert(IAssetInterestRateStrategy.InvalidOptimalUsageRatio.selector);
    strategy.setInterestRateData(ASSET_ID, abi.encode(data));
  }

  function test_noTokenization_allFieldsUnset() public pure {
    IAaveV4ConfigEngine.TokenizationSpokeConfig memory config = V4EngineDefaults.noTokenization();
    assertEq(config.addCap, 0, 'addCap');
    assertEq(config.proxyAdminOwner, address(0), 'proxyAdminOwner');
    assertEq(config.name, '', 'name');
    assertEq(config.symbol, '', 'symbol');
  }

  function _setNonBorrowableData() internal {
    strategy.setInterestRateData(ASSET_ID, abi.encode(V4EngineDefaults.nonBorrowableIRData()));
  }
}
