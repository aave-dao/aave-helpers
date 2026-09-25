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
 *   npx tsx scripts/add-storage-layout.ts --kind SomeContract --chainId 1 --address 0x...
 *
 *   npx tsx scripts/add-storage-layout.ts --kind SomeContract --pin 1:0x... --pin 8453:0x...
 *
 * --pin <chainId:address> (repeatable, any mode) records the deployment in pinnedAddresses so
 * it resolves to this kind. Use it whenever the layout depends on the deployed version rather
 * than on the address-book key. Without a source mode it only adds pins to an existing kind.
 */
import { execFileSync } from 'child_process';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'fs';
import { tmpdir } from 'os';
import { dirname, join, resolve, sep } from 'path';
import { Command, InvalidArgumentError } from 'commander';
import { getAddress, isAddress } from 'viem';
import { getSourceCode } from '@aave-dao/toolbox';
import type { StorageLayout } from '../utils/storageLayoutTypes';

const DB_PATH = join(import.meta.dirname, '..', 'utils', 'storageLayoutDb.ts');
const LAYOUTS_DIR = join(import.meta.dirname, '..', 'utils', 'storage-layouts');

type Pin = { chainId: number; address: string };

function parsePin(value: string, pins: Pin[] = []): Pin[] {
  const [chain, address] = value.split(':');
  const chainId = Number(chain);
  if (!Number.isSafeInteger(chainId) || chainId <= 0 || !address || !isAddress(address)) {
    throw new InvalidArgumentError(`expected <chainId>:<address>, got '${value}'`);
  }
  return [...pins, { chainId, address: getAddress(address) }];
}

const program = new Command()
  .name('add-storage-layout')
  .requiredOption('--kind <kind>', 'storageLayoutDb kind (valid TS identifier)')
  .option('--contract <src/File.sol:Name>', 'forge inspect target')
  .option('--root <path>', 'local foundry project')
  .option('--repo <org/repo>', 'github repo to shallow-clone')
  .option('--ref <ref>', 'branch or tag for --repo')
  .option('--chainId <id>', 'chain of the verified contract')
  .option('--address <0x..>', 'verified contract address')
  .option('--pin <chainId:address>', 'pin a deployment to this kind (repeatable)', parsePin, [])
  .parse();

const args = program.opts<{
  kind: string;
  contract?: string;
  root?: string;
  repo?: string;
  ref?: string;
  chainId?: string;
  address?: string;
  pin: Pin[];
}>();

