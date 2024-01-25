// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAavePolEthERC20Bridge {
  /*
   * Returns the address of the Mainnet contract to exit the burn from
   */
  function ROOT_CHAIN_MANAGER() external view returns (address);

  /*
   * This function withdraws an ERC20 token from Polygon to Mainnet. exit() needs
   * to be called on mainnet with the corresponding burnProof in order to complete.
   * @notice Polygon only. Function will revert if called from other network.
   * @param token Polygon address of ERC20 token to withdraw
   * @param amount Amount of tokens to withdraw
   */
  function bridge(address token, uint256 amount) external;

  /*
   * This function completes the withdrawal process from Polygon to Mainnet.
   * Burn proof is generated via API. Please see README.md
   * @notice Mainnet only. Function will revert if called from other network.
   * @param burnProof Burn proof generated via API.
   */
  function exit(bytes calldata burnProof) external;

  /*
   * This function completes the withdrawal process from Polygon to Mainnet.
   * Burn proofs are generated via API. Please see README.md
   * @notice Mainnet only. Function will revert if called from other network.
   * @param burnProofs Array of burn proofs generated via API.
   */
  function exit(bytes[] calldata burnProofs) external;

  /*
   * Withdraws tokens on Mainnet contract to Aave V3 Collector.
   * @notice Mainnet only. Function will revert if called from other network.
   * @param token Mainnet address of token to withdraw to Collector
   */
  function withdrawToCollector(address token) external;

  /*
   * This function checks whether the L2 token to L1 token mapping exists.
   * If the mapping doesn't exist, DO NOT BRIDGE from Polygon.
   * @notice Call on Mainnet only.
   * @param l2token Address of the token on Polygon.
   * @returns Boolean denoting whether mapping exists or not.
   */
  function isTokenMapped(address l2token) external view returns (bool);
}
