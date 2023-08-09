// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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
}