function usage(message: string): never {
  return program.error(message);
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
 * Normalizes a verified-source path into a project-relative path, keeping the original
 * layout (verified sources import root-relative, e.g. 'src/interfaces/X.sol'). They are
 * attacker-controlled, so every '.', '..', empty and drive-letter segment is dropped:
 * 'a/../../../etc/x' becomes 'a/etc/x'.
 */
function sanitizeSourcePath(sourcePath: string): string {
  const segments = sourcePath
    .split(/[\\/]+/)
    .filter((segment) => segment && segment !== '.' && segment !== '..' && !segment.includes(':'));
  if (!segments.length) throw new Error(`Unusable source path: ${sourcePath}`);
  // remapping targets rely on the trailing slash for prefix matching
  const trailing = /[\\/]$/.test(sourcePath) ? '/' : '';
  return join(...segments) + trailing;
}

/** `[context:]prefix=target`, with context and target normalized like source paths */
function sanitizeRemapping(remapping: string): string {
  const eq = remapping.indexOf('=');
  if (eq === -1) throw new Error(`Invalid remapping: ${remapping}`);
  const lhs = remapping.slice(0, eq);
  const colon = lhs.indexOf(':');
  const context = colon === -1 ? '' : `${sanitizeSourcePath(lhs.slice(0, colon))}:`;
  const prefix = colon === -1 ? lhs : lhs.slice(colon + 1);
  return `${context}${prefix}=${sanitizeSourcePath(remapping.slice(eq + 1))}`;
}

/** TOML basic string; JSON string escaping is a valid subset, so no value can break out */
const tomlString = (value: string) => JSON.stringify(value);

/**
 * Writes an etherscan verified source into `dest` as a compilable foundry project and
 * returns the `path:Name` forge inspect target.
 */
function materializeEtherscanProject(source: EtherscanSource, dest: string): string {
  const contractName = (source as any).ContractName as string;
  if (!/^[A-Za-z_$][A-Za-z0-9_$]*$/.test(contractName ?? '')) {
    throw new Error(`Invalid ContractName in verified source: ${contractName}`);
  }
  let raw = (source as any).SourceCode as string;
  // solc version like 'v0.8.20+commit.a1b79de6' -> '0.8.20'
  const solc = ((source as any).CompilerVersion as string).replace(/^v/, '').split('+')[0];
  if (!/^\d+\.\d+\.\d+$/.test(solc)) throw new Error(`Invalid compiler version: ${solc}`);

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
    const safePath = sanitizeSourcePath(path);
    // only solidity sources: a crafted remappings.txt or .env would be read by forge
    if (!safePath.endsWith('.sol')) throw new Error(`Refusing non-.sol verified source: ${path}`);
    const filePath = resolve(dest, safePath);
    if (!filePath.startsWith(resolve(dest) + sep)) {
      throw new Error(`Source path escapes project directory: ${path}`);
    }
    mkdirSync(dirname(filePath), { recursive: true });
    writeFileSync(filePath, content, 'utf-8');
    if (!target && contractRegex.test(content)) target = `${safePath}:${contractName}`;
  }
  if (!target) throw new Error(`Could not locate contract ${contractName} in verified sources`);

  const remappings: string[] = (settings.remappings ?? []).map(sanitizeRemapping);
  const optimizerRuns = Number(settings.optimizer?.runs ?? 200);
  if (!Number.isSafeInteger(optimizerRuns) || optimizerRuns < 0) {
    throw new Error(`Invalid optimizer runs: ${settings.optimizer?.runs}`);
  }
  const foundryToml = [
    '[profile.default]',
    `src = 'src'`,
    `libs = []`,
    `solc = ${tomlString(solc)}`,
    `optimizer = ${settings.optimizer?.enabled === true}`,
    `optimizer_runs = ${optimizerRuns}`,
    settings.evmVersion ? `evm_version = ${tomlString(String(settings.evmVersion))}` : '',
    settings.viaIR === true ? 'via_ir = true' : '',
    remappings.length ? `remappings = [${remappings.map(tomlString).join(', ')}]` : '',
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

function registerInDb(kind: string, pins: Pin[]) {
  let db = readFileSync(DB_PATH, 'utf-8');
  const importLine = `import { ${kind} } from './storage-layouts/${kind}';`;
  if (!db.includes(importLine)) {
    db = insertAfterMarker(db, '// <auto-imports>', importLine);
    db = insertAfterMarker(db, '// <auto-entries>', `  ${kind},`);
  }
  for (const pin of pins) {
    const key = `'${pin.chainId}:${pin.address.toLowerCase()}'`;
    if (db.includes(`${key}:`)) throw new Error(`${key} is already pinned in storageLayoutDb.ts`);
    db = insertAfterMarker(db, '// <auto-pins>', `  ${key}: '${kind}',`);
  }
  writeFileSync(DB_PATH, db, 'utf-8');
}

async function main() {
  const kind = args.kind;
  if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(kind))
    usage(`--kind must be a valid identifier, got '${kind}'`);

  let layout: StorageLayout;
  let source: string;

  if (!args.root && !args.repo && !args.chainId && !args.address && args.pin.length) {
    if (!existsSync(join(LAYOUTS_DIR, `${kind}.ts`)))
      usage(`Unknown kind ${kind}: nothing to pin to`);
    registerInDb(kind, args.pin);
    console.log(`Pinned ${args.pin.length} deployment(s) to ${kind}`);
    return;
  }

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
  registerInDb(kind, args.pin);
  console.log(
    `Registered ${kind} (${layout.storage.length} variables, source: ${source}) in ${layoutFile}`
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
