/**
 * Shape of `forge inspect <path>:<Contract> storage --json` output.
 *
 * Note: @aave-dao/toolbox declares a `FoundryStorage` type for the same data,
 * but with `slot: number` / `astId: string` / `numberOfBytes: number`, which
 * does not match what forge actually emits (`slot` and `numberOfBytes` are
 * strings, `astId` is a number) — hence these local definitions.
 */
export type StorageLayoutVariable = {
  astId: number;
  contract: string;
  label: string;
  /** byte offset within the slot, counted from the least significant byte */
  offset: number;
  /** decimal slot number as string; relative to the parent for struct members */
  slot: string;
  /** type id resolvable in StorageLayout['types'], e.g. 't_uint16' */
  type: string;
};

export type StorageLayoutType = {
  encoding: 'inplace' | 'mapping' | 'dynamic_array' | 'bytes';
  /** solidity type name, e.g. 'uint16', 'address', 'struct DataTypes.ReserveData' */
  label: string;
  /** decimal byte size as string */
  numberOfBytes: string;
  /** element type id for arrays */
  base?: string;
  /** key type id for mappings */
  key?: string;
  /** value type id for mappings */
  value?: string;
  /** struct members; `slot` is relative to the struct base */
  members?: StorageLayoutVariable[];
};

export type StorageLayout = {
  storage: StorageLayoutVariable[];
  types: Record<string, StorageLayoutType>;
};

export type LayoutEntry = {
  /** provenance, e.g. 'aave-v3-origin src/contracts/instances/PoolInstance.sol:PoolInstance' */
  source: string;
  layout: StorageLayout;
};
