import { type Hex } from 'viem';
import { isChange } from '../diff';
import { toAddressLink } from '../utils/markdown';
import { getClient } from '@bgd-labs/toolbox';
import type { CHAIN_ID } from '../snapshot-types';

export function renderPoolConfigSection(
  diffResult: Record<string, any>,
  chainId: CHAIN_ID
): string {
  if (!diffResult.poolConfig) return '';

  const configDiff = diffResult.poolConfig;
  const changedKeys = Object.keys(configDiff).filter((key) => isChange(configDiff[key]));
  if (!changedKeys.length) return '';

  const client = getClient(chainId, {});

  let md = '## Pool config changes\n\n';
  md += '| description | value before | value after |\n| --- | --- | --- |\n';

  for (const key of changedKeys) {
    const from = toAddressLink(configDiff[key].from as Hex, true, client);
    const to = toAddressLink(configDiff[key].to as Hex, true, client);
    md += `| ${key} | ${from} | ${to} |\n`;
  }

  md += '\n\n';
  return md;
}
