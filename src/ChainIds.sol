// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Vm} from 'forge-std/Vm.sol';

library ChainIds {
  uint256 internal constant MAINNET = 1;
  uint256 internal constant OPTIMISM = 10;
  uint256 internal constant BNB = 56;
  uint256 internal constant POLYGON = 137;
  uint256 internal constant FANTOM = 250;
  uint256 internal constant ZK_SYNC = 324;
  uint256 internal constant METIS = 1088;
  uint256 internal constant ZK_EVM = 1101;
  uint256 internal constant BASE = 8453;
  uint256 internal constant ARBITRUM = 42161;
  uint256 internal constant AVALANCHE = 43114;
  uint256 internal constant GNOSIS = 100;
  uint256 internal constant SEPOLIA = 11155111;
  uint256 internal constant HARMONY = 1666600000;
}

library ChainHelpers {
  error UnknownChainId();

  function selectChain(Vm vm, uint256 chainId) internal returns (uint256, uint256) {
    uint256 previousFork = vm.activeFork();
    if (chainId == block.chainid) return (previousFork, previousFork);
    uint256 newFork;
    if (chainId == ChainIds.MAINNET) {
      newFork = vm.createFork(vm.rpcUrl('mainnet'));
    } else if (chainId == ChainIds.OPTIMISM) {
      newFork = vm.createFork(vm.rpcUrl('optimism'));
    } else if (chainId == ChainIds.BNB) {
      newFork = vm.createFork(vm.rpcUrl('bnb'));
    } else if (chainId == ChainIds.POLYGON) {
      newFork = vm.createFork(vm.rpcUrl('polygon'));
    } else if (chainId == ChainIds.FANTOM) {
      newFork = vm.createFork(vm.rpcUrl('fantom'));
    } else if (chainId == ChainIds.ZK_SYNC) {
      newFork = vm.createFork(vm.rpcUrl('zkSync'));
    } else if (chainId == ChainIds.METIS) {
      newFork = vm.createFork(vm.rpcUrl('metis'));
    } else if (chainId == ChainIds.ZK_EVM) {
      newFork = vm.createFork(vm.rpcUrl('zkEvm'));
    } else if (chainId == ChainIds.BASE) {
      newFork = vm.createFork(vm.rpcUrl('base'));
    } else if (chainId == ChainIds.GNOSIS) {
      newFork = vm.createFork(vm.rpcUrl('gnosis'));
    } else if (chainId == ChainIds.ARBITRUM) {
      newFork = vm.createFork(vm.rpcUrl('arbitrum'));
    } else if (chainId == ChainIds.AVALANCHE) {
      newFork = vm.createFork(vm.rpcUrl('avalanche'));
    } else if (chainId == ChainIds.SEPOLIA) {
      newFork = vm.createFork(vm.rpcUrl('sepolia'));
    } else if (chainId == ChainIds.HARMONY) {
      newFork = vm.createFork(vm.rpcUrl('harmony'));
    } else {
      revert UnknownChainId();
    }
    return (previousFork, newFork);
  }
}
