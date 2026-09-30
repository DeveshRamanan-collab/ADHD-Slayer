import { Duration, RemovalPolicy } from 'aws-cdk-lib/core';
import * as cloudtrail from 'aws-cdk-lib/aws-cloudtrail';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as cwActions from 'aws-cdk-lib/aws-cloudwatch-actions';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as events from 'aws-cdk-lib/aws-events';
import * as eventsTargets from 'aws-cdk-lib/aws-events-targets';
import * as guardduty from 'aws-cdk-lib/aws-guardduty';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as subscriptions from 'aws-cdk-lib/aws-sns-subscriptions';
import type { Construct } from 'constructs';
import { FocusStack, type FocusStackProps } from '../focus-stack';
import { acknowledge } from '../nag';
import { retention } from '../util';
import type { ApiStack } from './api-stack';
import type { DataStack } from './data-stack';
import type { EmailStack } from './email-stack';
import type { JobsStack } from './jobs-stack';
import type { KeysStack } from './keys-stack';

export interface MonitoringStackProps extends FocusStackProps {
  readonly keys: KeysStack;
  readonly data: DataStack;
  readonly api: ApiStack;
  readonly jobs: JobsStack;
  readonly email: EmailStack;
}

export type Severity = 'page' | 'ticket';

/** Every alarm and alert rule, by the short name used in its title and README runbook anchor. */
export const ALERTS: Record<string, { severity: Severity; summary: string }> = {
  'api-5xx': { severity: 'page', summary: 'API 5xx responses above 2% of requests for 5 minutes' },
  'api-latency-p95': { severity: 'ticket', summary: 'API p95 response time above 800 ms for 30 minutes' },
  'api-unhealthy-hosts': { severity: 'page', summary: 'A load balancer target failing health checks for 5 minutes' },
  'db-free-storage': { severity: 'page', summary: 'Database free storage under 20%' },
  'db-failover': { severity: 'page', summary: 'The database failed over to its standby' },
  'ses-bounce-rate': { severity: 'ticket', summary: 'SES bounce rate above 2%' },
  'ses-complaint-rate': { severity: 'ticket', summary: 'SES complaint rate above 0.05%' },
  'ses-send-volume': { severity: 'ticket', summary: 'Over 2,000 emails in an hour' },
  'jobs-dlq': { severity: 'ticket', summary: 'A scheduled job failed to start after retries' },
  'jobs-dlq-growing': { severity: 'page', summary: 'Scheduled jobs keep failing to start' },
  'email-events-dlq': { severity: 'ticket', summary: 'Bounce or complaint events could not reach the API' },
  'webhook-signature-failures': { severity: 'page', summary: 'A webhook or App Store transaction signature failed' },
  'app-store-webhook-errors': { severity: 'page', summary: 'Over 5 App Store webhook errors in 15 minutes' },
  'kms-or-secret-access-denied': { severity: 'page', summary: 'KMS or Secrets Manager refused a request' },
  'guardduty-high': { severity: 'page', summary: 'GuardDuty reported a high severity finding' },
  'backup-failed': { severity: 'ticket', summary: 'An AWS Backup job or the copy to Melbourne failed' },
  'api-healthz-external': { severity: 'page', summary: '/healthz failing from outside AWS for 3 minutes (us-east-1)' },
  'dnssec-internal-failure': { severity: 'page', summary: 'Route 53 cannot sign the zone (us-east-1)' },
  'dnssec-ksk-needs-action': { severity: 'page', summary: 'The DNSSEC key signing key needs action (us-east-1)' },
};

/**
 * Owner alerts. One SNS topic with an email subscription, and CloudWatch alarms or EventBridge
 * rules for everything in 02-backend.md, "Monitoring and logging", that AWS can measure.
 * Alarm descriptions start with [PAGE] or [TICKET] and link the runbook in the README.
 *
 * The /healthz check and DNSSEC alarms live in the Global stack (us-east-1), because Route 53
 * metrics only exist there.
 */
export class MonitoringStack extends FocusStack {
  readonly alertTopic: sns.Topic;
  private readonly action: cwActions.SnsAction;

