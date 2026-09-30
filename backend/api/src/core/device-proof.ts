import { verify } from 'node:crypto';
import type { IncomingHttpHeaders } from 'node:http';
import type { Clock } from '../adapters/index.js';
import type { Queryable } from '../db/index.js';
import { fromBase64Url, sha256Hex } from './encoding.js';
import { ApiError } from './errors.js';
import { isUuid } from './ids.js';
import { lowS, p256PublicKey } from './p256.js';
import type { DeviceProofContext } from './request.js';

/** A proof's timestamp may be this far from the server clock either way (CONTRACT.md). */
export const PROOF_WINDOW_SECONDS = 300;
/** Seen signatures are kept this long; it covers the whole acceptance window. */
export const PROOF_REPLAY_SECONDS = 600;

/**
 * The signed text, four lines joined by `\n` with no trailing newline:
 * method in upper case, path with the query exactly as sent (including `/v1`), the
 * X-Device-Timestamp string, and lowercase hex SHA-256 of the exact body bytes.
 */
export function canonicalProofString(method: string, pathWithQuery: string, timestamp: string, body: Uint8Array | null): string {
  return [method.toUpperCase(), pathWithQuery, timestamp, sha256Hex(body ?? Buffer.alloc(0))].join('\n');
}

export interface ProofRequest {
  method: string;
  /** Path and query exactly as received. */
  url: string;
  headers: IncomingHttpHeaders;
  body: Buffer | null;
}

interface DeviceRow {
  account_id: string;
  signing_key: Buffer;
  revoked_at: Date | null;
}

/**
 * Checks the X-Device-Id, X-Device-Timestamp and X-Device-Signature headers. When `expect`
 * is given (BP routes) the device must be the session's own device on the session's account.
 * Consumes the proof: the same signature is refused for 10 minutes.
 *
 * Errors: DEVICE_PROOF_INVALID with `details.reason` of `missing`, `malformed`, `skewed`
 * (with `serverTime`), `invalid` or `replayed`; DEVICE_REVOKED for a removed device.
 */
export async function verifyDeviceProof(
  db: Queryable,
  clock: Clock,
  request: ProofRequest,
  expect?: { accountId: string; deviceId: string },
): Promise<DeviceProofContext> {
  const deviceHeader = request.headers['x-device-id'];
  const timestamp = request.headers['x-device-timestamp'];
  const signatureHeader = request.headers['x-device-signature'];
  if (deviceHeader === undefined || timestamp === undefined || signatureHeader === undefined) {
    throw invalid('missing');
  }
  if (typeof deviceHeader !== 'string' || typeof timestamp !== 'string' || typeof signatureHeader !== 'string') {
    throw invalid('malformed');
  }
  const signature = fromBase64Url(signatureHeader);
  if (!isUuid(deviceHeader) || !/^\d{1,12}$/.test(timestamp) || signature?.length !== 64) throw invalid('malformed');
  const deviceId = deviceHeader.toLowerCase();

  const now = clock.now();
  if (Math.abs(Math.floor(now.getTime() / 1000) - Number(timestamp)) > PROOF_WINDOW_SECONDS) {
    throw new ApiError('DEVICE_PROOF_INVALID', 401, { reason: 'skewed', serverTime: now.toISOString() });
  }

  const { rows } = await db.query<DeviceRow>('SELECT account_id, signing_key, revoked_at FROM devices WHERE id = $1', [
    deviceId,
  ]);
  const device = rows[0];
  const canonical = Buffer.from(canonicalProofString(request.method, request.url, timestamp, request.body), 'utf8');
  // Verify before revealing anything about the device, so only its holder learns it was removed.
  if (device === undefined || !signatureValid(device.signing_key, canonical, signature)) throw invalid('invalid');
  if (device.revoked_at !== null) throw new ApiError('DEVICE_REVOKED', 401);
  if (expect !== undefined && (device.account_id !== expect.accountId || deviceId !== expect.deviceId)) {
    throw invalid('invalid');
  }

  const stored = await db.query(
    `INSERT INTO device_proof_replays (device_id, signature, expires_at)
     VALUES ($1, $2, $3) ON CONFLICT DO NOTHING`,
    [deviceId, lowS(signature), new Date(now.getTime() + PROOF_REPLAY_SECONDS * 1000)],
  );
  if (stored.rowCount === 0) throw invalid('replayed');

  return { deviceId, accountId: device.account_id };
}

function signatureValid(signingKey: Buffer, canonical: Buffer, signature: Buffer): boolean {
  try {
    return verify('sha256', canonical, { key: p256PublicKey(signingKey), dsaEncoding: 'ieee-p1363' }, signature);
  } catch {
    return false;
  }
}

function invalid(reason: 'missing' | 'malformed' | 'invalid' | 'replayed'): ApiError<'DEVICE_PROOF_INVALID'> {
  return new ApiError('DEVICE_PROOF_INVALID', 401, { reason });
}
