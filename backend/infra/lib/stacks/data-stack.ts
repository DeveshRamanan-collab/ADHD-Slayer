import { Duration, RemovalPolicy } from 'aws-cdk-lib/core';
import * as backup from 'aws-cdk-lib/aws-backup';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as events from 'aws-cdk-lib/aws-events';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import type { Construct } from 'constructs';
import { FocusStack, type FocusStackProps } from '../focus-stack';
import { acknowledge } from '../nag';
import type { DrStack } from './dr-stack';
import type { KeysStack } from './keys-stack';
import type { NetworkStack } from './network-stack';

export interface DataStackProps extends FocusStackProps {
  readonly network: NetworkStack;
  readonly keys: KeysStack;
  readonly dr: DrStack;
}

/** Name of the database the API connects to (PGDATABASE). */
export const DATABASE_NAME = 'focus';
/** Master user in the generated secret. The API and jobs connect as this user. */
export const DATABASE_USER = 'focus_admin';
export const DATABASE_PORT = 5432;
/** Same set the generated secret excludes, so rotated passwords stay URL and shell safe. */
const PASSWORD_EXCLUDE_CHARACTERS = " %+~`#$&*()|[]{}:;<>?!'/@\"\\";

/**
 * PostgreSQL, the S3 buckets and backups.
 *
 * Recovery (02-backend.md): point-in-time recovery 35 days; AWS Backup copies daily to Melbourne
 * and keeps 35 days; S3 noncurrent versions expire at 35 days and replicate to Melbourne.
 */
export class DataStack extends FocusStack {
  readonly database: rds.DatabaseInstance;
  readonly databaseSecret: secretsmanager.ISecret;
  /** Load balancer, CloudFront and S3 server access logs. 14 days, because they hold IP addresses. */
  readonly accessLogs: s3.Bucket;
  /** Encrypted snapshots the server can't read. Versioned, replicated to Melbourne. */
  readonly snapshots: s3.Bucket;
  /** Opt-in crash reports, 90 days. */
  readonly diagnostics: s3.Bucket;
  /** Signed config and copy decks. */
  readonly content: s3.Bucket;
  /** Static website. Its bucket policy lives in the Edge stack, next to the distribution it names. */
  readonly website: s3.Bucket;

