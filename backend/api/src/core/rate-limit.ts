import type { FastifyRequest } from 'fastify';
import type { Deps } from '../deps.js';
import { ApiError } from './errors.js';
import { pseudonym } from './pseudonym.js';

export interface LimitRule {
  /** Names the limit, for example `email-start-email-15m`. Lowercase letters, digits, `.` and `-`. */
  name: string;
  /** What is counted: an email, device id, account id, session id or `req.ip`. Stored only as a keyed hash. */
  key: string;
  max: number;
  windowSeconds: number;
}

export interface LimitResult {
  allowed: boolean;
  count: number;
  /** Seconds until the window resets. */
  retryAfterSeconds: number;
}

const NAME = /^[a-z0-9.-]{1,64}$/;

/**
 * Counts one hit in a fixed window (aligned to multiples of `windowSeconds` since the Unix
 * epoch) with one atomic upsert on `rate_limits`, and reports whether it is within `max`.
 * Use this when an over-limit call must still answer normally (dropped email starts
 * still get their 202); otherwise use `limit`.
 */
export async function hitLimit(deps: Pick<Deps, 'db' | 'clock' | 'kms'>, rule: LimitRule): Promise<LimitResult> {
  if (!NAME.test(rule.name)) throw new TypeError(`bad rate limit name: ${rule.name}`);
  const now = deps.clock.now().getTime();
  const windowMs = rule.windowSeconds * 1000;
  const windowStart = new Date(Math.floor(now / windowMs) * windowMs);
  const windowEnd = new Date(windowStart.getTime() + windowMs);
  // GREATEST keeps two servers with slightly different clocks from resetting each other's window.
  const { rows } = await deps.db.query<{ count: number; expires_at: Date }>(
    `INSERT INTO rate_limits AS r (key, window_start, count, expires_at)
     VALUES ($1, $2, 1, $3)
     ON CONFLICT (key) DO UPDATE SET
       count = CASE WHEN r.window_start >= EXCLUDED.window_start THEN r.count + 1 ELSE 1 END,
       window_start = GREATEST(r.window_start, EXCLUDED.window_start),
       expires_at = GREATEST(r.expires_at, EXCLUDED.expires_at)
     RETURNING count, expires_at`,
    [`${rule.name}:${await pseudonym(deps.kms, rule.key)}`, windowStart, windowEnd],
  );
  const row = rows[0];
  if (row === undefined) throw new Error('rate limit upsert returned no row');
  return {
    allowed: row.count <= rule.max,
    count: row.count,
    retryAfterSeconds: Math.max(1, Math.ceil((row.expires_at.getTime() - now) / 1000)),
  };
}

/**
 * Counts a hit and throws RATE_LIMITED (429, `Retry-After`) when over the limit.
 *
 *   await limit(req, { name: 'refresh-1h', key: proof.deviceId, max: 60, windowSeconds: 3600 });
 */
export async function limit(request: FastifyRequest, rule: LimitRule): Promise<void> {
  const result = await hitLimit(request.server.deps, rule);
  if (!result.allowed) throw new ApiError('RATE_LIMITED', 429, {}, result.retryAfterSeconds);
}
