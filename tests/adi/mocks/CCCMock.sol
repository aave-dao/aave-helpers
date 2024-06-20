// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from 'solidity-utils/contracts/transparent-proxy/Initializable.sol';
import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';

contract Gap is OwnableWithGuardian {
  uint256[113] private gap; // simulates the storage of ccc
}

contract CCCMock is Gap, Initializable {
  event MockEvent(address indexed caller);

  function initializeRevision() external reinitializer(60) {
    emit MockEvent(msg.sender);
  }
}
