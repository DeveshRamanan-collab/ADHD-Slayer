import { randomBytes } from 'node:crypto';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * UUIDv7 (RFC 9562): 48-bit Unix milliseconds, then random bits. Server-made ids are
 * UUIDv7 so they sort by creation time. Pass `clock.now().getTime()` so ids follow the
 * injected clock in tests.
 */
export function uuidv7(nowMs: number = Date.now(), random: (size: number) => Uint8Array = randomBytes): string {
  const bytes = Buffer.from(random(16));
  bytes.writeUIntBE(nowMs, 0, 6);
  bytes[6] = 0x70 | ((bytes[6] ?? 0) & 0x0f); // version 7
  bytes[8] = 0x80 | ((bytes[8] ?? 0) & 0x3f); // RFC 9562 variant
  const hex = bytes.toString('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

export function isUuid(value: string): boolean {
  return UUID.test(value);
}
