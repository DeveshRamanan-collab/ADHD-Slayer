import {
  createCipheriv,
  createDecipheriv,
  createHmac,
  createPrivateKey,
  createPublicKey,
  generateKeyPairSync,
  randomBytes,
  sign as ecdsaSign,
  type KeyObject,
} from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { safeEqual } from '../../core/encoding.js';
import { x963FromKey } from '../../core/p256.js';
import type { Random } from '../random.js';
import { EnvelopeCipher } from './envelope.js';
import { messageBytes, type HmacKeyName, type Kms, type SigningKeyName } from './types.js';

/** `LOCAL_DATA_DIR/keys.json`: made once, then reused so local data stays readable across restarts. */
interface KeyFile {
  version: 1;
  /** AES-256 key that wraps envelope data keys (stands in for the app-envelope KMS key). */
  envelope: string;
  magicLink: string;
  receipt: string;
  /** PKCS#8 DER of the P-256 config signing key. */
  configSigning: string;
}

/** A local stand-in for AWS KMS with the same interface and byte formats. No network calls. */
export class LocalKms implements Kms {
  private readonly envelope: EnvelopeCipher;
  private readonly hmacKeys: Record<HmacKeyName, Buffer>;
  private readonly signingKey: KeyObject;

  private constructor(keys: KeyFile, random: Random) {
    const master = Buffer.from(keys.envelope, 'base64');
    this.envelope = new EnvelopeCipher(
      {
        generate: () => {
          const plaintext = random.bytes(32);
          return Promise.resolve({ plaintext, wrapped: wrap(master, plaintext, random) });
        },
        unwrap: (wrapped) => Promise.resolve(unwrap(master, wrapped)),
      },
      random,
    );
    this.hmacKeys = {
      magicLink: Buffer.from(keys.magicLink, 'base64'),
      receipt: Buffer.from(keys.receipt, 'base64'),
    };
    this.signingKey = createPrivateKey({ key: Buffer.from(keys.configSigning, 'base64'), format: 'der', type: 'pkcs8' });
  }

  static async open(dataDir: string, random: Random): Promise<LocalKms> {
    return new LocalKms(await loadOrCreateKeys(join(dataDir, 'keys.json')), random);
  }

  encrypt(plaintext: Uint8Array | string, context: string): Promise<Buffer> {
    return this.envelope.encrypt(plaintext, context);
  }

  decrypt(sealed: Uint8Array, context: string): Promise<Buffer> {
    return this.envelope.decrypt(sealed, context);
  }

  hmac(key: HmacKeyName, message: Uint8Array | string): Promise<Buffer> {
    return Promise.resolve(createHmac('sha256', this.hmacKeys[key]).update(messageBytes(message)).digest());
  }

  async verifyHmac(key: HmacKeyName, message: Uint8Array | string, mac: Uint8Array): Promise<boolean> {
    return safeEqual(await this.hmac(key, message), mac);
  }

  sign(_key: SigningKeyName, message: Uint8Array | string): Promise<Buffer> {
    const data = typeof message === 'string' ? Buffer.from(message, 'utf8') : message;
    return Promise.resolve(ecdsaSign('sha256', data, { key: this.signingKey, dsaEncoding: 'ieee-p1363' }));
  }

  publicKey(_key: SigningKeyName): Promise<Buffer> {
    return Promise.resolve(x963FromKey(createPublicKey(this.signingKey)));
  }
}

async function loadOrCreateKeys(path: string): Promise<KeyFile> {
  try {
    return JSON.parse(await readFile(path, 'utf8')) as KeyFile;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== 'ENOENT') throw error;
  }
  const { privateKey } = generateKeyPairSync('ec', { namedCurve: 'P-256' });
  const keys: KeyFile = {
    version: 1,
    envelope: randomBytes(32).toString('base64'),
    magicLink: randomBytes(32).toString('base64'),
    receipt: randomBytes(32).toString('base64'),
    configSigning: privateKey.export({ format: 'der', type: 'pkcs8' }).toString('base64'),
  };
  await mkdir(join(path, '..'), { recursive: true });
  try {
    // `wx` fails if another process created the file first; then use theirs.
    await writeFile(path, `${JSON.stringify(keys, null, 2)}\n`, { mode: 0o600, flag: 'wx' });
    return keys;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== 'EEXIST') throw error;
    return JSON.parse(await readFile(path, 'utf8')) as KeyFile;
  }
}

/** Local wrap of a data key: nonce (12) || AES-256-GCM ciphertext (32) || tag (16). */
function wrap(master: Buffer, dataKey: Buffer, random: Random): Buffer {
  const nonce = random.bytes(12);
  const cipher = createCipheriv('aes-256-gcm', master, nonce);
  const body = Buffer.concat([cipher.update(dataKey), cipher.final()]);
  return Buffer.concat([nonce, body, cipher.getAuthTag()]);
}

function unwrap(master: Buffer, wrapped: Buffer): Buffer {
  const decipher = createDecipheriv('aes-256-gcm', master, wrapped.subarray(0, 12));
  decipher.setAuthTag(wrapped.subarray(wrapped.length - 16));
  return Buffer.concat([decipher.update(wrapped.subarray(12, wrapped.length - 16)), decipher.final()]);
}
