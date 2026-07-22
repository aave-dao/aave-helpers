// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV4Avalanche} from 'aave-address-book/AaveV4Avalanche.sol';
import {AaveV4Payload} from 'aave-v4/config-engine/AaveV4Payload.sol';

/**
 * @dev Base smart contract for an Aave V4 governance payload on Avalanche.
 * @author Aave Labs
 */
abstract contract AaveV4PayloadAvalanche is AaveV4Payload(AaveV4Avalanche.CONFIG_ENGINE) {}
