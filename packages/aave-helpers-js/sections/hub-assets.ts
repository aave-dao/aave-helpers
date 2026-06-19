import type { Hex } from 'viem';
import { getClient } from '@aave-dao/toolbox';
import type { AaveV4Snapshot, V4HubAsset } from '../snapshot-types-v4';
import { formatV4Value, type V4FormatterContext } from '../formatters-v4';
import { toAddressLink } from '../utils/markdown';

/** All fields in display order. Every field is compared — even identity fields
 *  that "shouldn't" change — so unexpected mutations are never silently missed. */
const FIELD_ORDER: (keyof V4HubAsset)[] = [
  'symbol',
  'underlying',
  'decimals',
  'liquidityFee',
  'irStrategy',
  'feeReceiver',
  'reinvestmentController',
  'optimalUsageRatio',
  'baseDrawnRate',
  'rateGrowthBeforeOptimal',
  'rateGrowthAfterOptimal',
  'maxDrawnRate',
  // Asset state
  'deficitRay',
  'swept',
  'premiumShares',
  'premiumOffsetRay',
];

function hubAssetHeader(
  asset: V4HubAsset,
  hubAddr: string,
  assetId: string,
  chainId: number
): string {
  const client = getClient(chainId, {});
  const hubLink = toAddressLink(hubAddr as Hex, true, client);
  return `### ${asset.symbol} (assetId: ${assetId}) on Hub ${hubLink}\n\n`;
}

function renderNewHubAsset(
  asset: V4HubAsset,
  hubAddr: string,
  assetId: string,
  ctx: V4FormatterContext
): string {
  let md = hubAssetHeader(asset, hubAddr, assetId, ctx.chainId);
  md += '**NEW ASSET**\n\n';
  md += '| description | value |\n| --- | --- |\n';
  for (const key of FIELD_ORDER) {
    md += `| ${key} | ${formatV4Value('hubAsset', key, asset[key], ctx)} |\n`;
  }
  return md + '\n';
}

function renderHubAssetDiff(
  before: V4HubAsset,
  after: V4HubAsset,
  hubAddr: string,
  assetId: string,
  ctx: V4FormatterContext
): string {
  const rows: string[] = [];
  for (const key of FIELD_ORDER) {
    const bVal = before[key];
    const aVal = after[key];
    if (String(bVal) === String(aVal)) continue;
    const fromFmt = formatV4Value('hubAsset', key, bVal, ctx);
    const toFmt = formatV4Value('hubAsset', key, aVal, ctx);
    rows.push(`| ${key} | ${fromFmt} | ${toFmt} |`);
  }
  if (rows.length === 0) return '';

  let md = hubAssetHeader(after, hubAddr, assetId, ctx.chainId);
  md += '| description | value before | value after |\n| --- | --- | --- |\n';
  md += rows.join('\n') + '\n';
  return md + '\n';
}

export function renderHubAssetsSection(before: AaveV4Snapshot, after: AaveV4Snapshot): string {
  const ctx: V4FormatterContext = { chainId: after.chainId };

  const allHubAddrs = new Set([...Object.keys(before.hubAssets), ...Object.keys(after.hubAssets)]);

  let body = '';

  for (const hubAddr of allHubAddrs) {
    const beforeHub = before.hubAssets[hubAddr] ?? {};
    const afterHub = after.hubAssets[hubAddr] ?? {};

    const allAssetIds = new Set([...Object.keys(beforeHub), ...Object.keys(afterHub)]);

    for (const assetId of allAssetIds) {
      const bAsset = beforeHub[assetId];
      const aAsset = afterHub[assetId];

      if (bAsset && aAsset) {
        body += renderHubAssetDiff(bAsset, aAsset, hubAddr, assetId, ctx);
      } else if (aAsset) {
        body += renderNewHubAsset(aAsset, hubAddr, assetId, ctx);
      } else if (bAsset) {
        body += hubAssetHeader(bAsset, hubAddr, assetId, ctx.chainId) + '**REMOVED**\n\n';
      }
    }
  }

  if (!body) return '';
  return `## Hub Asset Changes\n\n${body}`;
}
