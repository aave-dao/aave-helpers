// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from 'solidity-utils/contracts/transparent-proxy/Initializable.sol';

contract CCCMock is Initializable {
  event MockEvent(address indexed caller);

  function initializeRevision() external reinitializer(3) {
    emit MockEvent(msg.sender);
  }
}
