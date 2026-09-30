import type { Deps } from '../deps.js';

/**
 * One retention rule from 03-data-model.md "Retention". The hourly `retention` job runs
 * the core sweeps below, then every module's `export const sweeps`. A sweep must be
 * idempotent and safe to run twice at once; it returns how many rows it removed.
 */
export interface Sweep {
  /** Lowercase with dashes, for the log line, for example `magic-links`. */
  name: string;
  run(deps: Deps): Promise<number>;
}

const DAY_MS = 24 * 60 * 60 * 1000;

function monthsBefore(date: Date, months: number): Date {
  const shifted = new Date(date);
  shifted.setUTCMonth(shifted.getUTCMonth() - months);
  return shifted;
}

/** Sweeps for the tables the core owns. */
export const coreSweeps: readonly Sweep[] = [
  {
    // Idempotency keys: 24 hours (expires_at is set to the end of that).
    name: 'idempotency-keys',
    run: async ({ db, clock }) =>
      (await db.query('DELETE FROM idempotency_keys WHERE expires_at <= $1', [clock.now()])).rowCount,
  },
  {
    // Rate limit rows: gone once their window ends, well inside the 48 hours allowed.
    name: 'rate-limits',
    run: async ({ db, clock }) => (await db.query('DELETE FROM rate_limits WHERE expires_at <= $1', [clock.now()])).rowCount,
  },
  {
    name: 'device-proof-replays',
    run: async ({ db, clock }) =>
      (await db.query('DELETE FROM device_proof_replays WHERE expires_at <= $1', [clock.now()])).rowCount,
  },
  {
    // Sessions: 30 days after they ended (revoked, or no longer refreshable).
    name: 'sessions',
    run: async ({ db, clock }) =>
      (
        await db.query('DELETE FROM sessions WHERE LEAST(revoked_at, idle_expires_at, absolute_expires_at) <= $1', [
          new Date(clock.now().getTime() - 30 * DAY_MS),
        ])
      ).rowCount,
  },
  {
    name: 'audit-log',
    run: async ({ db, clock }) =>
      (await db.query('DELETE FROM audit_log WHERE at <= $1', [monthsBefore(clock.now(), 24)])).rowCount,
  },
];
