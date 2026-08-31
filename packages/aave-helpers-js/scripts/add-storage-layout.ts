#!/usr/bin/env npx tsx
/**
 * Script to obtain a contract's storage layout (`forge inspect ... storage`) and register
 * it in utils/storageLayoutDb.ts so raw storage diffs of that contract kind get decoded.
 *
 * Modes:
 *   --root <path>          local foundry project (e.g. a vendored lib)
 *   --repo <org/repo>      shallow-clone a github repo (with submodules) to a temp dir
 *   --chainId <id> --address <0x..>
 *                          fetch verified source from etherscan (follows proxies) and
 *                          materialize it into a temp foundry project
 *
 * Usage:
 *   npx tsx scripts/add-storage-layout.ts --kind PoolInstance \
 *     --root ../../lib/aave-address-book/lib/aave-v3-origin \
 *     --contract src/contracts/instances/PoolInstance.sol:PoolInstance
 *
 *   npx tsx scripts/add-storage-layout.ts --kind PayloadsController \
 *     --repo aave-dao/aave-governance-v3 \
 *     --contract src/contracts/payloads/PayloadsController.sol:PayloadsController
 *
 *   npx tsx scripts/add-storage-layout.ts --kind SomeContract --chainId 1 --address 0x... [--pin]
 *
 * --pin additionally records `${chainId}:${address}` -> kind in pinnedAddresses, for
 * contracts the address book / snapshot context cannot resolve.
 */
import { execFileSync } from 'child_process';
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'fs';
import { tmpdir } from 'os';
import { dirname, join, resolve } from 'path';
import { parseArgs } from 'util';
import { getSourceCode } from '@aave-dao/toolbox';
import type { StorageLayout } from '../utils/storageLayoutTypes';

const DB_PATH = join(import.meta.dirname, '..', 'utils', 'storageLayoutDb.ts');
const LAYOUTS_DIR = join(import.meta.dirname, '..', 'utils', 'storage-layouts');

const { values: args } = parseArgs({
  options: {
    kind: { type: 'string' },
    contract: { type: 'string' },
    root: { type: 'string' },
    repo: { type: 'string' },
    ref: { type: 'string' },
    chainId: { type: 'string' },
    address: { type: 'string' },
    pin: { type: 'boolean', default: false },
  },
});

function usage(message: string): never {
  console.error(message);
  console.error(
    'Usage: npx tsx scripts/add-storage-layout.ts --kind <Kind> ' +
      '(--root <path> | --repo <org/repo> [--ref <ref>] | --chainId <id> --address <0x..>) ' +
      '[--contract <src/File.sol:Name>] [--pin]'
  );
  process.exit(1);
}

function forgeInspect(contract: string, cwd: string): StorageLayout {
  console.log(`Running forge inspect ${contract} storage in ${cwd}...`);
  const out = execFileSync('forge', ['inspect', contract, 'storage', '--json'], {
    cwd,
    encoding: 'utf-8',
    maxBuffer: 64 * 1024 * 1024,
  });
  return JSON.parse(out) as StorageLayout;
}

function cloneRepo(repo: string, ref: string | undefined, dest: string) {
  console.log(`Cloning ${repo}${ref ? `@${ref}` : ''}...`);
  const args = ['clone', '--depth', '1', '--recurse-submodules', '--shallow-submodules'];
  if (ref) args.push('--branch', ref);
  execFileSync('git', [...args, `https://github.com/${repo}.git`, dest], { stdio: 'inherit' });
}

type EtherscanSource = Awaited<ReturnType<typeof getSourceCode>>;

async function fetchVerifiedSource(chainId: number, address: `0x${string}`) {
  let source: EtherscanSource = await getSourceCode({
    chainId,
    address,
    apiKey: process.env.ETHERSCAN_API_KEY,
    apiUrl: process.env.EXPLORER_PROXY,
  });
  if (
    'Proxy' in source &&
    source.Proxy === '1' &&
    'Implementation' in source &&
    source.Implementation
  ) {
    console.log(`Proxy detected, fetching implementation at ${source.Implementation}...`);
    source = await getSourceCode({
      chainId,
      address: source.Implementation as `0x${string}`,
      apiKey: process.env.ETHERSCAN_API_KEY,
      apiUrl: process.env.EXPLORER_PROXY,
    });
  }
  return source;
}

/**
 * Writes an etherscan verified source into `dest` as a compilable foundry project and
 * returns the `path:Name` forge inspect target.
 */
