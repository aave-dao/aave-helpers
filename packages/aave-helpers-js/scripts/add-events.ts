#!/usr/bin/env npx tsx
/**
 * Script to fetch events from a verified contract and add missing ones to eventDb.ts
 *
 * Usage:
 *   npx tsx scripts/add-events.ts <chainId> <address>
 *
 * Examples:
 *   npx tsx scripts/add-events.ts 1 0x5ac4182a1dd41aeef465e40b82fd326bf66ab82c
 *   npx tsx scripts/add-events.ts 137 0xSomePolygonAddress
 */
import { readFileSync, writeFileSync } from 'fs';
import { join } from 'path';
import { getSourceCode } from '@bgd-labs/toolbox';
import { Abi, type AbiEvent, toEventSignature } from 'viem';
import { eventDb } from '../utils/eventDb';

const EVENT_DB_PATH = join(import.meta.dirname, '..', 'utils', 'eventDb.ts');

function eventKey(e: AbiEvent): string {
  const inputs = (e.inputs || []).map((i) => `${i.type}:${!!i.indexed}`).join(',');
  return `${e.name}(${inputs})`;
}

function getEventKeys(events: AbiEvent[]): Set<string> {
  return new Set(events.map(eventKey));
}

async function fetchEvents(chainId: number, address: `0x${string}`): Promise<AbiEvent[]> {
  const source = await getSourceCode({
    chainId,
    address,
    apiKey: process.env.ETHERSCAN_API_KEY,
    apiUrl: process.env.EXPLORER_PROXY,
  });
  const abi: Abi = typeof source.ABI === 'string' ? JSON.parse(source.ABI) : source.ABI;
  const events = abi.filter((item) => item.type === 'event');

  // If proxy, also fetch implementation events
  if (
    'Proxy' in source &&
    source.Proxy === '1' &&
    'Implementation' in source &&
    source.Implementation
  ) {
    console.log(`Proxy detected, fetching implementation at ${source.Implementation}...`);
    const implSource = await getSourceCode({
      chainId,
      address: source.Implementation,
      apiKey: process.env.ETHERSCAN_API_KEY,
      apiUrl: process.env.EXPLORER_PROXY,
    });
    const implAbi: Abi =
      typeof implSource.ABI === 'string' ? JSON.parse(implSource.ABI) : implSource.ABI;
    const implEvents = implAbi.filter((item) => item.type === 'event');
    events.push(...implEvents);
  }

  return events;
}

async function main() {
  const [, , chainIdStr, address] = process.argv;

  if (!chainIdStr || !address) {
    console.error('Usage: npx tsx scripts/add-events.ts <chainId> <address>');
    process.exit(1);
  }

  const chainId = Number(chainIdStr);
  console.log(`Fetching events for ${address} on chain ${chainId}...`);

  const fetchedEvents = await fetchEvents(chainId, address as `0x${string}`);
  console.log(`Found ${fetchedEvents.length} events in contract ABI`);

  const existingKeys = getEventKeys(eventDb);
  const newEvents = fetchedEvents.filter((e) => !existingKeys.has(eventKey(e)));

  // Deduplicate within new events
  const seen = new Set<string>();
  const uniqueNewEvents = newEvents.filter((e) => {
    const key = eventKey(e);
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });

  if (uniqueNewEvents.length === 0) {
    console.log('All events are already in eventDb. Nothing to add.');
    return;
  }

  console.log(`Adding ${uniqueNewEvents.length} new events:`);
  uniqueNewEvents.forEach((e) => {
    console.log(`  - ${toEventSignature(e)}`);
  });

  // Read the file and insert before the closing `];`
  const content = readFileSync(EVENT_DB_PATH, 'utf-8');
  const closingIndex = content.lastIndexOf('];');
  if (closingIndex === -1) {
    console.error('Could not find closing ]; in eventDb.ts');
    process.exit(1);
  }

  const newEntries = uniqueNewEvents.map((e) => '  ' + JSON.stringify(e)).join(',\n');
  const updated = content.slice(0, closingIndex) + newEntries + ',\n];\n';

  writeFileSync(EVENT_DB_PATH, updated, 'utf-8');
  console.log(`Updated ${EVENT_DB_PATH}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
