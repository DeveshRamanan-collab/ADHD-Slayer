import pg from 'pg';
import type { Logger } from 'pino';
import { errorFields } from '../core/log-fields.js';
import { PG_TYPE, parseInt8, type Db, type Queryable, type QueryResult } from './types.js';

const types = new pg.TypeOverrides();
types.setTypeParser(PG_TYPE.INT8, parseInt8);
// node-postgres turns a date into a Date at local midnight; keep the plain `YYYY-MM-DD` text.
types.setTypeParser(PG_TYPE.DATE, (value: string) => value);

function wrap(client: pg.Pool | pg.PoolClient): Queryable {
  return {
    async query<T>(sql: string, params: readonly unknown[] = []): Promise<QueryResult<T>> {
      const result = await client.query(sql, [...params]);
      return { rows: result.rows as T[], rowCount: result.rowCount ?? result.rows.length };
    },
    async exec(sql: string): Promise<void> {
      // Without parameters node-postgres uses the simple protocol, which allows several statements.
      await client.query(sql);
    },
  };
}

/**
 * node-postgres pool. With no connection string the standard PGHOST, PGPORT, PGDATABASE,
 * PGUSER, PGPASSWORD and PGSSLMODE variables apply (RDS credentials arrive that way).
 */
export function createPgDb(connectionString: string | undefined, logger: Logger): Db {
  const pool = new pg.Pool({
    connectionString,
    types,
    max: 10,
    application_name: 'focus-api',
    // UTC sessions; a runaway query can't hold a connection for more than 15 seconds.
    // Migrations lift the timeout for their own transactions.
    options: '-c TimeZone=UTC -c statement_timeout=15000',
  });
  // An idle client can fail (database restart, failover). Without a listener that crashes the process.
  pool.on('error', (error) => {
    logger.error(errorFields(error), 'idle database client failed');
  });

  const base = wrap(pool);
  return {
    driver: 'pg',
    query: base.query,
    exec: base.exec,
    async tx<T>(fn: (tx: Queryable) => Promise<T>): Promise<T> {
      const client = await pool.connect();
      let broken: Error | undefined;
      try {
        await client.query('BEGIN');
        const result = await fn(wrap(client));
        await client.query('COMMIT');
        return result;
      } catch (error) {
        try {
          await client.query('ROLLBACK');
        } catch (rollbackError) {
          // The connection is unusable; destroy it instead of returning it to the pool.
          broken = rollbackError instanceof Error ? rollbackError : new Error('rollback failed');
        }
        throw error;
      } finally {
        client.release(broken);
      }
    },
    close: () => pool.end(),
  };
}