function materializeEtherscanProject(source: EtherscanSource, dest: string): string {
  const contractName = (source as any).ContractName as string;
  if (!contractName) throw new Error('Verified source has no ContractName');
  let raw = (source as any).SourceCode as string;
  // solc version like 'v0.8.20+commit.a1b79de6' -> '0.8.20'
  const solc = ((source as any).CompilerVersion as string).replace(/^v/, '').split('+')[0];

  let sources: Record<string, { content: string }>;
  let settings: any = {};
  if (raw.startsWith('{')) {
    // standard-json input, etherscan double-wraps it in {{ }}
    if (raw.startsWith('{{')) raw = raw.slice(1, -1);
    const standardJson = JSON.parse(raw);
    sources = standardJson.sources ?? standardJson;
    settings = standardJson.settings ?? {};
  } else {
    sources = { [`${contractName}.sol`]: { content: raw } };
  }

  let target: string | undefined;
  const contractRegex = new RegExp(`(contract|abstract contract)\\s+${contractName}[\\s({]`);
  for (const [path, { content }] of Object.entries(sources)) {
    // source paths can escape the project root (../) or be absolute — normalize into src/
    const safePath = join('src', path.replace(/^[/.]+/, ''));
    const filePath = join(dest, safePath);
    mkdirSync(dirname(filePath), { recursive: true });
    writeFileSync(filePath, content, 'utf-8');
    if (!target && contractRegex.test(content)) target = `${safePath}:${contractName}`;
  }
  if (!target) throw new Error(`Could not locate contract ${contractName} in verified sources`);

  const remappings: string[] = (settings.remappings ?? []).map((r: string) => {
    const [from, to] = r.split('=');
    return `${from}=${join('src', to.replace(/^[/.]+/, ''))}`;
  });
  const foundryToml = [
    '[profile.default]',
    `src = 'src'`,
    `libs = []`,
    `solc = '${solc}'`,
    `optimizer = ${settings.optimizer?.enabled ?? false}`,
    `optimizer_runs = ${settings.optimizer?.runs ?? 200}`,
    settings.evmVersion ? `evm_version = '${settings.evmVersion}'` : '',
    settings.viaIR ? 'via_ir = true' : '',
    remappings.length ? `remappings = [${remappings.map((r) => `'${r}'`).join(', ')}]` : '',
  ]
    .filter(Boolean)
    .join('\n');
  writeFileSync(join(dest, 'foundry.toml'), foundryToml, 'utf-8');
  return target;
}

function insertAfterMarker(content: string, marker: string, line: string): string {
  const idx = content.indexOf(marker);
  if (idx === -1) throw new Error(`Marker ${marker} not found in storageLayoutDb.ts`);
  const lineEnd = content.indexOf('\n', idx);
  return content.slice(0, lineEnd + 1) + line + '\n' + content.slice(lineEnd + 1);
}

function registerInDb(kind: string, pin?: { chainId: number; address: string }) {
  let db = readFileSync(DB_PATH, 'utf-8');
  const importLine = `import { ${kind} } from './storage-layouts/${kind}';`;
  if (!db.includes(importLine)) {
    db = insertAfterMarker(db, '// <auto-imports>', importLine);
    db = insertAfterMarker(db, '// <auto-entries>', `  ${kind},`);
  }
  if (pin) {
    const pinLine = `  '${pin.chainId}:${pin.address.toLowerCase()}': '${kind}',`;
    if (!db.includes(pinLine)) db = insertAfterMarker(db, '// <auto-pins>', pinLine);
  }
  writeFileSync(DB_PATH, db, 'utf-8');
}

async function main() {
  const kind = args.kind;
  if (!kind) usage('Missing --kind');
  if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(kind))
    usage(`--kind must be a valid identifier, got '${kind}'`);

  let layout: StorageLayout;
  let source: string;
  let pin: { chainId: number; address: string } | undefined;

  if (args.root) {
    if (!args.contract) usage('--root mode requires --contract <src/File.sol:Name>');
    const root = resolve(args.root);
    layout = forgeInspect(args.contract, root);
    source = `${args.root} ${args.contract}`;
  } else if (args.repo) {
    if (!args.contract) usage('--repo mode requires --contract <src/File.sol:Name>');
    const tmp = mkdtempSync(join(tmpdir(), 'add-storage-layout-'));
    try {
      cloneRepo(args.repo, args.ref, tmp);
      const commit = execFileSync('git', ['rev-parse', '--short', 'HEAD'], {
        cwd: tmp,
        encoding: 'utf-8',
      }).trim();
      layout = forgeInspect(args.contract, tmp);
      source = `${args.repo}@${commit} ${args.contract}`;
    } finally {
      rmSync(tmp, { recursive: true, force: true });
    }
  } else if (args.chainId && args.address) {
    const chainId = Number(args.chainId);
    const address = args.address as `0x${string}`;
    console.log(`Fetching verified source for ${address} on chain ${chainId}...`);
    const verified = await fetchVerifiedSource(chainId, address);
    const tmp = mkdtempSync(join(tmpdir(), 'add-storage-layout-'));
    try {
      const target = materializeEtherscanProject(verified, tmp);
      layout = forgeInspect(args.contract ?? target, tmp);
      source = `${chainId}:${address} ${(verified as any).ContractName} (etherscan)`;
    } finally {
      rmSync(tmp, { recursive: true, force: true });
    }
    if (args.pin) pin = { chainId, address };
  } else {
    usage('Provide one of --root, --repo, or --chainId + --address');
  }

  if (!layout.storage?.length) {
    throw new Error('Layout has no storage entries — wrong contract, or it holds no state.');
  }

  mkdirSync(LAYOUTS_DIR, { recursive: true });
  const layoutFile = join(LAYOUTS_DIR, `${kind}.ts`);
  writeFileSync(
    layoutFile,
    `// Generated by scripts/add-storage-layout.ts — do not edit by hand.\n` +
      `import type { LayoutEntry } from '../storageLayoutTypes';\n\n` +
      `export const ${kind}: LayoutEntry = {\n` +
      `  source: ${JSON.stringify(source)},\n` +
      `  layout: ${JSON.stringify(layout)},\n` +
      `};\n`,
    'utf-8'
  );
  registerInDb(kind, pin);
  console.log(
    `Registered ${kind} (${layout.storage.length} variables, source: ${source}) in ${layoutFile}`
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
