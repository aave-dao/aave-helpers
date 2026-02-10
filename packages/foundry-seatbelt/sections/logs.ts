import type { Log } from '../snapshot-types';
import type { Abi, Hex, Address } from 'viem';
import { parseLogs } from '@bgd-labs/toolbox';
import eventDb from '../utils/eventDb.json';

export function renderLogsSection(logs: Log[] | undefined): string {
  if (!logs || !logs.length) return '';

  // Map our Log format to parseLogs format (emitter -> address)
  const toolboxLogs = logs.map((log) => ({
    topics: log.topics as [Hex],
    data: log.data as Hex,
    address: log.emitter as Address,
  }));

  const parsed = parseLogs({ logs: toolboxLogs, eventDb: eventDb as unknown as Abi });

  let md = '## Event logs\n\n';
  md += '| index | emitter | event |\n| --- | --- | --- |\n';

  for (let i = 0; i < parsed.length; i++) {
    const log = parsed[i];
    const emitter = logs[i].emitter;

    if (log.eventName) {
      const args = log.args ? formatArgs(log.args) : '';
      md += `| ${i} | ${emitter} | ${log.eventName}(${args}) |\n`;
    } else {
      const topics = logs[i].topics.map((t) => `\`${t}\``).join(', ');
      const data = logs[i].data.length > 66 ? `${logs[i].data.slice(0, 66)}...` : logs[i].data;
      md += `| ${i} | ${emitter} | topics: ${topics}, data: \`${data}\` |\n`;
    }
  }

  md += '\n';
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
