// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/console.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {AaveAddressBookV3} from "aave-address-book/AaveAddressBookV3.sol";
import {TokenData, IInterestRateStrategy} from "aave-address-book/AaveV3.sol";

struct ReserveTokens {
    address aToken;
    address stableDebtToken;
    address variableDebtToken;
}

struct ReserveConfig {
    string symbol;
    address underlying;
    address aToken;
    address stableDebtToken;
    address variableDebtToken;
    uint256 decimals;
    uint256 ltv;
    uint256 liquidationThreshold;
    uint256 liquidationBonus;
    uint256 liquidationProtocolFee;
    uint256 reserveFactor;
    bool usageAsCollateralEnabled;
    bool borrowingEnabled;
    address interestRateStrategy;
    bool stableBorrowRateEnabled;
    bool isActive;
    bool isFrozen;
    bool isSiloed;
    uint256 supplyCap;
    uint256 borrowCap;
    uint256 debtCeiling;
    uint256 eModeCategory;
}

struct InterestStrategyValues {
    uint256 excessUtilization;
    uint256 optimalUtilization;
    address addressesProvider;
    uint256 baseVariableBorrowRate;
    uint256 stableRateSlope1;
    uint256 stableRateSlope2;
    uint256 variableRateSlope1;
    uint256 variableRateSlope2;
}

interface IInitializableAdminUpgradeabilityProxy {
    function implementation() external returns (address);
}

