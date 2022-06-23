// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {AaveV3Helpers, ReserveConfig, ReserveTokens} from "../AaveV3Helpers.sol";
import {AaveAddressBookV3} from "aave-address-book/AaveAddressBookV3.sol";

contract AaveV3HelpersTest is Test {
    string public MARKET_NAME = AaveAddressBookV3.AaveV3Avalanche;

    address public constant USER_1 = address(1);

    function setUp() public {
        startHoax(USER_1);
    }

    function testDepositV3() public {
        address depositor = USER_1;
        address onBehalf = depositor;
        address asset = AaveAddressBookV3
            .getToken(MARKET_NAME, "DAI.e")
            .underlyingAsset;
        uint256 amount = 10 ether;

        deal(asset, depositor, 100 ether);

        AaveV3Helpers._deposit(MARKET_NAME, depositor, onBehalf, asset, amount);
    }

    function testBorrowV3() public {
        testDepositV3();
        address borrower = USER_1;
        uint256 amount = 3 * (10**6);
        address asset = AaveAddressBookV3
            .getToken(MARKET_NAME, "USDC")
            .underlyingAsset;
        deal(asset, asset, 2000 * (10**6));

        AaveV3Helpers._borrow(MARKET_NAME, borrower, asset, amount, 2);
    }

    function testRepayV3() public {
        testDepositV3();
        testBorrowV3();
        address debtor = USER_1;
        address asset = AaveAddressBookV3
            .getToken(MARKET_NAME, "USDC")
            .underlyingAsset;

        // Not possible to borrow and repay when vdebt index doesn't changing, so moving 1s
        skip(1);

        AaveV3Helpers._repay(
            MARKET_NAME,
            debtor,
            debtor,
            asset,
            type(uint256).max,
            2
        );
    }

    function testWithdrawV3() public {
        testDepositV3();
        testBorrowV3();
        testRepayV3();
        address depositor = USER_1;
        address asset = AaveAddressBookV3
            .getToken(MARKET_NAME, "DAI.e")
            .underlyingAsset;

        AaveV3Helpers._withdraw(
            MARKET_NAME,
            depositor,
            asset,
            type(uint256).max
        );
    }

    function testValidateConfigs() public {
        ReserveConfig[] memory allConfigs = AaveV3Helpers._getReservesConfigs(
            MARKET_NAME,
            false
        );

        // To check implementation() on a transparent proxy, we need to be the `admin`
        // which for Aave tokens is the POOL_CONFIGURATOR
        changePrank(
            address(AaveAddressBookV3.getMarket(MARKET_NAME).POOL_CONFIGURATOR)
        );

        AaveV3Helpers._validateReserveTokensImpls(
            AaveV3Helpers._findReserveConfig(allConfigs, "AAVE.e", false),
            ReserveTokens({
                aToken: 0xa5ba6E5EC19a1Bf23C857991c857dB62b2Aa187B,
                stableDebtToken: 0x52A1CeB68Ee6b7B5D13E0376A1E0E4423A8cE26e,
                variableDebtToken: 0x81387c40EB75acB02757C1Ae55D5936E78c9dEd3
            })
        );
    }
}
