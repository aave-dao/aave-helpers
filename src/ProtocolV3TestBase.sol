// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5 <0.9.0;

import {BaseProtocolV3TestBase} from './BaseProtocolV3TestBase.sol';

contract ProtocolV3TestBase is BaseProtocolV3TestBase {
  function _getBytecode(address contractAddress) internal override view returns (bytes memory) {
    return (contractAddress.code);
  }
}