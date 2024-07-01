// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {Rescuable} from 'solidity-utils/contracts/utils/Rescuable.sol';
/// TODO include after Rescuable721 gets merged in
// import {Rescuable721} from 'solidity-utils/contracts/utils/Rescuable721.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {IAaveStethWithdrawer, IWithdrawalQueueERC721, IWETH} from './interfaces/IAaveStethWithdrawer.sol';

contract AaveStethWithdrawer is Ownable, Rescuable, IAaveStethWithdrawer {
  using SafeERC20 for IERC20;

  /// auto incrementing index to store requestIds of withdrawals
  uint256 public nextIndex;

  /// stores a mapping of index to arrays of requestIds
  mapping(uint256 => uint256[]) public requestIds;

  IWithdrawalQueueERC721 public constant WSETH_WITHDRAWAL_QUEUE =
    IWithdrawalQueueERC721(0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1);

  constructor(address owner) {
    _transferOwnership(owner);
    IERC20(AaveV3EthereumAssets.wstETH_UNDERLYING).approve(
      address(WSETH_WITHDRAWAL_QUEUE),
      type(uint256).max
    );
  }

  /// @inheritdoc IAaveStethWithdrawer
  function startWithdraw(uint256[] calldata amounts) external {
    uint256 index = nextIndex++;
    uint256[] memory rIds = WSETH_WITHDRAWAL_QUEUE.requestWithdrawalsWstETH(amounts, address(this));

    requestIds[index] = rIds;
    emit StartedWithdrawal(amounts, index);
  }

  /// @inheritdoc IAaveStethWithdrawer
  function finalizeWithdraw(uint256 index) external {
    uint256[] memory reqIds = getRequestIds(index);
    uint256[] memory hintIds = WSETH_WITHDRAWAL_QUEUE.findCheckpointHints(
      reqIds,
      1,
      WSETH_WITHDRAWAL_QUEUE.getLastCheckpointIndex()
    );

    WSETH_WITHDRAWAL_QUEUE.claimWithdrawalsTo(reqIds, hintIds, address(this));

    uint256 ethBalance = address(this).balance;

    IWETH(AaveV3EthereumAssets.WETH_UNDERLYING).deposit{value: ethBalance}();

    IERC20(AaveV3EthereumAssets.WETH_UNDERLYING).transfer(
      address(AaveV3Ethereum.COLLECTOR),
      ethBalance
    );

    emit FinalizedWithdrawal(ethBalance, index);
  }
  
  /// @inheritdoc IAaveStethWithdrawer
  function getRequestIds(uint256 index) public view returns (uint256[] memory reqIds) {
    reqIds = requestIds[index];
  }

  /// @inheritdoc Rescuable
  function whoCanRescue() public view override returns (address) {
    return owner();
  }

  fallback() external payable {}
  receive() external payable {}
}
