// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
import {Vm} from 'forge-std/Vm.sol';

library StorageHelpers {
  /**
   * @param baseSlot base storage slot of the mapping
   * @param key the mapping key
   * @return uint256 calculated slot
   */
  function getStorageSlotUintMapping(
    uint256 baseSlot,
    uint256 key
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(key, baseSlot)));
  }

  /**
   * @dev duplicate of getStorageSlotUintMapping due to missing solc generics
   * @param baseSlot base storage slot of the mapping
   * @param key the mapping key
   * @return uint256 calculated slot
   */
  function getStorageSlotBytes32Mapping(
    uint256 baseSlot,
    bytes32 key
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(key, baseSlot)));
  }

  /**
   * @dev duplicate of getStorageSlotUintMapping due to missing solc generics
   * @param baseSlot base storage slot of the array
   * @param index the array index
   * @param elementSize the size of each array item (usually 1)
   * @return uint256 calculated slot
   */
  function arrLocation(
    uint256 baseSlot,
    uint256 index,
    uint256 elementSize
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(baseSlot))) + (index * elementSize);
  }

  function maskValueToBitsAtPosition(
    uint256 startBit,
    uint256 endBit,
    bytes32 storageBefore,
    bytes32 value
  ) internal pure returns (bytes32) {
    uint256 mask = ~((type(uint256).max << startBit) & (type(uint256).max >> (256 - endBit)));
    return bytes32((mask & uint256(storageBefore)) | (uint256(value) << startBit));
  }

  function writeBitsInStorageSlot(
    Vm vm,
    address targetContract,
    bytes32 slot,
    uint256 startBit,
    uint256 endBit,
    bytes32 value
  ) internal {
    bytes32 storageBefore = vm.load(targetContract, slot);
    vm.store(
      targetContract,
      slot,
      maskValueToBitsAtPosition(startBit, endBit, storageBefore, value)
    );
  }
}
