// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StringUtils {
  function toString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return '0';
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
}

library WeiConverter {
  using StringUtils for uint256;

  function weiToDecimal(uint256 weiValue, uint256 decimals) internal pure returns (string memory) {
    uint256 integralPart = weiValue / (10 ** decimals);
    uint256 fractionalPart = weiValue % (10 ** decimals);

    string memory integralStr = integralPart.toString();
    string memory fractionalStr = fractionalPart.toString();

    // Pad fractional part with leading zeros if necessary
    while (bytes(fractionalStr).length < decimals) {
      fractionalStr = string(abi.encodePacked('0', fractionalStr));
    }

    // Remove trailing zeros from the fractional part
    bytes memory fractionalBytes = bytes(fractionalStr);
    uint256 fractionalLength = fractionalBytes.length;
    while (fractionalLength > 0 && fractionalBytes[fractionalLength - 1] == '0') {
      fractionalLength--;
    }

    bytes memory truncatedFractionalBytes = new bytes(fractionalLength);
    for (uint256 i = 0; i < fractionalLength; i++) {
      truncatedFractionalBytes[i] = fractionalBytes[i];
    }

    string memory result = string(
      abi.encodePacked(integralStr, '.', string(truncatedFractionalBytes))
    );
    return result;
  }
}
