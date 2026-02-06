import { formatUnits } from 'viem';
import type { AaveV3Emode, AaveV3Snapshot } from './snapshot-types';
import { bitMapToIndexes } from '../utils/storageSlots';

export function renderEModeValue<T extends keyof AaveV3Emode>(
  key: T,
  emode: AaveV3Emode,
  snapshot: AaveV3Snapshot
) {
  if (!emode[key]) return '-';
  if (['reserveFactor', 'liquidationProtocolFee', 'liquidationThreshold', 'ltv'].includes(key))
    return `${formatUnits(BigInt(emode[key]), 2)} %`;
  if (key === 'liquidationBonus')
    return emode[key] === 0 ? '0 %' : `${((emode[key] as number) - 10000) / 100} %`;
  if (key === 'borrowableBitmap' || key === 'collateralBitmap') {
    const indexes = bitMapToIndexes(BigInt(emode[key]));
    return indexes
      .map(
        (i) =>
          snapshot.reserves[
            Object.keys(snapshot.reserves).find((key) => snapshot.reserves[key].id === i) as any
          ].symbol
      )
      .join(', ');
  }
  return emode[key];
}

const ORDER: (keyof AaveV3Emode)[] = [
  'eModeCategory',
  'label',
  'ltv',
  'liquidationThreshold',
  'liquidationBonus',
  'priceSource',
];
function sortEmodeKeys(a: keyof AaveV3Emode, b: keyof AaveV3Emode) {
  const indexA = ORDER.indexOf(a);
  const indexB = ORDER.indexOf(b);
  if (indexA !== -1 && indexB !== -1) {
    if (indexA > indexB) {
      return 1;
    }
    if (indexB > indexA) {
      return -1;
    }
  }
  if (indexA !== -1) return -1;
  if (indexB !== -1) return -1;
  return a.localeCompare(b);
}

const OMIT_KEYS: (keyof AaveV3Emode)[] = ['eModeCategory'];

export type EmodeDiff<A extends AaveV3Emode = AaveV3Emode> = {
  [key in keyof AaveV3Emode]: A[key] & {
    from: A[key] | null;
    to: A[key] | null;
  };
};

export function renderEmodeDiff(diff: EmodeDiff, pre: AaveV3Snapshot, post: AaveV3Snapshot) {
  let content = '| description | value before | value after |\n| --- | --- | --- |\n';
  (Object.keys(diff) as (keyof AaveV3Emode)[])
    .filter((key) => !OMIT_KEYS.includes(key))
    .sort(sortEmodeKeys)
    .map((key) => {
      if (typeof diff[key] === 'object' && diff[key].hasOwnProperty('from'))
        content += `| eMode.${key} | ${renderEModeValue(
          key,
          {
            ...diff,
            [key]: diff[key].from,
          },
          pre
        )} | ${renderEModeValue(key, { ...diff, [key]: diff[key].to }, post)} |\n`;
      else {
        const value = renderEModeValue(key, diff, pre);
        content += `| eMode.${key} (unchanged) | ${value} | ${value} |\n`;
      }
    });

  return content;
}
