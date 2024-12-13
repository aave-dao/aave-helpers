// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICollector} from "../../CollectorUtils.sol";
import {IPool} from "aave-address-book/AaveV3.sol";
import {ILendingPool} from "aave-address-book/AaveV2.sol";

import {AaveSwapper} from "src/swaps/AaveSwapper.sol";

interface IFinanceSteward {
    /**
     * @notice object with stream parameters
     * @param token ERC20 compatible asset
     * @param amount streamed amount in wei
     * @param start of the stream in timestamp
     * @param end of the stream in timestamp
     */
    struct StreamData {
        address token;
        uint256 amount;
        uint256 start;
        uint256 end;
    }

    /// @dev Amount cannot be zero
    error InvalidZeroAmount();

    /// @dev Address has not been previously approved as transfer recipient
    error UnrecognizedReceiver();

    /// @dev Transfer amount exceeds available balance
    error ExceedsBalance();

    /// @dev Transfer amount exceeds allowed budget for token
    /// @param remainingBudget The remaining budget left for the token
    error ExceedsBudget(uint256 remainingBudget);

    /// @dev Token has not been previously approved for swapping
    error UnrecognizedToken();

    /// @dev Oracle cannot be the zero-address
    error MissingPriceFeed();

    /// @dev Oracle did not return a valid value
    error PriceFeedFailure();

    /// @dev Stream start time cannot be less than current block.timestamp
    /// @dev Start time cannot be greater than end time
    error InvalidDate();

    /// @dev Cannot deplete reserves to less than minimum allowed
    /// @param minimumBalance The minimum allowed balance to keep in the Collector
    error MinimumBalanceShield(uint256 minimumBalance);

    /// @dev Slippage is too high
    error InvalidSlippage();

    /// @dev Aave V3 Pool must have been previously approved
    error UnrecognizedV3Pool();

    error V2PoolNotFound();

    /// @notice Emitted when the budget for a token is updated
    /// @param token The address of the token
    /// @param newAmount The new budget amount
    event BudgetUpdate(address indexed token, uint256 newAmount);

    /// @notice Emitted when a token is approved for swapping with its corresponding USD oracle
    /// @param token The address of the token approved for swapping
    /// @param oracleUSD The address of the oracle providing the USD price feed for the token
    event SwapApprovedToken(address indexed token, address indexed oracleUSD);

    /// @notice Emitted when a new V3 Pool gets listed
    /// @param V3Pool The address of the new pool
    event AddedV3Pool(address indexed V3Pool);

    /// @notice Emitted when an address is whitelisted as a receiver for transfers
    /// @param receiver The address that has been whitelisted
    event ReceiverWhitelisted(address indexed receiver);

    /// @notice Emitted when the minimum balance for a token is updated
    /// @param token The address of the token
    /// @param newAmount The new minimum balance for the token
    event MinimumTokenBalanceUpdated(address indexed token, uint256 newAmount);

    /// @notice Returns instance of Aave V3 Collector
    function COLLECTOR() external view returns (ICollector);

    /// @notice Returns whether receiver is approved to be transferred funds
    /// @param receiver Address of the user to receive funds
    function transferApprovedReceiver(address receiver) external view returns (bool);

    /// @notice Returns remaining budget for FinanceSteward to use with respective token
    /// @param token Address of the token to swap/transfer
    function tokenBudget(address token) external view returns (uint256);

    /// @notice Returns minimum balance of token to keep in Aave Pools
    /// @param token Address of the token to check balance for
    function minTokenBalance(address token) external view returns (uint256);

    /// @notice Approves a specified amount of a token for transfer to a recipient
    /// @param token The address of the token to approve
    /// @param to The address of the recipient
    /// @param amount The amount of the token to approve
    function approve(address token, address to, uint256 amount) external;

    /// @notice Transfers a specified amount of a token to a recipient
    /// @param token The address of the token to transfer
    /// @param to The address of the recipient
    /// @param amount The amount of the token to transfer
    function transfer(address token, address to, uint256 amount) external;

    /// @notice Creates a stream to transfer a specified amount of a token to a recipient over a duration
    /// @param to The address of the recipient
    /// @param stream Object including token, amount, start, end
    function createStream(address to, StreamData memory stream) external;

    /// @notice Cancels a stream identified by the streamId
    /// @param streamId The ID of the stream to cancel
    function cancelStream(uint256 streamId) external;

    /// @notice Increases the budget for a specified token by a specified amount
    /// @param token The address of the token
    /// @param amount The amount to increase the budget by
    function increaseBudget(address token, uint256 amount) external;

    /// @notice Decreases the budget for a specified token by a specified amount
    /// @param token The address of the token
    /// @param amount The amount to decrease the budget by
    function decreaseBudget(address token, uint256 amount) external;

    /// @notice Sets an address as a whitelisted receiver for transfers
    /// @param to The address to whitelist
    function setWhitelistedReceiver(address to) external;

    /// @notice Sets the minimum balance shield for a specified token
    /// @param token The address of the token
    /// @param amount The minimum balance to shield
    function setMinimumBalanceShield(address token, uint256 amount) external;
}