  constructor(scope: Construct, props: DataStackProps) {
    super(scope, 'Data', props);
    const { config, naming: n } = this;
    const { network, keys, dr } = props;

    // ---------------------------------------------------------------- access logs
    this.accessLogs = new s3.Bucket(this, 'AccessLogs', {
      bucketName: n.bucketName('access-logs'),
      // Load balancer and CloudFront log delivery only support S3-managed keys.
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      // CloudFront standard logs are delivered with ACLs.
      objectOwnership: s3.ObjectOwnership.BUCKET_OWNER_PREFERRED,
      enforceSSL: true,
      minimumTLSVersion: 1.2,
      removalPolicy: RemovalPolicy.RETAIN,
      lifecycleRules: [
        {
          id: `expire-${config.edgeLogRetentionDays}-days`,
          expiration: Duration.days(config.edgeLogRetentionDays),
          abortIncompleteMultipartUploadAfter: Duration.days(1),
        },
      ],
    });
    // Any bucket in this account may deliver S3 server access logs under s3/. Buckets in other
    // stacks (the CloudTrail bucket) rely on this, so their stacks don't edit this policy.
    this.accessLogs.addToResourcePolicy(
      new iam.PolicyStatement({
        sid: 'S3ServerAccessLogDelivery',
        principals: [new iam.ServicePrincipal('logging.s3.amazonaws.com')],
        actions: ['s3:PutObject'],
        resources: [this.accessLogs.arnForObjects('s3/*')],
        conditions: { StringEquals: { 'aws:SourceAccount': this.account } },
      }),
    );
    acknowledge(this.accessLogs, 'This is the access log bucket; logging it into itself would loop.', 'AwsSolutions-S1');

    const logsTo = (prefix: string) => ({ serverAccessLogsBucket: this.accessLogs, serverAccessLogsPrefix: `s3/${prefix}/` });
    const kmsEncrypted = {
      encryption: s3.BucketEncryption.KMS,
      encryptionKey: keys.s3,
      // Bucket keys cut KMS requests (and cost) by about 99%.
      bucketKeyEnabled: true,
    };
    const locked = {
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      objectOwnership: s3.ObjectOwnership.BUCKET_OWNER_ENFORCED,
      enforceSSL: true,
      minimumTLSVersion: 1.2,
      removalPolicy: RemovalPolicy.RETAIN,
    };

    // ---------------------------------------------------------------- snapshots
    this.snapshots = new s3.Bucket(this, 'Snapshots', {
      bucketName: n.bucketName('snapshots'),
      versioned: true,
      ...kmsEncrypted,
      ...locked,
      ...logsTo('snapshots'),
      lifecycleRules: [
        {
          id: 'expire-noncurrent-35-days',
          noncurrentVersionExpiration: Duration.days(35),
          expiredObjectDeleteMarker: true,
          abortIncompleteMultipartUploadAfter: Duration.days(1),
        },
      ],
    });
    // Uploads come from presigned URLs. Refuse any upload that asks for other encryption.
    this.snapshots.addToResourcePolicy(
      new iam.PolicyStatement({
        sid: 'DenyUploadsWithoutKms',
        effect: iam.Effect.DENY,
        principals: [new iam.AnyPrincipal()],
        actions: ['s3:PutObject'],
        resources: [this.snapshots.arnForObjects('*')],
        conditions: { StringNotEqualsIfExists: { 's3:x-amz-server-side-encryption': 'aws:kms' } },
      }),
    );
    this.snapshots.addToResourcePolicy(
      new iam.PolicyStatement({
        sid: 'DenyUploadsWithAnotherKey',
        effect: iam.Effect.DENY,
        principals: [new iam.AnyPrincipal()],
        actions: ['s3:PutObject'],
        resources: [this.snapshots.arnForObjects('*')],
        conditions: {
          StringNotEqualsIfExists: {
            's3:x-amz-server-side-encryption-aws-kms-key-id': [
              keys.s3.keyArn,
              keys.s3.keyId,
              `arn:aws:kms:${this.region}:${this.account}:${n.kmsAlias('s3')}`,
            ],
          },
        },
      }),
    );

    // Replication to Melbourne. Deletes replicate as delete markers; version-specific deletes
    // don't replicate by design, so the API must delete with a plain DeleteObject first (README).
    const replicationRole = new iam.Role(this, 'SnapshotsReplicationRole', {
      roleName: n.resource('snapshots-replication'),
      assumedBy: new iam.ServicePrincipal('s3.amazonaws.com'),
      description: 'Replicates encrypted snapshots from Sydney to Melbourne',
    });
    replicationRole.addToPolicy(
      new iam.PolicyStatement({
        actions: ['s3:GetReplicationConfiguration', 's3:ListBucket'],
        resources: [n.bucketArn('snapshots')],
      }),
    );
    replicationRole.addToPolicy(
      new iam.PolicyStatement({
        actions: ['s3:GetObjectVersionForReplication', 's3:GetObjectVersionAcl', 's3:GetObjectVersionTagging'],
        resources: [n.bucketArn('snapshots', '*')],
      }),
    );
    replicationRole.addToPolicy(
      new iam.PolicyStatement({
        actions: ['s3:ReplicateObject', 's3:ReplicateDelete', 's3:ReplicateTags'],
        resources: [n.bucketArn('snapshots-replica', '*')],
      }),
    );
    replicationRole.addToPolicy(
      new iam.PolicyStatement({
        actions: ['kms:Decrypt'],
        resources: [keys.s3.keyArn],
        conditions: { StringEquals: { 'kms:ViaService': `s3.${config.primaryRegion}.amazonaws.com` } },
      }),
    );
    replicationRole.addToPolicy(
      new iam.PolicyStatement({
        actions: ['kms:Encrypt', 'kms:GenerateDataKey'],
        resources: [dr.key.keyArn],
        conditions: { StringEquals: { 'kms:ViaService': `s3.${config.backupRegion}.amazonaws.com` } },
      }),
    );
    acknowledge(
      replicationRole.node.findChild('DefaultPolicy'),
      'S3 replication reads every object version in the snapshots bucket and writes every key in its Melbourne replica; object keys are per account and not known in advance.',
      `AwsSolutions-IAM5[Resource::${n.bucketArn('snapshots', '*')}]`,
      `AwsSolutions-IAM5[Resource::${n.bucketArn('snapshots-replica', '*')}]`,
    );
    (this.snapshots.node.defaultChild as s3.CfnBucket).replicationConfiguration = {
      role: replicationRole.roleArn,
      rules: [
        {
          id: 'snapshots-to-melbourne',
          status: 'Enabled',
          priority: 1,
          filter: { prefix: '' },
          deleteMarkerReplication: { status: 'Enabled' },
          sourceSelectionCriteria: { sseKmsEncryptedObjects: { status: 'Enabled' } },
          destination: {
            bucket: dr.snapshotsReplica.bucketArn,
            encryptionConfiguration: { replicaKmsKeyId: dr.key.keyArn },
            storageClass: 'STANDARD',
          },
        },
      ],
    };

    // ---------------------------------------------------------------- diagnostics, content, website
    this.diagnostics = new s3.Bucket(this, 'Diagnostics', {
      bucketName: n.bucketName('diagnostics'),
      ...kmsEncrypted,
      ...locked,
      ...logsTo('diagnostics'),
      lifecycleRules: [
        { id: 'expire-90-days', expiration: Duration.days(90), abortIncompleteMultipartUploadAfter: Duration.days(1) },
      ],
    });

    this.content = new s3.Bucket(this, 'Content', {
      bucketName: n.bucketName('content'),
      // Versioned so a bad publish can be rolled back to the previous object.
      versioned: true,
      ...kmsEncrypted,
      ...locked,
      ...logsTo('content'),
      lifecycleRules: [
        {
          id: 'expire-noncurrent-90-days',
          noncurrentVersionExpiration: Duration.days(90),
          expiredObjectDeleteMarker: true,
          abortIncompleteMultipartUploadAfter: Duration.days(1),
        },
      ],
    });

    this.website = new s3.Bucket(this, 'Website', {
      bucketName: n.bucketName('website'),
      // Public pages, read by CloudFront through origin access control. S3-managed keys keep the
      // origin simple; nothing here is personal.
      encryption: s3.BucketEncryption.S3_MANAGED,
      ...logsTo('website'),
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      objectOwnership: s3.ObjectOwnership.BUCKET_OWNER_ENFORCED,
      removalPolicy: RemovalPolicy.RETAIN,
      // No enforceSSL here: the Edge stack writes this bucket's only policy (TLS 1.2 or later,
      // plus read access for the one distribution). A second policy would fight over the same
      // AWS::S3::BucketPolicy.
    });
    acknowledge(
      this.website,
      'The TLS-only statement is in the bucket policy that the Edge stack attaches, together with the CloudFront origin access control grant.',
      'AwsSolutions-S10',
    );

    // ---------------------------------------------------------------- PostgreSQL
    const engine = rds.DatabaseInstanceEngine.postgres({ version: rds.PostgresEngineVersion.VER_17 });
    const parameterGroup = new rds.ParameterGroup(this, 'DatabaseParameters', {
      engine,
      description: 'Focus PostgreSQL 17',
      parameters: {
        'rds.force_ssl': '1',
        // Keep row values (emails in constraint errors, for example) out of database logs.
        log_error_verbosity: 'terse',
        log_min_error_statement: 'panic',
      },
    });

    // Created explicitly so the secret JSON carries `dbname` (ECS maps it to PGDATABASE; the
    // generated default only gains host, port and engine when attached to the instance).
    const credentialsSecret = new rds.DatabaseSecret(this, 'DatabaseSecret', {
      username: DATABASE_USER,
      dbname: DATABASE_NAME,
      secretName: n.secretName('rds'),
      excludeCharacters: PASSWORD_EXCLUDE_CHARACTERS,
    });

    this.database = new rds.DatabaseInstance(this, 'Database', {
      instanceIdentifier: n.resource('db'),
      engine,
      instanceType: new ec2.InstanceType(config.database.instanceClass),
      vpc: network.vpc,
      vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_ISOLATED },
      securityGroups: [network.databaseSecurityGroup],
      multiAz: config.database.multiAz,
      storageType: rds.StorageType.GP3,
      allocatedStorage: config.database.allocatedStorageGiB,
      maxAllocatedStorage: config.database.maxAllocatedStorageGiB,
      storageEncrypted: true,
      storageEncryptionKey: keys.rds,
      credentials: rds.Credentials.fromSecret(credentialsSecret),
      databaseName: DATABASE_NAME,
      parameterGroup,
      port: DATABASE_PORT,
      backupRetention: Duration.days(config.database.backupRetentionDays),
      // 02:00 to 02:30 Sydney standard time (03:00 in daylight time).
      preferredBackupWindow: '16:00-16:30',
      preferredMaintenanceWindow: 'sun:17:00-sun:17:30',
      deleteAutomatedBackups: false,
      deletionProtection: config.database.deletionProtection,
      removalPolicy: RemovalPolicy.SNAPSHOT,
      enablePerformanceInsights: config.database.performanceInsights,
      autoMinorVersionUpgrade: true,
      allowMajorVersionUpgrade: false,
      // Avoid paid Extended Support: RDS upgrades the minor/major version when support ends.
      engineLifecycleSupport: rds.EngineLifecycleSupport.OPEN_SOURCE_RDS_EXTENDED_SUPPORT_DISABLED,
      publiclyAccessible: false,
      copyTagsToSnapshot: true,
      caCertificate: rds.CaCertificate.RDS_CA_RSA2048_G1,
    });
    this.databaseSecret = this.database.secret!;

