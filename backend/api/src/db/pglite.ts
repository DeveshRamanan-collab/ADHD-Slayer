import { mkdir } from 'node:fs/promises';
import type { PGlite, Transaction } from '@electric-sql/pglite';
import { PG_TYPE, parseInt8, type Db, type Queryable, type QueryResult } from './types.js';

// Match node-postgres (see types.ts): Buffer for bytea, number for bigint, text for date.
// Passed per query so clones and reopened instances behave the same.
const parsers = {
  [PG_TYPE.BYTEA]: (value: string) => Buffer.from(value.slice(2), 'hex'), // text format is `\x` + hex
  [PG_TYPE.INT8]: parseInt8,
  [PG_TYPE.DATE]: (value: string) => value,
};

function wrap(target: PGlite | Transaction): Queryable {
  return {
    async query<T>(sql: string, params: readonly unknown[] = []): Promise<QueryResult<T>> {
      const result = await target.query<T>(sql, [...params], { parsers });
      // `rowCount` comes from the command tag, the same number node-postgres reports.
      return { rows: result.rows, rowCount: result.rowCount ?? result.rows.length };
    },
    async exec(sql: string): Promise<void> {
      await target.exec(sql, { parsers });
    },
  };
}

/**
 * Opens PGlite, the WASM build of Postgres, for local development and tests.
 * `location` is `memory` or a directory. Only one process may open a directory at a time.
 * PGlite is a dev dependency, loaded only here, so the production image never ships it.
 */
export async function openPglite(location: string): Promise<PGlite> {
  const { PGlite } = await import('@electric-sql/pglite');
  if (location !== 'memory') await mkdir(location, { recursive: true });
  const instance = await PGlite.create(location === 'memory' ? 'memory://' : location);
  await useUtc(instance);
  return instance;
}

/** Sessions run in UTC, as the node-postgres pool does. Call again on a clone. */
export async function useUtc(instance: PGlite): Promise<void> {
  await instance.exec(`SET TIME ZONE 'UTC'`);
}

export function pgliteDb(instance: PGlite): Db {
  const base = wrap(instance);
  return {
    driver: 'pglite',
    query: base.query,
    exec: base.exec,
    tx: (fn) => instance.transaction((tx) => fn(wrap(tx))),
    close: () => instance.close(),
  };
}
