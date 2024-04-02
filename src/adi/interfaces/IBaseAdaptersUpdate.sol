// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseReceiverAdaptersUpdate} from './IBaseReceiverAdaptersUpdate.sol';
import {IBaseForwarderAdaptersUpdate} from './IBaseForwarderAdaptersUpdate.sol';

/**
 * @title Interface of the base payload aDI and bridge adapters update
 * @author BGD Labs @bgdlabs
 */
interface IBaseAdaptersUpdate is IBaseReceiverAdaptersUpdate, IBaseForwarderAdaptersUpdate {

}
