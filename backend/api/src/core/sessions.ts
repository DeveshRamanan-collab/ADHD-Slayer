import { createCipheriv, createDecipheriv, hkdfSync } from 'node:crypto';
import type { Clock, Random } from '../adapters/index.js';
import type { Db, Queryable } from '../db/index.js';
import { audit } from './audit.js';
import { fromBase64Url, sha256Hex, toBase64Url } from './encoding.js';
import { ApiError } from './errors.js';
import { uuidv7 } from './ids.js';
import type { SessionOutput } from './schemas.js';

/**
 * Session tokens (02-backend.md "Sessions and devices", CONTRACT.md "Tokens"): opaque
 * 32-byte tokens, base64url, stored only as SHA-256 hex of the token string.
 */

const MINUTE = 60_000;
const DAY = 24 * 60 * MINUTE;
export const ACCESS_TOKEN_TTL_MS = 60 * MINUTE;
/** Refresh ends after 90 days unused... */
export const REFRESH_IDLE_TTL_MS = 90 * DAY;
/** ...or 365 days after sign-in. */
export const REFRESH_ABSOLUTE_TTL_MS = 365 * DAY;
/** An exact retry of a refresh within this window gets the same pair back. */
export const REFRESH_RETRY_GRACE_MS = 30_000;

const TOKEN = /^[A-Za-z0-9_-]{43}$/;

export function newToken(random: Random): string {
  return toBase64Url(random.bytes(32));
}

/** What the database stores for a token. */
export function hashToken(token: string): string {
  return sha256Hex(token);
}

export function isTokenShaped(token: string): boolean {
  return TOKEN.test(token);
}

export interface IssuedSession {
  sessionId: string;
  session: SessionOutput;
}

/**
 * Starts a session for a device at sign-in. Run it in the sign-in transaction, after the
 * account and device rows exist. The caller should first end the device's earlier sessions
 * with `revokeSessions(tx, deps, { deviceId }, 'signed_in_again')`.
 */
export async function issueSession(
  db: Queryable,
  deps: { clock: Clock; random: Random },
  input: { accountId: string; deviceId: string },
): Promise<IssuedSession> {
  const now = deps.clock.now();
  const sessionId = uuidv7(now.getTime());
  const accessToken = newToken(deps.random);
  const refreshToken = newToken(deps.random);
  const absoluteExpiresAt = new Date(now.getTime() + REFRESH_ABSOLUTE_TTL_MS);
  const accessExpiresAt = new Date(now.getTime() + ACCESS_TOKEN_TTL_MS);
  const idleExpiresAt = new Date(now.getTime() + REFRESH_IDLE_TTL_MS);
  await db.query(
    `INSERT INTO sessions (id, account_id, device_id, access_hash, access_expires_at, refresh_hash,
                           idle_expires_at, absolute_expires_at, created_at, last_used_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $9)`,
    [
      sessionId,
      input.accountId,
      input.deviceId,
      hashToken(accessToken),
      accessExpiresAt,
      hashToken(refreshToken),
      idleExpiresAt,
      absoluteExpiresAt,
      now,
    ],
  );
  return {
    sessionId,
    session: {
      accessToken,
      accessExpiresAt: accessExpiresAt.toISOString(),
      refreshToken,
      refreshExpiresAt: idleExpiresAt.toISOString(),
    },
  };
}

interface RotationRow {
  id: string;
  account_id: string;
  device_id: string;
  refresh_hash: string;
  rotated_at: Date | null;
  grace_pair_sealed: Buffer | null;
  access_expires_at: Date;
  idle_expires_at: Date;
  absolute_expires_at: Date;
  revoked_at: Date | null;
  account_status: string;
}

export interface RotatedSession {
  sessionId: string;
  accountId: string;
  session: SessionOutput;
}

/**
 * `POST /auth/refresh`: swaps a refresh token for a new pair. `deviceId` is the device
 * whose proof signed the request; it must own the session.
 *
 * - The current refresh token rotates: new access and refresh tokens, idle expiry renewed.
 * - The previous refresh token within 30 seconds of its rotation (a retry after a lost
 *   reply) gets the same pair again.
 * - The previous refresh token after that is reuse: the session ends, it is audited, and
 *   the caller gets SESSION_REVOKED.
 *
 * Errors: SESSION_REVOKED (unknown, ended, expired or reused token), DEVICE_PROOF_INVALID
 * (the proof came from another device).
 */
