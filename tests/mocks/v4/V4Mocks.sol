// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISpoke, IHub} from 'aave-address-book/AaveV4.sol';
import {IAssetInterestRateStrategy} from 'aave-v4/hub/interfaces/IAssetInterestRateStrategy.sol';

/// @notice ERC20 fixture that only exposes `symbol()`, the single call SnapshotV4
/// makes on the underlying token.
contract MockERC20Symbol {
  string public symbol;

  constructor(string memory _symbol) {
    symbol = _symbol;
  }
}

/// @notice Minimal IAaveOracle mock. Only the two functions SnapshotV4 reads
/// (`getReserveSource`, `getReservePrice`) are implemented.
contract MockOracle {
  mapping(uint256 => address) private _sources;
  mapping(uint256 => uint256) private _prices;

  function setReserve(uint256 reserveId, address source, uint256 price) external {
    _sources[reserveId] = source;
    _prices[reserveId] = price;
  }

  function getReserveSource(uint256 reserveId) external view returns (address) {
    return _sources[reserveId];
  }

  function getReservePrice(uint256 reserveId) external view returns (uint256) {
    return _prices[reserveId];
  }
}

/// @notice Minimal IAssetInterestRateStrategy mock.
contract MockIR {
  mapping(uint256 => IAssetInterestRateStrategy.InterestRateData) private _data;
  mapping(uint256 => uint256) private _maxRates;

  function setData(
    uint256 assetId,
    IAssetInterestRateStrategy.InterestRateData memory data,
    uint256 maxDrawnRate
  ) external {
    _data[assetId] = data;
    _maxRates[assetId] = maxDrawnRate;
  }

  function getInterestRateData(
    uint256 assetId
  ) external view returns (IAssetInterestRateStrategy.InterestRateData memory) {
    return _data[assetId];
  }

  function getMaxDrawnRate(uint256 assetId) external view returns (uint256) {
    return _maxRates[assetId];
  }
}

/// @notice Minimal ISpoke mock covering the reads SnapshotV4 performs on a spoke.
contract MockSpoke {
  address public ORACLE;
  uint16 public MAX_USER_RESERVES_LIMIT;
  ISpoke.LiquidationConfig private _liqConfig;

  ISpoke.Reserve[] private _reserves;
  mapping(uint256 => ISpoke.ReserveConfig) private _reserveConfigs;
  mapping(uint256 => mapping(uint32 => ISpoke.DynamicReserveConfig)) private _dynConfigs;

  function setOracle(address oracle) external {
    ORACLE = oracle;
  }

  function setMaxUserReservesLimit(uint16 limit) external {
    MAX_USER_RESERVES_LIMIT = limit;
  }

  function setLiquidationConfig(ISpoke.LiquidationConfig memory cfg) external {
    _liqConfig = cfg;
  }

  function addReserve(
    ISpoke.Reserve memory reserve,
    ISpoke.ReserveConfig memory config,
    ISpoke.DynamicReserveConfig memory dyn
  ) external returns (uint256 reserveId) {
    reserveId = _reserves.length;
    _reserves.push(reserve);
    _reserveConfigs[reserveId] = config;
    _dynConfigs[reserveId][reserve.dynamicConfigKey] = dyn;
  }

  // Per-field mutators for already-added reserves, used by snapshot delta tests.
  function setReserveConfig(uint256 reserveId, ISpoke.ReserveConfig memory config) external {
    _reserveConfigs[reserveId] = config;
  }

  function setDynamicReserveConfig(
    uint256 reserveId,
    uint32 dynamicConfigKey,
    ISpoke.DynamicReserveConfig memory dyn
  ) external {
    _dynConfigs[reserveId][dynamicConfigKey] = dyn;
  }

  function getReserveCount() external view returns (uint256) {
    return _reserves.length;
  }

  function getReserve(uint256 reserveId) external view returns (ISpoke.Reserve memory) {
    return _reserves[reserveId];
  }

  function getReserveConfig(uint256 reserveId) external view returns (ISpoke.ReserveConfig memory) {
    return _reserveConfigs[reserveId];
  }

  function getDynamicReserveConfig(
    uint256 reserveId,
    uint32 dynamicConfigKey
  ) external view returns (ISpoke.DynamicReserveConfig memory) {
    return _dynConfigs[reserveId][dynamicConfigKey];
  }

  function getLiquidationConfig() external view returns (ISpoke.LiquidationConfig memory) {
    return _liqConfig;
  }
}

/// @notice Minimal IHub mock covering the reads SnapshotV4 performs on a hub.
contract MockHub {
  IHub.Asset[] private _assets;
  mapping(uint256 => IHub.AssetConfig) private _assetConfigs;
  mapping(uint256 => address[]) private _spokesByAsset;
  mapping(uint256 => mapping(address => IHub.SpokeConfig)) private _spokeConfigs;
  mapping(uint256 => mapping(address => bool)) private _spokeRegistered;

  function addAsset(
    IHub.Asset memory asset,
    IHub.AssetConfig memory config
  ) external returns (uint256 assetId) {
    assetId = _assets.length;
    _assets.push(asset);
    _assetConfigs[assetId] = config;
  }

  // Per-asset mutators for already-added assets, used by snapshot delta tests.
  function setAsset(uint256 assetId, IHub.Asset memory asset) external {
    _assets[assetId] = asset;
  }

  function setAssetConfig(uint256 assetId, IHub.AssetConfig memory config) external {
    _assetConfigs[assetId] = config;
  }

  function addSpokeConfig(uint256 assetId, address spoke, IHub.SpokeConfig memory config) external {
    if (!_spokeRegistered[assetId][spoke]) {
      _spokesByAsset[assetId].push(spoke);
      _spokeRegistered[assetId][spoke] = true;
    }
    _spokeConfigs[assetId][spoke] = config;
  }

  function getAssetCount() external view returns (uint256) {
    return _assets.length;
  }

  function getAsset(uint256 assetId) external view returns (IHub.Asset memory) {
    return _assets[assetId];
  }

  function getAssetConfig(uint256 assetId) external view returns (IHub.AssetConfig memory) {
    return _assetConfigs[assetId];
  }

  function getAssetUnderlyingAndDecimals(uint256 assetId) external view returns (address, uint8) {
    return (_assets[assetId].underlying, _assets[assetId].decimals);
  }

  function getSpokeCount(uint256 assetId) external view returns (uint256) {
    return _spokesByAsset[assetId].length;
  }

  function getSpokeAddress(uint256 assetId, uint256 index) external view returns (address) {
    return _spokesByAsset[assetId][index];
  }

  function getSpokeConfig(
    uint256 assetId,
    address spoke
  ) external view returns (IHub.SpokeConfig memory) {
    return _spokeConfigs[assetId][spoke];
  }
}
