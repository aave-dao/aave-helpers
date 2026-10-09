// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV4EthereumSentora} from 'aave-address-book/AaveV4EthereumSentora.sol';
import {AaveV4Payload} from 'aave-v4/config-engine/AaveV4Payload.sol';

/**
 * @dev Base smart contract for an Aave V4 payload on the Ethereum Sentora market.
 * @author Aave Labs
 */
abstract contract AaveV4PayloadEthereumSentora is
  AaveV4Payload(AaveV4EthereumSentora.CONFIG_ENGINE)
{}
