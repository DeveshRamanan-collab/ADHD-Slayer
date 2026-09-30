import { createCipheriv, createDecipheriv } from 'node:crypto';
import type { Random } from '../random.js';

/**
 * Envelope encryption for `_enc` columns, shared by the AWS and local KMS.
 *
 * Each process asks the key service for one AES-256 data key (KMS GenerateDataKey) and
 * reuses it, so encrypting never calls KMS per request. Every value carries the wrapped
 * data key, so any process can decrypt it (one KMS Decrypt per distinct data key, cached).
 *
 * Stored bytes (bytea):
 *
 * | Bytes | Field |
 * |---|---|
 * | 1 | format version, 0x01 |
 * | 2 | length L of the wrapped data key, unsigned big-endian |
 * | L | wrapped data key (the KMS CiphertextBlob, or the local wrap) |
 * | 12 | AES-256-GCM nonce |
 * | n | ciphertext |
 * | 16 | GCM tag |
 *
 * The GCM additional data is the UTF-8 of `focus.envelope.v1:<context>`.
 */

export interface DataKeySource {
  /** A fresh 32-byte data key and its wrapped (encrypted) form. */
  generate(): Promise<{ plaintext: Buffer; wrapped: Buffer }>;
  unwrap(wrapped: Buffer): Promise<Buffer>;
}

const VERSION = 0x01;
const NONCE_BYTES = 12;
const TAG_BYTES = 16;
const MAX_CACHED_KEYS = 64;

export class EnvelopeCipher {
  private current: Promise<{ plaintext: Buffer; wrapped: Buffer }> | undefined;
  private readonly unwrapped = new Map<string, Promise<Buffer>>();

  constructor(
    private readonly source: DataKeySource,
    private readonly random: Random,
  ) {}

  async encrypt(plaintext: Uint8Array | string, context: string): Promise<Buffer> {
    const dataKey = await this.dataKey();
    const nonce = this.random.bytes(NONCE_BYTES);
    const cipher = createCipheriv('aes-256-gcm', dataKey.plaintext, nonce);
    cipher.setAAD(aad(context));
    const body = Buffer.concat([cipher.update(plaintext), cipher.final()]);
    const header = Buffer.alloc(3);
    header.writeUInt8(VERSION, 0);
    header.writeUInt16BE(dataKey.wrapped.length, 1);
    return Buffer.concat([header, dataKey.wrapped, nonce, body, cipher.getAuthTag()]);
  }

  async decrypt(sealed: Uint8Array, context: string): Promise<Buffer> {
    const bytes = Buffer.from(sealed);
    if (bytes.length < 3 || bytes.readUInt8(0) !== VERSION) throw new Error('unknown envelope format');
    const wrappedLength = bytes.readUInt16BE(1);
    const bodyStart = 3 + wrappedLength + NONCE_BYTES;
    if (bytes.length < bodyStart + TAG_BYTES) throw new Error('truncated envelope');
    const wrapped = bytes.subarray(3, 3 + wrappedLength);
    const nonce = bytes.subarray(3 + wrappedLength, bodyStart);
    const key = await this.unwrap(wrapped);
    const decipher = createDecipheriv('aes-256-gcm', key, nonce);
    decipher.setAAD(aad(context));
    decipher.setAuthTag(bytes.subarray(bytes.length - TAG_BYTES));
    return Buffer.concat([decipher.update(bytes.subarray(bodyStart, bytes.length - TAG_BYTES)), decipher.final()]);
  }

  private dataKey(): Promise<{ plaintext: Buffer; wrapped: Buffer }> {
    if (this.current === undefined) {
      const pending = this.source.generate();
      this.current = pending;
      // A failed call must not poison the cache; the next encrypt tries again.
      pending.catch(() => {
        if (this.current === pending) this.current = undefined;
      });
    }
    return this.current;
  }

  private async unwrap(wrapped: Buffer): Promise<Buffer> {
    const current = await this.current?.catch(() => undefined);
    if (current?.wrapped.equals(wrapped)) return current.plaintext;
    const id = wrapped.toString('base64');
    let key = this.unwrapped.get(id);
    if (key === undefined) {
      key = this.source.unwrap(Buffer.from(wrapped));
      if (this.unwrapped.size >= MAX_CACHED_KEYS) {
        const oldest = this.unwrapped.keys().next().value;
        if (oldest !== undefined) this.unwrapped.delete(oldest);
      }
      this.unwrapped.set(id, key);
      key.catch(() => this.unwrapped.delete(id));
    }
    return key;
  }
}

function aad(context: string): Buffer {
  return Buffer.from(`focus.envelope.v1:${context}`, 'utf8');
}
