import { CfnOutput, Duration, Stack } from 'aws-cdk-lib/core';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as scheduler from 'aws-cdk-lib/aws-scheduler';
import * as sqs from 'aws-cdk-lib/aws-sqs';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import type { Construct } from 'constructs';
import { SYDNEY_TIME_ZONE } from '../config';
import { FocusTaskDefinition } from '../constructs/focus-task-definition';
import { FocusStack, type FocusStackProps } from '../focus-stack';
import { JOBS, type JobDefinition } from '../jobs';
import { acknowledge } from '../nag';
import { buildTaskEnvironment } from '../task-environment';
import type { ApiStack } from './api-stack';
import type { DataStack } from './data-stack';
import type { KeysStack } from './keys-stack';
import type { NetworkStack } from './network-stack';
import type { RegistryStack } from './registry-stack';
import type { SecretsStack } from './secrets-stack';

export interface JobsStackProps extends FocusStackProps {
  readonly network: NetworkStack;
  readonly keys: KeysStack;
  readonly secrets: SecretsStack;
  readonly data: DataStack;
  readonly registry: RegistryStack;
  readonly api: ApiStack;
}

/**
 * Scheduled jobs (CONTRACT.md, "Jobs"): one task definition, one EventBridge Scheduler schedule
 * per job, evaluated in Australia/Sydney time.
 *
 * Schedules call ECS RunTask through Scheduler's universal target with the task definition
 * *family* name, so every run uses the latest registered revision. That is how a pipeline deploy
 * (which registers a new revision with the new image) reaches the jobs without touching
 * CloudFormation. Failed RunTask calls are retried, then land in a dead-letter queue that pages.
 */
export class JobsStack extends FocusStack {
  readonly task: FocusTaskDefinition;
  readonly deadLetterQueue: sqs.Queue;
  readonly schedules: Record<string, scheduler.CfnSchedule> = {};

  constructor(scope: Construct, props: JobsStackProps) {
    super(scope, 'Jobs', props);
    const { config, naming: n } = this;
    const { network, keys, secrets, data, registry, api } = props;

    const imageTag = ssm.StringParameter.valueForStringParameter(this, registry.imageTagParameterName);
    const image = ecs.ContainerImage.fromEcrRepository(registry.repository, imageTag);
    const taskEnvironment = buildTaskEnvironment({ config, keys, data, secrets });

    this.task = new FocusTaskDefinition(this, 'JobsTask', {
      config,
      family: 'jobs',
      description: 'scheduled jobs (App Store, deletions, retention, dormant accounts)',
      image,
      cpu: config.jobs.cpu,
      memoryMiB: config.jobs.memoryMiB,
      // The job name is appended per schedule; run with no name, the runner should print usage.
      command: config.commands.jobs,
      environment: {
        ...taskEnvironment.environment,
        // A literal ARN: the Monitoring stack creates the topic and deploys after this one, because
        // it also watches this stack's dead-letter queue.
        ALERT_TOPIC_ARN: n.alertTopicArn,
      },
      secrets: taskEnvironment.secrets,
      readonlyRootFilesystem: true,
    });
    this.task.acknowledgeExecutionRoleWildcards();
    this.grantJobPermissions(this.task.taskRole, keys);

    // ---------------------------------------------------------------- schedules
    this.deadLetterQueue = new sqs.Queue(this, 'SchedulerDeadLetterQueue', {
      queueName: n.resource('scheduler-dlq'),
      encryption: sqs.QueueEncryption.SQS_MANAGED,
      enforceSSL: true,
      retentionPeriod: Duration.days(14),
    });
    acknowledge(
      this.deadLetterQueue,
      'This queue is itself the dead-letter queue for EventBridge Scheduler; nothing reads from it automatically, and a CloudWatch alarm pages when it has messages.',
      'AwsSolutions-SQS3',
    );

    const familyArn = `arn:aws:ecs:${this.region}:${this.account}:task-definition/${n.family('jobs')}`;
    const schedulerRole = new iam.Role(this, 'SchedulerRole', {
      roleName: n.resource('jobs-scheduler'),
      description: 'EventBridge Scheduler: starts Focus job tasks',
      assumedBy: new iam.ServicePrincipal('scheduler.amazonaws.com', {
        conditions: { StringEquals: { 'aws:SourceAccount': this.account } },
      }),
    });
    schedulerRole.addToPolicy(
      new iam.PolicyStatement({
        sid: 'RunJobTasks',
        actions: ['ecs:RunTask'],
        resources: [familyArn, `${familyArn}:*`],
        conditions: { ArnEquals: { 'ecs:cluster': api.cluster.clusterArn } },
      }),
    );
    schedulerRole.addToPolicy(
      new iam.PolicyStatement({
        sid: 'PassJobRoles',
        actions: ['iam:PassRole'],
        resources: [this.task.taskRole.roleArn, this.task.executionRole.roleArn],
        conditions: { StringEquals: { 'iam:PassedToService': 'ecs-tasks.amazonaws.com' } },
      }),
    );
    schedulerRole.addToPolicy(
      new iam.PolicyStatement({
        sid: 'TagJobTasks',
        actions: ['ecs:TagResource'],
        resources: [`arn:aws:ecs:${this.region}:${this.account}:task/${n.clusterName}/*`],
        conditions: { StringEquals: { 'ecs:CreateAction': 'RunTask' } },
      }),
    );
    this.deadLetterQueue.grantSendMessages(schedulerRole);
    acknowledge(
      schedulerRole.node.findChild('DefaultPolicy'),
      'Each deploy registers a new revision of the one jobs family, and each run creates a new task id; both wildcards stay inside that family and this cluster.',
      `AwsSolutions-IAM5[Resource::${familyArn}:*]`,
      `AwsSolutions-IAM5[Resource::arn:aws:ecs:${this.region}:${this.account}:task/${n.clusterName}/*]`,
    );

    const group = new scheduler.CfnScheduleGroup(this, 'ScheduleGroup', { name: n.resource('jobs') });
    const subnets = network.vpc.selectSubnets({ subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS }).subnetIds;

    for (const job of JOBS) {
      const schedule = new scheduler.CfnSchedule(this, `Schedule-${job.name}`, {
        name: n.resource(job.name),
        groupName: group.name,
        description: job.description,
        scheduleExpression: job.schedule,
        scheduleExpressionTimezone: SYDNEY_TIME_ZONE,
        flexibleTimeWindow: { mode: 'OFF' },
        state: 'ENABLED',
        target: {
          arn: 'arn:aws:scheduler:::aws-sdk:ecs:runTask',
          roleArn: schedulerRole.roleArn,
          input: Stack.of(this).toJsonString(this.runTaskRequest(job, api.cluster.clusterArn, subnets, network.tasksSecurityGroup.securityGroupId)),
          retryPolicy: {
            maximumRetryAttempts: job.maximumRetryAttempts,
            maximumEventAgeInSeconds: job.maximumEventAgeSeconds,
          },
          deadLetterConfig: { arn: this.deadLetterQueue.queueArn },
        },
      });
      schedule.addResourceDependency(group);
      this.schedules[job.name] = schedule;
    }

    new CfnOutput(this, 'JobsFamily', { value: n.family('jobs') });
    new CfnOutput(this, 'DeadLetterQueueUrl', { value: this.deadLetterQueue.queueUrl });
  }

