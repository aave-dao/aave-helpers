// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV4Arc} from 'aave-address-book/AaveV4Arc.sol';
import {AaveV4Payload} from 'aave-v4/config-engine/AaveV4Payload.sol';

/**
 * @dev Base smart contract for an Aave V4 governance payload on Arc.
 * @author Aave Labs
 */
abstract contract AaveV4PayloadArc is AaveV4Payload(AaveV4Arc.CONFIG_ENGINE) {}
