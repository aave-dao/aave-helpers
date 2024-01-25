// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV2Polygon} from 'aave-address-book/AaveV2Polygon.sol';
import './AaveV2Payload.sol';

/**
 * @dev Base smart contract for an Aave v2 rates update on Avalanche.
 * @author BGD Labs
 */
// TODO: Add rates factory address after deploying
abstract contract AaveV2PayloadPolygon is AaveV2Payload(IEngine(AaveV2Polygon.CONFIG_ENGINE)) {

}
