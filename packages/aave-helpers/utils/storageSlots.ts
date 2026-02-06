import {
  type Hex,
  concat,
  encodeAbiParameters,
  fromHex,
  getAddress,
  keccak256,
  pad,
  parseAbiParameters,
  slice,
  toBytes,
  toHex,
  trim,
} from 'viem';
/**
 * @notice Returns the storage slot for a Solidity mapping with bytes32 keys, given the slot of the mapping itself
 * @dev Read more at https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html#mappings-and-dynamic-arrays
 * @param mappingSlot Mapping slot in storage
 * @param key Mapping key to find slot for
 * @returns Storage slot
 */
export function getSolidityStorageSlotBytes(mappingSlot: Hex, key: Hex) {
  const slot = pad(mappingSlot, { size: 32 });
  return trim(
    keccak256(encodeAbiParameters(parseAbiParameters('bytes32, uint256'), [key, BigInt(slot)]))
  );
}

/**
 * @notice Returns the storage slot for a Solidity mapping with uint keys, given the slot of the mapping itself
 * @dev Read more at https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html#mappings-and-dynamic-arrays
 * @param mappingSlot Mapping slot in storage
 * @param key Mapping key to find slot for
 * @returns Storage slot
 */
export function getSolidityStorageSlotUint(mappingSlot: bigint, key: bigint) {
  return keccak256(encodeAbiParameters(parseAbiParameters('uint256, uint256'), [key, mappingSlot]));
}

export function getSolidityStorageSlotAddress(mappingSlot: bigint | number, key: Hex) {
  return keccak256(
    encodeAbiParameters(parseAbiParameters('address, uint256'), [key, BigInt(mappingSlot)])
  );
}

/**
 * Returns the slot of an array item
 * @param baseSlot baseSlot of the array size pointer
 * @param arrayIndex index within the array
 * @param itemSize number of slots consumed per array item
 * @returns
 */
export function getDynamicArraySlot(baseSlot: bigint, arrayIndex: number, itemSize: number): Hex {
  return pad(
    toHex(
      fromHex(keccak256(encodeAbiParameters(parseAbiParameters('uint256'), [baseSlot])), 'bigint') +
        BigInt(arrayIndex * itemSize)
    ),
    { size: 32 }
  );
}

/**
 * https://ethereum.stackexchange.com/questions/107282/storage-and-memory-layout-of-strings
 * @param value string | bytes
 */
export function getBytesValue(value: string | Hex) {
  const bytesString = toBytes(value);
  if (bytesString.length > 31) throw new Error('Error: strings > 31 bytes are not implemented');
  return concat([
    toHex(pad(bytesString, { size: 31, dir: 'right' })),
    toHex(bytesString.length * 2, { size: 1 }),
  ]);
}

/**
 * Returns the selected bits of a uint256
 * @param _bigIntValue
 * @param startBit
 * @param endBit
 * @returns
 */
export function getBits(_bigIntValue: bigint | number | string, startBit: bigint, _endBit: bigint) {
  let endBit = _endBit;
  const bigIntValue = BigInt(_bigIntValue);
  if (startBit > endBit) {
    throw new Error('Invalid bit range: startBit must be less than or equal to endBit');
  }

  const bitLength = BigInt(bigIntValue.toString(2)).toString().length;
  if (endBit >= bitLength) {
    endBit = BigInt(bitLength - 1);
  }

  const mask = (1n << (endBit - startBit + 1n)) - 1n;
  const maskedValue = (bigIntValue >> startBit) & mask;
  return maskedValue.toString();
}

/**
 * Sets the bits in a bigint
 * @param _bigIntBase
 * @param startBit inclusive
 * @param endBit exclusive
 * @param value the value to replace
 * @returns
 */
export function setBits(
  _bigIntBase: bigint | number | string,
  startBit: bigint,
  endBit: bigint,
  _replaceValue: bigint | number
) {
  const bigIntBase = BigInt(_bigIntBase);
  const bigIntReplaceValue = BigInt(_replaceValue);

  // Calculate the mask for the specified range
  let mask = BigInt(0);
  for (let i = startBit; i < endBit; i++) {
    mask |= BigInt(1) << BigInt(i);
  }
  // Clear the bits in the original number within the specified range
  const clearedNumber = bigIntBase & ~mask;

  // Set the new bits in the specified range
  const result = clearedNumber | (bigIntReplaceValue << BigInt(startBit));
  return result;
}

export function bitMapToIndexes(bitmap: bigint) {
  const reserveIndexes = [];
  for (let i = 0; bitmap != 0n; i++) {
    if (bitmap & 0x1n) reserveIndexes.push(i);
    bitmap = bitmap >> 1n;
  }
  return reserveIndexes;
}

export function bytes32ToAddress(bytes32: Hex) {
  return getAddress(slice(bytes32, 12, 32));
}
