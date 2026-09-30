import { Duration, RemovalPolicy } from 'aws-cdk-lib/core';
import * as backup from 'aws-cdk-lib/aws-backup';
import * as kms from 'aws-cdk-lib/aws-kms';
import * as s3 from 'aws-cdk-lib/aws-s3';
import type { Construct } from 'constructs';
import { FocusStack, type FocusStackProps } from '../focus-stack';
import { acknowledge } from '../nag';

/**
 * Backup copies in Melbourne (ap-southeast-4): the replica of the snapshots bucket and the vault
 * that receives the daily database backup copy. Deployed before the Data stack, which points
 * replication and the backup plan here.
 */
export class DrStack extends FocusStack {
  readonly key: kms.Key;
  readonly snapshotsReplica: s3.Bucket;
  readonly vault: backup.BackupVault;

  constructor(scope: Construct, props: FocusStackProps) {
    super(scope, 'Dr', props, 'backup');
    const n = this.naming;

    this.key = new kms.Key(this, 'DrKey', {
      alias: n.kmsAlias('dr'),
      description: 'Focus Melbourne copies: replicated snapshots and database backup copies',
      enableKeyRotation: true,
      rotationPeriod: Duration.days(365),
      removalPolicy: RemovalPolicy.RETAIN,
    });

    this.snapshotsReplica = new s3.Bucket(this, 'SnapshotsReplica', {
      bucketName: n.bucketName('snapshots-replica'),
      versioned: true,
      encryption: s3.BucketEncryption.KMS,
      encryptionKey: this.key,
      bucketKeyEnabled: true,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      objectOwnership: s3.ObjectOwnership.BUCKET_OWNER_ENFORCED,
      enforceSSL: true,
      minimumTLSVersion: 1.2,
      removalPolicy: RemovalPolicy.RETAIN,
      lifecycleRules: [
        {
          id: 'expire-noncurrent-35-days',
          // Deletes in Sydney arrive here as delete markers; the copies they hide go after 35 days.
          noncurrentVersionExpiration: Duration.days(35),
          expiredObjectDeleteMarker: true,
          abortIncompleteMultipartUploadAfter: Duration.days(1),
        },
        {
          id: 'backstop-orphaned-copies',
          // Safety net only. A live account's newest snapshot is never older than 24 months plus
          // the 30-day dormant notice, so nothing live expires here. It catches a copy whose
          // source was deleted without a delete marker (see README, "Snapshot deletes").
          expiration: Duration.days(790),
        },
      ],
    });
    acknowledge(
      this.snapshotsReplica,
      'Written only by S3 replication and read only in a regional disaster; S3 server access logs would need a second log bucket in Melbourne for no practical gain.',
      'AwsSolutions-S1',
    );

    this.vault = new backup.BackupVault(this, 'DrVault', {
      backupVaultName: n.resource('dr'),
      encryptionKey: this.key,
      removalPolicy: RemovalPolicy.RETAIN,
    });
  }
}
