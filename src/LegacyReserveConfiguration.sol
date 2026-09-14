// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {DataTypes} from 'aave-v3-origin/contracts/protocol/libraries/types/DataTypes.sol';

/**
 * @notice Reads reserve configuration fields used by pools before v3.7.
 * @dev These fields were removed from the current ReserveConfiguration library.
 */
library LegacyReserveConfiguration {
  function getDebtCeiling(
    DataTypes.ReserveConfigurationMap memory configuration
  ) internal pure returns (uint256) {
    // Bits 212-251: debt ceiling in units of 0.01 USD.
    return uint40(configuration.data >> 212);
  }

  function getSiloedBorrowing(
    DataTypes.ReserveConfigurationMap memory configuration
  ) internal pure returns (bool) {
    return configuration.data & (1 << 62) != 0;
  }

  function getBorrowableInIsolation(
    DataTypes.ReserveConfigurationMap memory configuration
  ) internal pure returns (bool) {
    return configuration.data & (1 << 61) != 0;
  }
}
