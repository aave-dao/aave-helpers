import { type Client, type Hex, formatUnits } from 'viem';

/**
 * Returns a string with `,` separators for thousands.
 */
export function formatNumberString(x: string | number) {
  return String(x).replace(/\B(?<!\.\d*)(?=(\d{3})+(?!\d))/g, ',');
}

function limitDecimalsWithoutRounding(val: string, decimals: number) {
  const parts = val.split('.');
  if (parts.length !== 2) return val;
  return parts[0] + '.' + parts[1].substring(0, decimals);
}

export function prettifyNumber({
  value,
  decimals,
  prefix,
  suffix,
  showDecimals,
  patchedValue,
}: {
  value: string | number | bigint;
  decimals: number;
  prefix?: string;
  suffix?: string;
  showDecimals?: boolean;
  patchedValue?: string | number | bigint;
}) {
  const formattedNumber = limitDecimalsWithoutRounding(
    formatNumberString(formatUnits(BigInt(patchedValue || value), decimals)),
    4
  );
  return `${prefix ? `${prefix} ` : ''}${formattedNumber}${
    suffix ? ` ${suffix}` : ''
  } [${value}${showDecimals ? `, ${decimals} decimals` : ''}]`;
}

export function toAddressLink(address: Hex, md: boolean, client?: Client): string {
  if (!client) return address;
  const link = `${client.chain?.blockExplorers?.default.url}/address/${address}`;
  if (md) return toMarkdownLink(link, address);
  return link;
}

export function toTxLink(txn: Hex, md: boolean, client?: Client): string {
  if (!client) return txn;
  const link = `${client.chain?.blockExplorers?.default.url}/tx/${txn}`;
  if (md) return toMarkdownLink(link, txn);
  return link;
}

export function toMarkdownLink(link: string, title?: any) {
  return `[${title || link}](${link})`;
}

export function boolToMarkdown(value: boolean) {
  return value ? ':white_check_mark:' : ':x:';
}

export function renderUnixTime(time: number) {
  return new Date(time * 1000).toLocaleString('en-GB', { timeZone: 'UTC' });
}
