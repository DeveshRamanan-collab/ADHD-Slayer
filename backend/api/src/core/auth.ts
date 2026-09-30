import type { FastifyRequest } from 'fastify';
import { verifyDeviceProof } from './device-proof.js';
import { ApiError } from './errors.js';
import type { AuthContext, DeletingAccountMode, DeviceProofContext } from './request.js';
import { hashToken, isTokenShaped } from './sessions.js';

interface SessionRow {
  session_id: string;
  account_id: string;
  device_id: string;
  access_expires_at: Date;
  revoked_at: Date | null;
  account_status: 'active' | 'deleting';
  deletion_requested_at: Date | null;
  account_last_seen_on: string | null;
  device_found: boolean;
  device_revoked_at: Date | null;
  device_last_seen_on: string | null;
}

/**
 * Bearer check (auth B and BP, and B? when the header is present). Looks the access token
 * up by its SHA-256 hex, then checks the session, its device and its account. Sets and
 * returns `req.auth`, and records `last_seen_on` for the account and device once a day.
 *
 * Errors: UNAUTHENTICATED (no, malformed or unknown token), SESSION_REVOKED (ended session,
 * or account being deleted by default), DEVICE_REVOKED (the session's device was removed),
 * TOKEN_EXPIRED, and ACCOUNT_DELETION_PENDING when the route asks for it.
 */
export async function requireSession(
  request: FastifyRequest,
  options: { onDeletingAccount?: DeletingAccountMode } = {},
): Promise<AuthContext> {
  const { db, clock } = request.server.deps;
  const header = request.headers.authorization;
  const token = header === undefined ? undefined : /^Bearer (\S+)$/i.exec(header)?.[1];
  if (token === undefined || !isTokenShaped(token)) throw new ApiError('UNAUTHENTICATED', 401);

  const { rows } = await db.query<SessionRow>(
    `SELECT s.id AS session_id, s.account_id, s.device_id, s.access_expires_at, s.revoked_at,
            a.status AS account_status, a.deletion_requested_at, a.last_seen_on AS account_last_seen_on,
            d.id IS NOT NULL AS device_found, d.revoked_at AS device_revoked_at,
            d.last_seen_on AS device_last_seen_on
       FROM sessions s
       JOIN accounts a ON a.id = s.account_id
       LEFT JOIN devices d ON d.id = s.device_id AND d.account_id = s.account_id
      WHERE s.access_hash = $1`,
    [hashToken(token)],
  );
  const row = rows[0];
  if (row === undefined) throw new ApiError('UNAUTHENTICATED', 401);
  const auth: AuthContext = {
    accountId: row.account_id,
    sessionId: row.session_id,
    deviceId: row.device_id,
    accountStatus: row.account_status,
  };

  // Deletion ends every session at once, so this is checked before revocation.
  if (row.account_status === 'deleting') {
    const mode = options.onDeletingAccount ?? 'SESSION_REVOKED';
    if (mode === 'SESSION_REVOKED') throw new ApiError('SESSION_REVOKED', 401);
    if (mode === 'ACCOUNT_DELETION_PENDING') {
      throw new ApiError('ACCOUNT_DELETION_PENDING', 409, {
        deletionRequestedAt: row.deletion_requested_at?.toISOString() ?? null,
      });
    }
    request.auth = auth;
    return auth;
  }
  if (row.revoked_at !== null || !row.device_found) throw new ApiError('SESSION_REVOKED', 401);
  if (row.device_revoked_at !== null) throw new ApiError('DEVICE_REVOKED', 401);
  const now = clock.now();
  if (row.access_expires_at <= now) throw new ApiError('TOKEN_EXPIRED', 401);

  const today = now.toISOString().slice(0, 10);
  if (row.account_last_seen_on !== today) {
    await db.query(`UPDATE accounts SET last_seen_on = $2 WHERE id = $1 AND (last_seen_on IS NULL OR last_seen_on < $2)`, [
      row.account_id,
      today,
    ]);
  }
  if (row.device_last_seen_on !== today) {
    await db.query(`UPDATE devices SET last_seen_on = $2 WHERE id = $1 AND (last_seen_on IS NULL OR last_seen_on < $2)`, [
      row.device_id,
      today,
    ]);
  }
  request.auth = auth;
  return auth;
}

/**
 * Device proof check (auth P and BP). On BP routes, run after requireSession: the proof
 * must come from the session's own device. Sets and returns `req.deviceProof`.
 */
export async function requireDeviceProof(request: FastifyRequest): Promise<DeviceProofContext> {
  const { db, clock } = request.server.deps;
  const expect = request.auth === null ? undefined : { accountId: request.auth.accountId, deviceId: request.auth.deviceId };
  const proof = await verifyDeviceProof(
    db,
    clock,
    { method: request.method, url: request.url, headers: request.headers, body: request.rawBody },
    expect,
  );
  request.deviceProof = proof;
  return proof;
}
