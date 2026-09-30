import { createHmac } from 'node:crypto';
import type { Kms } from '../adapters/index.js';
import { toBase64Url } from './encoding.js';

const subkeys = new WeakMap<Kms, Promise<Buffer>>();

/**
 * Keyed hash for values that must not be stored in the clear, such as the email or IP a
 * rate limit is keyed by, or the IP scope of an unauthenticated Idempotency-Key. A plain
 * SHA-256 of an IPv4 address or email is easy to reverse by guessing; this one needs the
 * receipt HMAC key. The subkey is derived with one KMS call per process
 * (HMAC(receipt key, "focus.pseudonym.v1")), then hashing is local. 22 characters, 128 bits.
 */
export async function pseudonym(kms: Kms, value: string): Promise<string> {
  let subkey = subkeys.get(kms);
  if (subkey === undefined) {
    subkey = kms.hmac('receipt', 'focus.pseudonym.v1');
    subkeys.set(kms, subkey);
    subkey.catch(() => subkeys.delete(kms));
  }
  return toBase64Url(
    createHmac('sha256', await subkey)
      .update(value, 'utf8')
      .digest()
      .subarray(0, 16),
  );
}
