// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "solidity-utils/contracts/oz-common/interfaces/IERC20.sol";
import {SafeERC20} from "solidity-utils/contracts/oz-common/SafeERC20.sol";
import {OwnableWithGuardian} from "solidity-utils/contracts/access-control/OwnableWithGuardian.sol";
import {ICollector, CollectorUtils as CU} from "../CollectorUtils.sol";
import {IFinanceSteward} from "./interfaces/IFinanceSteward.sol";

/**
 * @title FinanceSteward
 * @author luigy-lemon  (Karpatkey)
 * @author efecarranza  (Tokenlogic)
 * @notice Helper contract that enables a Guardian to execute permissioned actions on the Aave Collector
 */
contract FinanceSteward is OwnableWithGuardian, IFinanceSteward {
    using CU for ICollector;
    using CU for CU.IOInput;
    using CU for CU.CreateStreamInput;

    /// @inheritdoc IFinanceSteward
    ICollector public immutable COLLECTOR;

    /// @inheritdoc IFinanceSteward
    mapping(address receiver => bool isApproved) public transferApprovedReceiver;

    /// @inheritdoc IFinanceSteward
    mapping(address token => uint256 budget) public tokenBudget;

    /// @inheritdoc IFinanceSteward
    mapping(address token => uint256 minimumBalanceLeft) public minTokenBalance;

    constructor(address _owner, address _guardian, address collector) {
        _transferOwnership(_owner);
        _updateGuardian(_guardian);
        COLLECTOR = ICollector(collector);
    }

    /// Controlled Actions

    /// @inheritdoc IFinanceSteward
    function approve(address token, address to, uint256 amount) external onlyOwnerOrGuardian {
        _validateTransfer(token, to, amount);
        COLLECTOR.approve(token, to, amount);
    }

    /// @inheritdoc IFinanceSteward
    function transfer(address token, address to, uint256 amount) external onlyOwnerOrGuardian {
        _validateTransfer(token, to, amount);
        COLLECTOR.transfer(token, to, amount);
    }

    /// @inheritdoc IFinanceSteward
    function createStream(address to, StreamData memory stream) external onlyOwnerOrGuardian {
        if (stream.start < block.timestamp || stream.end <= stream.start) {
            revert InvalidDate();
        }

        _validateTransfer(stream.token, to, stream.amount);

        uint256 duration = stream.end - stream.start;

        CU.CreateStreamInput memory utilsData =
            CU.CreateStreamInput(stream.token, to, stream.amount, stream.start, duration);

        CU.stream(COLLECTOR, utilsData);
    }

    function cancelStream(uint256 streamId) external onlyOwnerOrGuardian {
        COLLECTOR.cancelStream(streamId);
    }

    /// DAO Actions

    /// @inheritdoc IFinanceSteward
    function increaseBudget(address token, uint256 amount) external onlyOwner {
        uint256 currentBudget = tokenBudget[token];
        _updateBudget(token, currentBudget + amount);
    }

    /// @inheritdoc IFinanceSteward
    function decreaseBudget(address token, uint256 amount) external onlyOwner {
        uint256 currentBudget = tokenBudget[token];
        if (amount > currentBudget) {
            _updateBudget(token, 0);
        } else {
            _updateBudget(token, currentBudget - amount);
        }
    }

    /// @inheritdoc IFinanceSteward
    function setWhitelistedReceiver(address to) external onlyOwner {
        transferApprovedReceiver[to] = true;
        emit ReceiverWhitelisted(to);
    }

    /// @inheritdoc IFinanceSteward
    function setMinimumBalanceShield(address token, uint256 amount) external onlyOwner {
        minTokenBalance[token] = amount;
        emit MinimumTokenBalanceUpdated(token, amount);
    }

    /// Logic

    /// @dev Internal function to validate a transfer's parameters
    function _validateTransfer(address token, address to, uint256 amount) internal {
        if (transferApprovedReceiver[to] == false) {
            revert UnrecognizedReceiver();
        }

        uint256 currentBalance = IERC20(token).balanceOf(address(COLLECTOR));
        if (currentBalance < amount) {
            revert ExceedsBalance();
        }
        if (minTokenBalance[token] > 0) {
            if (currentBalance - amount < minTokenBalance[token]) {
                revert MinimumBalanceShield(minTokenBalance[token]);
            }
        }

        uint256 currentBudget = tokenBudget[token];
        if (currentBudget < amount) {
            revert ExceedsBudget(currentBudget);
        }
        _updateBudget(token, currentBudget - amount);
    }

    function _updateBudget(address token, uint256 newAmount) internal {
        tokenBudget[token] = newAmount;
        emit BudgetUpdate(token, newAmount);
    }
}
