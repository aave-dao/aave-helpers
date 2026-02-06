import { type Hex, formatUnits } from 'viem';
import { prettifyNumber, toAddressLink } from '../utils/markdown';
import type { AaveV3Reserve, CHAIN_ID } from './snapshot-types';
import { getClient } from '@bgd-labs/toolbox';

export function renderReserveValue<T extends keyof AaveV3Reserve>(
  key: T,
  reserve: AaveV3Reserve,
  chainId: CHAIN_ID
) {
  if (['reserveFactor', 'liquidationProtocolFee', 'liquidationThreshold', 'ltv'].includes(key))
    return prettifyNumber({ value: reserve[key] as string, decimals: 2, suffix: '%' });
  if (['supplyCap', 'borrowCap'].includes(key))
    return `${reserve[key].toLocaleString('en-US')} ${reserve.symbol}`;
  if (['aTokenUnderlyingBalance', 'virtualBalance'].includes(key))
    return prettifyNumber({
      value: reserve[key] as string,
      decimals: reserve.decimals,
      suffix: reserve.symbol,
    });
  if (key === 'debtCeiling')
    return prettifyNumber({ value: reserve[key] as string, decimals: 2, suffix: '$' });
  if (['liquidityIndex', 'variableBorrowIndex'].includes(key))
    return prettifyNumber({ value: reserve[key] as string, decimals: 27, suffix: '%' }); // `${Number(formatUnits(BigInt(reserve[key]), 27)).toLocaleString('en-US')}`;
  if (['currentLiquidityRate', 'currentVariableBorrowRate'].includes(key))
    return prettifyNumber({ value: reserve[key] as string, decimals: 25, suffix: '%' }); // `${Number(formatUnits(BigInt(reserve[key]), 25)).toLocaleString('en-US')} %`;
  if (key === 'liquidationBonus')
    return reserve[key] === 0 ? '0 %' : `${((reserve[key] as number) - 10000) / 100} %`;
  if (key === 'interestRateStrategy')
    return toAddressLink(
      reserve[key] as Hex,
      true,
      getClient(chainId, { providerConfig: { alchemyKey: process.env.ALCHEMY_API_KEY } })
    );
  if (key === 'oracleLatestAnswer' && reserve.oracleDecimals)
    return formatUnits(BigInt(reserve[key]), reserve.oracleDecimals);
  if (typeof reserve[key] === 'number') return reserve[key].toLocaleString('en-US');
  if (typeof reserve[key] === 'string' && /0x.+/.test(reserve[key] as string))
    return toAddressLink(
      reserve[key] as Hex,
      true,
      getClient(chainId, { providerConfig: { alchemyKey: process.env.ALCHEMY_API_KEY } })
    );
  return reserve[key];
}

function renderReserveHeadline(reserve: AaveV3Reserve, chainId: CHAIN_ID) {
  return `#### ${reserve.symbol} (${toAddressLink(reserve.underlying as Hex, true, getClient(chainId, { providerConfig: { alchemyKey: process.env.ALCHEMY_API_KEY } }))})\n\n`;
}

const ORDER: (keyof AaveV3Reserve)[] = [
  'symbol',
  'decimals',
  'isActive',
  'isFrozen',
  'supplyCap',
  'borrowCap',
  'debtCeiling',
  'isSiloed',
  'isFlashloanable',
  'eModeCategory',
  'oracle',
  'oracleDecimals',
  'oracleDescription',
  'oracleName',
  'oracleLatestAnswer',
  'usageAsCollateralEnabled',
  'ltv',
  'liquidationThreshold',
  'liquidationBonus',
  'liquidationProtocolFee',
  'reserveFactor',
  'aToken',
  'aTokenImpl',
  'variableDebtToken',
  'variableDebtTokenImpl',
  'stableDebtToken',
  'stableDebtTokenImpl',
  'borrowingEnabled',
  'stableBorrowRateEnabled',
  'isBorrowableInIsolation',
  'interestRateStrategy',
  'liquidityIndex',
  'variableBorrowIndex',
];
function sortReserveKeys(a: keyof AaveV3Reserve, b: keyof AaveV3Reserve) {
  const indexA = ORDER.indexOf(a);
  if (indexA === -1) return 1;
  const indexB = ORDER.indexOf(b);
  if (indexB === -1) return -1;
  return indexA - indexB;
}

function renderReserveConfig(reserve: AaveV3Reserve, chainId: CHAIN_ID) {
  let content = '| description | value |\n| --- | --- |\n';
  const OMIT_KEYS: (keyof AaveV3Reserve)[] = [
    'underlying', // already rendered in the header
    'symbol', // already rendered in the header
  ];
  (Object.keys(reserve) as (keyof AaveV3Reserve)[])
    .filter((key) => !OMIT_KEYS.includes(key))
    .sort(sortReserveKeys)
    .map((key) => {
      content += `| ${key} | ${renderReserveValue(key, reserve, chainId)} |\n`;
    });
  return content;
}

export function renderReserve(reserve: AaveV3Reserve, chainId: CHAIN_ID) {
  let content = renderReserveHeadline(reserve, chainId);
  content += renderReserveConfig(reserve, chainId);
  return content;
}

export type ReserveDiff<A extends AaveV3Reserve = AaveV3Reserve> = {
  [key in keyof A]: A[key] & { from: A[key] | null; to: A[key] | null };
};

export function renderReserveDiff(diff: ReserveDiff, chainId: CHAIN_ID) {
  let content = renderReserveHeadline(diff as AaveV3Reserve, chainId);
  content += '| description | value before | value after |\n| --- | --- | --- |\n';
  const from = Object.keys(diff).reduce((acc, _key) => {
    const key = _key as keyof AaveV3Reserve;
    (acc as any)[key] = typeof diff[key] === 'object' ? diff[key].from : diff[key];
    return acc;
  }, {} as AaveV3Reserve);
  const to = Object.keys(diff).reduce((acc, _key) => {
    const key = _key as keyof AaveV3Reserve;
    (acc as any)[key] = typeof diff[key] === 'object' ? diff[key].to : diff[key];
    return acc;
  }, {} as AaveV3Reserve);
  (Object.keys(diff) as (keyof AaveV3Reserve)[])
    .filter((key) => diff[key].hasOwnProperty('from'))
    .sort(sortReserveKeys)
    .map((key) => {
      content += `| ${key} | ${renderReserveValue(key, from, chainId)} | ${renderReserveValue(key, to, chainId)} |\n`;
    });
  return content;
}
