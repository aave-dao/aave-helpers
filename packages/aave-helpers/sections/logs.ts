import type { Log } from '../snapshot-types';

export function renderLogsSection(logs: Log[] | undefined): string {
  if (!logs || !logs.length) return '';

  let md = '## Event logs\n\n';
  md += '| index | emitter | topics | data |\n| --- | --- | --- | --- |\n';

  for (let i = 0; i < logs.length; i++) {
    const log = logs[i];
    const topics = log.topics.map((t) => `\`${t}\``).join(', ');
    const data = log.data.length > 66 ? `${log.data.slice(0, 66)}...` : log.data;
    md += `| ${i} | ${log.emitter} | ${topics} | \`${data}\` |\n`;
  }

  md += '\n';
  return md;
}
