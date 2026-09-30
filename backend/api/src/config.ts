import { resolve } from 'node:path';
import { z } from 'zod';

/**
 * Environment configuration, validated once at startup. Variable names are fixed by
 * backend/CONTRACT.md. `FOCUS_ENV=local` fills every other value with a default so
 * `npm run dev` needs no setup; staging and production fail fast on anything missing.
 */

export type FocusEnv = 'local' | 'staging' | 'production';
export type LogLevel = 'fatal' | 'error' | 'warn' | 'info' | 'debug' | 'trace' | 'silent';
export type AppStoreEnvironment = 'Production' | 'Sandbox' | 'Xcode' | 'LocalTesting';

export interface Config {
  env: FocusEnv;
  port: number;
  logLevel: LogLevel;
  /** No trailing slash and no `/v1`, for example `https://api.focus.adhdslayer.au`. */
  publicApiUrl: string;
  /** Email links point here. */
  publicWebUrl: string;
  /** `postgres://...`, `pglite://memory` or `pglite://<dir>`; undefined means the standard `PG*` variables. */
  databaseUrl: string | undefined;
  awsRegion: string;
  buckets: { snapshots: string; diagnostics: string; content: string };
  /** Absolute path; local adapters write here. */
  localDataDir: string;
  kms: {
    envelopeKeyId: string;
    magicLinkHmacKeyId: string;
    receiptHmacKeyId: string;
    configSigningKeyId: string;
  };
  ses: { from: string; configurationSet: string; supportFrom: string };
  apple: {
    teamId: string;
    bundleId: string;
    /** Numeric App Store id; required in production only. */
    appAppleId: string | undefined;
    siwaKeyId: string;
    siwaPrivateKey: string;
  };
  appStore: { issuerId: string; keyId: string; privateKey: string; environment: AppStoreEnvironment };
  google: { iosClientId: string };
  /** Both undefined keeps support requests in the database only. */
  helpdesk: { webhookUrl: string | undefined; apiKey: string | undefined };
  alertTopicArn: string | undefined;
}

export class ConfigError extends Error {
  override name = 'ConfigError';
}

const emptyToUndefined = (value: unknown): unknown =>
  typeof value === 'string' && value.trim() === '' ? undefined : value;

const text = z.preprocess(emptyToUndefined, z.string().optional());

const baseUrl = z.preprocess(
  emptyToUndefined,
  z
    .url({ protocol: /^https?$/ })
    .refine((value) => !value.endsWith('/') && !value.endsWith('/v1'), 'no trailing slash and no /v1')
    .optional(),
);

const EnvSchema = z.object({
  FOCUS_ENV: z.enum(['local', 'staging', 'production']),
  PORT: z.preprocess(emptyToUndefined, z.coerce.number().int().min(1).max(65_535).optional()),
  LOG_LEVEL: z.preprocess(
    emptyToUndefined,
    z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).optional(),
  ),
  PUBLIC_API_URL: baseUrl,
  PUBLIC_WEB_URL: baseUrl,
  DATABASE_URL: z.preprocess(
    emptyToUndefined,
    z
      .string()
      .regex(/^(postgres(ql)?|pglite):\/\//, 'must start with postgres://, postgresql:// or pglite://')
      .optional(),
  ),
  PGHOST: text,
  AWS_REGION: text,
  SNAPSHOTS_BUCKET: text,
  DIAGNOSTICS_BUCKET: text,
  CONTENT_BUCKET: text,
  LOCAL_DATA_DIR: text,
  KMS_ENVELOPE_KEY_ID: text,
  KMS_MAGIC_LINK_HMAC_KEY_ID: text,
  KMS_RECEIPT_HMAC_KEY_ID: text,
  KMS_CONFIG_SIGNING_KEY_ID: text,
  SES_FROM: text,
  SES_CONFIGURATION_SET: text,
  SUPPORT_FROM: text,
  APPLE_TEAM_ID: text,
  APPLE_BUNDLE_ID: text,
  APPLE_APP_APPLE_ID: z.preprocess(emptyToUndefined, z.string().regex(/^\d+$/, 'must be numeric').optional()),
  APPLE_SIWA_KEY_ID: text,
  APPLE_SIWA_PRIVATE_KEY: text,
  APPSTORE_ISSUER_ID: text,
  APPSTORE_KEY_ID: text,
  APPSTORE_PRIVATE_KEY: text,
  APPSTORE_ENVIRONMENT: z.preprocess(
    emptyToUndefined,
    z.enum(['Production', 'Sandbox', 'Xcode', 'LocalTesting']).optional(),
  ),
  GOOGLE_IOS_CLIENT_ID: text,
  HELPDESK_WEBHOOK_URL: z.preprocess(emptyToUndefined, z.url({ protocol: /^https$/ }).optional()),
  HELPDESK_API_KEY: text,
  ALERT_TOPIC_ARN: text,
});

type Env = z.infer<typeof EnvSchema>;

