import { Duration, RemovalPolicy } from 'aws-cdk-lib/core';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as kms from 'aws-cdk-lib/aws-kms';
import type { Construct } from 'constructs';
import { FocusStack, type FocusStackProps } from '../focus-stack';

/**
 * KMS keys for one environment (02-backend.md, "Backups, keys and secrets").
 *
 * Key policies keep the default "this account's IAM decides" statement. Each task role then gets
 * an identity policy naming only the keys and actions it needs (see the Api and Jobs stacks), so
 * every use is visible in CloudTrail and no server key can open a person's data.
 */
export class KeysStack extends FocusStack {
  /** Encrypts the database storage and its snapshots. */
  readonly rds: kms.Key;
  /** SSE-KMS for snapshots, crash reports and content buckets. */
  readonly s3: kms.Key;
  /** Envelope encryption in the app: Apple refresh tokens, support text, reply emails. */
  readonly appEnvelope: kms.Key;
  /** HMAC-SHA256 over email link tokens and codes. */
  readonly magicLinkHmac: kms.Key;
  /** HMAC-SHA256 for deletion receipts (keyed hash of the account id). */
  readonly receiptHmac: kms.Key;
  /** ES256 signing of config and copy decks, used only by publish-config and publish-copy. */
  readonly configSigning: kms.Key;
  /** Encrypts the SNS topics (alerts, email events). Not in the spec's list: SNS needs a customer key so CloudWatch, EventBridge and SES can publish. */
  readonly messaging: kms.Key;

  constructor(scope: Construct, props: FocusStackProps) {
    super(scope, 'Keys', props);
    const n = this.naming;

    const symmetric = (id: string, name: string, description: string): kms.Key =>
      new kms.Key(this, id, {
        alias: n.kmsAlias(name),
        description,
        enableKeyRotation: true,
        rotationPeriod: Duration.days(365),
        pendingWindow: Duration.days(30),
        removalPolicy: RemovalPolicy.RETAIN,
      });

    const hmac = (id: string, name: string, description: string): kms.Key =>
      new kms.Key(this, id, {
        alias: n.kmsAlias(name),
        description,
        keySpec: kms.KeySpec.HMAC_256,
        keyUsage: kms.KeyUsage.GENERATE_VERIFY_MAC,
        pendingWindow: Duration.days(30),
        removalPolicy: RemovalPolicy.RETAIN,
      });

    this.rds = symmetric('Rds', 'rds', 'Focus database storage and snapshots');
    this.s3 = symmetric('S3', 's3', 'Focus S3 objects: encrypted snapshots, crash reports, signed content');
    this.appEnvelope = symmetric('AppEnvelope', 'app-envelope', 'Focus application envelope encryption: Apple refresh tokens, support text, reply emails');
    this.magicLinkHmac = hmac('MagicLinkHmac', 'magic-link-hmac', 'Focus email sign-in link and code HMAC');
    this.receiptHmac = hmac('ReceiptHmac', 'receipt-hmac', 'Focus deletion receipt HMAC');
    this.configSigning = new kms.Key(this, 'ConfigSigning', {
      alias: n.kmsAlias('config-signing'),
      description: 'Focus config and copy deck signing (ES256). The next key ships in the app a release early.',
      keySpec: kms.KeySpec.ECC_NIST_P256,
      keyUsage: kms.KeyUsage.SIGN_VERIFY,
      pendingWindow: Duration.days(30),
      removalPolicy: RemovalPolicy.RETAIN,
    });
    this.messaging = symmetric('Messaging', 'messaging', 'Focus SNS topics: owner alerts and email bounce events');

    // CloudWatch alarms, EventBridge rules and SES publish to encrypted topics through SNS, which
    // uses this key on their behalf. AWS documents these statements without conditions; adding
    // source conditions here risks silently dropping alarms, and the topic policies already limit
    // who may publish.
    this.messaging.addToResourcePolicy(
      new iam.PolicyStatement({
        sid: 'AllowAwsServicesToPublishToEncryptedTopics',
        principals: [
          new iam.ServicePrincipal('cloudwatch.amazonaws.com'),
          new iam.ServicePrincipal('events.amazonaws.com'),
          new iam.ServicePrincipal('ses.amazonaws.com'),
        ],
        actions: ['kms:Decrypt', 'kms:GenerateDataKey*'],
        resources: ['*'],
      }),
    );
  }
}
