import type { AbiEvent } from 'viem';

export const eventDb: AbiEvent[] = [
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'previousOwner', type: 'address' },
      { indexed: true, internalType: 'address', name: 'newOwner', type: 'address' },
    ],
    name: 'OwnershipTransferred',
    type: 'event',
  },
  {
    type: 'event',
    name: 'RoleGranted',
    inputs: [
      {
        name: 'role',
        type: 'bytes32',
        indexed: true,
        internalType: 'bytes32',
      },
      {
        name: 'account',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'sender',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
    ],
  },
  {
    type: 'event',
    name: 'Approval',
    inputs: [
      {
        name: 'owner',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'spender',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'value',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
    ],
  },
  {
    type: 'event',
    name: 'Transfer',
    inputs: [
      {
        name: 'from',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'to',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'value',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
    ],
  },
  {
    type: 'event',
    name: 'RegistrationRequested',
    inputs: [
      {
        name: 'hash',
        type: 'bytes32',
        indexed: true,
        internalType: 'bytes32',
      },
      {
        name: 'name',
        type: 'string',
        indexed: false,
        internalType: 'string',
      },
      {
        name: 'encryptedEmail',
        type: 'bytes',
        indexed: false,
        internalType: 'bytes',
      },
      {
        name: 'upkeepContract',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'gasLimit',
        type: 'uint32',
        indexed: false,
        internalType: 'uint32',
      },
      {
        name: 'adminAddress',
        type: 'address',
        indexed: false,
        internalType: 'address',
      },
      {
        name: 'triggerType',
        type: 'uint8',
        indexed: false,
        internalType: 'uint8',
      },
      {
        name: 'triggerConfig',
        type: 'bytes',
        indexed: false,
        internalType: 'bytes',
      },
      {
        name: 'offchainConfig',
        type: 'bytes',
        indexed: false,
        internalType: 'bytes',
      },
      {
        name: 'checkData',
        type: 'bytes',
        indexed: false,
        internalType: 'bytes',
      },
      {
        name: 'amount',
        type: 'uint96',
        indexed: false,
        internalType: 'uint96',
      },
    ],
  },
  {
    type: 'event',
    name: 'UpkeepRegistered',
    inputs: [
      {
        name: 'id',
        type: 'uint256',
        indexed: true,
        internalType: 'uint256',
      },
      {
        name: 'performGas',
        type: 'uint32',
        indexed: false,
        internalType: 'uint32',
      },
      {
        name: 'admin',
        type: 'address',
        indexed: false,
        internalType: 'address',
      },
    ],
  },
  {
    type: 'event',
    name: 'UpkeepCheckDataSet',
    inputs: [
      {
        name: 'id',
        type: 'uint256',
        indexed: true,
        internalType: 'uint256',
      },
      {
        name: 'newCheckData',
        type: 'bytes',
        indexed: false,
        internalType: 'bytes',
      },
    ],
  },
  {
    type: 'event',
    name: 'UpkeepTriggerConfigSet',
    inputs: [
      {
        name: 'id',
        type: 'uint256',
        indexed: true,
        internalType: 'uint256',
      },
      {
        name: 'triggerConfig',
        type: 'bytes',
        indexed: false,
        internalType: 'bytes',
      },
    ],
  },
  {
    type: 'event',
    name: 'UpkeepOffchainConfigSet',
    inputs: [
      {
        name: 'id',
        type: 'uint256',
        indexed: true,
        internalType: 'uint256',
      },
      {
        name: 'offchainConfig',
        type: 'bytes',
        indexed: false,
        internalType: 'bytes',
      },
    ],
  },
  {
    type: 'event',
    name: 'Transfer',
    inputs: [
      {
        name: 'from',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'to',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'value',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'data',
        type: 'bytes',
        indexed: false,
        internalType: 'bytes',
      },
    ],
  },
  {
    type: 'event',
    name: 'FundsAdded',
    inputs: [
      {
        name: 'id',
        type: 'uint256',
        indexed: true,
        internalType: 'uint256',
      },
      {
        name: 'from',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'amount',
        type: 'uint96',
        indexed: false,
        internalType: 'uint96',
      },
    ],
  },
  {
    type: 'event',
    name: 'RegistrationApproved',
    inputs: [
      {
        name: 'hash',
        type: 'bytes32',
        indexed: true,
        internalType: 'bytes32',
      },
      {
        name: 'displayName',
        type: 'string',
        indexed: false,
        internalType: 'string',
      },
      {
        name: 'upkeepId',
        type: 'uint256',
        indexed: true,
        internalType: 'uint256',
      },
    ],
  },
  {
    type: 'event',
    name: 'KeeperRegistered',
    inputs: [
      {
        name: 'id',
        type: 'uint256',
        indexed: true,
        internalType: 'uint256',
      },
      {
        name: 'upkeep',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'amount',
        type: 'uint96',
        indexed: true,
        internalType: 'uint96',
      },
    ],
  },
  {
    type: 'event',
    name: 'ExecutedAction',
    inputs: [
      {
        name: 'target',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'value',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'signature',
        type: 'string',
        indexed: false,
        internalType: 'string',
      },
      {
        name: 'data',
        type: 'bytes',
        indexed: false,
        internalType: 'bytes',
      },
      {
        name: 'executionTime',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'withDelegatecall',
        type: 'bool',
        indexed: false,
        internalType: 'bool',
      },
      {
        name: 'resultData',
        type: 'bytes',
        indexed: false,
        internalType: 'bytes',
      },
    ],
  },
  {
    type: 'event',
    name: 'PayloadExecuted',
    inputs: [
      {
        name: 'payloadId',
        type: 'uint40',
        indexed: false,
        internalType: 'uint40',
      },
    ],
  },
  {
    type: 'event',
    name: 'Mint',
    inputs: [
      {
        name: 'caller',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'onBehalfOf',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'value',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'balanceIncrease',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'index',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
    ],
  },
  {
    type: 'event',
    name: 'BalanceTransfer',
    inputs: [
      {
        name: 'from',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'to',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'value',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'index',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
    ],
  },
  {
    type: 'event',
    name: 'CancelStream',
    inputs: [
      {
        name: 'streamId',
        type: 'uint256',
        indexed: true,
        internalType: 'uint256',
      },
      {
        name: 'sender',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'recipient',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'senderBalance',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'recipientBalance',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
    ],
  },
  {
    type: 'event',
    name: 'CreateStream',
    inputs: [
      {
        name: 'streamId',
        type: 'uint256',
        indexed: true,
        internalType: 'uint256',
      },
      {
        name: 'sender',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'recipient',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'deposit',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'tokenAddress',
        type: 'address',
        indexed: false,
        internalType: 'address',
      },
      {
        name: 'startTime',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'stopTime',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
    ],
  },
  {
    type: 'event',
    name: 'SupplyCapChanged',
    inputs: [
      {
        name: 'asset',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'oldSupplyCap',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'newSupplyCap',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
    ],
  },
  {
    type: 'event',
    name: 'BorrowCapChanged',
    inputs: [
      {
        name: 'asset',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'oldBorrowCap',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'newBorrowCap',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
    ],
  },
  {
    type: 'event',
    name: 'BridgeAdapterUpdated',
    inputs: [
      {
        name: 'destinationChainId',
        type: 'uint256',
        indexed: true,
        internalType: 'uint256',
      },
      {
        name: 'bridgeAdapter',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'destinationBridgeAdapter',
        type: 'address',
        indexed: false,
        internalType: 'address',
      },
      {
        name: 'allowed',
        type: 'bool',
        indexed: true,
        internalType: 'bool',
      },
    ],
  },
  {
    type: 'event',
    name: 'AssetSourceUpdated',
    inputs: [
      {
        name: 'asset',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'source',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
    ],
  },
  {
    type: 'event',
    name: 'Initialized',
    inputs: [
      {
        name: 'underlyingAsset',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'pool',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'treasury',
        type: 'address',
        indexed: false,
        internalType: 'address',
      },
      {
        name: 'incentivesController',
        type: 'address',
        indexed: false,
        internalType: 'address',
      },
      {
        name: 'aTokenDecimals',
        type: 'uint8',
        indexed: false,
        internalType: 'uint8',
      },
      {
        name: 'aTokenName',
        type: 'string',
        indexed: false,
        internalType: 'string',
      },
      {
        name: 'aTokenSymbol',
        type: 'string',
        indexed: false,
        internalType: 'string',
      },
      {
        name: 'params',
        type: 'bytes',
        indexed: false,
        internalType: 'bytes',
      },
    ],
  },
  {
    type: 'event',
    name: 'Initialized',
    inputs: [
      {
        name: 'underlyingAsset',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'pool',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'incentivesController',
        type: 'address',
        indexed: false,
        internalType: 'address',
      },
      {
        name: 'debtTokenDecimals',
        type: 'uint8',
        indexed: false,
        internalType: 'uint8',
      },
      {
        name: 'debtTokenName',
        type: 'string',
        indexed: false,
        internalType: 'string',
      },
      {
        name: 'debtTokenSymbol',
        type: 'string',
        indexed: false,
        internalType: 'string',
      },
      {
        name: 'params',
        type: 'bytes',
        indexed: false,
        internalType: 'bytes',
      },
    ],
  },
  {
    type: 'event',
    name: 'RateDataUpdate',
    inputs: [
      {
        name: 'reserve',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'optimalUsageRatio',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'baseVariableBorrowRate',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'variableRateSlope1',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'variableRateSlope2',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
    ],
  },
  {
    type: 'event',
    name: 'ReserveInitialized',
    inputs: [
      {
        name: 'asset',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'aToken',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'stableDebtToken',
        type: 'address',
        indexed: false,
        internalType: 'address',
      },
      {
        name: 'variableDebtToken',
        type: 'address',
        indexed: false,
        internalType: 'address',
      },
      {
        name: 'interestRateStrategyAddress',
        type: 'address',
        indexed: false,
        internalType: 'address',
      },
    ],
  },
  {
    type: 'event',
    name: 'ReserveInterestRateDataChanged',
    inputs: [
      {
        name: 'asset',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'strategy',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'data',
        type: 'bytes',
        indexed: false,
        internalType: 'bytes',
      },
    ],
  },
  {
    type: 'event',
    name: 'ReserveBorrowing',
    inputs: [
      {
        name: 'asset',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'enabled',
        type: 'bool',
        indexed: false,
        internalType: 'bool',
      },
    ],
  },
  {
    type: 'event',
    name: 'BorrowableInIsolationChanged',
    inputs: [
      {
        name: 'asset',
        type: 'address',
        indexed: false,
        internalType: 'address',
      },
      {
        name: 'borrowable',
        type: 'bool',
        indexed: false,
        internalType: 'bool',
      },
    ],
  },
  {
    type: 'event',
    name: 'SiloedBorrowingChanged',
    inputs: [
      {
        name: 'asset',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'oldState',
        type: 'bool',
        indexed: false,
        internalType: 'bool',
      },
      {
        name: 'newState',
        type: 'bool',
        indexed: false,
        internalType: 'bool',
      },
    ],
  },
  {
    type: 'event',
    name: 'ReserveFactorChanged',
    inputs: [
      {
        name: 'asset',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'oldReserveFactor',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'newReserveFactor',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
    ],
  },
  {
    type: 'event',
    name: 'ReserveDataUpdated',
    inputs: [
      {
        name: 'reserve',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'liquidityRate',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'stableBorrowRate',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'variableBorrowRate',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'liquidityIndex',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'variableBorrowIndex',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
    ],
  },
  {
    type: 'event',
    name: 'ReserveFlashLoaning',
    inputs: [
      {
        name: 'asset',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'enabled',
        type: 'bool',
        indexed: false,
        internalType: 'bool',
      },
    ],
  },
  {
    type: 'event',
    name: 'CollateralConfigurationChanged',
    inputs: [
      {
        name: 'asset',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'ltv',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'liquidationThreshold',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'liquidationBonus',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
    ],
  },
  {
    type: 'event',
    name: 'DebtCeilingChanged',
    inputs: [
      {
        name: 'asset',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'oldDebtCeiling',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'newDebtCeiling',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
    ],
  },
  {
    type: 'event',
    name: 'LiquidationProtocolFeeChanged',
    inputs: [
      {
        name: 'asset',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'oldFee',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'newFee',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
    ],
  },
  {
    type: 'event',
    name: 'EModeCategoryAdded',
    inputs: [
      {
        name: 'categoryId',
        type: 'uint8',
        indexed: true,
        internalType: 'uint8',
      },
      {
        name: 'ltv',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'liquidationThreshold',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'liquidationBonus',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'oracle',
        type: 'address',
        indexed: false,
        internalType: 'address',
      },
      {
        name: 'label',
        type: 'string',
        indexed: false,
        internalType: 'string',
      },
    ],
  },
  {
    type: 'event',
    name: 'AssetCollateralInEModeChanged',
    inputs: [
      {
        name: 'asset',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'categoryId',
        type: 'uint8',
        indexed: false,
        internalType: 'uint8',
      },
      {
        name: 'collateral',
        type: 'bool',
        indexed: false,
        internalType: 'bool',
      },
    ],
  },
  {
    type: 'event',
    name: 'AssetBorrowableInEModeChanged',
    inputs: [
      {
        name: 'asset',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'categoryId',
        type: 'uint8',
        indexed: false,
        internalType: 'uint8',
      },
      {
        name: 'borrowable',
        type: 'bool',
        indexed: false,
        internalType: 'bool',
      },
    ],
  },
  {
    type: 'event',
    name: 'Supply',
    inputs: [
      {
        name: 'reserve',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'user',
        type: 'address',
        indexed: false,
        internalType: 'address',
      },
      {
        name: 'onBehalfOf',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'amount',
        type: 'uint256',
        indexed: false,
        internalType: 'uint256',
      },
      {
        name: 'referralCode',
        type: 'uint16',
        indexed: true,
        internalType: 'uint16',
      },
    ],
  },
  {
    type: 'event',
    name: 'AgentRegistered',
    inputs: [
      { name: 'agentId', type: 'uint256', indexed: true, internalType: 'uint256' },
      { name: 'riskOracle', type: 'address', indexed: true, internalType: 'address' },
      { name: 'updateType', type: 'string', indexed: true, internalType: 'string' },
    ],
  },
  {
    type: 'event',
    name: 'AgentAdminSet',
    inputs: [
      { name: 'agentId', type: 'uint256', indexed: true, internalType: 'uint256' },
      { name: 'admin', type: 'address', indexed: true, internalType: 'address' },
    ],
  },
  {
    type: 'event',
    name: 'MaxBatchSizeSet',
    inputs: [{ name: 'maxBatchSize', type: 'uint256', indexed: true, internalType: 'uint256' }],
  },
  {
    type: 'event',
    name: 'AgentAddressSet',
    inputs: [
      { name: 'agentId', type: 'uint256', indexed: true, internalType: 'uint256' },
      { name: 'agentAddress', type: 'address', indexed: true, internalType: 'address' },
    ],
  },
  {
    type: 'event',
    name: 'AgentPermissionedStatusSet',
    inputs: [
      { name: 'agentId', type: 'uint256', indexed: true, internalType: 'uint256' },
      { name: 'isAgentPermissioned', type: 'bool', indexed: true, internalType: 'bool' },
    ],
  },
  {
    type: 'event',
    name: 'PermissionedSenderAdded',
    inputs: [
      { name: 'agentId', type: 'uint256', indexed: true, internalType: 'uint256' },
      { name: 'sender', type: 'address', indexed: true, internalType: 'address' },
    ],
  },
  {
    type: 'event',
    name: 'PermissionedSenderRemoved',
    inputs: [
      { name: 'agentId', type: 'uint256', indexed: true, internalType: 'uint256' },
      { name: 'sender', type: 'address', indexed: true, internalType: 'address' },
    ],
  },
  {
    type: 'event',
    name: 'AllowedMarketAdded',
    inputs: [
      { name: 'agentId', type: 'uint256', indexed: true, internalType: 'uint256' },
      { name: 'market', type: 'address', indexed: true, internalType: 'address' },
    ],
  },
  {
    type: 'event',
    name: 'AllowedMarketRemoved',
    inputs: [
      { name: 'agentId', type: 'uint256', indexed: true, internalType: 'uint256' },
      { name: 'market', type: 'address', indexed: true, internalType: 'address' },
    ],
  },
  {
    type: 'event',
    name: 'RestrictedMarketAdded',
    inputs: [
      { name: 'agentId', type: 'uint256', indexed: true, internalType: 'uint256' },
      { name: 'market', type: 'address', indexed: true, internalType: 'address' },
    ],
  },
  {
    type: 'event',
    name: 'RestrictedMarketRemoved',
    inputs: [
      { name: 'agentId', type: 'uint256', indexed: true, internalType: 'uint256' },
      { name: 'market', type: 'address', indexed: true, internalType: 'address' },
    ],
  },
  {
    type: 'event',
    name: 'ExpirationPeriodSet',
    inputs: [
      { name: 'agentId', type: 'uint256', indexed: true, internalType: 'uint256' },
      { name: 'expirationPeriod', type: 'uint256', indexed: true, internalType: 'uint256' },
    ],
  },
  {
    type: 'event',
    name: 'AgentEnabledSet',
    inputs: [
      { name: 'agentId', type: 'uint256', indexed: true, internalType: 'uint256' },
      { name: 'enable', type: 'bool', indexed: true, internalType: 'bool' },
    ],
  },
  {
    type: 'event',
    name: 'MinimumDelaySet',
    inputs: [
      { name: 'agentId', type: 'uint256', indexed: true, internalType: 'uint256' },
      { name: 'minimumDelay', type: 'uint256', indexed: true, internalType: 'uint256' },
    ],
  },
  {
    type: 'event',
    name: 'AgentContextSet',
    inputs: [
      { name: 'agentId', type: 'uint256', indexed: true, internalType: 'uint256' },
      { name: 'context', type: 'bytes', indexed: true, internalType: 'bytes' },
    ],
  },
  {
    type: 'event',
    name: 'MarketsFromAgentEnabled',
    inputs: [
      { name: 'agentId', type: 'uint256', indexed: true, internalType: 'uint256' },
      { name: 'enabled', type: 'bool', indexed: true, internalType: 'bool' },
    ],
  },
  {
    type: 'event',
    name: 'UpdateInjected',
    inputs: [
      { name: 'agentId', type: 'uint256', indexed: true, internalType: 'uint256' },
      { name: 'market', type: 'address', indexed: true, internalType: 'address' },
      { name: 'updateType', type: 'string', indexed: true, internalType: 'string' },
      { name: 'updateId', type: 'uint256', indexed: false, internalType: 'uint256' },
      { name: 'newValue', type: 'bytes', indexed: false, internalType: 'bytes' },
    ],
  },
  {
    type: 'event',
    name: 'EmissionAdminUpdated',
    inputs: [
      {
        name: 'reward',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'oldAdmin',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
      {
        name: 'newAdmin',
        type: 'address',
        indexed: true,
        internalType: 'address',
      },
    ],
  },
  {
    type: 'event',
    name: 'DefaultRangeConfigSet',
    inputs: [
      { name: 'agentHub', type: 'address', indexed: true, internalType: 'address' },
      { name: 'agentId', type: 'uint256', indexed: true, internalType: 'uint256' },
      { name: 'updateType', type: 'string', indexed: true, internalType: 'string' },
      {
        name: 'config',
        type: 'tuple',
        indexed: false,
        internalType: 'struct IRangeValidationModule.RangeConfig',
        components: [
          { name: 'maxIncrease', type: 'uint120', internalType: 'uint120' },
          { name: 'maxDecrease', type: 'uint120', internalType: 'uint120' },
          { name: 'isIncreaseRelative', type: 'bool', internalType: 'bool' },
          { name: 'isDecreaseRelative', type: 'bool', internalType: 'bool' },
        ],
      },
    ],
  },
  {
    type: 'event',
    name: 'MarketRangeConfigSet',
    inputs: [
      { name: 'agentHub', type: 'address', indexed: true, internalType: 'address' },
      { name: 'agentId', type: 'uint256', indexed: true, internalType: 'uint256' },
      { name: 'market', type: 'address', indexed: true, internalType: 'address' },
      { name: 'updateType', type: 'string', indexed: false, internalType: 'string' },
      {
        name: 'config',
        type: 'tuple',
        indexed: false,
        internalType: 'struct IRangeValidationModule.RangeConfig',
        components: [
          { name: 'maxIncrease', type: 'uint120', internalType: 'uint120' },
          { name: 'maxDecrease', type: 'uint120', internalType: 'uint120' },
          { name: 'isIncreaseRelative', type: 'bool', internalType: 'bool' },
          { name: 'isDecreaseRelative', type: 'bool', internalType: 'bool' },
        ],
      },
    ],
  },
  {
    anonymous: false,
    inputs: [
      { indexed: false, internalType: 'uint8', name: 'leafType', type: 'uint8' },
      { indexed: false, internalType: 'uint32', name: 'originNetwork', type: 'uint32' },
      { indexed: false, internalType: 'address', name: 'originAddress', type: 'address' },
      { indexed: false, internalType: 'uint32', name: 'destinationNetwork', type: 'uint32' },
      { indexed: false, internalType: 'address', name: 'destinationAddress', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
      { indexed: false, internalType: 'bytes', name: 'metadata', type: 'bytes' },
      { indexed: false, internalType: 'uint32', name: 'depositCount', type: 'uint32' },
    ],
    name: 'BridgeEvent',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: false, internalType: 'uint32', name: 'index', type: 'uint32' },
      { indexed: false, internalType: 'uint32', name: 'originNetwork', type: 'uint32' },
      { indexed: false, internalType: 'address', name: 'originAddress', type: 'address' },
      { indexed: false, internalType: 'address', name: 'destinationAddress', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
    name: 'ClaimEvent',
    type: 'event',
  },
  { anonymous: false, inputs: [], name: 'EmergencyStateActivated', type: 'event' },
  { anonymous: false, inputs: [], name: 'EmergencyStateDeactivated', type: 'event' },
  {
    anonymous: false,
    inputs: [{ indexed: false, internalType: 'uint8', name: 'version', type: 'uint8' }],
    name: 'Initialized',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: false, internalType: 'uint32', name: 'originNetwork', type: 'uint32' },
      { indexed: false, internalType: 'address', name: 'originTokenAddress', type: 'address' },
      { indexed: false, internalType: 'address', name: 'wrappedTokenAddress', type: 'address' },
      { indexed: false, internalType: 'bytes', name: 'metadata', type: 'bytes' },
    ],
    name: 'NewWrappedToken',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: false, internalType: 'address', name: 'oldGuardian', type: 'address' },
      { indexed: false, internalType: 'address', name: 'newGuardian', type: 'address' },
    ],
    name: 'GuardianUpdated',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'asset', type: 'address' },
      { indexed: false, internalType: 'address', name: 'currentOracle', type: 'address' },
      { indexed: false, internalType: 'address', name: 'svrOracle', type: 'address' },
    ],
    name: 'SvrOracleConfigChanged',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: false, internalType: 'address', name: 'previousAdmin', type: 'address' },
      { indexed: false, internalType: 'address', name: 'newAdmin', type: 'address' },
    ],
    name: 'AdminChanged',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [{ indexed: true, internalType: 'address', name: 'implementation', type: 'address' }],
    name: 'Upgraded',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [{ indexed: false, internalType: 'address', name: 'sender', type: 'address' }],
    name: 'AllowListAdd',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [{ indexed: false, internalType: 'address', name: 'sender', type: 'address' }],
    name: 'AllowListRemove',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'sender', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
    name: 'Burned',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: false, internalType: 'uint64', name: 'remoteChainSelector', type: 'uint64' },
      { indexed: false, internalType: 'bytes', name: 'remoteToken', type: 'bytes' },
      {
        components: [
          { internalType: 'bool', name: 'isEnabled', type: 'bool' },
          { internalType: 'uint128', name: 'capacity', type: 'uint128' },
          { internalType: 'uint128', name: 'rate', type: 'uint128' },
        ],
        indexed: false,
        internalType: 'struct RateLimiter.Config',
        name: 'outboundRateLimiterConfig',
        type: 'tuple',
      },
      {
        components: [
          { internalType: 'bool', name: 'isEnabled', type: 'bool' },
          { internalType: 'uint128', name: 'capacity', type: 'uint128' },
          { internalType: 'uint128', name: 'rate', type: 'uint128' },
        ],
        indexed: false,
        internalType: 'struct RateLimiter.Config',
        name: 'inboundRateLimiterConfig',
        type: 'tuple',
      },
    ],
    name: 'ChainAdded',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: false, internalType: 'uint64', name: 'remoteChainSelector', type: 'uint64' },
      {
        components: [
          { internalType: 'bool', name: 'isEnabled', type: 'bool' },
          { internalType: 'uint128', name: 'capacity', type: 'uint128' },
          { internalType: 'uint128', name: 'rate', type: 'uint128' },
        ],
        indexed: false,
        internalType: 'struct RateLimiter.Config',
        name: 'outboundRateLimiterConfig',
        type: 'tuple',
      },
      {
        components: [
          { internalType: 'bool', name: 'isEnabled', type: 'bool' },
          { internalType: 'uint128', name: 'capacity', type: 'uint128' },
          { internalType: 'uint128', name: 'rate', type: 'uint128' },
        ],
        indexed: false,
        internalType: 'struct RateLimiter.Config',
        name: 'inboundRateLimiterConfig',
        type: 'tuple',
      },
    ],
    name: 'ChainConfigured',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: false, internalType: 'uint64', name: 'remoteChainSelector', type: 'uint64' },
    ],
    name: 'ChainRemoved',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      {
        components: [
          { internalType: 'bool', name: 'isEnabled', type: 'bool' },
          { internalType: 'uint128', name: 'capacity', type: 'uint128' },
          { internalType: 'uint128', name: 'rate', type: 'uint128' },
        ],
        indexed: false,
        internalType: 'struct RateLimiter.Config',
        name: 'config',
        type: 'tuple',
      },
    ],
    name: 'ConfigChanged',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'sender', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
    name: 'Locked',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'sender', type: 'address' },
      { indexed: true, internalType: 'address', name: 'recipient', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
    name: 'Minted',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'from', type: 'address' },
      { indexed: true, internalType: 'address', name: 'to', type: 'address' },
    ],
    name: 'OwnershipTransferRequested',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [{ indexed: false, internalType: 'address', name: 'rateLimitAdmin', type: 'address' }],
    name: 'RateLimitAdminSet',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'sender', type: 'address' },
      { indexed: true, internalType: 'address', name: 'recipient', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
    name: 'Released',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'uint64', name: 'remoteChainSelector', type: 'uint64' },
      { indexed: false, internalType: 'bytes', name: 'remotePoolAddress', type: 'bytes' },
    ],
    name: 'RemotePoolAdded',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'uint64', name: 'remoteChainSelector', type: 'uint64' },
      { indexed: false, internalType: 'bytes', name: 'remotePoolAddress', type: 'bytes' },
    ],
    name: 'RemotePoolRemoved',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: false, internalType: 'address', name: 'oldRouter', type: 'address' },
      { indexed: false, internalType: 'address', name: 'newRouter', type: 'address' },
    ],
    name: 'RouterUpdated',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [{ indexed: false, internalType: 'uint256', name: 'tokens', type: 'uint256' }],
    name: 'TokensConsumed',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'asset', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'emission', type: 'uint256' },
    ],
    name: 'AssetConfigUpdated',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'asset', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'index', type: 'uint256' },
    ],
    name: 'AssetIndexUpdated',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'user', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
    name: 'Cooldown',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [{ indexed: false, internalType: 'uint256', name: 'cooldownSeconds', type: 'uint256' }],
    name: 'CooldownSecondsChanged',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [{ indexed: false, internalType: 'uint256', name: 'endTimestamp', type: 'uint256' }],
    name: 'DistributionEndChanged',
    type: 'event',
  },
  { anonymous: false, inputs: [], name: 'EIP712DomainChanged', type: 'event' },
  {
    anonymous: false,
    inputs: [{ indexed: false, internalType: 'uint216', name: 'exchangeRate', type: 'uint216' }],
    name: 'ExchangeRateChanged',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [{ indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' }],
    name: 'FundsReturned',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [{ indexed: false, internalType: 'uint64', name: 'version', type: 'uint64' }],
    name: 'Initialized',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [{ indexed: false, internalType: 'uint256', name: 'newPercentage', type: 'uint256' }],
    name: 'MaxSlashablePercentageChanged',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'newPendingAdmin', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'role', type: 'uint256' },
    ],
    name: 'PendingAdminChanged',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'from', type: 'address' },
      { indexed: true, internalType: 'address', name: 'to', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'assets', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'shares', type: 'uint256' },
    ],
    name: 'Redeem',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: false, internalType: 'address', name: 'user', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
    name: 'RewardsAccrued',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'from', type: 'address' },
      { indexed: true, internalType: 'address', name: 'to', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
    name: 'RewardsClaimed',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'newAdmin', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'role', type: 'uint256' },
    ],
    name: 'RoleClaimed',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'destination', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
    name: 'Slashed',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [{ indexed: false, internalType: 'uint256', name: 'windowSeconds', type: 'uint256' }],
    name: 'SlashingExitWindowDurationChanged',
    type: 'event',
  },
  { anonymous: false, inputs: [], name: 'SlashingSettled', type: 'event' },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'from', type: 'address' },
      { indexed: true, internalType: 'address', name: 'to', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'assets', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'shares', type: 'uint256' },
    ],
    name: 'Staked',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'user', type: 'address' },
      { indexed: true, internalType: 'address', name: 'asset', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'index', type: 'uint256' },
    ],
    name: 'UserIndexUpdated',
    type: 'event',
  },
  {
    constant: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'token', type: 'address' },
      { indexed: true, internalType: 'address', name: 'currentAdmin', type: 'address' },
      { indexed: true, internalType: 'address', name: 'newAdmin', type: 'address' },
    ],
    name: 'AdministratorTransferRequested',
    payable: false,
    type: 'event',
  },
  {
    constant: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'token', type: 'address' },
      { indexed: true, internalType: 'address', name: 'newAdmin', type: 'address' },
    ],
    name: 'AdministratorTransferred',
    payable: false,
    type: 'event',
  },
  {
    constant: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'token', type: 'address' },
      { indexed: true, internalType: 'address', name: 'previousPool', type: 'address' },
      { indexed: true, internalType: 'address', name: 'newPool', type: 'address' },
    ],
    name: 'PoolSet',
    payable: false,
    type: 'event',
  },
  {
    constant: false,
    inputs: [{ indexed: false, internalType: 'address', name: 'module', type: 'address' }],
    name: 'RegistryModuleAdded',
    payable: false,
    type: 'event',
  },
  {
    constant: false,
    inputs: [{ indexed: true, internalType: 'address', name: 'module', type: 'address' }],
    name: 'RegistryModuleRemoved',
    payable: false,
    type: 'event',
  },
  {
    constant: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'facilitatorAddress', type: 'address' },
      { indexed: true, internalType: 'bytes32', name: 'label', type: 'bytes32' },
      { indexed: false, internalType: 'uint256', name: 'bucketCapacity', type: 'uint256' },
    ],
    name: 'FacilitatorAdded',
    payable: false,
    type: 'event',
  },
  {
    constant: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'facilitatorAddress', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'oldCapacity', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'newCapacity', type: 'uint256' },
    ],
    name: 'FacilitatorBucketCapacityUpdated',
    payable: false,
    type: 'event',
  },
  {
    constant: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'facilitatorAddress', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'oldLevel', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'newLevel', type: 'uint256' },
    ],
    name: 'FacilitatorBucketLevelUpdated',
    payable: false,
    type: 'event',
  },
  {
    constant: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'facilitatorAddress', type: 'address' },
    ],
    name: 'FacilitatorRemoved',
    payable: false,
    type: 'event',
  },
  {
    constant: false,
    inputs: [
      { indexed: true, internalType: 'bytes32', name: 'role', type: 'bytes32' },
      { indexed: true, internalType: 'bytes32', name: 'previousAdminRole', type: 'bytes32' },
      { indexed: true, internalType: 'bytes32', name: 'newAdminRole', type: 'bytes32' },
    ],
    name: 'RoleAdminChanged',
    payable: false,
    type: 'event',
  },
  {
    constant: false,
    inputs: [
      { indexed: true, internalType: 'bytes32', name: 'role', type: 'bytes32' },
      { indexed: true, internalType: 'address', name: 'account', type: 'address' },
      { indexed: true, internalType: 'address', name: 'sender', type: 'address' },
    ],
    name: 'RoleRevoked',
    payable: false,
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'from', type: 'address' },
      { indexed: true, internalType: 'address', name: 'target', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'value', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'balanceIncrease', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'index', type: 'uint256' },
    ],
    name: 'Burn',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'reserve', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'newDeficitOffset', type: 'uint256' },
    ],
    name: 'DeficitOffsetChanged',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'reserve', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
    name: 'DeficitOffsetCovered',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'caller', type: 'address' },
      { indexed: true, internalType: 'address', name: 'token', type: 'address' },
      { indexed: true, internalType: 'address', name: 'to', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
    name: 'ERC20Rescued',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'caller', type: 'address' },
      { indexed: true, internalType: 'address', name: 'to', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
    name: 'NativeTokensRescued',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'reserve', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'newPendingDeficit', type: 'uint256' },
    ],
    name: 'PendingDeficitChanged',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'reserve', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
    name: 'PendingDeficitCovered',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'reserve', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
    name: 'ReserveDeficitCovered',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'reserve', type: 'address' },
      { indexed: true, internalType: 'address', name: 'umbrellaStake', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'liquidationFee', type: 'uint256' },
      {
        indexed: false,
        internalType: 'address',
        name: 'umbrellaStakeUnderlyingOracle',
        type: 'address',
      },
    ],
    name: 'SlashingConfigurationChanged',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'reserve', type: 'address' },
      { indexed: true, internalType: 'address', name: 'umbrellaStake', type: 'address' },
    ],
    name: 'SlashingConfigurationRemoved',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'reserve', type: 'address' },
      { indexed: true, internalType: 'address', name: 'umbrellaStake', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'fee', type: 'uint256' },
    ],
    name: 'StakeTokenSlashed',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'umbrellaStake', type: 'address' },
      { indexed: true, internalType: 'address', name: 'underlying', type: 'address' },
      { indexed: false, internalType: 'string', name: 'name', type: 'string' },
      { indexed: false, internalType: 'string', name: 'symbol', type: 'string' },
    ],
    name: 'UmbrellaStakeTokenCreated',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'reserve', type: 'address' },
      { indexed: false, internalType: 'address', name: 'user', type: 'address' },
      { indexed: true, internalType: 'address', name: 'onBehalfOf', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
      {
        indexed: false,
        internalType: 'enum DataTypes.InterestRateMode',
        name: 'interestRateMode',
        type: 'uint8',
      },
      { indexed: false, internalType: 'uint256', name: 'borrowRate', type: 'uint256' },
      { indexed: true, internalType: 'uint16', name: 'referralCode', type: 'uint16' },
    ],
    name: 'Borrow',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'reserve', type: 'address' },
      { indexed: false, internalType: 'address', name: 'caller', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amountCovered', type: 'uint256' },
    ],
    name: 'DeficitCovered',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'user', type: 'address' },
      { indexed: true, internalType: 'address', name: 'debtAsset', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amountCreated', type: 'uint256' },
    ],
    name: 'DeficitCreated',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'target', type: 'address' },
      { indexed: false, internalType: 'address', name: 'initiator', type: 'address' },
      { indexed: true, internalType: 'address', name: 'asset', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
      {
        indexed: false,
        internalType: 'enum DataTypes.InterestRateMode',
        name: 'interestRateMode',
        type: 'uint8',
      },
      { indexed: false, internalType: 'uint256', name: 'premium', type: 'uint256' },
      { indexed: true, internalType: 'uint16', name: 'referralCode', type: 'uint16' },
    ],
    name: 'FlashLoan',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'asset', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'totalDebt', type: 'uint256' },
    ],
    name: 'IsolationModeTotalDebtUpdated',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'collateralAsset', type: 'address' },
      { indexed: true, internalType: 'address', name: 'debtAsset', type: 'address' },
      { indexed: true, internalType: 'address', name: 'user', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'debtToCover', type: 'uint256' },
      {
        indexed: false,
        internalType: 'uint256',
        name: 'liquidatedCollateralAmount',
        type: 'uint256',
      },
      { indexed: false, internalType: 'address', name: 'liquidator', type: 'address' },
      { indexed: false, internalType: 'bool', name: 'receiveAToken', type: 'bool' },
    ],
    name: 'LiquidationCall',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'reserve', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amountMinted', type: 'uint256' },
    ],
    name: 'MintedToTreasury',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'user', type: 'address' },
      { indexed: true, internalType: 'address', name: 'positionManager', type: 'address' },
    ],
    name: 'PositionManagerApproved',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'user', type: 'address' },
      { indexed: true, internalType: 'address', name: 'positionManager', type: 'address' },
    ],
    name: 'PositionManagerRevoked',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'reserve', type: 'address' },
      { indexed: true, internalType: 'address', name: 'user', type: 'address' },
      { indexed: true, internalType: 'address', name: 'repayer', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
      { indexed: false, internalType: 'bool', name: 'useATokens', type: 'bool' },
    ],
    name: 'Repay',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'reserve', type: 'address' },
      { indexed: true, internalType: 'address', name: 'user', type: 'address' },
    ],
    name: 'ReserveUsedAsCollateralDisabled',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'reserve', type: 'address' },
      { indexed: true, internalType: 'address', name: 'user', type: 'address' },
    ],
    name: 'ReserveUsedAsCollateralEnabled',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'user', type: 'address' },
      { indexed: false, internalType: 'uint8', name: 'categoryId', type: 'uint8' },
    ],
    name: 'UserEModeSet',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'reserve', type: 'address' },
      { indexed: true, internalType: 'address', name: 'user', type: 'address' },
      { indexed: true, internalType: 'address', name: 'to', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
    name: 'Withdraw',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'caller', type: 'address' },
      { indexed: true, internalType: 'address', name: 'token', type: 'address' },
      { indexed: true, internalType: 'address', name: 'to', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
    name: 'ERC20Rescued',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: false, internalType: 'address', name: 'oldAddress', type: 'address' },
      { indexed: false, internalType: 'address', name: 'newAddress', type: 'address' },
    ],
    name: 'LimitOrderPriceCheckerUpdated',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'fromToken', type: 'address' },
      { indexed: true, internalType: 'address', name: 'toToken', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'minAmountOut', type: 'uint256' },
    ],
    name: 'LimitSwapRequested',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: false, internalType: 'address', name: 'oldAddress', type: 'address' },
      { indexed: false, internalType: 'address', name: 'newAddress', type: 'address' },
    ],
    name: 'MilkmanAddressUpdated',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'caller', type: 'address' },
      { indexed: true, internalType: 'address', name: 'to', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
    name: 'NativeTokensRescued',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: false, internalType: 'address', name: 'oldAddress', type: 'address' },
      { indexed: false, internalType: 'address', name: 'newAddress', type: 'address' },
    ],
    name: 'PriceCheckerUpdated',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: false, internalType: 'address', name: 'oldAddress', type: 'address' },
      { indexed: false, internalType: 'address', name: 'newAddress', type: 'address' },
    ],
    name: 'RelayerAddressUpdated',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'fromToken', type: 'address' },
      { indexed: true, internalType: 'address', name: 'toToken', type: 'address' },
      { indexed: false, internalType: 'bool', name: 'allowed', type: 'bool' },
    ],
    name: 'SetSwappablePair',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'token', type: 'address' },
      { indexed: true, internalType: 'address', name: 'oracle', type: 'address' },
    ],
    name: 'SetTokenOracle',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'fromToken', type: 'address' },
      { indexed: true, internalType: 'address', name: 'toToken', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
    name: 'SwapCanceled',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'fromToken', type: 'address' },
      { indexed: true, internalType: 'address', name: 'toToken', type: 'address' },
      { indexed: false, internalType: 'address', name: 'fromOracle', type: 'address' },
      { indexed: false, internalType: 'address', name: 'toOracle', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'slippage', type: 'uint256' },
    ],
    name: 'SwapRequested',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'fromToken', type: 'address' },
      { indexed: true, internalType: 'address', name: 'toToken', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'totalAmount', type: 'uint256' },
    ],
    name: 'TWAPSwapCanceled',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'fromToken', type: 'address' },
      { indexed: true, internalType: 'address', name: 'toToken', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'totalAmount', type: 'uint256' },
    ],
    name: 'TWAPSwapRequested',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'token', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'budget', type: 'uint256' },
    ],
    name: 'UpdatedTokenBudget',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: false, internalType: 'address', name: 'token', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
    name: 'Bridge',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: false, internalType: 'bytes', name: 'proof', type: 'bytes' },
    ],
    name: 'Exit',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [],
    name: 'FailedToSendETH',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: false, internalType: 'address', name: 'token', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
    name: 'WithdrawToCollector',
    type: 'event',
  },
  // ============================================================
  // Aave V4 — Hub events (IHubBase)
  // ============================================================
  {
    type: 'event',
    name: 'Add',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'assetId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'spoke', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'shares', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    name: 'Remove',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'assetId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'spoke', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'shares', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    name: 'Draw',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'assetId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'spoke', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'drawnShares', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'drawnAmount', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    name: 'Restore',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'assetId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'spoke', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'drawnShares', type: 'uint256' },
      {
        indexed: false,
        internalType: 'struct IHubBase.PremiumDelta',
        name: 'premiumDelta',
        type: 'tuple',
        components: [
          { internalType: 'int256', name: 'sharesDelta', type: 'int256' },
          { internalType: 'int256', name: 'offsetRayDelta', type: 'int256' },
          { internalType: 'uint256', name: 'restoredPremiumRay', type: 'uint256' },
        ],
      },
      { indexed: false, internalType: 'uint256', name: 'drawnAmount', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'premiumAmount', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    name: 'RefreshPremium',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'assetId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'spoke', type: 'address' },
      {
        indexed: false,
        internalType: 'struct IHubBase.PremiumDelta',
        name: 'premiumDelta',
        type: 'tuple',
        components: [
          { internalType: 'int256', name: 'sharesDelta', type: 'int256' },
          { internalType: 'int256', name: 'offsetRayDelta', type: 'int256' },
          { internalType: 'uint256', name: 'restoredPremiumRay', type: 'uint256' },
        ],
      },
    ],
  },
  {
    type: 'event',
    name: 'ReportDeficit',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'assetId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'spoke', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'drawnShares', type: 'uint256' },
      {
        indexed: false,
        internalType: 'struct IHubBase.PremiumDelta',
        name: 'premiumDelta',
        type: 'tuple',
        components: [
          { internalType: 'int256', name: 'sharesDelta', type: 'int256' },
          { internalType: 'int256', name: 'offsetRayDelta', type: 'int256' },
          { internalType: 'uint256', name: 'restoredPremiumRay', type: 'uint256' },
        ],
      },
      { indexed: false, internalType: 'uint256', name: 'deficitAmountRay', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    name: 'TransferShares',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'assetId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'sender', type: 'address' },
      { indexed: true, internalType: 'address', name: 'receiver', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'shares', type: 'uint256' },
    ],
  },
  // ============================================================
  // Aave V4 — Hub events (IHub)
  // ============================================================
  {
    type: 'event',
    name: 'AddAsset',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'assetId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'underlying', type: 'address' },
      { indexed: false, internalType: 'uint8', name: 'decimals', type: 'uint8' },
    ],
  },
  {
    type: 'event',
    name: 'UpdateAsset',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'assetId', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'drawnIndex', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'drawnRate', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'accruedFees', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    name: 'UpdateAssetConfig',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'assetId', type: 'uint256' },
      {
        indexed: false,
        internalType: 'struct IHub.AssetConfig',
        name: 'config',
        type: 'tuple',
        components: [
          { internalType: 'address', name: 'feeReceiver', type: 'address' },
          { internalType: 'uint16', name: 'liquidityFee', type: 'uint16' },
          { internalType: 'address', name: 'irStrategy', type: 'address' },
          { internalType: 'address', name: 'reinvestmentController', type: 'address' },
        ],
      },
    ],
  },
  {
    type: 'event',
    name: 'AddSpoke',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'assetId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'spoke', type: 'address' },
    ],
  },
  {
    type: 'event',
    name: 'UpdateSpokeConfig',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'assetId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'spoke', type: 'address' },
      {
        indexed: false,
        internalType: 'struct IHub.SpokeConfig',
        name: 'config',
        type: 'tuple',
        components: [
          { internalType: 'uint40', name: 'addCap', type: 'uint40' },
          { internalType: 'uint40', name: 'drawCap', type: 'uint40' },
          { internalType: 'uint24', name: 'riskPremiumThreshold', type: 'uint24' },
          { internalType: 'bool', name: 'active', type: 'bool' },
          { internalType: 'bool', name: 'halted', type: 'bool' },
        ],
      },
    ],
  },
  {
    type: 'event',
    name: 'MintFeeShares',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'assetId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'feeReceiver', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'shares', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'assets', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    name: 'Sweep',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'assetId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'reinvestmentController', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    name: 'Reclaim',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'assetId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'reinvestmentController', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    name: 'EliminateDeficit',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'assetId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'callerSpoke', type: 'address' },
      { indexed: true, internalType: 'address', name: 'coveredSpoke', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'shares', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'deficitAmountRay', type: 'uint256' },
    ],
  },
  // ============================================================
  // Aave V4 — Hub events (IAssetInterestRateStrategy)
  // ============================================================
  {
    type: 'event',
    name: 'UpdateInterestRateData',
    inputs: [
      { indexed: true, internalType: 'address', name: 'hub', type: 'address' },
      { indexed: true, internalType: 'uint256', name: 'assetId', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'optimalUsageRatio', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'baseDrawnRate', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'rateGrowthBeforeOptimal', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'rateGrowthAfterOptimal', type: 'uint256' },
    ],
  },
  // ============================================================
  // Aave V4 — Spoke events (ISpoke)
  // ============================================================
  {
    type: 'event',
    name: 'SetSpokeImmutables',
    inputs: [
      { indexed: true, internalType: 'address', name: 'oracle', type: 'address' },
      { indexed: false, internalType: 'uint16', name: 'maxUserReservesLimit', type: 'uint16' },
    ],
  },
  {
    type: 'event',
    name: 'UpdateLiquidationConfig',
    inputs: [
      {
        indexed: false,
        internalType: 'struct ISpoke.LiquidationConfig',
        name: 'config',
        type: 'tuple',
        components: [
          { internalType: 'uint128', name: 'targetHealthFactor', type: 'uint128' },
          { internalType: 'uint64', name: 'healthFactorForMaxBonus', type: 'uint64' },
          { internalType: 'uint16', name: 'liquidationBonusFactor', type: 'uint16' },
        ],
      },
    ],
  },
  {
    type: 'event',
    name: 'AddReserve',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'reserveId', type: 'uint256' },
      { indexed: true, internalType: 'uint256', name: 'assetId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'hub', type: 'address' },
    ],
  },
  {
    type: 'event',
    name: 'UpdateReserveConfig',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'reserveId', type: 'uint256' },
      {
        indexed: false,
        internalType: 'struct ISpoke.ReserveConfig',
        name: 'config',
        type: 'tuple',
        components: [
          { internalType: 'uint24', name: 'collateralRisk', type: 'uint24' },
          { internalType: 'bool', name: 'paused', type: 'bool' },
          { internalType: 'bool', name: 'frozen', type: 'bool' },
          { internalType: 'bool', name: 'borrowable', type: 'bool' },
          { internalType: 'bool', name: 'receiveSharesEnabled', type: 'bool' },
        ],
      },
    ],
  },
  {
    type: 'event',
    name: 'UpdateReservePriceSource',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'reserveId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'priceSource', type: 'address' },
    ],
  },
  {
    type: 'event',
    name: 'AddDynamicReserveConfig',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'reserveId', type: 'uint256' },
      { indexed: true, internalType: 'uint32', name: 'dynamicConfigKey', type: 'uint32' },
      {
        indexed: false,
        internalType: 'struct ISpoke.DynamicReserveConfig',
        name: 'config',
        type: 'tuple',
        components: [
          { internalType: 'uint16', name: 'collateralFactor', type: 'uint16' },
          { internalType: 'uint32', name: 'maxLiquidationBonus', type: 'uint32' },
          { internalType: 'uint16', name: 'liquidationFee', type: 'uint16' },
        ],
      },
    ],
  },
  {
    type: 'event',
    name: 'UpdateDynamicReserveConfig',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'reserveId', type: 'uint256' },
      { indexed: true, internalType: 'uint32', name: 'dynamicConfigKey', type: 'uint32' },
      {
        indexed: false,
        internalType: 'struct ISpoke.DynamicReserveConfig',
        name: 'config',
        type: 'tuple',
        components: [
          { internalType: 'uint16', name: 'collateralFactor', type: 'uint16' },
          { internalType: 'uint32', name: 'maxLiquidationBonus', type: 'uint32' },
          { internalType: 'uint16', name: 'liquidationFee', type: 'uint16' },
        ],
      },
    ],
  },
  {
    type: 'event',
    name: 'UpdatePositionManager',
    inputs: [
      { indexed: true, internalType: 'address', name: 'positionManager', type: 'address' },
      { indexed: false, internalType: 'bool', name: 'active', type: 'bool' },
    ],
  },
  {
    type: 'event',
    name: 'Supply',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'reserveId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'caller', type: 'address' },
      { indexed: true, internalType: 'address', name: 'user', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'suppliedShares', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'suppliedAmount', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    name: 'Withdraw',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'reserveId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'caller', type: 'address' },
      { indexed: true, internalType: 'address', name: 'user', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'withdrawnShares', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'withdrawnAmount', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    name: 'Borrow',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'reserveId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'caller', type: 'address' },
      { indexed: true, internalType: 'address', name: 'user', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'drawnShares', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'drawnAmount', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    name: 'Repay',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'reserveId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'caller', type: 'address' },
      { indexed: true, internalType: 'address', name: 'user', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'drawnShares', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'totalAmountRepaid', type: 'uint256' },
      {
        indexed: false,
        internalType: 'struct IHubBase.PremiumDelta',
        name: 'premiumDelta',
        type: 'tuple',
        components: [
          { internalType: 'int256', name: 'sharesDelta', type: 'int256' },
          { internalType: 'int256', name: 'offsetRayDelta', type: 'int256' },
          { internalType: 'uint256', name: 'restoredPremiumRay', type: 'uint256' },
        ],
      },
    ],
  },
  {
    type: 'event',
    name: 'LiquidationCall',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'collateralReserveId', type: 'uint256' },
      { indexed: true, internalType: 'uint256', name: 'debtReserveId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'user', type: 'address' },
      { indexed: false, internalType: 'address', name: 'liquidator', type: 'address' },
      { indexed: false, internalType: 'bool', name: 'receiveShares', type: 'bool' },
      { indexed: false, internalType: 'uint256', name: 'debtAmountRestored', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'drawnSharesLiquidated', type: 'uint256' },
      {
        indexed: false,
        internalType: 'struct IHubBase.PremiumDelta',
        name: 'premiumDelta',
        type: 'tuple',
        components: [
          { internalType: 'int256', name: 'sharesDelta', type: 'int256' },
          { internalType: 'int256', name: 'offsetRayDelta', type: 'int256' },
          { internalType: 'uint256', name: 'restoredPremiumRay', type: 'uint256' },
        ],
      },
      { indexed: false, internalType: 'uint256', name: 'collateralAmountRemoved', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'collateralSharesLiquidated', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'collateralSharesToLiquidator', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    name: 'SetUsingAsCollateral',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'reserveId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'caller', type: 'address' },
      { indexed: true, internalType: 'address', name: 'user', type: 'address' },
      { indexed: false, internalType: 'bool', name: 'usingAsCollateral', type: 'bool' },
    ],
  },
  {
    type: 'event',
    name: 'UpdateUserRiskPremium',
    inputs: [
      { indexed: true, internalType: 'address', name: 'user', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'riskPremium', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    name: 'RefreshAllUserDynamicConfig',
    inputs: [
      { indexed: true, internalType: 'address', name: 'user', type: 'address' },
    ],
  },
  {
    type: 'event',
    name: 'RefreshSingleUserDynamicConfig',
    inputs: [
      { indexed: true, internalType: 'address', name: 'user', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'reserveId', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    name: 'SetUserPositionManager',
    inputs: [
      { indexed: true, internalType: 'address', name: 'user', type: 'address' },
      { indexed: true, internalType: 'address', name: 'positionManager', type: 'address' },
      { indexed: false, internalType: 'bool', name: 'approve', type: 'bool' },
    ],
  },
  {
    type: 'event',
    name: 'RefreshPremiumDebt',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'reserveId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'user', type: 'address' },
      {
        indexed: false,
        internalType: 'struct IHubBase.PremiumDelta',
        name: 'premiumDelta',
        type: 'tuple',
        components: [
          { internalType: 'int256', name: 'sharesDelta', type: 'int256' },
          { internalType: 'int256', name: 'offsetRayDelta', type: 'int256' },
          { internalType: 'uint256', name: 'restoredPremiumRay', type: 'uint256' },
        ],
      },
    ],
  },
  // ============================================================
  // Aave V4 — Spoke events (IAaveOracle)
  // ============================================================
  {
    type: 'event',
    name: 'UpdateReserveSource',
    inputs: [
      { indexed: true, internalType: 'uint256', name: 'reserveId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'source', type: 'address' },
    ],
  },
  {
    type: 'event',
    name: 'SetSpoke',
    inputs: [
      { indexed: true, internalType: 'address', name: 'spoke', type: 'address' },
    ],
  },
  // ============================================================
  // Aave V4 — Spoke events (ITokenizationSpoke)
  // ============================================================
  {
    type: 'event',
    name: 'SetTokenizationSpokeImmutables',
    inputs: [
      { indexed: true, internalType: 'address', name: 'hub', type: 'address' },
      { indexed: true, internalType: 'uint256', name: 'assetId', type: 'uint256' },
    ],
  },
  // ============================================================
  // Aave V4 — Position Manager events (IPositionManagerBase)
  // ============================================================
  {
    type: 'event',
    name: 'RegisterSpoke',
    inputs: [
      { indexed: true, internalType: 'address', name: 'spoke', type: 'address' },
      { indexed: false, internalType: 'bool', name: 'registered', type: 'bool' },
    ],
  },
  // ============================================================
  // Aave V4 — Position Manager events (IConfigPositionManager)
  // ============================================================
  {
    type: 'event',
    name: 'UpdateConfigPermissions',
    inputs: [
      { indexed: true, internalType: 'address', name: 'spoke', type: 'address' },
      { indexed: true, internalType: 'address', name: 'delegator', type: 'address' },
      { indexed: true, internalType: 'address', name: 'delegatee', type: 'address' },
      { indexed: false, internalType: 'uint8', name: 'oldPermissions', type: 'uint8' },
      { indexed: false, internalType: 'uint8', name: 'newPermissions', type: 'uint8' },
    ],
  },
  {
    type: 'event',
    name: 'SetUsingAsCollateralOnBehalfOf',
    inputs: [
      { indexed: true, internalType: 'address', name: 'spoke', type: 'address' },
      { indexed: true, internalType: 'address', name: 'caller', type: 'address' },
      { indexed: true, internalType: 'address', name: 'onBehalfOf', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'reserveId', type: 'uint256' },
      { indexed: false, internalType: 'bool', name: 'usingAsCollateral', type: 'bool' },
    ],
  },
  {
    type: 'event',
    name: 'UpdateUserRiskPremiumOnBehalfOf',
    inputs: [
      { indexed: true, internalType: 'address', name: 'spoke', type: 'address' },
      { indexed: true, internalType: 'address', name: 'caller', type: 'address' },
      { indexed: true, internalType: 'address', name: 'onBehalfOf', type: 'address' },
    ],
  },
  {
    type: 'event',
    name: 'UpdateUserDynamicConfigOnBehalfOf',
    inputs: [
      { indexed: true, internalType: 'address', name: 'spoke', type: 'address' },
      { indexed: true, internalType: 'address', name: 'caller', type: 'address' },
      { indexed: true, internalType: 'address', name: 'onBehalfOf', type: 'address' },
    ],
  },
  // ============================================================
  // Aave V4 — Position Manager events (IGiverPositionManager)
  // ============================================================
  {
    type: 'event',
    name: 'SupplyOnBehalfOf',
    inputs: [
      { indexed: true, internalType: 'address', name: 'spoke', type: 'address' },
      { indexed: true, internalType: 'address', name: 'caller', type: 'address' },
      { indexed: true, internalType: 'address', name: 'onBehalfOf', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'reserveId', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'suppliedShares', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'suppliedAmount', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    name: 'RepayOnBehalfOf',
    inputs: [
      { indexed: true, internalType: 'address', name: 'spoke', type: 'address' },
      { indexed: true, internalType: 'address', name: 'caller', type: 'address' },
      { indexed: true, internalType: 'address', name: 'onBehalfOf', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'reserveId', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'repaidShares', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'repaidAmount', type: 'uint256' },
    ],
  },
  // ============================================================
  // Aave V4 — Position Manager events (ITakerPositionManager)
  // ============================================================
  {
    type: 'event',
    name: 'WithdrawApproval',
    inputs: [
      { indexed: true, internalType: 'address', name: 'spoke', type: 'address' },
      { indexed: true, internalType: 'uint256', name: 'reserveId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'owner', type: 'address' },
      { indexed: false, internalType: 'address', name: 'spender', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    name: 'BorrowApproval',
    inputs: [
      { indexed: true, internalType: 'address', name: 'spoke', type: 'address' },
      { indexed: true, internalType: 'uint256', name: 'reserveId', type: 'uint256' },
      { indexed: true, internalType: 'address', name: 'owner', type: 'address' },
      { indexed: false, internalType: 'address', name: 'spender', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    name: 'WithdrawOnBehalfOf',
    inputs: [
      { indexed: true, internalType: 'address', name: 'spoke', type: 'address' },
      { indexed: true, internalType: 'address', name: 'caller', type: 'address' },
      { indexed: true, internalType: 'address', name: 'onBehalfOf', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'reserveId', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'withdrawnShares', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'withdrawnAmount', type: 'uint256' },
    ],
  },
  {
    type: 'event',
    name: 'BorrowOnBehalfOf',
    inputs: [
      { indexed: true, internalType: 'address', name: 'spoke', type: 'address' },
      { indexed: true, internalType: 'address', name: 'caller', type: 'address' },
      { indexed: true, internalType: 'address', name: 'onBehalfOf', type: 'address' },
      { indexed: false, internalType: 'uint256', name: 'reserveId', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'drawnShares', type: 'uint256' },
      { indexed: false, internalType: 'uint256', name: 'drawnAmount', type: 'uint256' },
    ],
  },
];
