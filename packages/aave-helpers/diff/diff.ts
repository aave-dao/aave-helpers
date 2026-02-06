/**
 * Highly inspired by - reimplemented a bit simpler & added types
 * @license MIT https://github.com/omgaz/diffler
 * Author: Gary Chisholm @omgaz
 */

export type Difference<A extends Record<string, any>, B extends Record<string, any>> = {
  [key in keyof Omit<A, keyof B>]: { from: A[key]; to: null };
} & {
  [key in keyof Omit<B, keyof A>]: { from: null; to: B[key] };
};

export type DiffOutput<A extends Record<string, any>, B extends Record<string, any>> = {
  [key in keyof (A | B)]: DiffOutput<A[key], B[key]>;
} & Difference<A, B>;

export function diff<T extends Record<string, any>, X extends Record<string, any>>(
  a: T,
  b: X,
  removeUnchanged?: boolean
): DiffOutput<T, X> {
  const out = {} as Record<string, any>;
  for (const key in a) {
    if (!b.hasOwnProperty(key)) {
      out[key] = { from: a[key], to: null };
    } else {
      if (typeof a[key] === 'object') {
        const tempDiff = diff(a[key], b[key], removeUnchanged);
        if (Object.keys(tempDiff).length > 0) {
          out[key] = tempDiff;
        }
      } else {
        if (b[key as string] === a[key]) {
          if (!removeUnchanged) out[key] = a[key];
        } else {
          out[key] = { from: a[key], to: b[key] };
        }
      }
    }
  }
  for (const key in b) {
    if (a.hasOwnProperty(key)) continue;
    out[key] = { from: null, to: b[key] };
  }
  return out as DiffOutput<T, X>;
}
