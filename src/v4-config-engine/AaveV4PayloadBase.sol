// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV4Base} from 'aave-address-book/AaveV4Base.sol';
import {AaveV4Payload} from 'aave-v4/config-engine/AaveV4Payload.sol';

/**
 * @dev Base smart contract for an Aave V4 governance payload on Base.
 * @author Aave Labs
 */
abstract contract AaveV4PayloadBase is AaveV4Payload(AaveV4Base.CONFIG_ENGINE) {}