export async function rotateSession(
  db: Db,
  deps: { clock: Clock; random: Random },
  input: { refreshToken: string; deviceId: string; requestId?: string },
): Promise<RotatedSession> {
  if (!isTokenShaped(input.refreshToken)) throw new ApiError('SESSION_REVOKED', 401);
  const presented = hashToken(input.refreshToken);
  const now = deps.clock.now();

  const outcome = await db.tx(async (tx): Promise<RotatedSession | 'reused' | 'refused'> => {
    const { rows } = await tx.query<RotationRow>(
      `SELECT s.id, s.account_id, s.device_id, s.refresh_hash, s.rotated_at, s.grace_pair_sealed,
              s.access_expires_at, s.idle_expires_at, s.absolute_expires_at, s.revoked_at,
              a.status AS account_status
         FROM sessions s JOIN accounts a ON a.id = s.account_id
        WHERE s.refresh_hash = $1 OR s.prev_refresh_hash = $1
          FOR UPDATE OF s`,
      [presented],
    );
    const row = rows[0];
    if (row === undefined) return 'refused';
    if (row.device_id !== input.deviceId) throw new ApiError('DEVICE_PROOF_INVALID', 401, { reason: 'invalid' });
    const expired = now >= row.idle_expires_at || now >= row.absolute_expires_at;
    if (row.revoked_at !== null || row.account_status !== 'active' || expired) return 'refused';

    if (row.refresh_hash !== presented) {
      const inGrace =
        row.rotated_at !== null && now.getTime() - row.rotated_at.getTime() <= REFRESH_RETRY_GRACE_MS;
      const pair = inGrace && row.grace_pair_sealed !== null ? openPair(input.refreshToken, row) : null;
      if (pair !== null) {
        return {
          sessionId: row.id,
          accountId: row.account_id,
          session: {
            ...pair,
            accessExpiresAt: row.access_expires_at.toISOString(),
            refreshExpiresAt: row.idle_expires_at.toISOString(),
          },
        };
      }
      await tx.query(`UPDATE sessions SET revoked_at = $2, revoke_reason = 'refresh_reuse' WHERE id = $1`, [row.id, now]);
      await audit(tx, {
        actor: 'system',
        accountId: row.account_id,
        action: 'session.refresh_reuse',
        target: row.id,
        requestId: input.requestId ?? null,
        at: now,
      });
      return 'reused';
    }

    const accessToken = newToken(deps.random);
    const refreshToken = newToken(deps.random);
    const cap = row.absolute_expires_at.getTime();
    const accessExpiresAt = new Date(Math.min(now.getTime() + ACCESS_TOKEN_TTL_MS, cap));
    const idleExpiresAt = new Date(Math.min(now.getTime() + REFRESH_IDLE_TTL_MS, cap));
    await tx.query(
      `UPDATE sessions
          SET access_hash = $2, access_expires_at = $3, refresh_hash = $4, prev_refresh_hash = $5,
              rotated_at = $6, grace_pair_sealed = $7, idle_expires_at = $8, last_used_at = $6
        WHERE id = $1`,
      [
        row.id,
        hashToken(accessToken),
        accessExpiresAt,
        hashToken(refreshToken),
        presented,
        now,
        sealPair(input.refreshToken, row.id, { accessToken, refreshToken }, deps.random),
        idleExpiresAt,
      ],
    );
    return {
      sessionId: row.id,
      accountId: row.account_id,
      session: {
        accessToken,
        accessExpiresAt: accessExpiresAt.toISOString(),
        refreshToken,
        refreshExpiresAt: idleExpiresAt.toISOString(),
      },
    };
  });

  // Thrown after the transaction so the reuse revocation and its audit entry commit.
  if (outcome === 'reused' || outcome === 'refused') throw new ApiError('SESSION_REVOKED', 401);
  return outcome;
}

export type SessionTarget = { sessionId: string } | { deviceId: string } | { accountId: string };

/**
 * Ends sessions: one (logout), every session of a device (device removed, signed in again)
 * or of an account (deletion). Returns how many were still open.
 */
export async function revokeSessions(
  db: Queryable,
  deps: { clock: Clock },
  target: SessionTarget,
  reason: string,
): Promise<number> {
  const [column, value] =
    'sessionId' in target
      ? ['id', target.sessionId]
      : 'deviceId' in target
        ? ['device_id', target.deviceId]
        : ['account_id', target.accountId];
  const { rowCount } = await db.query(
    `UPDATE sessions SET revoked_at = $2, revoke_reason = $3 WHERE ${column} = $1 AND revoked_at IS NULL`,
    [value, deps.clock.now(), reason],
  );
  return rowCount;
}

/**
 * The pair made at the last rotation, sealed with AES-256-GCM under a key derived from the
 * refresh token it replaced. The server never holds that token, so only a client retrying
 * with it can open the pair; the database alone reveals nothing.
 * Layout: nonce (12) || ciphertext of access (32) || refresh (32) || tag (16).
 */
function sealPair(
  previousRefreshToken: string,
  sessionId: string,
  pair: { accessToken: string; refreshToken: string },
  random: Random,
): Buffer {
  const nonce = random.bytes(12);
  const cipher = createCipheriv('aes-256-gcm', graceKey(previousRefreshToken, sessionId), nonce);
  cipher.setAAD(Buffer.from(sessionId, 'utf8'));
  const plaintext = Buffer.concat([tokenBytes(pair.accessToken), tokenBytes(pair.refreshToken)]);
  const body = Buffer.concat([cipher.update(plaintext), cipher.final()]);
  return Buffer.concat([nonce, body, cipher.getAuthTag()]);
}

function openPair(
  previousRefreshToken: string,
  row: { id: string; grace_pair_sealed: Buffer | null },
): { accessToken: string; refreshToken: string } | null {
  const sealed = row.grace_pair_sealed;
  if (sealed?.length !== 12 + 64 + 16) return null;
  try {
    const decipher = createDecipheriv('aes-256-gcm', graceKey(previousRefreshToken, row.id), sealed.subarray(0, 12));
    decipher.setAAD(Buffer.from(row.id, 'utf8'));
    decipher.setAuthTag(sealed.subarray(76));
    const plaintext = Buffer.concat([decipher.update(sealed.subarray(12, 76)), decipher.final()]);
    return { accessToken: toBase64Url(plaintext.subarray(0, 32)), refreshToken: toBase64Url(plaintext.subarray(32)) };
  } catch {
    return null;
  }
}

function graceKey(previousRefreshToken: string, sessionId: string): Buffer {
  return Buffer.from(hkdfSync('sha256', previousRefreshToken, sessionId, 'focus.session.grace.v1', 32));
}

function tokenBytes(token: string): Buffer {
  const bytes = fromBase64Url(token);
  if (bytes?.length !== 32) throw new TypeError('malformed token');
  return bytes;
}
