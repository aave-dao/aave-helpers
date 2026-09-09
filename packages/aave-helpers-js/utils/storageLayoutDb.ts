import type { Hex } from 'viem';
import type { LayoutEntry } from './storageLayoutTypes';

// Storage layouts for known contract kinds. Grown via:
//   npx tsx scripts/add-storage-layout.ts --kind <Kind> (--root <path> | --repo <org/repo> | --chainId <id> --address <0x..>) --contract <src/File.sol:Name>
// Each entry lives in utils/storage-layouts/<Kind>.ts and is generated — do not edit by hand.

// <auto-imports>
import { CrossChainController } from './storage-layouts/CrossChainController';
import { Governance } from './storage-layouts/Governance';
import { PayloadsController } from './storage-layouts/PayloadsController';
import { AccessManagerEnumerable } from './storage-layouts/AccessManagerEnumerable';
import { SpokeInstance } from './storage-layouts/SpokeInstance';
import { HubInstance } from './storage-layouts/HubInstance';
import { RewardsController } from './storage-layouts/RewardsController';
import { AaveOracle } from './storage-layouts/AaveOracle';
import { ACLManager } from './storage-layouts/ACLManager';
import { PoolAddressesProvider } from './storage-layouts/PoolAddressesProvider';
import { VariableDebtTokenInstance } from './storage-layouts/VariableDebtTokenInstance';
import { ATokenInstance } from './storage-layouts/ATokenInstance';
import { PoolConfiguratorInstance } from './storage-layouts/PoolConfiguratorInstance';
import { PoolInstance } from './storage-layouts/PoolInstance';
// </auto-imports>

export const storageLayoutDb: Record<string, LayoutEntry> = {
  // <auto-entries>
  CrossChainController,
  Governance,
  PayloadsController,
  AccessManagerEnumerable,
  SpokeInstance,
  HubInstance,
  RewardsController,
  AaveOracle,
  ACLManager,
  PoolAddressesProvider,
  VariableDebtTokenInstance,
  ATokenInstance,
  PoolConfiguratorInstance,
  PoolInstance,
  // </auto-entries>
};

/**
 * Addresses the address book does not know, pinned to a contract kind by
 * scripts/add-storage-layout.ts --pin. Key format: `${chainId}:${lowercase address}`.
 */
export const pinnedAddresses: Record<string, string> = {
  // <auto-pins>
  // </auto-pins>
};

/**
 * Layout-independent slots that decode the same way on every contract.
 */
export const wellKnownSlots: Record<Hex, { label: string; type: string }> = {
  // ERC-1967
  '0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc': {
    label: 'implementation (ERC-1967)',
    type: 'address',
  },
  '0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103': {
    label: 'admin (ERC-1967)',
    type: 'address',
  },
  '0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50': {
    label: 'beacon (ERC-1967)',
    type: 'address',
  },
  // keccak256('INCENTIVES_CONTROLLER') - 1, used by aave incentivized erc20s
  '0x703c2c8634bed68d98c029c18f310e7f7ec0e5d6342c590190b3cb8b3ba54532': {
    label: 'incentivesController',
    type: 'address',
  },
};

/**
 * Human readable names for enum values, keyed by the solidity type label as it
 * appears in storage layouts (`types[t].label`).
 */
export const enumRegistry: Record<string, Record<number, string>> = {
  'enum IPayloadsControllerCore.PayloadState': {
    0: 'None',
    1: 'Created',
    2: 'Queued',
    3: 'Executed',
    4: 'Cancelled',
    5: 'Expired',
  },
  'enum PayloadsControllerUtils.AccessControl': {
    0: 'Level_null',
    1: 'Level_1',
    2: 'Level_2',
  },
};
