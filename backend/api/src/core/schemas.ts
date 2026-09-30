import { z } from 'zod';
import { fromBase64Url } from './encoding.js';
import { ERROR_CODES } from './errors.js';
import { isP256Point } from './p256.js';

/**
 * Shared wire schemas (02-backend.md "API", CONTRACT.md "Wire formats"). Request schemas may
 * transform (for example base64url to Buffer); response schemas must stay plain JSON types
 * because the serializer encodes through them, so handlers convert Dates with `iso()` and
 * bytes with `toBase64Url()`.
 */

/** UTC ISO 8601 with milliseconds and `Z`, the only time format on the wire. */
export const IsoDateTime = z.iso.datetime({ precision: 3 });

export function iso(date: Date): string {
  return date.toISOString();
}

/** Lowercase hyphenated UUID; uppercase input (iOS `uuidString`) is accepted and lowercased. */
export const Uuid = z.uuid().transform((value) => value.toLowerCase());

/** Unpadded base64url decoded to a Buffer, optionally of an exact length. */
export function base64UrlBytes(options: { length?: number; maxLength?: number } = {}) {
  const { length, maxLength } = options;
  const label = length === undefined ? 'base64url bytes' : `base64url of ${String(length)} bytes`;
  return z
    .string()
    .refine((value) => {
      const bytes = fromBase64Url(value);
      if (bytes === null) return false;
      if (length !== undefined && bytes.length !== length) return false;
      return maxLength === undefined || bytes.length <= maxLength;
    }, `must be unpadded ${label}`)
    .transform((value) => fromBase64Url(value) ?? Buffer.alloc(0));
}

/** P-256 public key as base64url of the 65-byte X9.63 point, checked to be on the curve. */
export const P256PublicKey = base64UrlBytes({ length: 65 }).refine(isP256Point, 'must be a P-256 public key');

/** The `device` object sent at sign-in (02-backend.md "API"). */
export const DeviceInput = z.object({
  deviceId: Uuid,
  model: z.string().min(1).max(64),
  osVersion: z.string().min(1).max(32),
  appVersion: z.string().min(1).max(32),
  signingKey: P256PublicKey,
  agreementKey: P256PublicKey,
});
export type DeviceInput = z.output<typeof DeviceInput>;

/** The `session` object returned by sign-in and refresh. */
export const SessionOutput = z.object({
  accessToken: z.string(),
  accessExpiresAt: IsoDateTime,
  refreshToken: z.string(),
  refreshExpiresAt: IsoDateTime,
});
export type SessionOutput = z.output<typeof SessionOutput>;

/** `{"error":{"code","message","details","retryAfterSeconds"?}}`, attached to every route's 4xx and 5xx. */
export const ErrorEnvelope = z.object({
  error: z.object({
    code: z.enum(ERROR_CODES),
    message: z.string(),
    details: z.record(z.string(), z.unknown()),
    retryAfterSeconds: z.number().int().positive().optional(),
  }),
});
z.globalRegistry.add(ErrorEnvelope, { id: 'Error' });
