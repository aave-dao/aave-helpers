// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';
import {ICollector, CollectorUtils as CU} from '../CollectorUtils.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV2Ethereum, AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {IPool, DataTypes as DataTypesV3} from 'aave-address-book/AaveV3.sol';
import {ILendingPool, DataTypes as DataTypesV2} from 'aave-address-book/AaveV2.sol';
import {IPoolV3FinSteward} from './interfaces/IPoolV3FinSteward.sol';

/**
 * @title PoolV3FinSteward
 * @author luigy-lemon  (Karpatkey)
 * @author efecarranza  (Tokenlogic)
 * @notice Helper contract that enables a Guardian to execute permissioned actions on the Aave Collector
 */
contract PoolV3FinSteward is OwnableWithGuardian, IPoolV3FinSteward {
  using DataTypesV2 for DataTypesV2.ReserveData;
  using DataTypesV3 for DataTypesV3.ReserveDataLegacy;
  using CU for ICollector;
  using CU for CU.IOInput;

  /// @inheritdoc IPoolV3FinSteward
  ICollector public immutable COLLECTOR = AaveV3Ethereum.COLLECTOR;

  /// @inheritdoc IPoolV3FinSteward
  ILendingPool public v2Pool = ILendingPool(AaveV2Ethereum.POOL);

  /// @inheritdoc IPoolV3FinSteward
  mapping(address pool => bool isApproved) public v3Pools;

  /// @inheritdoc IPoolV3FinSteward
  mapping(address token => uint256 minimumBalanceLeft) public minTokenBalance;

  constructor(address _owner, address _guardian) {
    _transferOwnership(_owner);
    _updateGuardian(_guardian);
    _setV3Pool(address(AaveV3Ethereum.POOL)); // Main
    _setV3Pool(0x0AA97c284e98396202b6A04024F5E2c65026F3c0); // EtherFi
    _setV3Pool(0x4e033931ad43597d96D6bcc25c280717730B58B1); // Lido
  }

  /// Steward Actions

  /// @inheritdoc IPoolV3FinSteward
  function depositV3(address pool, address reserve, uint256 amount) external onlyOwnerOrGuardian {
    if (amount == 0) revert InvalidZeroAmount();
    _validateV3Pool(pool);
    CU.IOInput memory depositData = CU.IOInput(pool, reserve, amount);
    CU.depositToV3(COLLECTOR, depositData);
  }

  /// @inheritdoc IPoolV3FinSteward
  function withdrawV3(address pool, address reserve, uint256 amount) external onlyOwnerOrGuardian {
    if (amount == 0) revert InvalidZeroAmount();
    _validateV3Pool(pool);

    DataTypesV3.ReserveDataLegacy memory reserveData = IPool(pool).getReserveData(reserve);
    address atoken = reserveData.aTokenAddress;
    uint256 validAmount = _validateAmount(atoken, amount);

    CU.IOInput memory withdrawData = CU.IOInput(pool, reserve, validAmount);

    CU.withdrawFromV3(COLLECTOR, withdrawData, address(COLLECTOR));
  }

  /// @inheritdoc IPoolV3FinSteward
  function migrateV2toV3(
    address pool,
    address reserve,
    uint256 amount
  ) external onlyOwnerOrGuardian {
    if (amount == 0) revert InvalidZeroAmount();
    if (address(v2Pool) == address(0)) revert V2PoolNotFound();

    _validateV3Pool(pool);

    DataTypesV2.ReserveData memory reserveData = v2Pool.getReserveData(reserve);
    address atoken = reserveData.aTokenAddress;

    uint256 balanceBefore = IERC20(reserve).balanceOf(address(COLLECTOR));
    uint256 validAmount = _validateAmount(atoken, amount);
    CU.IOInput memory withdrawData = CU.IOInput(address(v2Pool), reserve, validAmount);
    CU.withdrawFromV2(COLLECTOR, withdrawData, address(COLLECTOR));

    uint256 balanceAfter = IERC20(reserve).balanceOf(address(COLLECTOR));

    CU.IOInput memory depositData = CU.IOInput(pool, reserve, balanceAfter - balanceBefore);
    CU.depositToV3(COLLECTOR, depositData);
  }

  /// @inheritdoc IPoolV3FinSteward
  function withdrawV2(address reserve, uint256 amount) external onlyOwnerOrGuardian {
    if (amount == 0) revert InvalidZeroAmount();
    if (address(v2Pool) == address(0)) revert V2PoolNotFound();

    DataTypesV2.ReserveData memory reserveData = v2Pool.getReserveData(reserve);

    address atoken = reserveData.aTokenAddress;
    uint256 validAmount = _validateAmount(atoken, amount);
    CU.IOInput memory withdrawData = CU.IOInput(address(v2Pool), reserve, validAmount);
    CU.withdrawFromV2(COLLECTOR, withdrawData, address(COLLECTOR));
  }

  /// @inheritdoc IPoolV3FinSteward
  function validateAmount(address token, uint256 amount) external view {
    _validateAmount(token, amount);
  }

  /// @inheritdoc IPoolV3FinSteward
  function validateV3Pool(address pool) external view {
    _validateV3Pool(pool);
  }

  /// DAO Actions

  /// @inheritdoc IPoolV3FinSteward
  function setMinimumBalanceShield(address token, uint256 amount) external onlyOwner {
    minTokenBalance[token] = amount;
    emit MinimumTokenBalanceUpdated(token, amount);
  }

  /// @inheritdoc IPoolV3FinSteward
  function setV3Pool(address newV3pool) external onlyOwner {
    _setV3Pool(newV3pool);
  }

  /// @inheritdoc IPoolV3FinSteward
  function setV2Pool(address newV2pool) external onlyOwner {
    _setV2Pool(newV2pool);
  }

  /// Logic

  /// @dev Internal function to approve an Aave V3 Pool instance
  function _setV3Pool(address newV3pool) internal {
    if (newV3pool == address(0)) revert InvalidZeroAddress();

    v3Pools[newV3pool] = true;
    emit AddedV3Pool(newV3pool);
  }

  /// @dev Internal function to approve an Aave V2 Pool instance
  function _setV2Pool(address newV2pool) internal {
    if (newV2pool == address(0)) revert InvalidZeroAddress();
    
    v2Pool = ILendingPool(newV2pool);
    emit AddedV2Pool(newV2pool);
  }

  /// @dev Internal function to validate if an Aave V3 Pool instance has been approved
  function _validateV3Pool(address pool) internal view {
    if (v3Pools[pool] == false) revert UnrecognizedV3Pool();
  }

  /// @dev Internal function to validate minimum-amount to be left in a reserve
  function _validateAmount(address token, uint256 amount) internal view returns (uint256) {
    uint256 balance = IERC20(token).balanceOf(address(COLLECTOR));
    if (minTokenBalance[token] > 0) {
      uint256 leftover = (amount > balance) ? 0 : balance - amount;

      if (minTokenBalance[token] > leftover) revert MinimumBalanceShield(minTokenBalance[token]);
    }

    return (amount > balance) ? balance : amount;
  }
}
