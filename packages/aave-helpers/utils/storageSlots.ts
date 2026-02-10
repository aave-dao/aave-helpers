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
} from 'viem';

export function getSolidityStorageSlotBytes(mappingSlot: Hex, key: Hex) {
  const slot = pad(mappingSlot, { size: 32 });
  return keccak256(
    encodeAbiParameters(parseAbiParameters('bytes32, uint256'), [key, BigInt(slot)])
  );
}

export function getSolidityStorageSlotUint(mappingSlot: bigint, key: bigint) {
  return keccak256(encodeAbiParameters(parseAbiParameters('uint256, uint256'), [key, mappingSlot]));
}

export function getSolidityStorageSlotAddress(mappingSlot: bigint | number, key: Hex) {
  return keccak256(
    encodeAbiParameters(parseAbiParameters('address, uint256'), [key, BigInt(mappingSlot)])
  );
}

export function getDynamicArraySlot(baseSlot: bigint, arrayIndex: number, itemSize: number): Hex {
  return pad(
    toHex(
      fromHex(keccak256(encodeAbiParameters(parseAbiParameters('uint256'), [baseSlot])), 'bigint') +
        BigInt(arrayIndex * itemSize)
    ),
    { size: 32 }
  );
}

export function getBytesValue(value: string | Hex) {
  const bytesString = toBytes(value);
  if (bytesString.length > 31) throw new Error('Error: strings > 31 bytes are not implemented');
  return concat([
    toHex(pad(bytesString, { size: 31, dir: 'right' })),
    toHex(bytesString.length * 2, { size: 1 }),
  ]);
}

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
  return ((bigIntValue >> startBit) & mask).toString();
}

export function setBits(
  _bigIntBase: bigint | number | string,
  startBit: bigint,
  endBit: bigint,
  _replaceValue: bigint | number
) {
  const bigIntBase = BigInt(_bigIntBase);
  const bigIntReplaceValue = BigInt(_replaceValue);
  let mask = 0n;
  for (let i = startBit; i < endBit; i++) {
    mask |= 1n << BigInt(i);
  }
  return (bigIntBase & ~mask) | (bigIntReplaceValue << BigInt(startBit));
}

export function bitMapToIndexes(bitmap: bigint) {
  const indexes: number[] = [];
  for (let i = 0; bitmap !== 0n; i++) {
    if (bitmap & 1n) indexes.push(i);
    bitmap = bitmap >> 1n;
  }
  return indexes;
}

export function bytes32ToAddress(bytes32: Hex) {
  return getAddress(slice(bytes32, 12, 32));
}
