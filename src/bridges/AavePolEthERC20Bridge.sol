// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3Polygon} from 'aave-address-book/AaveV3Polygon.sol';

import {IAavePolEthERC20Bridge} from './IAavePolEthERC20Bridge.sol';

interface IRootChainManager {
  function exit(bytes calldata inputData) external;
}

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);

  function transfer(address to, uint256 amount) external returns (bool);

  function withdraw(uint256 amount) external;
}

contract AavePolEthERC20Bridge is IAavePolEthERC20Bridge {
  error InvalidChain();

  event Exit();
  event Withdraw(address token, uint256 amount);
  event WithdrawToCollector(address token, uint256 amount);

  uint256 public constant ETHEREUM_CHAIN_ID = 1;
  uint256 public constant POLYGON_CHAIN_ID = 137;

  address public constant ROOT_CHAIN_MANAGER = 0xA0c68C638235ee32657e8f720a23ceC1bFc77C77;

  /*
   * This function withdraws an ERC20 token from Polygon to Mainnet. exit() needs
   * to be called on mainnet with the corresponding burnProof in order to complete.
   * @notice Polygon only. Function will revert if called from other network.
   * @param token Polygon address of ERC20 token to withdraw
   * @param amount Amount of tokens to withdraw
   */
  function withdraw(address token, uint256 amount) external {
    if (block.chainid != POLYGON_CHAIN_ID) revert InvalidChain();

    IERC20(token).withdraw(amount);
    emit Withdraw(token, amount);
  }

  /*
   * This function completes the withdrawal process from Polygon to Mainnet.
   * Burn proof is generated via API. Please see README.md
   * @notice Mainnet only. Function will revert if called from other network.
   * @param burnProof Burn proof generated via API.
   */
  function exit(bytes calldata burnProof) external {
    if (block.chainid != ETHEREUM_CHAIN_ID) revert InvalidChain();

    IRootChainManager(ROOT_CHAIN_MANAGER).exit(burnProof);
    emit Exit();
  }

  /*
   * Withdraws tokens on Mainnet contract to Aave V3 Collector.
   * @notice Mainnet only. Function will revert if called from other network.
   * @param token Mainnet address of token to withdraw to Collector
   */
  function withdrawToCollector(address token) external {
    if (block.chainid != ETHEREUM_CHAIN_ID) revert InvalidChain();

    uint256 balance = IERC20(token).balanceOf(address(this));

    IERC20(token).transfer(address(AaveV3Ethereum.COLLECTOR), balance);
    emit WithdrawToCollector(token, balance);
  }

  /*
   * @notice Transfer any tokens accidentally sent to this contract to Aave V3 Polygon Collector
   * @param tokens List of token addresses
   */
  function rescueTokens(address[] calldata tokens) external {
    if (block.chainid != POLYGON_CHAIN_ID) revert InvalidChain();

    for (uint256 i = 0; i < tokens.length; ++i) {
      IERC20(tokens[i]).transfer(
        address(AaveV3Polygon.COLLECTOR),
        IERC20(tokens[i]).balanceOf(address(this))
      );
    }
  }
}
