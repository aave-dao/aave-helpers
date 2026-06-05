import type { Hex } from 'viem';
import { getClient } from '@bgd-labs/toolbox';
import type { AaveV4Snapshot, V4AccessManagerRole } from '../snapshot-types-v4';
import { toAddressLink } from '../utils/markdown';

type RoleEntry = V4AccessManagerRole | undefined;

function setOf(arr: string[] | undefined): Set<string> {
  return new Set((arr ?? []).map((v) => v.toLowerCase()));
}

function diffSets(b: Set<string>, a: Set<string>): { added: string[]; removed: string[] } {
  const added: string[] = [];
  const removed: string[] = [];
  for (const v of a) if (!b.has(v)) added.push(v);
  for (const v of b) if (!a.has(v)) removed.push(v);
  return { added, removed };
}

function renderAddrList(values: string[], chainId: number): string {
  if (values.length === 0) return '*(none)*';
  const client = getClient(chainId, {});
  return values.map((v) => toAddressLink(v as Hex, true, client)).join(', ');
}

function diffTargetSelectorPairs(
  b: V4AccessManagerRole | undefined,
  a: V4AccessManagerRole | undefined
): { added: string[]; removed: string[] } {
  const beforePairs = new Set<string>();
  const afterPairs = new Set<string>();
  for (let i = 0; i < (b?.targets.length ?? 0); i++) {
    beforePairs.add(`${b!.targets[i].toLowerCase()}|${b!.selectors[i]}`);
  }
  for (let i = 0; i < (a?.targets.length ?? 0); i++) {
    afterPairs.add(`${a!.targets[i].toLowerCase()}|${a!.selectors[i]}`);
  }
  const added: string[] = [];
  const removed: string[] = [];
  for (const p of afterPairs) if (!beforePairs.has(p)) added.push(p);
  for (const p of beforePairs) if (!afterPairs.has(p)) removed.push(p);
  return { added, removed };
}

function renderRoleDiff(
  amAddr: string,
  roleId: string,
  before: RoleEntry,
  after: RoleEntry,
  chainId: number
): string {
  const members = diffSets(setOf(before?.members), setOf(after?.members));
  const targetSelectors = diffTargetSelectorPairs(before, after);
  const labelChanged = (before?.label ?? '') !== (after?.label ?? '');

  if (
    !labelChanged &&
    members.added.length === 0 &&
    members.removed.length === 0 &&
    targetSelectors.added.length === 0 &&
    targetSelectors.removed.length === 0
  ) {
    return '';
  }

  const client = getClient(chainId, {});
  const amLink = toAddressLink(amAddr as Hex, true, client);

  let md = `#### ${amLink} role ${roleId}`;
  if ((after ?? before)?.label) {
    md += ` (${(after ?? before)!.label})`;
  }
  md += '\n\n';

  if (labelChanged) {
    md += `- label: "${before?.label ?? ''}" -> "${after?.label ?? ''}"\n`;
  }
  if (members.added.length > 0) {
    md += `- members added: ${renderAddrList(members.added, chainId)}\n`;
  }
  if (members.removed.length > 0) {
    md += `- members removed: ${renderAddrList(members.removed, chainId)}\n`;
  }
  if (targetSelectors.added.length > 0) {
    md += `- target/selector grants added:\n`;
    for (const p of targetSelectors.added) {
      const [t, s] = p.split('|');
      md += `  - ${toAddressLink(t as Hex, true, client)} ${s}\n`;
    }
  }
  if (targetSelectors.removed.length > 0) {
    md += `- target/selector grants removed:\n`;
    for (const p of targetSelectors.removed) {
      const [t, s] = p.split('|');
      md += `  - ${toAddressLink(t as Hex, true, client)} ${s}\n`;
    }
  }
  md += '\n';
  return md;
}

export function renderAccessManagerRolesSection(
  before: AaveV4Snapshot,
  after: AaveV4Snapshot
): string {
  const beforeAm = before.accessManagerRoles ?? {};
  const afterAm = after.accessManagerRoles ?? {};
  const allAms = new Set<string>([...Object.keys(beforeAm), ...Object.keys(afterAm)]);

  let body = '';
  for (const amAddr of allAms) {
    const beforeRoles = beforeAm[amAddr] ?? {};
    const afterRoles = afterAm[amAddr] ?? {};
    const allRoles = new Set<string>([...Object.keys(beforeRoles), ...Object.keys(afterRoles)]);
    for (const roleId of [...allRoles].sort((a, b) => Number(a) - Number(b))) {
      body += renderRoleDiff(
        amAddr,
        roleId,
        beforeRoles[roleId],
        afterRoles[roleId],
        after.chainId
      );
    }
  }

  if (!body) return '';
  return `## Access Manager Role Changes\n\n${body}`;
}
