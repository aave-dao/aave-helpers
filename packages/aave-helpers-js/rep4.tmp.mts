import { readFileSync } from 'fs';
import { getSolidityStorageSlotUint, getSolidityStorageSlotAddress } from '@aave-dao/toolbox';
import { storageLayoutDb } from './utils/storageLayoutDb';
const l = storageLayoutDb.AccessManagerEnumerable.layout;
for (const v of l.storage) console.log(v.slot.padStart(3), v.label, v.type.slice(0, 70));
const rolesSlot = BigInt(l.storage.find((v) => v.label === '_roles')!.slot);
const steward = '0xd8d7AbC42c1c938BdEC94fF8da1b3cd5b7e3b107';
for (const role of [200n, 400n]) {
  const roleBase = BigInt(getSolidityStorageSlotUint(rolesSlot, role));
  console.log(
    role,
    'members[steward] =',
    getSolidityStorageSlotAddress(roleBase, steward).slice(0, 12)
  );
}
const sb = JSON.parse(readFileSync('/tmp/sb_dump_43114.json', 'utf-8'));
const am = sb.raw['0xe069096bDAfF9bAD15b2f1079EaF0f1685a24522'].stateDiff;
for (const [k, v] of Object.entries<any>(am))
  console.log(k.slice(0, 12), v.previousValue.slice(-16), '->', v.newValue.slice(-16));
