import * as ecs from 'aws-cdk-lib/aws-ecs';
import { Naming, type EnvironmentConfig } from './config';
import type { DataStack } from './stacks/data-stack';
import type { KeysStack } from './stacks/keys-stack';
import type { SecretsStack } from './stacks/secrets-stack';

export interface TaskEnvironmentProps {
  readonly config: EnvironmentConfig;
  readonly keys: KeysStack;
  readonly data: DataStack;
  readonly secrets: SecretsStack;
}

export interface TaskEnvironment {
  readonly environment: Record<string, string>;
  readonly secrets: Record<string, ecs.Secret>;
}

/**
 * Environment variables named in backend/CONTRACT.md, "Environment variables (API and jobs)".
 * Not set in AWS: DATABASE_URL (the PG* variables are used instead) and LOCAL_DATA_DIR (local only).
 * ALERT_TOPIC_ARN is added for jobs only (Jobs stack).
 */
export const CONTRACT_ENVIRONMENT = [
  'FOCUS_ENV',
  'PORT',
  'LOG_LEVEL',
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
  'APPLE_APP_APPLE_ID',
  'APPLE_SIWA_KEY_ID',
  'APPSTORE_ISSUER_ID',
  'APPSTORE_KEY_ID',
  'APPSTORE_ENVIRONMENT',
  'GOOGLE_IOS_CLIENT_ID',
  'HELPDESK_WEBHOOK_URL',
  'PGSSLMODE',
] as const;

/** ECS secrets: the RDS secret's fields and the three pasted keys. */
export const CONTRACT_SECRETS = [
  'PGHOST',
  'PGPORT',
  'PGDATABASE',
  'PGUSER',
  'PGPASSWORD',
  'APPLE_SIWA_PRIVATE_KEY',
  'APPSTORE_PRIVATE_KEY',
  'HELPDESK_API_KEY',
] as const;

export function buildTaskEnvironment(props: TaskEnvironmentProps): TaskEnvironment {
  const { config, keys, data, secrets } = props;
  const n = new Naming(config);

  const environment: Record<(typeof CONTRACT_ENVIRONMENT)[number], string> & Record<string, string> = {
    FOCUS_ENV: config.envName,
    PORT: String(config.api.containerPort),
    LOG_LEVEL: config.api.logLevel,
    PUBLIC_API_URL: n.publicApiUrl,
    PUBLIC_WEB_URL: n.publicWebUrl,
    AWS_REGION: config.primaryRegion,
    SNAPSHOTS_BUCKET: data.snapshots.bucketName,
    DIAGNOSTICS_BUCKET: data.diagnostics.bucketName,
    CONTENT_BUCKET: data.content.bucketName,
    KMS_ENVELOPE_KEY_ID: keys.appEnvelope.keyArn,
    KMS_MAGIC_LINK_HMAC_KEY_ID: keys.magicLinkHmac.keyArn,
    KMS_RECEIPT_HMAC_KEY_ID: keys.receiptHmac.keyArn,
    KMS_CONFIG_SIGNING_KEY_ID: keys.configSigning.keyArn,
    SES_FROM: `Focus <${n.signInAddress}>`,
    SES_CONFIGURATION_SET: n.sesConfigurationSetName,
    SUPPORT_FROM: `Focus support <${n.supportAddress}>`,
    APPLE_TEAM_ID: config.apple.teamId,
    APPLE_BUNDLE_ID: config.apple.bundleId,
    APPLE_APP_APPLE_ID: config.apple.appAppleId,
    APPLE_SIWA_KEY_ID: config.apple.siwaKeyId,
    APPSTORE_ISSUER_ID: config.apple.appStoreIssuerId,
    APPSTORE_KEY_ID: config.apple.appStoreKeyId,
    APPSTORE_ENVIRONMENT: config.apple.appStoreEnvironment,
    GOOGLE_IOS_CLIENT_ID: config.googleIosClientId,
    HELPDESK_WEBHOOK_URL: config.helpdeskWebhookUrl,
    PGSSLMODE: 'require',
    // Not in CONTRACT.md, harmless if unused:
    NODE_ENV: 'production',
    // The snapshots bucket's KMS key, for the x-amz-server-side-encryption-aws-kms-key-id upload
    // header (CONTRACT.md, Snapshots). The bucket policy refuses uploads naming any other key.
    SNAPSHOTS_KMS_KEY_ID: keys.s3.keyArn,
  };

  const db = data.databaseSecret;
  const taskSecrets: Record<(typeof CONTRACT_SECRETS)[number], ecs.Secret> = {
    PGHOST: ecs.Secret.fromSecretsManager(db, 'host'),
    PGPORT: ecs.Secret.fromSecretsManager(db, 'port'),
    PGDATABASE: ecs.Secret.fromSecretsManager(db, 'dbname'),
    PGUSER: ecs.Secret.fromSecretsManager(db, 'username'),
    PGPASSWORD: ecs.Secret.fromSecretsManager(db, 'password'),
    APPLE_SIWA_PRIVATE_KEY: ecs.Secret.fromSecretsManager(secrets.secrets.appleSiwaKey),
    APPSTORE_PRIVATE_KEY: ecs.Secret.fromSecretsManager(secrets.secrets.appStoreKey),
    HELPDESK_API_KEY: ecs.Secret.fromSecretsManager(secrets.secrets.helpdeskApiKey),
  };

  return { environment, secrets: taskSecrets };
}