library AaveV3Helpers {
    // ----------------------------------------------
    // ----------------------------------------------
    // ----- TEST UTILS
    // ----------------------------------------------
    // ----------------------------------------------

    function _getReservesConfigs(string memory marketName, bool withLogs)
        internal
        view
        returns (ReserveConfig[] memory)
    {
        AaveAddressBookV3.Market memory market = AaveAddressBookV3.getMarket(
            marketName
        );

        TokenData[] memory reserves = market
            .POOL_DATA_PROVIDER
            .getAllReservesTokens();

        ReserveConfig[] memory configs = new ReserveConfig[](reserves.length);

        for (uint256 i = 0; i < reserves.length; i++) {
            (
                uint256 decimals,
                uint256 ltv,
                uint256 liquidationThreshold,
                uint256 liquidationBonus,
                uint256 reserveFactor,
                bool usageAsCollateralEnabled,
                bool borrowingEnabled,
                bool stableBorrowRateEnabled,
                bool isActive,
                bool isFrozen
            ) = market.POOL_DATA_PROVIDER.getReserveConfigurationData(
                    reserves[i].tokenAddress
                );
            configs[i].symbol = reserves[i].symbol;
            configs[i].underlying = reserves[i].tokenAddress;
            configs[i].decimals = decimals;
            configs[i].ltv = ltv;
            configs[i].liquidationThreshold = liquidationThreshold;
            configs[i].liquidationBonus = liquidationBonus;
            configs[i].reserveFactor = reserveFactor;
            configs[i].usageAsCollateralEnabled = usageAsCollateralEnabled;
            configs[i].borrowingEnabled = borrowingEnabled;
            configs[i].stableBorrowRateEnabled = stableBorrowRateEnabled;
            configs[i].interestRateStrategy = market
                .POOL
                .getReserveData(reserves[i].tokenAddress)
                .interestRateStrategyAddress;
            configs[i].isActive = isActive;
            configs[i].isFrozen = isFrozen;
            configs[i].isSiloed = market.POOL_DATA_PROVIDER.getSiloedBorrowing(
                reserves[i].tokenAddress
            );
            (configs[i].borrowCap, configs[i].supplyCap) = market
                .POOL_DATA_PROVIDER
                .getReserveCaps(reserves[i].tokenAddress);
            configs[i].debtCeiling = market.POOL_DATA_PROVIDER.getDebtCeiling(
                reserves[i].tokenAddress
            );
            configs[i].eModeCategory = market
                .POOL_DATA_PROVIDER
                .getReserveEModeCategory(reserves[i].tokenAddress);
            configs[i].liquidationProtocolFee = market
                .POOL_DATA_PROVIDER
                .getLiquidationProtocolFee(reserves[i].tokenAddress);

            (
                configs[i].aToken,
                configs[i].stableDebtToken,
                configs[i].variableDebtToken
            ) = market.POOL_DATA_PROVIDER.getReserveTokensAddresses(
                configs[i].underlying
            );

            if (withLogs) {
                _logReserveConfig(configs[i]);
            }
        }

        return configs;
    }

    function _findReserveConfig(
        ReserveConfig[] memory configs,
        string memory symbolOfUnderlying,
        bool withLogs
    ) internal view returns (ReserveConfig memory) {
        for (uint256 i = 0; i < configs.length; i++) {
            if (
                keccak256(abi.encodePacked(configs[i].symbol)) ==
                keccak256(abi.encodePacked(symbolOfUnderlying))
            ) {
                if (withLogs) {
                    _logReserveConfig(configs[i]);
                }
                return configs[i];
            }
        }
        revert("RESERVE_CONFIG_NOT_FOUND");
    }

    function _logReserveConfig(ReserveConfig memory config) internal view {
        console.log("Symbol ", config.symbol);
        console.log("Underlying address ", config.underlying);
        console.log("AToken address ", config.aToken);
        console.log("Stable debt token address ", config.stableDebtToken);
        console.log("Variable debt token address ", config.variableDebtToken);
        console.log("Decimals ", config.decimals);
        console.log("LTV ", config.ltv);
        console.log("Liquidation Threshold ", config.liquidationThreshold);
        console.log("Liquidation Bonus ", config.liquidationBonus);
        console.log("Liquidation protocol fee ", config.liquidationProtocolFee);
        console.log("Reserve Factor ", config.reserveFactor);
        console.log(
            "Usage as collateral enabled ",
            (config.usageAsCollateralEnabled) ? "Yes" : "No"
        );
        console.log(
            "Borrowing enabled ",
            (config.borrowingEnabled) ? "Yes" : "No"
        );
        console.log(
            "Stable borrow rate enabled ",
            (config.stableBorrowRateEnabled) ? "Yes" : "No"
        );
        console.log("Supply cap ", config.supplyCap);
        console.log("Borrow cap ", config.borrowCap);
        console.log("Debt ceiling ", config.debtCeiling);
        console.log("eMode category ", config.eModeCategory);
        console.log("Interest rate strategy ", config.interestRateStrategy);
        console.log("Is active ", (config.isActive) ? "Yes" : "No");
        console.log("Is frozen ", (config.isFrozen) ? "Yes" : "No");
        console.log("Is siloed ", (config.isSiloed) ? "Yes" : "No");
        console.log("-----");
        console.log("-----");
    }

    function _validateReserveConfig(
        ReserveConfig memory expectedConfig,
        ReserveConfig[] memory allConfigs
    ) internal view {
        ReserveConfig memory config = _findReserveConfig(
            allConfigs,
            expectedConfig.symbol,
            false
        );
        require(
            keccak256(bytes(config.symbol)) ==
                keccak256(bytes(expectedConfig.symbol)),
            "_validateConfigsInAave() : INVALID_SYMBOL"
        );
        require(
            config.underlying == expectedConfig.underlying,
            "_validateConfigsInAave() : INVALID_UNDERLYING"
        );
        require(
            config.decimals == expectedConfig.decimals,
            "_validateConfigsInAave: INVALID_DECIMALS"
        );
        require(
            config.ltv == expectedConfig.ltv,
            "_validateConfigsInAave: INVALID_LTV"
        );
        require(
            config.liquidationThreshold == expectedConfig.liquidationThreshold,
            "_validateConfigsInAave: INVALID_LIQ_THRESHOLD"
        );
        require(
            config.liquidationBonus == expectedConfig.liquidationBonus,
            "_validateConfigsInAave: INVALID_LIQ_BONUS"
        );
        require(
            config.liquidationProtocolFee ==
                expectedConfig.liquidationProtocolFee,
            "_validateConfigsInAave: INVALID_LIQUIDATION_PROTOCOL_FEE"
        );
        require(
            config.reserveFactor == expectedConfig.reserveFactor,
            "_validateConfigsInAave: INVALID_RESERVE_FACTOR"
        );

        require(
            config.usageAsCollateralEnabled ==
                expectedConfig.usageAsCollateralEnabled,
            "_validateConfigsInAave: INVALID_USAGE_AS_COLLATERAL"
        );
        require(
            config.borrowingEnabled == expectedConfig.borrowingEnabled,
            "_validateConfigsInAave: INVALID_BORROWING_ENABLED"
        );
        require(
            config.stableBorrowRateEnabled ==
                expectedConfig.stableBorrowRateEnabled,
            "_validateConfigsInAave: INVALID_STABLE_BORROW_ENABLED"
        );
        require(
            config.isActive == expectedConfig.isActive,
            "_validateConfigsInAave: INVALID_IS_ACTIVE"
        );
        require(
            config.isFrozen == expectedConfig.isFrozen,
            "_validateConfigsInAave: INVALID_IS_FROZEN"
        );
        require(
            config.isSiloed == expectedConfig.isSiloed,
            "_validateConfigsInAave: INVALID_IS_SILOED"
        );
        require(
            config.supplyCap == expectedConfig.supplyCap,
            "_validateConfigsInAave: INVALID_SUPPLY_CAP"
        );
        require(
            config.borrowCap == expectedConfig.borrowCap,
            "_validateConfigsInAave: INVALID_BORROW_CAP"
        );
        require(
            config.debtCeiling == expectedConfig.debtCeiling,
            "_validateConfigsInAave: INVALID_DEBT_CEILING"
        );
        require(
            config.eModeCategory == expectedConfig.eModeCategory,
            "_validateConfigsInAave: INVALID_EMODE_CATEGORY"
        );
        require(
            config.interestRateStrategy == expectedConfig.interestRateStrategy,
            "_validateConfigsInAave: INVALID_INTEREST_RATE_STRATEGY"
        );
    }

    function _validateInterestRateStrategy(
        string memory marketName,
        address asset,
        address expectedStrategy,
        InterestStrategyValues memory expectedStrategyValues
    ) internal view {
        AaveAddressBookV3.Market memory market = AaveAddressBookV3.getMarket(
            marketName
        );

        IInterestRateStrategy strategy = IInterestRateStrategy(
            market.POOL_DATA_PROVIDER.getInterestRateStrategyAddress(asset)
        );

        require(
            address(strategy) == expectedStrategy,
            "_validateInterestRateStrategy() : INVALID_STRATEGY_ADDRESS"
        );

        require(
            strategy.MAX_EXCESS_USAGE_RATIO() ==
                expectedStrategyValues.excessUtilization,
            "_validateInterestRateStrategy() : INVALID_EXCESS_RATE"
        );
        require(
            strategy.OPTIMAL_USAGE_RATIO() ==
                expectedStrategyValues.optimalUtilization,
            "_validateInterestRateStrategy() : INVALID_OPTIMAL_RATE"
        );
        require(
            address(strategy.ADDRESSES_PROVIDER()) ==
                expectedStrategyValues.addressesProvider,
            "_validateInterestRateStrategy() : INVALID_ADDRESSES_PROVIDER"
        );
        require(
            strategy.getBaseVariableBorrowRate() ==
                expectedStrategyValues.baseVariableBorrowRate,
            "_validateInterestRateStrategy() : INVALID_BASE_VARIABLE_BORROW"
        );
        require(
            strategy.getStableRateSlope1() ==
                expectedStrategyValues.stableRateSlope1,
            "_validateInterestRateStrategy() : INVALID_STABLE_SLOPE_1"
        );
        require(
            strategy.getStableRateSlope2() ==
                expectedStrategyValues.stableRateSlope2,
            "_validateInterestRateStrategy() : INVALID_STABLE_SLOPE_2"
        );
        require(
            strategy.getVariableRateSlope1() ==
                expectedStrategyValues.variableRateSlope1,
            "_validateInterestRateStrategy() : INVALID_VARIABLE_SLOPE_1"
        );
        require(
            strategy.getVariableRateSlope2() ==
                expectedStrategyValues.variableRateSlope2,
            "_validateInterestRateStrategy() : INVALID_VARIABLE_SLOPE_2"
        );
        require(
            strategy.getMaxVariableBorrowRate() ==
                expectedStrategyValues.baseVariableBorrowRate +
                    expectedStrategyValues.variableRateSlope1 +
                    expectedStrategyValues.variableRateSlope2,
            "_validateInterestRateStrategy() : INVALID_VARIABLE_SLOPE_2"
        );
    }

    function _noReservesConfigsChangesApartNewListings(
        ReserveConfig[] memory allConfigsBefore,
        ReserveConfig[] memory allConfigsAfter
    ) internal pure {
        for (uint256 i = 0; i < allConfigsBefore.length; i++) {
            require(
                keccak256(abi.encodePacked(allConfigsBefore[i].symbol)) ==
                    keccak256(abi.encodePacked(allConfigsAfter[i].symbol)),
                "_noReservesConfigsChangesApartNewListings() : UNEXPECTED_SYMBOL_CHANGED"
            );
            require(
                allConfigsBefore[i].underlying == allConfigsAfter[i].underlying,
                "_noReservesConfigsChangesApartNewListings() : UNEXPECTED_UNDERLYING_CHANGED"
            );
            require(
                allConfigsBefore[i].aToken == allConfigsAfter[i].aToken,
                "_noReservesConfigsChangesApartNewListings() : UNEXPECTED_ATOKEN_CHANGED"
            );
            require(
                allConfigsBefore[i].stableDebtToken ==
                    allConfigsAfter[i].stableDebtToken,
                "_noReservesConfigsChangesApartNewListings() : UNEXPECTED_STOKEN_CHANGED"
            );
            require(
                allConfigsBefore[i].variableDebtToken ==
                    allConfigsAfter[i].variableDebtToken,
                "_noReservesConfigsChangesApartNewListings() : UNEXPECTED_VTOKEN_CHANGED"
            );
            require(
                allConfigsBefore[i].decimals == allConfigsAfter[i].decimals,
                "_noReservesConfigsChangesApartNewListings() : UNEXPECTED_DECIMALS_CHANGED"
            );
            require(
                allConfigsBefore[i].ltv == allConfigsAfter[i].ltv,
                "_noReservesConfigsChangesApartNewListings() : UNEXPECTED_LTV_CHANGED"
            );
            require(
                allConfigsBefore[i].liquidationThreshold ==
                    allConfigsAfter[i].liquidationThreshold,
                "_noReservesConfigsChangesApartNewListings() : UNEXPECTED_LIQ_THRESHOLD_CHANGED"
            );
            require(
                allConfigsBefore[i].liquidationBonus ==
                    allConfigsAfter[i].liquidationBonus,
                "_noReservesConfigsChangesApartNewListings() : UNEXPECTED_LIQ_BONUS_CHANGED"
            );
            require(
                allConfigsBefore[i].liquidationProtocolFee ==
                    allConfigsAfter[i].liquidationProtocolFee,
                "_noReservesConfigsChangesApartNewListings() : UNEXPECTED_LIQ_PROTOCOL_FEE_CHANGED"
            );
            require(
                allConfigsBefore[i].reserveFactor ==
                    allConfigsAfter[i].reserveFactor,
                "_noReservesConfigsChangesApartNewListings() : UNEXPECTED_RESERVE_FACTOR_CHANGED"
            );
            require(
                allConfigsBefore[i].usageAsCollateralEnabled ==
                    allConfigsAfter[i].usageAsCollateralEnabled,
                "_noReservesConfigsChangesApartNewListings() : UNEXPECTED_USAGE_AS_COLLATERAL_ENABLED_CHANGED"
            );
            require(
                allConfigsBefore[i].borrowingEnabled ==
                    allConfigsAfter[i].borrowingEnabled,
                "_noReservesConfigsChangesApartNewListings() : UNEXPECTED_BORROWING_ENABLED_CHANGED"
            );
            require(
                allConfigsBefore[i].stableBorrowRateEnabled ==
                    allConfigsAfter[i].stableBorrowRateEnabled,
                "_noReservesConfigsChangesApartNewListings() : UNEXPECTED_STABLE_BORROWING_CHANGED"
            );
            require(
                allConfigsBefore[i].interestRateStrategy ==
                    allConfigsAfter[i].interestRateStrategy,
                "_noReservesConfigsChangesApartNewListings() : UNEXPECTED_INTEREST_RATE_STRATEGY_CHANGED"
            );
            require(
                allConfigsBefore[i].isActive == allConfigsAfter[i].isActive,
                "_noReservesConfigsChangesApartNewListings() : UNEXPECTED_IS_ACTIVE_CHANGED"
            );
            require(
                allConfigsBefore[i].isFrozen == allConfigsAfter[i].isFrozen,
                "_noReservesConfigsChangesApartNewListings() : UNEXPECTED_IS_FROZEN_CHANGED"
            );
            require(
                allConfigsBefore[i].isSiloed == allConfigsAfter[i].isSiloed,
                "_noReservesConfigsChangesApartNewListings() : UNEXPECTED_IS_SILOED_CHANGED"
            );
            require(
                allConfigsBefore[i].supplyCap == allConfigsAfter[i].supplyCap,
                "_noReservesConfigsChangesApartNewListings() : UNEXPECTED_SUPPLY_CAP_CHANGED"
            );
            require(
                allConfigsBefore[i].supplyCap == allConfigsAfter[i].borrowCap,
                "_noReservesConfigsChangesApartNewListings() : UNEXPECTED_BORROW_CAP_CHANGED"
            );
            require(
                allConfigsBefore[i].debtCeiling ==
                    allConfigsAfter[i].debtCeiling,
                "_noReservesConfigsChangesApartNewListings() : UNEXPECTED_DEBTCEILING_CHANGED"
            );
            require(
                allConfigsBefore[i].eModeCategory ==
                    allConfigsAfter[i].eModeCategory,
                "_noReservesConfigsChangesApartNewListings() : UNEXPECTED_EMODECATEGORY_CHANGED"
            );
        }
    }

    function _validateCountOfListings(
        uint256 count,
        ReserveConfig[] memory allConfigsBefore,
        ReserveConfig[] memory allConfigsAfter
    ) internal pure {
        require(
            allConfigsBefore.length == allConfigsAfter.length - count,
            "_validateCountOfListings() : INVALID_COUNT_OF_LISTINGS"
        );
    }

    function _validateReserveTokensImpls(
        ReserveConfig memory config,
        ReserveTokens memory expectedImpls
    ) internal {
        require(
            IInitializableAdminUpgradeabilityProxy(config.aToken)
                .implementation() == expectedImpls.aToken,
            "_validateReserveTokensImpls() : INVALID_ATOKEN_IMPL"
        );

        require(
            IInitializableAdminUpgradeabilityProxy(config.stableDebtToken)
                .implementation() == expectedImpls.stableDebtToken,
            "_validateReserveTokensImpls() : INVALID_STOKEN_IMPL"
        );

        require(
            IInitializableAdminUpgradeabilityProxy(config.variableDebtToken)
                .implementation() == expectedImpls.variableDebtToken,
            "_validateReserveTokensImpls() : INVALID_VTOKEN_IMPL"
        );
    }

    function _validateAssetSourceOnOracle(
        string memory marketName,
        address asset,
        address expectedSource
    ) internal view {
        AaveAddressBookV3.Market memory market = AaveAddressBookV3.getMarket(
            marketName
        );

        require(
            market.ORACLE.getSourceOfAsset(asset) == expectedSource,
            "_validateAssetSourceOnOracle() : INVALID_PRICE_SOURCE"
        );
    }

    // ----------------------------------------------
    // ----------------------------------------------
    // ----- ACTIONS IN THE POOL
    // ----------------------------------------------
    // ----------------------------------------------

    function _deposit(
        string memory marketName,
        address depositor,
        address onBehalfOf,
        address asset,
        uint256 amount
    ) internal {
        AaveAddressBookV3.Market memory market = AaveAddressBookV3.getMarket(
            marketName
        );

        _approveIfNeeded(asset, depositor, address(market.POOL), amount);
        market.POOL.supply(asset, amount, onBehalfOf, 0);
    }

    function _borrow(
        string memory marketName,
        address onBehalfOf,
        address asset,
        uint256 amount,
        uint256 interestRateMode
    ) internal {
        AaveAddressBookV3.Market memory market = AaveAddressBookV3.getMarket(
            marketName
        );

        market.POOL.borrow(asset, amount, interestRateMode, 0, onBehalfOf);
    }

    function _repay(
        string memory marketName,
        address whoRepays,
        address debtor,
        address asset,
        uint256 amount,
        uint256 interestRateMode
    ) internal {
        AaveAddressBookV3.Market memory market = AaveAddressBookV3.getMarket(
            marketName
        );

        _approveIfNeeded(asset, whoRepays, address(market.POOL), amount);
        market.POOL.repay(asset, amount, interestRateMode, debtor);
    }

    function _withdraw(
        string memory marketName,
        address to,
        address asset,
        uint256 amount
    ) internal {
        AaveAddressBookV3.Market memory market = AaveAddressBookV3.getMarket(
            marketName
        );

        market.POOL.withdraw(asset, amount, to);
    }

    function _approveIfNeeded(
        address asset,
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = IERC20(asset).allowance(owner, spender);

        if (currentAllowance < amount) {
            IERC20(asset).approve(spender, 0);
            IERC20(asset).approve(spender, amount);
        }
    }

    // ----------------------------------------------
    // ----------------------------------------------
    // ----- MISC
    // ----------------------------------------------
    // ----------------------------------------------

    /// @dev To contemplate +1/-1 precision issues when rounding, mainly on aTokens
    function _almostEqual(uint256 a, uint256 b) internal pure returns (bool) {
        if (b == 0) {
            return (a == b) || (a == (b + 1));
        } else {
            return (a == b) || (a == (b + 1)) || (a == (b - 1));
        }
    }
}
