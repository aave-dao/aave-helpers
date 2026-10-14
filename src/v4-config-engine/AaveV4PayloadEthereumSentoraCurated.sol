// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV4EthereumSentoraCurated} from 'aave-address-book/AaveV4EthereumSentoraCurated.sol';
import {AaveV4Payload} from 'aave-v4/config-engine/AaveV4Payload.sol';

/**
 * @dev Base smart contract for an Aave V4 payload on the Ethereum Sentora curated market.
 * @author Aave Labs
 */
abstract contract AaveV4PayloadEthereumSentoraCurated is
  AaveV4Payload(AaveV4EthereumSentoraCurated.CONFIG_ENGINE)
{}
