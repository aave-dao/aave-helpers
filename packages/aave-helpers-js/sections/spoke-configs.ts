import type { Hex } from 'viem';
import { getClient } from '@bgd-labs/toolbox';
import type { AaveV4Snapshot, V4SpokeConfig } from '../snapshot-types-v4';
import { formatV4Value, type V4FormatterContext } from '../formatters-v4';
import { toAddressLink } from '../utils/markdown';

/** All fields in display order. Every field is compared */
const FIELD_ORDER: (keyof V4SpokeConfig)[] = [
  'assetSymbol',
  'addCap',
  'drawCap',
  'riskPremiumThreshold',
  'active',
  'halted',
];

/**
 * Parse the composite key "hubAddr_assetId_spokeAddr".
 */
function parseConfigKey(key: string): { hubAddr: string; assetId: string; spokeAddr: string } {
  const hubAddr = key.slice(0, 42);
  // skip the underscore after hub address
  const rest = key.slice(43);
  const underscoreIdx = rest.indexOf('_');
  const assetId = rest.slice(0, underscoreIdx);
  const spokeAddr = rest.slice(underscoreIdx + 1);
  return { hubAddr, assetId, spokeAddr };
}

function configHeader(
  cfg: V4SpokeConfig,
  hubAddr: string,
  assetId: string,
  spokeAddr: string,
  chainId: number
): string {
  const client = getClient(chainId, {});
  const hubLink = toAddressLink(hubAddr as Hex, true, client);
  const spokeLink = toAddressLink(spokeAddr as Hex, true, client);
  return `### ${cfg.assetSymbol} (assetId: ${assetId}) on Hub ${hubLink} / Spoke ${spokeLink}\n\n`;
}

function renderNewConfig(
  cfg: V4SpokeConfig,
  hubAddr: string,
  assetId: string,
  spokeAddr: string,
  ctx: V4FormatterContext
): string {
  const cfgCtx: V4FormatterContext = { ...ctx, spokeConfig: cfg };
  let md = configHeader(cfg, hubAddr, assetId, spokeAddr, ctx.chainId);
  md += '**NEW SPOKE**\n\n';
  md += '| description | value |\n| --- | --- |\n';
  for (const key of FIELD_ORDER) {
    md += `| ${key} | ${formatV4Value('spokeConfig', key, cfg[key], cfgCtx)} |\n`;
  }
  return md + '\n';
}

function renderConfigDiff(
  before: V4SpokeConfig,
  after: V4SpokeConfig,
  hubAddr: string,
  assetId: string,
  spokeAddr: string,
  ctx: V4FormatterContext
): string {
  const cfgCtx: V4FormatterContext = { ...ctx, spokeConfig: after };
  const rows: string[] = [];
  for (const key of FIELD_ORDER) {
    const bVal = before[key];
    const aVal = after[key];
    if (String(bVal) === String(aVal)) continue;
    const fromFmt = formatV4Value('spokeConfig', key, bVal, cfgCtx);
    const toFmt = formatV4Value('spokeConfig', key, aVal, cfgCtx);
    rows.push(`| ${key} | ${fromFmt} | ${toFmt} |`);
  }
  if (rows.length === 0) return '';

  let md = configHeader(after, hubAddr, assetId, spokeAddr, ctx.chainId);
  md += '| description | value before | value after |\n| --- | --- | --- |\n';
  md += rows.join('\n') + '\n';
  return md + '\n';
}

export function renderSpokeConfigsSection(before: AaveV4Snapshot, after: AaveV4Snapshot): string {
  const ctx: V4FormatterContext = { chainId: after.chainId };

  const allKeys = new Set([
    ...Object.keys(before.spokeConfigs),
    ...Object.keys(after.spokeConfigs),
  ]);

  let body = '';

  for (const key of allKeys) {
    const { hubAddr, assetId, spokeAddr } = parseConfigKey(key);
    const bCfg = before.spokeConfigs[key];
    const aCfg = after.spokeConfigs[key];

    if (bCfg && aCfg) {
      body += renderConfigDiff(bCfg, aCfg, hubAddr, assetId, spokeAddr, ctx);
    } else if (aCfg) {
      body += renderNewConfig(aCfg, hubAddr, assetId, spokeAddr, ctx);
    } else if (bCfg) {
      body += configHeader(bCfg, hubAddr, assetId, spokeAddr, ctx.chainId) + '**REMOVED**\n\n';
    }
  }

  if (!body) return '';
  return `## Hub Spoke Config Changes\n\n${body}`;
}
