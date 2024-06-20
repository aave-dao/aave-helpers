// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from 'solidity-utils/contracts/transparent-proxy/Initializable.sol';

contract CCCMock is Initializable {
  event MockEvent(address indexed caller);

  constructor() {}

  function initializeRevision() external reinitializer(60) {
    emit MockEvent(msg.sender);
  }
}
