import type { Hex } from 'viem';
import { getClient } from '@bgd-labs/toolbox';
import type { AaveV4Snapshot, V4SpokeCap } from '../snapshot-types-v4';
import { formatV4Value, type V4FormatterContext } from '../formatters-v4';
import { toAddressLink } from '../utils/markdown';

/** All fields in display order. Every field is compared so unexpected mutations
 *  are never silently missed. */
const FIELD_ORDER: (keyof V4SpokeCap)[] = [
  'assetSymbol',
  'addCap',
  'drawCap',
  'riskPremiumThreshold',
  'active',
  'halted',
];

/**
 * Parse the composite key "hubAddr_assetId_spokeAddr".
 * Ethereum addresses are 42 chars (0x + 40 hex), so the split is unambiguous.
 */
function parseCapKey(key: string): { hubAddr: string; assetId: string; spokeAddr: string } {
  const hubAddr = key.slice(0, 42);
  // skip the underscore after hub address
  const rest = key.slice(43);
  const underscoreIdx = rest.indexOf('_');
  const assetId = rest.slice(0, underscoreIdx);
  const spokeAddr = rest.slice(underscoreIdx + 1);
  return { hubAddr, assetId, spokeAddr };
}

function capHeader(
  cap: V4SpokeCap,
  hubAddr: string,
  assetId: string,
  spokeAddr: string,
  chainId: number
): string {
  const client = getClient(chainId, {});
  const hubLink = toAddressLink(hubAddr as Hex, true, client);
  const spokeLink = toAddressLink(spokeAddr as Hex, true, client);
  return `### ${cap.assetSymbol} (assetId: ${assetId}) on Hub ${hubLink} / Spoke ${spokeLink}\n\n`;
}

function renderNewCap(
  cap: V4SpokeCap,
  hubAddr: string,
  assetId: string,
  spokeAddr: string,
  ctx: V4FormatterContext
): string {
  const capCtx: V4FormatterContext = { ...ctx, spokeCap: cap };
  let md = capHeader(cap, hubAddr, assetId, spokeAddr, ctx.chainId);
  md += '**NEW SPOKE**\n\n';
  md += '| description | value |\n| --- | --- |\n';
  for (const key of FIELD_ORDER) {
    md += `| ${key} | ${formatV4Value('spokeCap', key, cap[key], capCtx)} |\n`;
  }
  return md + '\n';
}

function renderCapDiff(
  before: V4SpokeCap,
  after: V4SpokeCap,
  hubAddr: string,
  assetId: string,
  spokeAddr: string,
  ctx: V4FormatterContext
): string {
  const capCtx: V4FormatterContext = { ...ctx, spokeCap: after };
  const rows: string[] = [];
  for (const key of FIELD_ORDER) {
    const bVal = before[key];
    const aVal = after[key];
    if (String(bVal) === String(aVal)) continue;
    const fromFmt = formatV4Value('spokeCap', key, bVal, capCtx);
    const toFmt = formatV4Value('spokeCap', key, aVal, capCtx);
    rows.push(`| ${key} | ${fromFmt} | ${toFmt} |`);
  }
  if (rows.length === 0) return '';

  let md = capHeader(after, hubAddr, assetId, spokeAddr, ctx.chainId);
  md += '| description | value before | value after |\n| --- | --- | --- |\n';
  md += rows.join('\n') + '\n';
  return md + '\n';
}

export function renderSpokeCapsSection(before: AaveV4Snapshot, after: AaveV4Snapshot): string {
  const ctx: V4FormatterContext = { chainId: after.chainId };

  const allKeys = new Set([...Object.keys(before.spokeCaps), ...Object.keys(after.spokeCaps)]);

  let body = '';

  for (const key of allKeys) {
    const { hubAddr, assetId, spokeAddr } = parseCapKey(key);
    const bCap = before.spokeCaps[key];
    const aCap = after.spokeCaps[key];

    if (bCap && aCap) {
      body += renderCapDiff(bCap, aCap, hubAddr, assetId, spokeAddr, ctx);
    } else if (aCap) {
      body += renderNewCap(aCap, hubAddr, assetId, spokeAddr, ctx);
    } else if (bCap) {
      body += capHeader(bCap, hubAddr, assetId, spokeAddr, ctx.chainId) + '**REMOVED**\n\n';
    }
  }

  if (!body) return '';
  return `## Hub Spoke Cap Changes\n\n${body}`;
}