/** Required in staging and production. `APPLE_APP_APPLE_ID` is checked separately (production only). */
const REQUIRED_WHEN_DEPLOYED = [
  'PUBLIC_API_URL',
  'PUBLIC_WEB_URL',
  'AWS_REGION',
  'SNAPSHOTS_BUCKET',
  'DIAGNOSTICS_BUCKET',
  'CONTENT_BUCKET',
  'KMS_ENVELOPE_KEY_ID',
  'KMS_MAGIC_LINK_HMAC_KEY_ID',
  'KMS_RECEIPT_HMAC_KEY_ID',
  'KMS_CONFIG_SIGNING_KEY_ID',
  'SES_FROM',
  'SES_CONFIGURATION_SET',
  'SUPPORT_FROM',
  'APPLE_TEAM_ID',
  'APPLE_BUNDLE_ID',
  'APPLE_SIWA_KEY_ID',
  'APPLE_SIWA_PRIVATE_KEY',
  'APPSTORE_ISSUER_ID',
  'APPSTORE_KEY_ID',
  'APPSTORE_PRIVATE_KEY',
  'APPSTORE_ENVIRONMENT',
  'GOOGLE_IOS_CLIENT_ID',
  'ALERT_TOPIC_ARN',
] as const satisfies readonly (keyof Env)[];

/**
 * Reads and validates the environment. Throws ConfigError naming every missing or invalid
 * variable (never their values, which may be secrets).
 */
export function loadConfig(source: NodeJS.ProcessEnv = process.env): Config {
  const parsed = EnvSchema.safeParse(source);
  if (!parsed.success) {
    const problems = parsed.error.issues.map((issue) => `${issue.path.join('.')} (${issue.message})`);
    throw new ConfigError(`Invalid configuration: ${problems.join('; ')}`);
  }
  const env = parsed.data;
  const local = env.FOCUS_ENV === 'local';

  if (!local) {
    const missing: string[] = REQUIRED_WHEN_DEPLOYED.filter((name) => env[name] === undefined);
    if (env.FOCUS_ENV === 'production' && env.APPLE_APP_APPLE_ID === undefined) missing.push('APPLE_APP_APPLE_ID');
    if (env.DATABASE_URL === undefined && env.PGHOST === undefined) missing.push('DATABASE_URL or PGHOST');
    if (env.HELPDESK_WEBHOOK_URL !== undefined && env.HELPDESK_API_KEY === undefined) missing.push('HELPDESK_API_KEY');
    if (missing.length > 0) throw new ConfigError(`Missing configuration for ${env.FOCUS_ENV}: ${missing.join(', ')}`);
    if (env.DATABASE_URL?.startsWith('pglite://')) {
      throw new ConfigError('DATABASE_URL may use pglite:// only when FOCUS_ENV=local');
    }
    if (env.PUBLIC_API_URL?.startsWith('http://') || env.PUBLIC_WEB_URL?.startsWith('http://')) {
      throw new ConfigError('PUBLIC_API_URL and PUBLIC_WEB_URL must use https outside local');
    }
  }

  const port = env.PORT ?? 8080;
  const localDataDir = resolve(env.LOCAL_DATA_DIR ?? '.data');
  // In local mode every remaining value falls back to a harmless default; deployed
  // environments reached this point only if the value exists, so the defaults never apply there.
  const or = (value: string | undefined, localDefault: string): string => value ?? localDefault;

  return {
    env: env.FOCUS_ENV,
    port,
    logLevel: env.LOG_LEVEL ?? (local ? 'debug' : 'info'),
    publicApiUrl: or(env.PUBLIC_API_URL, `http://localhost:${String(port)}`),
    publicWebUrl: or(env.PUBLIC_WEB_URL, 'http://localhost:8081'),
    databaseUrl: env.DATABASE_URL ?? (local ? `pglite://${localDataDir}/pglite` : undefined),
    awsRegion: or(env.AWS_REGION, 'ap-southeast-2'),
    buckets: {
      snapshots: or(env.SNAPSHOTS_BUCKET, 'focus-local-snapshots'),
      diagnostics: or(env.DIAGNOSTICS_BUCKET, 'focus-local-diagnostics'),
      content: or(env.CONTENT_BUCKET, 'focus-local-content'),
    },
    localDataDir,
    kms: {
      envelopeKeyId: or(env.KMS_ENVELOPE_KEY_ID, 'local-envelope'),
      magicLinkHmacKeyId: or(env.KMS_MAGIC_LINK_HMAC_KEY_ID, 'local-magic-link-hmac'),
      receiptHmacKeyId: or(env.KMS_RECEIPT_HMAC_KEY_ID, 'local-receipt-hmac'),
      configSigningKeyId: or(env.KMS_CONFIG_SIGNING_KEY_ID, 'local-config-signing'),
    },
    ses: {
      from: or(env.SES_FROM, 'Focus <signin@focus.adhdslayer.au>'),
      configurationSet: or(env.SES_CONFIGURATION_SET, 'local'),
      supportFrom: or(env.SUPPORT_FROM, 'Focus support <support@focus.adhdslayer.au>'),
    },
    apple: {
      teamId: or(env.APPLE_TEAM_ID, ''),
      bundleId: or(env.APPLE_BUNDLE_ID, 'au.adhdslayer.focus'),
      appAppleId: env.APPLE_APP_APPLE_ID,
      siwaKeyId: or(env.APPLE_SIWA_KEY_ID, ''),
      siwaPrivateKey: or(env.APPLE_SIWA_PRIVATE_KEY, ''),
    },
    appStore: {
      issuerId: or(env.APPSTORE_ISSUER_ID, ''),
      keyId: or(env.APPSTORE_KEY_ID, ''),
      privateKey: or(env.APPSTORE_PRIVATE_KEY, ''),
      environment: env.APPSTORE_ENVIRONMENT ?? 'LocalTesting',
    },
    google: { iosClientId: or(env.GOOGLE_IOS_CLIENT_ID, '') },
    helpdesk: { webhookUrl: env.HELPDESK_WEBHOOK_URL, apiKey: env.HELPDESK_API_KEY },
    alertTopicArn: env.ALERT_TOPIC_ARN,
  };
}
