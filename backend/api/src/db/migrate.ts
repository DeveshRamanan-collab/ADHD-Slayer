import { readdir, readFile } from 'node:fs/promises';
import type { Logger } from 'pino';
import { sha256Hex } from '../core/encoding.js';
import type { Db } from './types.js';

/**
 * Forward-only SQL migrations from `migrations/NNNN_name.sql`, applied in order, each in
 * its own transaction together with its `schema_migrations` row. Runners on several
 * machines serialize on an advisory lock, so a migration never runs twice. A migration
 * that was edited after it was applied stops the run: fix forward with a new file.
 *
 * Numbering: 0001-0099 core, 0100-0199 accounts/auth/devices/support/deletion,
 * 0200-0299 keys/sync/store/content/diagnostics.
 */

/** `migrations/` at the package root, next to both src/ and dist/. */
export const MIGRATIONS_DIR = new URL('../../migrations/', import.meta.url);

const FILE_NAME = /^(\d{4})_([a-z0-9_]+)\.sql$/;

export interface Migration {
  version: string;
  name: string;
  sql: string;
  checksum: string;
}

export async function readMigrations(dir: URL = MIGRATIONS_DIR): Promise<Migration[]> {
  const migrations: Migration[] = [];
  for (const file of (await readdir(dir)).filter((name) => name.endsWith('.sql')).sort()) {
    const match = FILE_NAME.exec(file);
    if (match === null) throw new Error(`migration file names look like 0001_name.sql: ${file}`);
    const [, version = '', name = ''] = match;
    if (migrations.some((migration) => migration.version === version)) throw new Error(`two migrations numbered ${version}`);
    const sql = await readFile(new URL(file, dir), 'utf8');
    migrations.push({ version, name, sql, checksum: sha256Hex(sql) });
  }
  return migrations;
}

const LOCK = `SELECT pg_advisory_xact_lock(hashtext('focus-api/migrations'))`;

/** Applies every pending migration. Returns the versions applied by this call. */
export async function migrate(db: Db, logger: Logger, dir: URL = MIGRATIONS_DIR): Promise<string[]> {
  const migrations = await readMigrations(dir);
  await db.tx(async (tx) => {
    await tx.query(LOCK);
    await tx.exec(`CREATE TABLE IF NOT EXISTS schema_migrations (
      version text PRIMARY KEY,
      name text NOT NULL,
      checksum text NOT NULL,
      applied_at timestamptz NOT NULL DEFAULT now()
    )`);
  });

  const applied: string[] = [];
  for (const migration of migrations) {
    const ran = await db.tx(async (tx) => {
      await tx.query(LOCK);
      const { rows } = await tx.query<{ checksum: string }>('SELECT checksum FROM schema_migrations WHERE version = $1', [
        migration.version,
      ]);
      const existing = rows[0];
      if (existing !== undefined) {
        if (existing.checksum !== migration.checksum) {
          throw new Error(`migration ${migration.version}_${migration.name} was edited after it was applied`);
        }
        return false;
      }
      await tx.exec('SET LOCAL statement_timeout = 0'); // lift the pool's 15-second limit for DDL
      await tx.exec(migration.sql);
      await tx.query('INSERT INTO schema_migrations (version, name, checksum) VALUES ($1, $2, $3)', [
        migration.version,
        migration.name,
        migration.checksum,
      ]);
      return true;
    });
    if (ran) {
      applied.push(migration.version);
      logger.info({ migration: `${migration.version}_${migration.name}` }, 'migration applied');
    }
  }
  return applied;
}

/** Versions in `migrations/` that the database has not applied yet. */
export async function pendingMigrations(db: Db, dir: URL = MIGRATIONS_DIR): Promise<string[]> {
  const migrations = await readMigrations(dir);
  const { rows: table } = await db.query<{ present: boolean }>(
    `SELECT to_regclass('schema_migrations') IS NOT NULL AS present`,
  );
  if (table[0]?.present !== true) return migrations.map((migration) => migration.version);
  const { rows } = await db.query<{ version: string }>('SELECT version FROM schema_migrations');
  const done = new Set(rows.map((row) => row.version));
  return migrations.filter((migration) => !done.has(migration.version)).map((migration) => migration.version);
}
