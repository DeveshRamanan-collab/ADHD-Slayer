/** HMAC_256 keys: `KMS_MAGIC_LINK_HMAC_KEY_ID` and `KMS_RECEIPT_HMAC_KEY_ID`. */
export type HmacKeyName = 'magicLink' | 'receipt';

/** ECC_NIST_P256 signing key `KMS_CONFIG_SIGNING_KEY_ID`, used by publish-config and publish-copy. */
export type SigningKeyName = 'configSigning';

/** AWS KMS accepts at most 4 KiB per GenerateMac message; the local KMS enforces the same. */
export const KMS_MAX_MESSAGE_BYTES = 4096;

export interface Kms {
  /**
   * Encrypts a value for an `_enc` column with the app-envelope key (format in envelope.ts).
   * `context` binds the ciphertext to where it is stored, for example
   * `support_requests.message_enc:<id>`; decrypting needs the same context.
   */
  encrypt(plaintext: Uint8Array | string, context: string): Promise<Buffer>;
  decrypt(sealed: Uint8Array, context: string): Promise<Buffer>;
  /** HMAC-SHA256 (32 bytes). */
  hmac(key: HmacKeyName, message: Uint8Array | string): Promise<Buffer>;
  /** Constant-time check of an HMAC-SHA256. */
  verifyHmac(key: HmacKeyName, message: Uint8Array | string, mac: Uint8Array): Promise<boolean>;
  /** ES256 over the message: raw 64-byte `r || s` of ECDSA P-256 over SHA-256(message). */
  sign(key: SigningKeyName, message: Uint8Array | string): Promise<Buffer>;
  /** The signing key's public key as its 65-byte X9.63 point (what the app bundles). */
  publicKey(key: SigningKeyName): Promise<Buffer>;
}

export function messageBytes(message: Uint8Array | string): Buffer {
  const bytes = typeof message === 'string' ? Buffer.from(message, 'utf8') : Buffer.from(message);
  if (bytes.length > KMS_MAX_MESSAGE_BYTES) throw new RangeError('KMS messages are limited to 4096 bytes');
  return bytes;
}
