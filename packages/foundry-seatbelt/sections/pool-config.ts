import { type Hex } from 'viem';
import { isChange, type DiffResult, type Change } from '../diff';
import { toAddressLink } from '../utils/markdown';
import { getClient } from '@bgd-labs/toolbox';
import type { AaveV3Config, AaveV3Snapshot, CHAIN_ID } from '../snapshot-types';

export function renderPoolConfigSection(
  diffResult: DiffResult<AaveV3Snapshot>,
  chainId: CHAIN_ID
): string {
  if (!diffResult.poolConfig) return '';

  const configDiff = diffResult.poolConfig as DiffResult<AaveV3Config>;
  const changedKeys = Object.keys(configDiff).filter((key) =>
    isChange(configDiff[key as keyof AaveV3Config])
  );
  if (!changedKeys.length) return '';

  const client = getClient(chainId, {});

  let md = '## Pool config changes\n\n';
  md += '| description | value before | value after |\n| --- | --- | --- |\n';

  for (const key of changedKeys) {
    const change = configDiff[key as keyof AaveV3Config] as Change<string>;
    const from = toAddressLink(change.from as Hex, true, client);
    const to = toAddressLink(change.to as Hex, true, client);
    md += `| ${key} | ${from} | ${to} |\n`;
  }

  md += '\n\n';
  return md;
}
