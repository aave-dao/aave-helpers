import type { Hex } from 'viem';
import type { LayoutEntry } from './storageLayoutTypes';

// Storage layouts for known contract kinds. Grown via:
//   npx tsx scripts/add-storage-layout.ts --kind <Kind> (--root <path> | --repo <org/repo> | --chainId <id> --address <0x..>) --contract <src/File.sol:Name>
// Each entry lives in utils/storage-layouts/<Kind>.ts and is generated — do not edit by hand.

// <auto-imports>
import { PermissionedPayloadsController } from './storage-layouts/PermissionedPayloadsController';
import { V3RiskStewardFlatConfig } from './storage-layouts/V3RiskStewardFlatConfig';
import { V3RiskStewardDebtCeiling } from './storage-layouts/V3RiskStewardDebtCeiling';
import { V3RiskSteward } from './storage-layouts/V3RiskSteward';
import { V4RiskSteward } from './storage-layouts/V4RiskSteward';
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
  PermissionedPayloadsController,
  V3RiskStewardFlatConfig,
  V3RiskStewardDebtCeiling,
  V3RiskSteward,
  V4RiskSteward,
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
  '43114:0xd8d7abc42c1c938bdec94ff8da1b3cd5b7e3b107': 'V4RiskSteward',
  '8453:0x577dd4c67d4c7278cdf3bc03ae9a391c4c72db4f': 'V4RiskSteward',
  '1:0x6f48d9cdb8ee6e17c96b2d8aec128af426a295c1': 'V4RiskSteward',
  '1:0x81afd0f99c2afa2f2dd7e387c2ef9cd2a29b6e1a': 'V3RiskStewardFlatConfig',
  '42161:0x085e34722e04567df9e6d2c32e82fd74f3342e79': 'V3RiskStewardFlatConfig',
  '8453:0xb892202d9ce2c16c565a492a5168689b215eb269': 'V3RiskStewardFlatConfig',
  '43114:0x57218f3ab422a39115951c3eb06881a7a719dfdd': 'V3RiskStewardFlatConfig',
  '9745:0xe1472037c9f17ac00bf5336272ab74e423b9254d': 'V3RiskStewardDebtCeiling',
  '9745:0x530034d1a739afd261291b86a5c3b95ec30c4b44': 'V3RiskStewardDebtCeiling',
  '59144:0xdde20b20e21a6f3b7080e740b684cdf5b764b80d': 'V3RiskStewardDebtCeiling',
  '10:0x14a6801dbebbd6cbe009c10ecfda98c1c7b89012': 'V3RiskStewardDebtCeiling',
  '56:0x655252250f4a453854040a49e8280951a76f3033': 'V3RiskStewardDebtCeiling',
  '100:0x655252250f4a453854040a49e8280951a76f3033': 'V3RiskStewardDebtCeiling',
  '1088:0x97cb9e81d480a2ab03299760654c1ddc0c16be07': 'V3RiskStewardDebtCeiling',
  '137:0x35b09a414f6003346ca2e2553b3ea91cd3524af3': 'V3RiskStewardDebtCeiling',
  '1:0x80cfd14236409107c220d1d0a3de845b48fdcdfc': 'V3RiskStewardDebtCeiling',
  '1:0xf721be7aa57a987f3e4d05dac6fcb5abf9f7ce9a': 'V3RiskStewardDebtCeiling',
  '1:0x9f76954f5b55b4908d178f31c07f9537ac8328e7': 'V3RiskStewardDebtCeiling',
  '143:0x98217a06721ebf727f2c8d9ad7718ec28b7aae34': 'V3RiskSteward',
  '4326:0xb5a1fe36dcf5ba149cb8d90a03f4709141ee5442': 'V3RiskSteward',
  '9745:0xdde20b20e21a6f3b7080e740b684cdf5b764b80d': 'V3RiskSteward',
  '146:0xb9898c9f4711cbcad882863302ef8300bfc9d6dc': 'V3RiskSteward',
  '5000:0xb5a1fe36dcf5ba149cb8d90a03f4709141ee5442': 'V3RiskSteward',
  '42220:0xf73f2634b43344d86921da3391d4ef0d5675dd63': 'V3RiskSteward',
  '59144:0xe77af99210ac55939e1ba0bfc6a9a20e1da73b25': 'V3RiskSteward',
  '1:0x9db34dc89d9bc56a5e2899c328d959ef9e072645': 'V3RiskSteward',
  '1:0x5ba8d98fee911c2422ebebfb6b774128924ccd68': 'V3RiskSteward',
  '10:0x33df99d9d6f69fbe2722920883609532efc2541d': 'V3RiskSteward',
  '42161:0xc5762e5a5c12886d4f6768549a9c605823d029e9': 'V3RiskSteward',
  '56:0x42ca9e62c9b61d01bb222d6e69f095ee98e61ce8': 'V3RiskSteward',
  '100:0xd7f6cba78fce1799c29460765c97d7792eed0756': 'V3RiskSteward',
  '8453:0x494bcfd3937abdebef3d2c2eae1ce8a2fb629032': 'V3RiskSteward',
  '43114:0x43632469e02cdaaeb4de3dcbfcaabef310975729': 'V3RiskSteward',
  '137:0x8f3537814430829ca6760c92859f1a3ce235049a': 'V3RiskSteward',
  '1:0x13a9cc64344b02bacc5ad9cf38b5711f1b9ec3d4': 'V3RiskSteward',
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
