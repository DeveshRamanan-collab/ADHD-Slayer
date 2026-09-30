import { createHmac, randomBytes } from 'node:crypto';
import { mkdir, readdir, readFile, rename, rm, stat, writeFile } from 'node:fs/promises';
import { dirname, join, relative, sep } from 'node:path';
import { fromBase64Url, safeEqual, sha256, toBase64Url } from '../../core/encoding.js';
import type { Clock } from '../clock.js';
import {
  isSafeObjectKey,
  type BucketName,
  type ObjectHead,
  type ObjectStore,
  type ObjectSummary,
  type PresignedGet,
  type PresignedPut,
} from './types.js';

const BUCKETS: readonly BucketName[] = ['snapshots', 'diagnostics', 'content'];

/** Stands in for the SSE-KMS key id header value in local mode. */
export const LOCAL_SSE_KEY_ID = 'local';

export type PresignCheck = 'ok' | 'expired' | 'badSignature';

/**
 * Files under `LOCAL_DATA_DIR/objects/<bucket>/<key>`. Presigned URLs point at the
 * local-only routes `PUT|GET /v1/_local/objects/<bucket>/<key>?exp=<unix>&sig=<hmac>`
 * (CONTRACT.md "Snapshots"). The HMAC covers the method, path, expiry and, for PUT, every
 * header the client must send, so a changed checksum or length is refused like S3 would.
 */
export class LocalObjectStore implements ObjectStore {
  private constructor(
    private readonly root: string,
    private readonly tmpDir: string,
    private readonly publicApiUrl: string,
    private readonly secret: Buffer,
    private readonly clock: Clock,
  ) {}

  static async open(dataDir: string, publicApiUrl: string, clock: Clock): Promise<LocalObjectStore> {
    const root = join(dataDir, 'objects');
    const tmpDir = join(dataDir, 'objects-tmp');
    await mkdir(root, { recursive: true });
    await mkdir(tmpDir, { recursive: true });
    return new LocalObjectStore(root, tmpDir, publicApiUrl, await loadOrCreateSecret(join(dataDir, 'object-store.key')), clock);
  }

  presignPut(
    bucket: BucketName,
    key: string,
    input: { sizeBytes: number; sha256: Buffer; expiresInSeconds: number },
  ): Promise<PresignedPut> {
    this.path(bucket, key);
    const headers = {
      'Content-Type': 'application/octet-stream',
      'Content-Length': String(input.sizeBytes),
      'x-amz-checksum-sha256': input.sha256.toString('base64'),
      'x-amz-server-side-encryption': 'aws:kms',
      'x-amz-server-side-encryption-aws-kms-key-id': LOCAL_SSE_KEY_ID,
    };
    const exp = this.expiry(input.expiresInSeconds);
    const sig = this.signature(putCanonical(bucket, key, exp, headers));
    return Promise.resolve({ url: this.url(bucket, key, exp, sig), headers, expiresAt: new Date(exp * 1000) });
  }

  presignGet(bucket: BucketName, key: string, input: { expiresInSeconds: number }): Promise<PresignedGet> {
    this.path(bucket, key);
    const exp = this.expiry(input.expiresInSeconds);
    const sig = this.signature(['GET', `${bucket}/${key}`, String(exp)].join('\n'));
    return Promise.resolve({ url: this.url(bucket, key, exp, sig), expiresAt: new Date(exp * 1000) });
  }

  /** Checks a presigned PUT against the headers actually sent. */
  checkPresignedPut(
    bucket: BucketName,
    key: string,
    query: { exp?: string; sig?: string },
    headers: Record<string, string | undefined>,
  ): PresignCheck {
    const sent = {
      'Content-Type': headers['content-type'] ?? '',
      'Content-Length': headers['content-length'] ?? '',
      'x-amz-checksum-sha256': headers['x-amz-checksum-sha256'] ?? '',
      'x-amz-server-side-encryption': headers['x-amz-server-side-encryption'] ?? '',
      'x-amz-server-side-encryption-aws-kms-key-id': headers['x-amz-server-side-encryption-aws-kms-key-id'] ?? '',
    };
    return this.check(query, (exp) => putCanonical(bucket, key, exp, sent));
  }

  checkPresignedGet(bucket: BucketName, key: string, query: { exp?: string; sig?: string }): PresignCheck {
    return this.check(query, (exp) => ['GET', `${bucket}/${key}`, String(exp)].join('\n'));
  }

