import type { Log, CHAIN_ID } from '../snapshot-types';
import type { Abi, Hex, Address } from 'viem';
import { parseLogs, enhanceLogs, getClient } from '@bgd-labs/toolbox';
import { isKnownAddress } from '../utils/address';
import eventDb from '../utils/eventDb.json';

export async function renderLogsSection(
  logs: Log[] | undefined,
  chainId: CHAIN_ID
): Promise<string> {
  if (!logs || !logs.length) return '';

  // Map our Log format to parseLogs format (emitter -> address)
  const toolboxLogs = logs.map((log) => ({
    topics: log.topics as [Hex],
    data: log.data as Hex,
    address: log.emitter as Address,
  }));

  const parsed = parseLogs({ logs: toolboxLogs, eventDb: eventDb as unknown as Abi });
  const client = getClient(chainId, {});
  const enhanced = await enhanceLogs(client, parsed);

  // Build parsed entries with their original index
  const entries = enhanced.map((log, i) => {
    const emitter = logs[i].emitter;
    let event: string;

    if (log.eventName) {
      const args = log.args ? formatArgs(log.args) : '';
      event = `${log.eventName}(${args})`;
    } else {
      const topics = logs[i].topics.map((t) => `\`${t}\``).join(', ');
      const data = logs[i].data.length > 66 ? `${logs[i].data.slice(0, 66)}...` : logs[i].data;
      event = `topics: ${topics}, data: \`${data}\``;
    }

    return { emitter, event, index: i };
  });

  // Group by emitter, preserving order of first appearance
  const grouped = new Map<
    string,
    { emitter: string; events: { index: number; event: string }[] }
  >();
  for (const entry of entries) {
    let group = grouped.get(entry.emitter);
    if (!group) {
      group = { emitter: entry.emitter, events: [] };
      grouped.set(entry.emitter, group);
    }
    group.events.push({ index: entry.index, event: entry.event });
  }

  let md = '## Event logs\n\n';

  for (const group of grouped.values()) {
    const knownName = isKnownAddress(group.emitter as Address, chainId);
    const label = knownName ? knownName.join(', ') : null;
    const heading = label ? `${group.emitter} (${label})` : group.emitter;

    md += `#### ${heading}\n\n`;
    md += '| index | event |\n| --- | --- |\n';
    for (const entry of group.events) {
      md += `| ${entry.index} | ${entry.event} |\n`;
    }
    md += '\n';
  }

  return md;
}

function formatArgs(args: any): string {
  if (Array.isArray(args)) {
    return args.map((v) => formatValue(v)).join(', ');
  }
  if (typeof args === 'object' && args !== null) {
    return Object.entries(args)
      .map(([k, v]) => `${k}: ${formatValue(v)}`)
      .join(', ');
  }
  return String(args);
}

function formatValue(v: unknown): string {
  if (typeof v === 'bigint') return v.toString();
  if (typeof v === 'string') return v;
  if (typeof v === 'boolean') return String(v);
  if (Array.isArray(v)) return `[${v.map(formatValue).join(', ')}]`;
  if (typeof v === 'object' && v !== null) return JSON.stringify(v);
  return String(v);
}
