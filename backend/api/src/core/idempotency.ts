import type { FastifyReply, FastifyRequest } from 'fastify';
import { sha256Hex } from './encoding.js';
import { ApiError } from './errors.js';
import { errorFields } from './log-fields.js';
import { pseudonym } from './pseudonym.js';

/**
 * `Idempotency-Key` for routes declared `config: { idempotent: true }` (CONTRACT.md
 * "General"). The key is optional; when sent it is 1 to 128 visible ASCII characters.
 *
 * - Scope: the account (B, BP), else the proven device (P), else a keyed hash of the IP,
 *   plus the method and route template.
 * - The first request claims the key with a 60-second lease while it runs. A 2xx reply is
 *   stored for 24 hours; any other reply releases the key so the client can retry.
 * - Same key and same body bytes within 24 hours: the stored status and body are replayed
 *   and the handler does not run. Same key, other body: IDEMPOTENCY_MISMATCH (422).
 * - Same key while the first is still running: RATE_LIMITED with Retry-After 1.
 *
 * Idempotent routes must reply with JSON or an empty body.
 */

const KEY = /^[\x21-\x7e]{1,128}$/;
const STORE_MS = 24 * 60 * 60 * 1000;
const LEASE_MS = 60 * 1000;

interface StoredKey {
  body_hash: string;
  status: number | null;
  response: unknown;
}

/**
 * preHandler: claims the key, or answers from the stored reply. When it answers it returns
 * the reply: Fastify then waits for the response to finish before deciding whether to run
 * the handler (`reply.sent` turns true only after the onSend hooks), so a replay never runs it.
 */
export async function beginIdempotency(request: FastifyRequest, reply: FastifyReply): Promise<FastifyReply | undefined> {
  const header = request.headers['idempotency-key'];
  if (header === undefined) return undefined;
  if (typeof header !== 'string' || !KEY.test(header)) {
    throw new ApiError('VALIDATION_ERROR', 422, {
      in: 'headers',
      issues: [{ path: '/idempotency-key', message: 'must be 1 to 128 visible ASCII characters' }],
    });
  }
  const { db, clock, kms } = request.server.deps;
  const principal =
    request.auth !== null
      ? `account:${request.auth.accountId}`
      : request.deviceProof !== null
        ? `device:${request.deviceProof.deviceId}`
        : `ip:${await pseudonym(kms, request.ip)}`;
  const scope = `${principal}|${request.method} ${request.routeOptions.url ?? ''}`;
  const bodyHash = sha256Hex(request.rawBody ?? Buffer.alloc(0));
  const now = clock.now();

  // Claim a new key, or take over one whose reply expired or whose lease was abandoned.
  const claim = await db.query(
    `INSERT INTO idempotency_keys AS k (scope, key, body_hash, status, response, expires_at)
     VALUES ($1, $2, $3, NULL, NULL, $4)
     ON CONFLICT (scope, key) DO UPDATE
       SET body_hash = EXCLUDED.body_hash, status = NULL, response = NULL, expires_at = EXCLUDED.expires_at
       WHERE k.expires_at <= $5`,
    [scope, header, bodyHash, new Date(now.getTime() + LEASE_MS), now],
  );
  if (claim.rowCount === 1) {
    request.idempotency = { scope, key: header };
    return undefined;
  }

  const { rows } = await db.query<StoredKey>(
    'SELECT body_hash, status, response FROM idempotency_keys WHERE scope = $1 AND key = $2',
    [scope, header],
  );
  const stored = rows[0];
  if (stored !== undefined && stored.body_hash !== bodyHash) throw new ApiError('IDEMPOTENCY_MISMATCH', 422);
  if (stored === undefined || stored.status === null) {
    throw new ApiError('RATE_LIMITED', 429, { reason: 'idempotencyKeyInUse' }, 1);
  }
  reply.code(stored.status);
  if (stored.response === null) return reply.send();
  // A string body with a JSON content type is sent as-is, not re-serialized.
  return reply.type('application/json; charset=utf-8').send(JSON.stringify(stored.response));
}

/** onSend: stores a 2xx reply for replay, or releases the key. */
export async function finishIdempotency(request: FastifyRequest, reply: FastifyReply, payload: unknown): Promise<void> {
  const claim = request.idempotency;
  if (claim === null) return;
  request.idempotency = null;
  const { db, clock } = request.server.deps;
  try {
    if (reply.statusCode >= 200 && reply.statusCode < 300) {
      const body = typeof payload === 'string' && payload.length > 0 ? payload : null;
      await db.query(
        `UPDATE idempotency_keys SET status = $3, response = $4::jsonb, expires_at = $5
          WHERE scope = $1 AND key = $2`,
        [claim.scope, claim.key, reply.statusCode, body, new Date(clock.now().getTime() + STORE_MS)],
      );
    } else {
      await db.query('DELETE FROM idempotency_keys WHERE scope = $1 AND key = $2 AND status IS NULL', [
        claim.scope,
        claim.key,
      ]);
    }
  } catch (error) {
    // The reply still goes out; the lease lapses in 60 seconds and a retry runs again.
    request.log.error(errorFields(error), 'idempotency key update failed');
  }
}
