// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {GovV3Helpers, PayloadsControllerUtils} from '../src/GovV3Helpers.sol';

contract PreviewLink is Test {
  function testPreviewLink() public pure {
    PayloadsControllerUtils.Payload[] memory payloads = new PayloadsControllerUtils.Payload[](2);
    payloads[0].payloadId = 1;
    payloads[0].accessLevel = PayloadsControllerUtils.AccessControl.Level_1;
    payloads[0].chain = 12;
    payloads[0].payloadsController = address(213123213213123213);
    payloads[1].payloadId = 2;
    payloads[1].accessLevel = PayloadsControllerUtils.AccessControl.Level_1;
    payloads[1].chain = 32;
    payloads[1].payloadsController = address(434343434343434);

    GovV3Helpers.generateProposalPreviewLink(
      vm,
      payloads,
      0x12f2d9c91e4e23ae4009ab9ef5862ee0ae79498937b66252213221f04a5d5b32,
      0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496
    );
  }
}