    // Rotate the generated credentials every 30 days (02-backend.md). The Api stack redeploys the
    // service after each rotation so new tasks pick up the new password (README runbook).
    // Built directly rather than with addRotationSingleUser(): that helper opens the database port
    // using the instance's port token, which would make the Network stack depend on this one.
    // The literal port keeps the (already present) rule inside the Network stack.
    new secretsmanager.SecretRotation(this, 'DatabaseSecretRotation', {
      application: secretsmanager.SecretRotationApplication.POSTGRES_ROTATION_SINGLE_USER,
      secret: this.databaseSecret,
      target: {
        connections: new ec2.Connections({
          securityGroups: [network.databaseSecurityGroup],
          defaultPort: ec2.Port.tcp(DATABASE_PORT),
        }),
      },
      vpc: network.vpc,
      vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS },
      securityGroup: network.rotationSecurityGroup,
      automaticallyAfter: Duration.days(config.database.credentialRotationDays),
      excludeCharacters: PASSWORD_EXCLUDE_CHARACTERS,
    });

    acknowledge(
      this.database,
      'Port obscurity adds nothing here: the database sits in subnets with no route out and accepts connections only from the API, task and rotation security groups.',
      'AwsSolutions-RDS11',
    );
    if (!config.database.deletionProtection) {
      acknowledge(this.database, 'Staging holds synthetic data only and is torn down and rebuilt freely; production has deletion protection on.', 'AwsSolutions-RDS10');
    }
    if (!config.database.multiAz) {
      acknowledge(this.database, 'Multi-AZ turned off in config for this environment to save cost; production keeps it on.', 'AwsSolutions-RDS3');
    }

    // ---------------------------------------------------------------- AWS Backup
    const vault = new backup.BackupVault(this, 'Vault', {
      backupVaultName: n.resource('primary'),
      removalPolicy: RemovalPolicy.RETAIN,
    });
    const plan = new backup.BackupPlan(this, 'BackupPlan', {
      backupPlanName: n.resource('daily'),
      backupVault: vault,
    });
    plan.addRule(
      new backup.BackupPlanRule({
        ruleName: 'daily-copy-to-melbourne',
        // 05:00 Sydney standard time, clear of the RDS backup window.
        scheduleExpression: events.Schedule.cron({ minute: '0', hour: '19' }),
        startWindow: Duration.hours(1),
        completionWindow: Duration.hours(4),
        deleteAfter: Duration.days(35),
        copyActions: [{ destinationBackupVault: dr.vault, deleteAfter: Duration.days(35) }],
      }),
    );
    const selection = plan.addSelection('Database', {
      backupSelectionName: 'database',
      resources: [backup.BackupResource.fromRdsDatabaseInstance(this.database)],
      allowRestores: true,
    });
    acknowledge(
      selection.node.findChild('Role'),
      'AWS Backup service roles use the AWS managed backup and restore policies, which AWS keeps current as services change.',
      'AwsSolutions-IAM4[Policy::arn:<AWS::Partition>:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup]',
      'AwsSolutions-IAM4[Policy::arn:<AWS::Partition>:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores]',
    );
  }
}
