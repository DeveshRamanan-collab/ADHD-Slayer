import type { Logger } from 'pino';
import type { Config } from '../config.js';
import type { Clock } from './clock.js';
import { LocalKms } from './kms/local.js';
import type { Kms } from './kms/types.js';
import { OutboxMailer } from './mailer/outbox.js';
import type { Mailer } from './mailer/types.js';
import { LocalObjectStore } from './object-store/local.js';
import type { ObjectStore } from './object-store/types.js';
import type { Random } from './random.js';

export type { Clock } from './clock.js';
export type { HmacKeyName, Kms, SigningKeyName } from './kms/types.js';
export type { MailMessage, Mailer } from './mailer/types.js';
export type { BucketName, ObjectHead, ObjectStore, ObjectSummary, PresignedGet, PresignedPut } from './object-store/types.js';
export type { Random } from './random.js';

export interface Adapters {
  objectStore: ObjectStore;
  kms: Kms;
  mailer: Mailer;
}

interface AdapterContext {
  logger: Logger;
  clock: Clock;
  random: Random;
}

/** `FOCUS_ENV=local` gets file-backed stand-ins with no AWS calls; staging and production get AWS. */
export async function createAdapters(config: Config, context: AdapterContext): Promise<Adapters> {
  if (config.env === 'local') return createLocalAdapters(config, context);
  // Loaded on demand so local runs and tests never load the AWS SDK.
  const [{ S3ObjectStore }, { AwsKms }, { SesMailer }] = await Promise.all([
    import('./object-store/s3.js'),
    import('./kms/aws.js'),
    import('./mailer/ses.js'),
  ]);
  return {
    objectStore: new S3ObjectStore(config.buckets, config.awsRegion, context.clock),
    kms: new AwsKms(config, context.random),
    mailer: new SesMailer(config.ses, config.awsRegion),
  };
}

export async function createLocalAdapters(config: Config, context: AdapterContext): Promise<Adapters> {
  return {
    objectStore: await LocalObjectStore.open(config.localDataDir, config.publicApiUrl, context.clock),
    kms: await LocalKms.open(config.localDataDir, context.random),
    mailer: new OutboxMailer(config.localDataDir, config.ses, context.logger, context.clock, context.random),
  };
}