  /**
   * The ECS RunTask request for one job, in the AWS SDK member casing that Scheduler universal
   * targets use (the same as Step Functions SDK integrations).
   */
  runTaskRequest(job: JobDefinition, clusterArn: string, subnets: string[], securityGroupId: string): Record<string, unknown> {
    return {
      Cluster: clusterArn,
      // Family only: RunTask uses the latest ACTIVE revision.
      TaskDefinition: this.naming.family('jobs'),
      LaunchType: 'FARGATE',
      Count: 1,
      StartedBy: `scheduler/${job.name}`.slice(0, 128),
      NetworkConfiguration: {
        AwsvpcConfiguration: {
          Subnets: subnets,
          SecurityGroups: [securityGroupId],
          AssignPublicIp: 'DISABLED',
        },
      },
      Overrides: {
        ContainerOverrides: [{ Name: this.task.containerName, Command: [...this.config.commands.jobs, job.name] }],
      },
    };
  }

  private grantJobPermissions(role: iam.Role, keys: KeysStack): void {
    const n = this.naming;
    const region = this.config.primaryRegion;
    keys.appEnvelope.grant(role, 'kms:Encrypt', 'kms:Decrypt', 'kms:GenerateDataKey');
    keys.receiptHmac.grant(role, 'kms:GenerateMac', 'kms:VerifyMac');
    // Publishing to the KMS-encrypted alerts topic needs the topic's key.
    keys.messaging.grant(role, 'kms:GenerateDataKey', 'kms:Decrypt');
    role.addToPolicy(new iam.PolicyStatement({ sid: 'PublishOwnerAlerts', actions: ['sns:Publish'], resources: [n.alertTopicArn] }));
    // Account deletion and retention remove snapshot versions and old crash reports.
    role.addToPolicy(
      new iam.PolicyStatement({
        sid: 'DeleteSnapshotObjects',
        actions: ['s3:DeleteObject', 's3:DeleteObjectVersion', 's3:GetObjectVersion', 's3:GetObject'],
        resources: [n.bucketArn('snapshots', 'accounts/*')],
      }),
    );
    role.addToPolicy(
      new iam.PolicyStatement({
        sid: 'ListSnapshots',
        actions: ['s3:ListBucket', 's3:ListBucketVersions'],
        resources: [n.bucketArn('snapshots')],
      }),
    );
    role.addToPolicy(
      new iam.PolicyStatement({
        sid: 'ExpireCrashReports',
        actions: ['s3:DeleteObject'],
        resources: [n.bucketArn('diagnostics', '*')],
      }),
    );
    role.addToPolicy(new iam.PolicyStatement({ sid: 'ListCrashReports', actions: ['s3:ListBucket'], resources: [n.bucketArn('diagnostics')] }));
    role.addToPolicy(
      new iam.PolicyStatement({
        sid: 'SnapshotObjectsKmsThroughS3',
        actions: ['kms:Decrypt'],
        resources: [keys.s3.keyArn],
        conditions: { StringEquals: { 'kms:ViaService': `s3.${region}.amazonaws.com` } },
      }),
    );
    role.addToPolicy(
      new iam.PolicyStatement({
        sid: 'SendTransactionalEmail',
        actions: ['ses:SendEmail', 'ses:SendRawEmail'],
        resources: [
          `arn:aws:ses:${region}:${this.account}:identity/${this.config.domainName}`,
          `arn:aws:ses:${region}:${this.account}:configuration-set/${n.sesConfigurationSetName}`,
        ],
        conditions: { StringEquals: { 'ses:FromAddress': [n.signInAddress, n.supportAddress] } },
      }),
    );
    acknowledge(
      role.node.findChild('DefaultPolicy'),
      'Deletion and retention sweeps remove objects under keys made per account at run time (snapshots under accounts/, crash reports by random id).',
      `AwsSolutions-IAM5[Resource::${n.bucketArn('snapshots', 'accounts/*')}]`,
      `AwsSolutions-IAM5[Resource::${n.bucketArn('diagnostics', '*')}]`,
    );
  }
}
