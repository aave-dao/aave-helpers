import * as addresses from '@aave-dao/aave-address-book';
import { findObjectPaths } from 'find-object-paths';
import { type Address, getAddress } from 'viem';

/**
 * Checks if address is listed in the aave-address-book.
 * Returns found paths or undefined.
 */
export function isKnownAddress(value: Address, chainId: number): string[] | void {
  const transformedAddresses = Object.keys(addresses).reduce(
    (acc, key) => {
      if ((addresses as any)[key].CHAIN_ID === chainId) {
        const chainAddresses = { ...(addresses as any)[key] };
        if (chainAddresses.E_MODES) delete chainAddresses.E_MODES;
        acc[key] = chainAddresses;
      }
      return acc;
    },
    {} as { [key: string]: any }
  );
  const results = findObjectPaths(transformedAddresses, { value: getAddress(value) });
  if (typeof results === 'string') return [results];
  return results;
}
