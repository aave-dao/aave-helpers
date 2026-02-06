import { type Client, type Hex, formatUnits, Address, getContract } from 'viem';
import { findAsset } from './address';

export function boolToMarkdown(value: boolean) {
  if (value) return ':white_check_mark:';
  return ':sos:';
}

/**
 * Turns a plaintext address into a link to etherscan page of that address
 * @param address to be linked
 * @param code whether to link to the code tab
 */
export function toAddressLink(address: Hex, md: boolean, client?: Client): string {
  if (!client) return address;
  const link = `${client.chain?.blockExplorers?.default.url}/address/${address}`;
  if (md) return toMarkdownLink(link, address);
  return link;
}

/**
 * Turns a plaintext address into a link to etherscan page of that address
 * @param address to be linked
 * @param code whether to link to the code tab
 */
export function toTxLink(txn: Hex, md: boolean, client?: Client): string {
  if (!client) return txn;
  const link = `${client.chain?.blockExplorers?.default.url}/tx/${txn}`;
  if (md) return toMarkdownLink(link, txn);
  return link;
}

export function toMarkdownLink(link: string, title?: any) {
  return `[${title || link}](${link})`;
}

export function renderUnixTime(time: number) {
  return new Date(time * 1000).toLocaleString('en-GB', { timeZone: 'UTC' });
}

export function flagKnownAddress(isKnown: string[] | void) {
  if (isKnown === undefined || isKnown.length === 0) return '';
  return `[:ghost:](https://github.com/bgd-labs/aave-address-book "${isKnown.join(', ')}")`;
}

/**
 * Returns a string with `,` separators.
 * Not using toLocalString() as it forces us to use `number` types, which can be problematic with decimals & big numbers
 * @param x
 * @returns
 * credits: https://stackoverflow.com/a/2901298
 */
export function formatNumberString(x: string | number) {
  return String(x).replace(/\B(?<!\.\d*)(?=(\d{3})+(?!\d))/g, ',');
}

function limitDecimalsWithoutRounding(val: string, decimals: number) {
  const parts = val.split('.');
  if (parts.length != 2) return val;
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
  // allow overwriting the value when formatting
  // this is useful for e.g. 1e4 % numbers, when the 100% should be removed in the formatting
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

export function wrapInQuotes(name: string, quotes: boolean) {
  if (quotes) return '`' + name + '`';
  return name;
}

export async function addAssetSymbol(client: Client, value: Address) {
  const asset = await findAsset(client, value);
  return `${value} (symbol: ${asset.symbol})`;
}

const CL_PROXY_ABI = [
  {
    inputs: [],
    name: 'decimals',
    outputs: [{ internalType: 'uint8', name: '', type: 'uint8' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'description',
    outputs: [{ internalType: 'string', name: '', type: 'string' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'latestAnswer',
    outputs: [{ internalType: 'int256', name: '', type: 'int256' }],
    stateMutability: 'view',
    type: 'function',
  },
] as const;

export async function addAssetPrice(client: Client, address: Address) {
  const clProxy = getContract({ client, address, abi: CL_PROXY_ABI });
  let decimals = 0,
    latestAnswer = 0n,
    description = 'unknown';
  try {
    decimals = await clProxy.read.decimals();
  } catch (e) {}
  try {
    latestAnswer = await clProxy.read.latestAnswer();
  } catch (e) {}
  try {
    description = await clProxy.read.description();
  } catch (e) {}
  return `${address} (latestAnswer: ${
    decimals ? prettifyNumber({ value: latestAnswer, decimals, showDecimals: true }) : latestAnswer
  }, description: ${description})`;
}
