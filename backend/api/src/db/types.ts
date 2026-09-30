/**
 * The one database interface feature code uses. Both drivers (node-postgres in AWS, PGlite
 * locally and in tests) return the same JavaScript types:
 *
 * | Postgres type | JavaScript |
 * |---|---|
 * | uuid, text | string |
 * | integer, bigint | number (bigint values outside the safe integer range throw) |
 * | timestamptz | Date |
 * | date | string `YYYY-MM-DD` |
 * | bytea | Buffer |
 * | json, jsonb | parsed value |
 * | boolean | boolean |
 *
 * Parameters: pass Date for timestamptz, `YYYY-MM-DD` strings for date, Buffer for bytea,
 * and `JSON.stringify(value)` for json/jsonb (node-postgres would turn a JS array into a
 * Postgres array literal).
 */

export type Row = Record<string, unknown>;

export interface QueryResult<T> {
  rows: T[];
  /** Rows changed by INSERT, UPDATE or DELETE, or rows returned by SELECT. */
  rowCount: number;
}

export interface Queryable {
  /** One statement with `$1` style parameters. The row type is a cast, as with node-postgres. */
  query<T = Row>(sql: string, params?: readonly unknown[]): Promise<QueryResult<T>>;
  /** A script of several statements without parameters (migrations). */
  exec(sql: string): Promise<void>;
}

export interface Db extends Queryable {
  readonly driver: 'pg' | 'pglite';
  /**
   * Runs `fn` in a transaction and commits when it resolves, rolls back when it throws.
   * Use only the `tx` argument inside: on PGlite the outer `db` waits for the transaction
   * to finish, so calling it inside `fn` deadlocks.
   */
  tx<T>(fn: (tx: Queryable) => Promise<T>): Promise<T>;
  close(): Promise<void>;
}

export const PG_TYPE = { BYTEA: 17, INT8: 20, DATE: 1082 } as const;

/** bigint as a JS number, refusing values that would silently lose precision. */
export function parseInt8(value: string): number {
  const parsed = Number(value);
  if (!Number.isSafeInteger(parsed)) throw new RangeError('bigint value outside the safe integer range');
  return parsed;
}
