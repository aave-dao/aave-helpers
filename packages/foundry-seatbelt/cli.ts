#!/usr/bin/env node
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'fs';
import { dirname, join } from 'path';
import { Command } from 'commander';
import { Aip, cidV0ToBs58, hash, parseFrontmatterMd } from '@bgd-labs/toolbox';
import { diffSnapshots } from './protocol-diff';

const program = new Command();

program.name('foundry-seatbelt').description('Aave protocol snapshot tooling').version('1.0.0');

program
  .command('diff-snapshots')
  .description('Diff two Aave V3 protocol snapshot JSON files and produce a markdown report')
  .argument('<before>', 'path to the before snapshot JSON')
  .argument('<after>', 'path to the after snapshot JSON')
  .requiredOption('-o, --out <path>', 'output path for the markdown report')
  .action(async (beforePath: string, afterPath: string, opts: { out: string }) => {
    const before = JSON.parse(readFileSync(beforePath, 'utf-8'));
    const after = JSON.parse(readFileSync(afterPath, 'utf-8'));

    const md = await diffSnapshots(before, after);

    mkdirSync(dirname(opts.out), { recursive: true });
    writeFileSync(opts.out, md, 'utf-8');
  });

async function uploadToPinata(source: string) {
  const PINATA_KEY = process.env.PINATA_KEY;
  if (!PINATA_KEY) throw new Error('PINATA_KEY env must be set');
  const PINATA_SECRET = process.env.PINATA_SECRET;
  if (!PINATA_SECRET) throw new Error('PINATA_SECRET env must be set');
  const data = new FormData();
  data.append('file', new Blob([source]));
  const res = await fetch('https://api.pinata.cloud/pinning/pinFileToIPFS', {
    method: 'POST',
    body: data,
    headers: {
      pinata_api_key: PINATA_KEY,
      pinata_secret_api_key: PINATA_SECRET,
    },
  });

  if (!res.ok) {
    throw Error(await res.text());
  }

  const result = await res.json();

  if (result.error) throw { message: result.error };
  return result;
}

async function uploadToTheGraph(source: string) {
  const data = new FormData();
  data.append('file', new Blob([source]));
  const res = await fetch('https://api.thegraph.com/ipfs/api/v0/add', {
    method: 'POST',
    body: data,
  });
  return await res.json();
}

program
  .command('ipfs')
  .description('generates the ipfs hash for specified source')
  .argument('<source>')
  .option('-u, --upload')
  .option('--verbose')
  .action(async (source, { upload, verbose }) => {
    const filePath = join(process.cwd(), source);
    if (!existsSync(filePath)) {
      throw new Error('FILE_NOT_FOUND');
    }
    const content = readFileSync(filePath, 'utf8');
    const parsed = parseFrontmatterMd(content);
    Aip(parsed);

    const cid0 = await hash(content);
    const bs58Hash = cidV0ToBs58(cid0);

    if (upload) {
      const [pinata, thegraph] = await Promise.all([
        uploadToPinata(content),
        uploadToTheGraph(content),
      ]);
      if (verbose) {
        console.log('pinata response', pinata);
        console.log('thegraph response', thegraph);
      }
    }

    // log as hex to console so foundry can read the content
    console.log(bs58Hash);
  });

program.parse();
