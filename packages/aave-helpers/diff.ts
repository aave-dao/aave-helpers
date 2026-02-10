/**
 * Generic recursive object diff.
 *
 * For each key present in either `a` or `b`:
 * - If both have the key and the values are objects, recurse.
 * - If both have the key and the values are equal primitives, keep as-is (or omit if `removeUnchanged`).
 * - If both have the key but values differ, produce `{ from, to }`.
 * - If only `a` has the key, produce `{ from: value, to: null }`.
 * - If only `b` has the key, produce `{ from: null, to: value }`.
 */

/** A changed field: carries the old and new value. */
export type Change<T> = { from: T | null; to: T | null };

/** Recursively maps each field to either its unchanged value, a Change, or a nested diff. */
export type DiffResult<T extends Record<string, any>> = {
  [K in keyof T]?: T[K] extends Record<string, any>
    ? DiffResult<T[K]> | Change<T[K]>
    : T[K] | Change<T[K]>;
};

export function diff<T extends Record<string, any>>(
  a: T,
  b: T,
  removeUnchanged?: boolean
): DiffResult<T> {
  const out: Record<string, any> = {};

  for (const key in a) {
    if (!Object.prototype.hasOwnProperty.call(b, key)) {
      out[key] = { from: a[key], to: null };
    } else if (
      typeof a[key] === 'object' &&
      a[key] !== null &&
      typeof b[key] === 'object' &&
      b[key] !== null
    ) {
      const nested = diff(a[key], b[key], removeUnchanged);
      if (Object.keys(nested).length > 0) {
        out[key] = nested;
      }
    } else if (a[key] === b[key]) {
      if (!removeUnchanged) out[key] = a[key];
    } else {
      out[key] = { from: a[key], to: b[key] };
    }
  }

  for (const key in b) {
    if (!Object.prototype.hasOwnProperty.call(a, key)) {
      out[key] = { from: null, to: b[key] };
    }
  }

  return out as DiffResult<T>;
}

/**
 * Check if a diff entry represents a changed value (has `from`/`to` shape).
 */
export function isChange<T = any>(value: any): value is Change<T> {
  return typeof value === 'object' && value !== null && 'from' in value && 'to' in value;
}

/**
 * Check if any direct child of the diff object has changes.
 */
export function hasChanges<T extends Record<string, any>>(
  diffObj: DiffResult<T> | Record<string, unknown> | null | undefined
): boolean {
  if (!diffObj) return false;
  return Object.values(diffObj).some(isChange);
}