  async head(bucket: BucketName, key: string): Promise<ObjectHead | null> {
    const body = await this.getObject(bucket, key);
    return body === null ? null : { size: body.length, sha256: sha256(body) };
  }

  async getObject(bucket: BucketName, key: string): Promise<Buffer | null> {
    try {
      return await readFile(this.path(bucket, key));
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === 'ENOENT') return null;
      throw error;
    }
  }

  async putObject(bucket: BucketName, key: string, body: Buffer): Promise<void> {
    const target = this.path(bucket, key);
    await mkdir(dirname(target), { recursive: true });
    // Write then rename, so a reader never sees half an object.
    const temporary = join(this.tmpDir, randomBytes(8).toString('hex'));
    await writeFile(temporary, body);
    await rename(temporary, target);
  }

  async delete(bucket: BucketName, key: string): Promise<void> {
    await rm(this.path(bucket, key), { force: true });
  }

  async deletePrefix(bucket: BucketName, prefix: string): Promise<number> {
    const objects = await this.list(bucket, prefix);
    for (const object of objects) await this.delete(bucket, object.key);
    return objects.length;
  }

  async list(bucket: BucketName, prefix: string): Promise<ObjectSummary[]> {
    const bucketRoot = join(this.root, bucketDir(bucket));
    let entries;
    try {
      entries = await readdir(bucketRoot, { recursive: true, withFileTypes: true });
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === 'ENOENT') return [];
      throw error;
    }
    const keys = entries
      .filter((entry) => entry.isFile())
      .map((entry) => relative(bucketRoot, join(entry.parentPath, entry.name)).split(sep).join('/'))
      .filter((key) => key.startsWith(prefix))
      .sort();
    return Promise.all(
      keys.map(async (key) => ({ key, size: (await stat(join(bucketRoot, ...key.split('/')))).size })),
    );
  }

  private path(bucket: BucketName, key: string): string {
    if (!isSafeObjectKey(key)) throw new TypeError('unsafe object key');
    return join(this.root, bucketDir(bucket), ...key.split('/'));
  }

  private expiry(expiresInSeconds: number): number {
    return Math.floor(this.clock.now().getTime() / 1000) + expiresInSeconds;
  }

  private url(bucket: BucketName, key: string, exp: number, sig: string): string {
    return `${this.publicApiUrl}/v1/_local/objects/${bucket}/${key}?exp=${String(exp)}&sig=${sig}`;
  }

  private signature(canonical: string): string {
    return toBase64Url(createHmac('sha256', this.secret).update(canonical).digest());
  }

  private check(query: { exp?: string; sig?: string }, canonical: (exp: number) => string): PresignCheck {
    if (query.exp === undefined || query.sig === undefined || !/^\d{1,12}$/.test(query.exp)) return 'badSignature';
    const given = fromBase64Url(query.sig);
    const expected = Buffer.from(this.signature(canonical(Number(query.exp))), 'base64url');
    if (given === null || !safeEqual(given, expected)) return 'badSignature';
    return Number(query.exp) * 1000 < this.clock.now().getTime() ? 'expired' : 'ok';
  }
}

export function isBucketName(value: string): value is BucketName {
  return (BUCKETS as readonly string[]).includes(value);
}

function bucketDir(bucket: BucketName): string {
  if (!isBucketName(bucket)) throw new TypeError('unknown bucket');
  return bucket;
}

function putCanonical(bucket: BucketName, key: string, exp: number, headers: Record<string, string>): string {
  return [
    'PUT',
    `${bucket}/${key}`,
    String(exp),
    headers['Content-Type'],
    headers['Content-Length'],
    headers['x-amz-checksum-sha256'],
    headers['x-amz-server-side-encryption'],
    headers['x-amz-server-side-encryption-aws-kms-key-id'],
  ].join('\n');
}

async function loadOrCreateSecret(path: string): Promise<Buffer> {
  try {
    return Buffer.from(await readFile(path, 'utf8'), 'base64');
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== 'ENOENT') throw error;
  }
  const secret = randomBytes(32);
  try {
    await writeFile(path, secret.toString('base64'), { mode: 0o600, flag: 'wx' });
    return secret;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== 'EEXIST') throw error;
    return Buffer.from(await readFile(path, 'utf8'), 'base64');
  }
}
