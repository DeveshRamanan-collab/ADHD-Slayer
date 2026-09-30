import {
  DecryptCommand,
  GenerateDataKeyCommand,
  GenerateMacCommand,
  GetPublicKeyCommand,
  KMSClient,
  KMSInvalidMacException,
  SignCommand,
  VerifyMacCommand,
} from '@aws-sdk/client-kms';
import { createPublicKey } from 'node:crypto';
import type { Config } from '../../config.js';
import { sha256 } from '../../core/encoding.js';
import { derToRawSignature, x963FromKey } from '../../core/p256.js';
import type { Random } from '../random.js';
import { EnvelopeCipher } from './envelope.js';
import { messageBytes, type HmacKeyName, type Kms, type SigningKeyName } from './types.js';

/** Encryption context on every data key, so a wrapped key is useless outside this purpose. */
const ENVELOPE_CONTEXT = { purpose: 'focus.envelope.v1' };

/** AWS KMS in `AWS_REGION`, with the key ids from CONTRACT.md. */
export class AwsKms implements Kms {
  private readonly client: KMSClient;
  private readonly envelope: EnvelopeCipher;
  private readonly hmacKeyIds: Record<HmacKeyName, string>;
  private readonly signingKeyIds: Record<SigningKeyName, string>;
  private readonly publicKeys = new Map<SigningKeyName, Promise<Buffer>>();

  constructor(config: Pick<Config, 'awsRegion' | 'kms'>, random: Random, client?: KMSClient) {
    this.client = client ?? new KMSClient({ region: config.awsRegion });
    const envelopeKeyId = config.kms.envelopeKeyId;
    this.envelope = new EnvelopeCipher(
      {
        generate: async () => {
          const out = await this.client.send(
            new GenerateDataKeyCommand({ KeyId: envelopeKeyId, KeySpec: 'AES_256', EncryptionContext: ENVELOPE_CONTEXT }),
          );
          if (out.Plaintext === undefined || out.CiphertextBlob === undefined) throw new Error('KMS returned no data key');
          return { plaintext: Buffer.from(out.Plaintext), wrapped: Buffer.from(out.CiphertextBlob) };
        },
        unwrap: async (wrapped) => {
          const out = await this.client.send(
            new DecryptCommand({ KeyId: envelopeKeyId, CiphertextBlob: wrapped, EncryptionContext: ENVELOPE_CONTEXT }),
          );
          if (out.Plaintext === undefined) throw new Error('KMS returned no plaintext');
          return Buffer.from(out.Plaintext);
        },
      },
      random,
    );
    this.hmacKeyIds = { magicLink: config.kms.magicLinkHmacKeyId, receipt: config.kms.receiptHmacKeyId };
    this.signingKeyIds = { configSigning: config.kms.configSigningKeyId };
  }

  encrypt(plaintext: Uint8Array | string, context: string): Promise<Buffer> {
    return this.envelope.encrypt(plaintext, context);
  }

  decrypt(sealed: Uint8Array, context: string): Promise<Buffer> {
    return this.envelope.decrypt(sealed, context);
  }

  async hmac(key: HmacKeyName, message: Uint8Array | string): Promise<Buffer> {
    const out = await this.client.send(
      new GenerateMacCommand({ KeyId: this.hmacKeyIds[key], Message: messageBytes(message), MacAlgorithm: 'HMAC_SHA_256' }),
    );
    if (out.Mac === undefined) throw new Error('KMS returned no MAC');
    return Buffer.from(out.Mac);
  }

  async verifyHmac(key: HmacKeyName, message: Uint8Array | string, mac: Uint8Array): Promise<boolean> {
    try {
      const out = await this.client.send(
        new VerifyMacCommand({
          KeyId: this.hmacKeyIds[key],
          Message: messageBytes(message),
          Mac: mac,
          MacAlgorithm: 'HMAC_SHA_256',
        }),
      );
      return out.MacValid === true;
    } catch (error) {
      if (error instanceof KMSInvalidMacException) return false;
      throw error;
    }
  }

  async sign(key: SigningKeyName, message: Uint8Array | string): Promise<Buffer> {
    // Sign the SHA-256 digest (MessageType DIGEST): RAW messages are capped at 4 KiB and
    // copy decks are larger. The signature is the same ES256 value either way.
    const out = await this.client.send(
      new SignCommand({
        KeyId: this.signingKeyIds[key],
        Message: sha256(message),
        MessageType: 'DIGEST',
        SigningAlgorithm: 'ECDSA_SHA_256',
      }),
    );
    if (out.Signature === undefined) throw new Error('KMS returned no signature');
    return derToRawSignature(out.Signature);
  }

  publicKey(key: SigningKeyName): Promise<Buffer> {
    let cached = this.publicKeys.get(key);
    if (cached === undefined) {
      cached = this.client.send(new GetPublicKeyCommand({ KeyId: this.signingKeyIds[key] })).then((out) => {
        if (out.PublicKey === undefined) throw new Error('KMS returned no public key');
        return x963FromKey(createPublicKey({ key: Buffer.from(out.PublicKey), format: 'der', type: 'spki' }));
      });
      this.publicKeys.set(key, cached);
      cached.catch(() => this.publicKeys.delete(key));
    }
    return cached;
  }
}
