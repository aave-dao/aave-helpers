#!/usr/bin/env node
import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { dirname } from 'path';
import { Command } from 'commander';
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

program.parse();
