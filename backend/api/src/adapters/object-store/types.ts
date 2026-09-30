/** Logical buckets; `SNAPSHOTS_BUCKET`, `DIAGNOSTICS_BUCKET` and `CONTENT_BUCKET` name the real ones. */
export type BucketName = 'snapshots' | 'diagnostics' | 'content';

export interface PresignedPut {
  url: string;
  /** Headers the client must send exactly (CONTRACT.md "Snapshots"), including Content-Length. */
  headers: Record<string, string>;
  expiresAt: Date;
}

export interface PresignedGet {
  url: string;
  expiresAt: Date;
}

export interface ObjectHead {
  size: number;
  /** SHA-256 recorded at upload, or null when the object has no full-object checksum. */
  sha256: Buffer | null;
}

export interface ObjectSummary {
  key: string;
  size: number;
}

export interface ObjectStore {
  /**
   * A URL the client PUTs the object to. The upload must carry `sha256` as
   * `x-amz-checksum-sha256` and is stored with SSE-KMS; anything else is refused.
   */
  presignPut(
    bucket: BucketName,
    key: string,
    input: { sizeBytes: number; sha256: Buffer; expiresInSeconds: number },
  ): Promise<PresignedPut>;
  presignGet(bucket: BucketName, key: string, input: { expiresInSeconds: number }): Promise<PresignedGet>;
  /** Size and checksum of the current version, or null when missing. */
  head(bucket: BucketName, key: string): Promise<ObjectHead | null>;
  getObject(bucket: BucketName, key: string): Promise<Buffer | null>;
  putObject(bucket: BucketName, key: string, body: Buffer, input?: { contentType?: string }): Promise<void>;
  /** Deletes every version and delete marker of exactly this key. */
  delete(bucket: BucketName, key: string): Promise<void>;
  /**
   * Deletes every version and delete marker under a prefix, including keys whose current
   * version is already a delete marker (account deletion: `accounts/<accountId>/`).
   * Returns the number of versions removed.
   */
  deletePrefix(bucket: BucketName, prefix: string): Promise<number>;
  /** Current objects under a prefix, sorted by key. */
  list(bucket: BucketName, prefix: string): Promise<ObjectSummary[]>;
}

/** Object keys use S3's safe characters, `/`-separated, with no empty, `.` or `..` segment. */
export function isSafeObjectKey(key: string): boolean {
  if (key.length === 0 || key.length > 1024) return false;
  return key.split('/').every((segment) => /^[A-Za-z0-9!_.*'()-]+$/.test(segment) && segment !== '.' && segment !== '..');
}
