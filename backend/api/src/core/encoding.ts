import { createHash, timingSafeEqual } from 'node:crypto';

const BASE64URL = /^[A-Za-z0-9_-]*$/;

/** Unpadded base64url, the wire format for binary fields (CONTRACT.md "General"). */
export function toBase64Url(bytes: Uint8Array): string {
  return Buffer.from(bytes).toString('base64url');
}

/**
 * Strict unpadded base64url decode. Returns null for padding, foreign characters or
 * non-canonical input, so a value that decodes always re-encodes to the same string.
 */
export function fromBase64Url(text: string): Buffer | null {
  if (!BASE64URL.test(text) || text.length % 4 === 1) return null;
  const bytes = Buffer.from(text, 'base64url');
  return toBase64Url(bytes) === text ? bytes : null;
}

export function sha256(data: Uint8Array | string): Buffer {
  return createHash('sha256').update(data).digest();
}

/** Lowercase hex SHA-256, used for token hashes and the proof body hash. */
export function sha256Hex(data: Uint8Array | string): string {
  return createHash('sha256').update(data).digest('hex');
}

/** Constant-time comparison that also accepts buffers of different lengths. */
export function safeEqual(a: Uint8Array, b: Uint8Array): boolean {
  return a.length === b.length && timingSafeEqual(a, b);
}