  constructor(scope: Construct, props: MonitoringStackProps) {
    super(scope, 'Monitoring', props);
    const { config, naming: n } = this;
    const { keys, data, api, jobs, email } = props;

    this.alertTopic = new sns.Topic(this, 'Alerts', {
      topicName: n.alertTopicName,
      displayName: `Focus ${config.envName} alerts`,
      masterKey: keys.messaging,
      enforceSSL: true,
    });
    this.alertTopic.addToResourcePolicy(
      new iam.PolicyStatement({
        sid: 'AllowCloudWatchAlarms',
        principals: [new iam.ServicePrincipal('cloudwatch.amazonaws.com')],
        actions: ['sns:Publish'],
        resources: [this.alertTopic.topicArn],
        conditions: { StringEquals: { 'aws:SourceAccount': this.account } },
      }),
    );
    this.alertTopic.addSubscription(new subscriptions.EmailSubscription(config.alertEmail));
    this.action = new cwActions.SnsAction(this.alertTopic);

    // ---------------------------------------------------------------- API
    const lb = api.loadBalancer.metrics;
    const minute = Duration.minutes(1);
    this.alarm('api-5xx', {
      // Percentage of requests that were 5xx, from the load balancer and the targets. Minutes with
      // under 20 requests count as 0, so one error at 3 am doesn't page anyone.
      metric: new cloudwatch.MathExpression({
        expression: 'IF(requests >= 20, 100 * (FILL(target5xx, 0) + FILL(elb5xx, 0)) / requests, 0)',
        usingMetrics: {
          requests: lb.requestCount({ period: minute, statistic: cloudwatch.Stats.SUM }),
          target5xx: lb.httpCodeTarget(elbv2.HttpCodeTarget.TARGET_5XX_COUNT, { period: minute, statistic: cloudwatch.Stats.SUM }),
          elb5xx: lb.httpCodeElb(elbv2.HttpCodeElb.ELB_5XX_COUNT, { period: minute, statistic: cloudwatch.Stats.SUM }),
        },
        period: minute,
        label: '5xx % of requests',
      }),
      threshold: 2,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      evaluationPeriods: 5,
      datapointsToAlarm: 5,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });
    this.alarm('api-latency-p95', {
      metric: lb.targetResponseTime({ period: Duration.minutes(5), statistic: cloudwatch.Stats.p(95) }),
      threshold: 0.8,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      evaluationPeriods: 6,
      datapointsToAlarm: 6,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });
    this.alarm('api-unhealthy-hosts', {
      metric: api.targetGroup.metrics.unhealthyHostCount({ period: minute, statistic: cloudwatch.Stats.MAXIMUM }),
      threshold: 0,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      evaluationPeriods: 5,
      datapointsToAlarm: 5,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });

    // Log-based alarms. These read the API's structured JSON logs and assume the field names
    // `route` (route template) and `status`, and `errorCode` for API error codes (README,
    // "What the infrastructure assumes about the API").
    const apiLogs = logs.LogGroup.fromLogGroupName(this, 'ApiLogs', n.logGroupName('api'));
    const namespace = `Focus/${config.envName}`;
    const webhookSignatureFailures = new logs.MetricFilter(this, 'WebhookSignatureFailuresFilter', {
      logGroup: apiLogs,
      metricNamespace: namespace,
      metricName: 'WebhookSignatureFailures',
      filterPattern: logs.FilterPattern.literal(
        '{ (($.route = "/v1/webhooks/*") && ($.status = 400 || $.status = 401 || $.status = 403)) || ($.errorCode = "JWS_INVALID") }',
      ),
      metricValue: '1',
      defaultValue: 0,
    });
    this.alarm('webhook-signature-failures', {
      metric: webhookSignatureFailures.metric({ period: Duration.minutes(5), statistic: cloudwatch.Stats.SUM }),
      threshold: 0,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      evaluationPeriods: 1,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });
    const appStoreWebhookErrors = new logs.MetricFilter(this, 'AppStoreWebhookErrorsFilter', {
      logGroup: apiLogs,
      metricNamespace: namespace,
      metricName: 'AppStoreWebhookErrors',
      filterPattern: logs.FilterPattern.literal('{ ($.route = "/v1/webhooks/app-store") && ($.status >= 400) }'),
      metricValue: '1',
      defaultValue: 0,
    });
    this.alarm('app-store-webhook-errors', {
      metric: appStoreWebhookErrors.metric({ period: Duration.minutes(15), statistic: cloudwatch.Stats.SUM }),
      threshold: 5,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      evaluationPeriods: 1,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });

    // ---------------------------------------------------------------- database
    const allocatedBytes = config.database.allocatedStorageGiB * 1024 ** 3;
    this.alarm('db-free-storage', {
      metric: data.database.metricFreeStorageSpace({ period: Duration.minutes(5), statistic: cloudwatch.Stats.MINIMUM }),
      // 20% of the configured allocation. If storage autoscaling grows the volume, raise
      // database.allocatedStorageGiB in config to match (README runbook).
      threshold: Math.round(allocatedBytes * 0.2),
      comparisonOperator: cloudwatch.ComparisonOperator.LESS_THAN_THRESHOLD,
      evaluationPeriods: 2,
      datapointsToAlarm: 2,
      treatMissingData: cloudwatch.TreatMissingData.BREACHING,
    });
    this.rule('db-failover', {
      eventPattern: {
        source: ['aws.rds'],
        detailType: ['RDS DB Instance Event'],
        detail: { SourceIdentifier: [n.resource('db')], EventCategories: ['failover'] },
      },
      message: events.RuleTargetInput.fromText(
        `[PAGE] ${n.resource('db')} failover: ${events.EventField.fromPath('$.detail.Message')} Runbook: backend/infra/README.md#db-failover`,
      ),
    });

    // ---------------------------------------------------------------- email (account level SES metrics)
    const ses = (metricName: string, statistic: string, period: Duration) =>
      new cloudwatch.Metric({ namespace: 'AWS/SES', metricName, statistic, period });
    this.alarm('ses-bounce-rate', {
      metric: ses('Reputation.BounceRate', cloudwatch.Stats.MAXIMUM, Duration.minutes(15)),
      threshold: 0.02,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      evaluationPeriods: 1,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });
    this.alarm('ses-complaint-rate', {
      metric: ses('Reputation.ComplaintRate', cloudwatch.Stats.MAXIMUM, Duration.minutes(15)),
      threshold: 0.0005,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      evaluationPeriods: 1,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });
    this.alarm('ses-send-volume', {
      metric: ses('Send', cloudwatch.Stats.SUM, Duration.hours(1)),
      threshold: 2000,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      evaluationPeriods: 1,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });
    this.alarm('email-events-dlq', {
      metric: email.eventsDeadLetterQueue.metricApproximateNumberOfMessagesVisible({ period: Duration.minutes(5), statistic: cloudwatch.Stats.MAXIMUM }),
      threshold: 0,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      evaluationPeriods: 1,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });

    // ---------------------------------------------------------------- jobs
    const dlqDepth = jobs.deadLetterQueue.metricApproximateNumberOfMessagesVisible({ period: Duration.minutes(5), statistic: cloudwatch.Stats.MAXIMUM });
    this.alarm('jobs-dlq', {
      metric: dlqDepth,
      threshold: 0,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      evaluationPeriods: 1,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });
    this.alarm('jobs-dlq-growing', {
      metric: dlqDepth,
      threshold: 10,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_OR_EQUAL_TO_THRESHOLD,
      evaluationPeriods: 1,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });

    // ---------------------------------------------------------------- backups
    this.rule('backup-failed', {
      eventPattern: {
        source: ['aws.backup'],
        detailType: ['Backup Job State Change', 'Copy Job State Change'],
        detail: { state: ['FAILED', 'ABORTED', 'EXPIRED'] },
      },
      message: events.RuleTargetInput.fromText(
        `[TICKET] AWS Backup ${events.EventField.fromPath('$.detail-type')}: ${events.EventField.fromPath('$.detail.state')} for ${events.EventField.fromPath('$.detail.resourceArn')}. Runbook: backend/infra/README.md#backup-failed`,
      ),
    });

    // ---------------------------------------------------------------- GuardDuty
    if (config.monitoring.enableGuardDuty) {
      new guardduty.CfnDetector(this, 'GuardDuty', {
        enable: true,
        findingPublishingFrequency: 'FIFTEEN_MINUTES',
        features: [
          { name: 'S3_DATA_EVENTS', status: 'ENABLED' },
          { name: 'RDS_LOGIN_EVENTS', status: 'ENABLED' },
        ],
      });
    }
    this.rule('guardduty-high', {
      eventPattern: {
        source: ['aws.guardduty'],
        detailType: ['GuardDuty Finding'],
        detail: { severity: events.Match.greaterThanOrEqual(7) },
      },
      message: events.RuleTargetInput.fromText(
        `[PAGE] GuardDuty ${events.EventField.fromPath('$.detail.type')} (severity ${events.EventField.fromPath('$.detail.severity')}): ${events.EventField.fromPath('$.detail.title')}. Runbook: backend/infra/README.md#guardduty-high`,
      ),
    });

    // ---------------------------------------------------------------- CloudTrail
    if (config.monitoring.enableCloudTrail) {
      this.createTrail();
    }
  }

