import { getAddressBookReferences } from '@aave-dao/aave-address-book/utils';
import type { Address } from 'viem';
import type { AaveV3Snapshot } from '../snapshot-types';
import type { AaveV4Snapshot } from '../snapshot-types-v4';
import { pinnedAddresses } from './storageLayoutDb';

/** lowercase address -> contract kind, derived from a snapshot's own data */
export type SnapshotContext = Map<string, string>;

/**
 * Maps the last segment of an address-book reference (e.g. `AaveV3Ethereum.POOL`)
 * to a storageLayoutDb kind. Top-level-only segments are checked against the
 * reference depth so that e.g. `ASSETS.WETH.ORACLE` (a price feed) does not
 * resolve like the market-level `ORACLE` (the AaveOracle).
 */
const REFERENCE_SEGMENT_TO_KIND: Record<string, { kind: string; topLevelOnly?: boolean }> = {
  POOL: { kind: 'PoolInstance', topLevelOnly: true },
  POOL_CONFIGURATOR: { kind: 'PoolConfiguratorInstance', topLevelOnly: true },
  POOL_ADDRESSES_PROVIDER: { kind: 'PoolAddressesProvider', topLevelOnly: true },
  ACL_MANAGER: { kind: 'ACLManager', topLevelOnly: true },
  ORACLE: { kind: 'AaveOracle', topLevelOnly: true },
  DEFAULT_INCENTIVES_CONTROLLER: { kind: 'RewardsController', topLevelOnly: true },
  PAYLOADS_CONTROLLER: { kind: 'PayloadsController' },
  GOVERNANCE: { kind: 'Governance', topLevelOnly: true },
  CROSS_CHAIN_CONTROLLER: { kind: 'CrossChainController' },
  A_TOKEN: { kind: 'ATokenInstance' },
  V_TOKEN: { kind: 'VariableDebtTokenInstance' },
  HUB: { kind: 'HubInstance' },
  SPOKE: { kind: 'SpokeInstance' },
  ACCESS_MANAGER: { kind: 'AccessManagerEnumerable' },
};

function set(ctx: SnapshotContext, address: string | undefined, kind: string) {
  if (address && address.startsWith('0x')) ctx.set(address.toLowerCase(), kind);
}

export function buildV3Context(after: AaveV3Snapshot): SnapshotContext {
  const ctx: SnapshotContext = new Map();
  set(ctx, after.poolConfig?.pool, 'PoolInstance');
  set(ctx, after.poolConfig?.poolConfigurator, 'PoolConfiguratorInstance');
  set(ctx, after.poolConfig?.poolAddressesProvider, 'PoolAddressesProvider');
  set(ctx, after.poolConfig?.oracle, 'AaveOracle');
  for (const reserve of Object.values(after.reserves ?? {})) {
    set(ctx, reserve.aToken, 'ATokenInstance');
    set(ctx, reserve.variableDebtToken, 'VariableDebtTokenInstance');
  }
  return ctx;
}

export function buildV4Context(after: AaveV4Snapshot): SnapshotContext {
  const ctx: SnapshotContext = new Map();
  for (const [spoke, reserves] of Object.entries(after.spokeReserves ?? {})) {
    set(ctx, spoke, 'SpokeInstance');
    for (const reserve of Object.values(reserves)) set(ctx, reserve.hub, 'HubInstance');
  }
  for (const hub of Object.keys(after.hubAssets ?? {})) set(ctx, hub, 'HubInstance');
  for (const spoke of Object.keys(after.spokeConfigs ?? {})) set(ctx, spoke, 'SpokeInstance');
  for (const accessManager of Object.keys(after.accessManagerRoles ?? {})) {
    set(ctx, accessManager, 'AccessManagerEnumerable');
  }
  return ctx;
}

/**
 * Resolves which storageLayoutDb kind an address belongs to, if any.
 * Order: snapshot context (covers fresh deployments) -> address book -> pinned addresses.
 */
export function resolveContractKind(
  address: Address,
  chainId: number,
  context: SnapshotContext
): string | undefined {
  const fromContext = context.get(address.toLowerCase());
  if (fromContext) return fromContext;

  for (const reference of getAddressBookReferences(address, chainId)) {
    const segments = reference.split('.');
    const match = REFERENCE_SEGMENT_TO_KIND[segments[segments.length - 1]];
    if (match && (!match.topLevelOnly || segments.length === 2)) return match.kind;
  }

  return pinnedAddresses[`${chainId}:${address.toLowerCase()}`];
}
