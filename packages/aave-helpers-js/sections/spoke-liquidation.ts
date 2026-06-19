import type { Hex } from 'viem';
import { getClient } from '@aave-dao/toolbox';
import type { AaveV4Snapshot, V4SpokeLiquidationConfig } from '../snapshot-types-v4';
import { formatV4Value, type V4FormatterContext } from '../formatters-v4';
import { toAddressLink } from '../utils/markdown';

/** All fields in display order (this section already covers every field). */
const FIELD_ORDER: (keyof V4SpokeLiquidationConfig)[] = [
  'targetHealthFactor',
  'healthFactorForMaxBonus',
  'liquidationBonusFactor',
  'maxUserReservesLimit',
];

function spokeHeader(spokeAddr: string, chainId: number): string {
  const client = getClient(chainId, {});
  const spokeLink = toAddressLink(spokeAddr as Hex, true, client);
  return `### Spoke ${spokeLink}\n\n`;
}

function renderNewSpokeLiq(
  config: V4SpokeLiquidationConfig,
  spokeAddr: string,
  ctx: V4FormatterContext
): string {
  let md = spokeHeader(spokeAddr, ctx.chainId);
  md += '**NEW**\n\n';
  md += '| description | value |\n| --- | --- |\n';
  for (const key of FIELD_ORDER) {
    md += `| ${key} | ${formatV4Value('spokeLiq', key, config[key], ctx)} |\n`;
  }
  return md + '\n';
}

function renderSpokeLiqDiff(
  before: V4SpokeLiquidationConfig,
  after: V4SpokeLiquidationConfig,
  spokeAddr: string,
  ctx: V4FormatterContext
): string {
  const rows: string[] = [];
  for (const key of FIELD_ORDER) {
    const bVal = before[key];
    const aVal = after[key];
    if (String(bVal) === String(aVal)) continue;
    const fromFmt = formatV4Value('spokeLiq', key, bVal, ctx);
    const toFmt = formatV4Value('spokeLiq', key, aVal, ctx);
    rows.push(`| ${key} | ${fromFmt} | ${toFmt} |`);
  }
  if (rows.length === 0) return '';

  let md = spokeHeader(spokeAddr, ctx.chainId);
  md += '| description | value before | value after |\n| --- | --- | --- |\n';
  md += rows.join('\n') + '\n';
  return md + '\n';
}

export function renderSpokeLiquidationSection(
  before: AaveV4Snapshot,
  after: AaveV4Snapshot
): string {
  const ctx: V4FormatterContext = { chainId: after.chainId };

  const allSpokeAddrs = new Set([
    ...Object.keys(before.spokeLiquidationConfigs),
    ...Object.keys(after.spokeLiquidationConfigs),
  ]);

  let body = '';

  for (const spokeAddr of allSpokeAddrs) {
    const bConfig = before.spokeLiquidationConfigs[spokeAddr];
    const aConfig = after.spokeLiquidationConfigs[spokeAddr];

    if (bConfig && aConfig) {
      body += renderSpokeLiqDiff(bConfig, aConfig, spokeAddr, ctx);
    } else if (aConfig) {
      body += renderNewSpokeLiq(aConfig, spokeAddr, ctx);
    } else if (bConfig) {
      body += spokeHeader(spokeAddr, ctx.chainId) + '**REMOVED**\n\n';
    }
  }

  if (!body) return '';
  return `## Spoke Liquidation Config Changes\n\n${body}`;
}