  private createTrail(): void {
    const { config, naming: n } = this;
    const trailBucket = new s3.Bucket(this, 'CloudTrailBucket', {
      bucketName: n.bucketName('cloudtrail'),
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      objectOwnership: s3.ObjectOwnership.BUCKET_OWNER_ENFORCED,
      enforceSSL: true,
      minimumTLSVersion: 1.2,
      versioned: true,
      removalPolicy: RemovalPolicy.RETAIN,
      serverAccessLogsBucket: s3.Bucket.fromBucketName(this, 'AccessLogs', n.bucketName('access-logs')),
      serverAccessLogsPrefix: 's3/cloudtrail/',
      lifecycleRules: [
        {
          id: 'keep-one-year',
          expiration: Duration.days(365),
          noncurrentVersionExpiration: Duration.days(30),
          abortIncompleteMultipartUploadAfter: Duration.days(1),
        },
      ],
    });
    acknowledge(
      trailBucket,
      'The access log bucket (Data stack) already lets S3 log delivery from any bucket in this account write under s3/, so this stack leaves its policy alone.',
      'Annotation::@aws-cdk/aws-s3:accessLogsPolicyNotAdded',
    );
    const trailLogs = new logs.LogGroup(this, 'CloudTrailLogs', {
      logGroupName: n.logGroupName('cloudtrail'),
      retention: retention(config.logRetentionDays),
      removalPolicy: RemovalPolicy.DESTROY,
    });
    const trail = new cloudtrail.Trail(this, 'Trail', {
      trailName: n.resource('trail'),
      bucket: trailBucket,
      isMultiRegionTrail: true,
      includeGlobalServiceEvents: true,
      enableFileValidation: true,
      managementEvents: cloudtrail.ReadWriteType.ALL,
      sendToCloudWatchLogs: true,
      cloudWatchLogGroup: trailLogs,
    });
    void trail;

    const accessDenied = new logs.MetricFilter(this, 'KmsOrSecretAccessDeniedFilter', {
      logGroup: trailLogs,
      metricNamespace: `Focus/${config.envName}`,
      metricName: 'KmsOrSecretAccessDenied',
      filterPattern: logs.FilterPattern.literal(
        '{ (($.eventSource = "kms.amazonaws.com") || ($.eventSource = "secretsmanager.amazonaws.com")) && (($.errorCode = "AccessDenied*") || ($.errorCode = "*UnauthorizedOperation")) }',
      ),
      metricValue: '1',
      defaultValue: 0,
    });
    this.alarm('kms-or-secret-access-denied', {
      metric: accessDenied.metric({ period: Duration.minutes(5), statistic: cloudwatch.Stats.SUM }),
      threshold: 0,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      evaluationPeriods: 1,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });
  }

  private alarm(name: keyof typeof ALERTS & string, props: Omit<cloudwatch.AlarmProps, 'alarmName' | 'alarmDescription'>): cloudwatch.Alarm {
    const alert = ALERTS[name];
    const alarm = new cloudwatch.Alarm(this, `Alarm-${name}`, {
      ...props,
      alarmName: this.naming.alarmName(name),
      alarmDescription: `[${alert.severity.toUpperCase()}] ${alert.summary}. Runbook: backend/infra/README.md#${name}`,
    });
    alarm.addAlarmAction(this.action);
    if (alert.severity === 'page') alarm.addOkAction(this.action);
    return alarm;
  }

  private rule(name: keyof typeof ALERTS & string, props: { eventPattern: events.EventPattern; message: events.RuleTargetInput }): events.Rule {
    return new events.Rule(this, `Rule-${name}`, {
      ruleName: this.naming.alarmName(name),
      description: `[${ALERTS[name].severity.toUpperCase()}] ${ALERTS[name].summary}`,
      eventPattern: props.eventPattern,
      targets: [new eventsTargets.SnsTopic(this.alertTopic, { message: props.message })],
    });
  }
}

