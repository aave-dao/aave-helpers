import type { Hex } from 'viem';
import { getClient } from '@bgd-labs/toolbox';
import type { AaveV4Snapshot, V4SpokeReserve } from '../snapshot-types-v4';
import { formatV4Value, type V4FormatterContext } from '../formatters-v4';
import { toAddressLink } from '../utils/markdown';

/** All fields in display order. Every field is compared — even identity fields
 *  that "shouldn't" change — so unexpected mutations are never silently missed. */
const FIELD_ORDER: (keyof V4SpokeReserve)[] = [
  'symbol',
  'underlying',
  'hub',
  'assetId',
  'decimals',
  'collateralRisk',
  'paused',
  'frozen',
  'borrowable',
  'receiveSharesEnabled',
  'dynamicConfigKey',
  'collateralFactor',
  'maxLiquidationBonus',
  'liquidationFee',
  'oracleAddress',
  'priceSource',
  'oraclePrice',
];

function reserveHeader(
  reserve: V4SpokeReserve,
  spokeAddr: string,
  reserveId: string,
  chainId: number
): string {
  const client = getClient(chainId, {});
  const underlyingLink = toAddressLink(reserve.underlying as Hex, true, client);
  const spokeLink = toAddressLink(spokeAddr as Hex, true, client);
  return `### ${reserve.symbol} (${underlyingLink}) on Spoke ${spokeLink} [reserveId: ${reserveId}]\n\n`;
}

function renderNewReserve(
  reserve: V4SpokeReserve,
  spokeAddr: string,
  reserveId: string,
  ctx: V4FormatterContext
): string {
  let md = reserveHeader(reserve, spokeAddr, reserveId, ctx.chainId);
  md += '**NEW RESERVE**\n\n';
  md += '| description | value |\n| --- | --- |\n';
  for (const key of FIELD_ORDER) {
    md += `| ${key} | ${formatV4Value('spokeReserve', key, reserve[key], ctx)} |\n`;
  }
  return md + '\n';
}

function renderReserveDiff(
  before: V4SpokeReserve,
  after: V4SpokeReserve,
  spokeAddr: string,
  reserveId: string,
  ctx: V4FormatterContext
): string {
  const rows: string[] = [];
  for (const key of FIELD_ORDER) {
    const bVal = before[key];
    const aVal = after[key];
    if (String(bVal) === String(aVal)) continue;
    const fromFmt = formatV4Value('spokeReserve', key, bVal, ctx);
    const toFmt = formatV4Value('spokeReserve', key, aVal, ctx);
    rows.push(`| ${key} | ${fromFmt} | ${toFmt} |`);
  }
  if (rows.length === 0) return '';

  let md = reserveHeader(after, spokeAddr, reserveId, ctx.chainId);
  md += '| description | value before | value after |\n| --- | --- | --- |\n';
  md += rows.join('\n') + '\n';
  return md + '\n';
}

export function renderSpokeReservesSection(before: AaveV4Snapshot, after: AaveV4Snapshot): string {
  const ctx: V4FormatterContext = { chainId: after.chainId };

  const allSpokeAddrs = new Set([
    ...Object.keys(before.spokeReserves),
    ...Object.keys(after.spokeReserves),
  ]);

  let body = '';

  for (const spokeAddr of allSpokeAddrs) {
    const beforeSpoke = before.spokeReserves[spokeAddr] ?? {};
    const afterSpoke = after.spokeReserves[spokeAddr] ?? {};

    const allReserveIds = new Set([...Object.keys(beforeSpoke), ...Object.keys(afterSpoke)]);

    for (const reserveId of allReserveIds) {
      const bRes = beforeSpoke[reserveId];
      const aRes = afterSpoke[reserveId];

      if (bRes && aRes) {
        body += renderReserveDiff(bRes, aRes, spokeAddr, reserveId, ctx);
      } else if (aRes) {
        body += renderNewReserve(aRes, spokeAddr, reserveId, ctx);
      } else if (bRes) {
        body += reserveHeader(bRes, spokeAddr, reserveId, ctx.chainId) + '**REMOVED**\n\n';
      }
    }
  }

  if (!body) return '';
  return `## Spoke Reserve Changes\n\n${body}`;
}
