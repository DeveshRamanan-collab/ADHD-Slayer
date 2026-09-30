import type { Queryable } from '../db/index.js';

export type AuditActor = 'system' | 'account' | 'staff';

export interface AuditEntry {
  actor: AuditActor;
  accountId: string | null;
  /** Dotted verb, for example `session.refresh_reuse`, `device.removed`, `recovery.read`. */
  action: string;
  /** What was acted on, as an id (never an email or name). */
  target?: string | null;
  requestId?: string | null;
  /** Never personal data. */
  details?: Record<string, unknown>;
  /** Defaults to the database's now(). */
  at?: Date;
}

/**
 * Appends to `audit_log` (kept 24 months): sign-ins, refresh reuse, device changes, key
 * epochs, recovery slot reads, deletions, staff access. Pass the transaction client so the
 * entry commits with the change it records.
 */
export async function audit(db: Queryable, entry: AuditEntry): Promise<void> {
  await db.query(
    `INSERT INTO audit_log (at, actor, account_id, action, target, request_id, details)
     VALUES (COALESCE($1::timestamptz, now()), $2, $3, $4, $5, $6, $7::jsonb)`,
    [
      entry.at ?? null,
      entry.actor,
      entry.accountId,
      entry.action,
      entry.target ?? null,
      entry.requestId ?? null,
      JSON.stringify(entry.details ?? {}),
    ],
  );
}
