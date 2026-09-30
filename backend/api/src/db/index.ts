import { resolve } from 'node:path';
import type { Logger } from 'pino';
import { createPgDb } from './pg.js';
import { openPglite, pgliteDb } from './pglite.js';
import type { Db } from './types.js';

export type { Db, Queryable, QueryResult, Row } from './types.js';

/**
 * `pglite://memory` and `pglite://<dir>` open PGlite (local and tests); anything else,
 * including undefined (the PG* variables), opens a node-postgres pool.
 */
export async function createDb(url: string | undefined, logger: Logger): Promise<Db> {
  if (url?.startsWith('pglite://')) {
    const location = url.slice('pglite://'.length);
    return pgliteDb(await openPglite(location === 'memory' ? 'memory' : resolve(location)));
  }
  return createPgDb(url, logger);
}
