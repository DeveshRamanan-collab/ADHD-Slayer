import {
  DeleteObjectsCommand,
  GetBucketEncryptionCommand,
  GetObjectCommand,
  HeadObjectCommand,
  ListObjectsV2Command,
  ListObjectVersionsCommand,
  NoSuchKey,
  NotFound,
  PutObjectCommand,
  S3Client,
  type ObjectIdentifier,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import type { Config } from '../../config.js';
import { sha256 } from '../../core/encoding.js';
import type { Clock } from '../clock.js';
import type { BucketName, ObjectHead, ObjectStore, ObjectSummary, PresignedGet, PresignedPut } from './types.js';

/**
 * S3 in `AWS_REGION`. Buckets are versioned with SSE-KMS by default (backend/infra).
 *
 * The SSE-KMS key id that presigned uploads must name is read from each bucket's default
 * encryption (GetBucketEncryption, once per process), because CONTRACT.md has no variable
 * for it. The task role therefore needs `s3:GetEncryptionConfiguration` on the buckets.
 */
export class S3ObjectStore implements ObjectStore {
  private readonly client: S3Client;
  private readonly kmsKeyIds = new Map<BucketName, Promise<string>>();

  constructor(
    private readonly buckets: Config['buckets'],
    region: string,
    private readonly clock: Clock,
    client?: S3Client,
  ) {
    // WHEN_REQUIRED stops the SDK adding its own CRC32 checksum, which would break presigned
    // uploads; every upload names its SHA-256 explicitly instead.
    this.client =
      client ??
      new S3Client({ region, requestChecksumCalculation: 'WHEN_REQUIRED', responseChecksumValidation: 'WHEN_REQUIRED' });
  }

  async presignPut(
    bucket: BucketName,
    key: string,
    input: { sizeBytes: number; sha256: Buffer; expiresInSeconds: number },
  ): Promise<PresignedPut> {
    const kmsKeyId = await this.kmsKeyId(bucket);
    const checksum = input.sha256.toString('base64');
    const command = new PutObjectCommand({
      Bucket: this.buckets[bucket],
      Key: key,
      ContentType: 'application/octet-stream',
      ContentLength: input.sizeBytes,
      ChecksumSHA256: checksum,
      ServerSideEncryption: 'aws:kms',
      SSEKMSKeyId: kmsKeyId,
    });
    const url = await getSignedUrl(this.client, command, {
      expiresIn: input.expiresInSeconds,
      // Sign these as headers (not query parameters) so S3 refuses any other type, length or checksum.
      signableHeaders: new Set(['content-type', 'content-length']),
      unhoistableHeaders: new Set(['x-amz-checksum-sha256']),
    });
    return {
      url,
      headers: {
        'Content-Type': 'application/octet-stream',
        'Content-Length': String(input.sizeBytes),
        'x-amz-checksum-sha256': checksum,
        'x-amz-server-side-encryption': 'aws:kms',
        'x-amz-server-side-encryption-aws-kms-key-id': kmsKeyId,
      },
      expiresAt: this.expiresAt(input.expiresInSeconds),
    };
  }

  async presignGet(bucket: BucketName, key: string, input: { expiresInSeconds: number }): Promise<PresignedGet> {
    const command = new GetObjectCommand({ Bucket: this.buckets[bucket], Key: key });
    const url = await getSignedUrl(this.client, command, { expiresIn: input.expiresInSeconds });
    return { url, expiresAt: this.expiresAt(input.expiresInSeconds) };
  }

  async head(bucket: BucketName, key: string): Promise<ObjectHead | null> {
    try {
      const out = await this.client.send(
        new HeadObjectCommand({ Bucket: this.buckets[bucket], Key: key, ChecksumMode: 'ENABLED' }),
      );
      // Multipart uploads report a checksum of part checksums (`...-N`); that is not the object's SHA-256.
      const checksum = out.ChecksumSHA256;
      return {
        size: out.ContentLength ?? 0,
        sha256: checksum === undefined || checksum.includes('-') ? null : Buffer.from(checksum, 'base64'),
      };
    } catch (error) {
      if (error instanceof NotFound) return null;
      throw error;
    }
  }

  async getObject(bucket: BucketName, key: string): Promise<Buffer | null> {
    try {
      const out = await this.client.send(new GetObjectCommand({ Bucket: this.buckets[bucket], Key: key }));
      if (out.Body === undefined) return Buffer.alloc(0);
      return Buffer.from(await out.Body.transformToByteArray());
    } catch (error) {
      if (error instanceof NoSuchKey) return null;
      throw error;
    }
  }

  async putObject(bucket: BucketName, key: string, body: Buffer, input: { contentType?: string } = {}): Promise<void> {
    await this.client.send(
      new PutObjectCommand({
        Bucket: this.buckets[bucket],
        Key: key,
        Body: body,
        ContentType: input.contentType ?? 'application/octet-stream',
        ChecksumSHA256: sha256(body).toString('base64'),
        ServerSideEncryption: 'aws:kms',
        SSEKMSKeyId: await this.kmsKeyId(bucket),
      }),
    );
  }

  async delete(bucket: BucketName, key: string): Promise<void> {
    await this.deleteVersions(bucket, key, (candidate) => candidate === key);
  }

  deletePrefix(bucket: BucketName, prefix: string): Promise<number> {
    return this.deleteVersions(bucket, prefix, () => true);
  }

  async list(bucket: BucketName, prefix: string): Promise<ObjectSummary[]> {
    const objects: ObjectSummary[] = [];
    let token: string | undefined;
    do {
      const page = await this.client.send(
        new ListObjectsV2Command({ Bucket: this.buckets[bucket], Prefix: prefix, ContinuationToken: token }),
      );
      for (const object of page.Contents ?? []) {
        if (object.Key !== undefined) objects.push({ key: object.Key, size: object.Size ?? 0 });
      }
      token = page.IsTruncated === true ? page.NextContinuationToken : undefined;
    } while (token !== undefined);
    return objects.sort((a, b) => (a.key < b.key ? -1 : a.key > b.key ? 1 : 0));
  }

  /** Lists every version and delete marker under `prefix` and deletes those whose key matches. */
  private async deleteVersions(bucket: BucketName, prefix: string, matches: (key: string) => boolean): Promise<number> {
    let deleted = 0;
    let keyMarker: string | undefined;
    let versionIdMarker: string | undefined;
    do {
      const page = await this.client.send(
        new ListObjectVersionsCommand({
          Bucket: this.buckets[bucket],
          Prefix: prefix,
          KeyMarker: keyMarker,
          VersionIdMarker: versionIdMarker,
        }),
      );
      const objects: ObjectIdentifier[] = [...(page.Versions ?? []), ...(page.DeleteMarkers ?? [])]
        .filter((version) => version.Key !== undefined && matches(version.Key))
        .map((version) => ({ Key: version.Key, VersionId: version.VersionId }));
      if (objects.length > 0) {
        const out = await this.client.send(
          new DeleteObjectsCommand({ Bucket: this.buckets[bucket], Delete: { Objects: objects, Quiet: true } }),
        );
        if ((out.Errors?.length ?? 0) > 0) throw new Error('S3 refused to delete some object versions');
        deleted += objects.length;
      }
      const more = page.IsTruncated === true;
      keyMarker = more ? page.NextKeyMarker : undefined;
      versionIdMarker = more ? page.NextVersionIdMarker : undefined;
    } while (keyMarker !== undefined);
    return deleted;
  }

  private kmsKeyId(bucket: BucketName): Promise<string> {
    let cached = this.kmsKeyIds.get(bucket);
    if (cached === undefined) {
      cached = this.client
        .send(new GetBucketEncryptionCommand({ Bucket: this.buckets[bucket] }))
        .then((out) => {
          const rule = out.ServerSideEncryptionConfiguration?.Rules?.find(
            (candidate) => candidate.ApplyServerSideEncryptionByDefault?.SSEAlgorithm === 'aws:kms',
          );
          const keyId = rule?.ApplyServerSideEncryptionByDefault?.KMSMasterKeyID;
          if (keyId === undefined) throw new Error('bucket has no default SSE-KMS key');
          return keyId;
        });
      this.kmsKeyIds.set(bucket, cached);
      cached.catch(() => this.kmsKeyIds.delete(bucket));
    }
    return cached;
  }

  private expiresAt(expiresInSeconds: number): Date {
    return new Date(this.clock.now().getTime() + expiresInSeconds * 1000);
  }
}
