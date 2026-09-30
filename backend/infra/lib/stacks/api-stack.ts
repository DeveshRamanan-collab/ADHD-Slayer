import { CfnOutput, Duration, RemovalPolicy, Stack } from 'aws-cdk-lib/core';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as events from 'aws-cdk-lib/aws-events';
import * as eventsTargets from 'aws-cdk-lib/aws-events-targets';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as route53Targets from 'aws-cdk-lib/aws-route53-targets';
import * as sfn from 'aws-cdk-lib/aws-stepfunctions';
import * as tasks from 'aws-cdk-lib/aws-stepfunctions-tasks';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as wafv2 from 'aws-cdk-lib/aws-wafv2';
import type { Construct } from 'constructs';
import { FocusTaskDefinition } from '../constructs/focus-task-definition';
import { FocusStack, type FocusStackProps } from '../focus-stack';
import { acknowledge } from '../nag';
import { buildTaskEnvironment } from '../task-environment';
import { retention } from '../util';
import type { DataStack } from './data-stack';
import type { KeysStack } from './keys-stack';
import type { NetworkStack } from './network-stack';
import type { RegistryStack } from './registry-stack';
import type { SecretsStack } from './secrets-stack';

export interface ApiStackProps extends FocusStackProps {
  readonly network: NetworkStack;
  readonly keys: KeysStack;
  readonly secrets: SecretsStack;
  readonly data: DataStack;
  readonly registry: RegistryStack;
}

/** WAF response body for the per-IP rate rule, in the API's error format (CONTRACT.md). */
const RATE_LIMITED_BODY = JSON.stringify({
  error: { code: 'RATE_LIMITED', message: 'Too many requests from this address', details: {}, retryAfterSeconds: 300 },
});

/**
 * The API on ECS Fargate behind an HTTPS-only load balancer with AWS WAF, plus the task
 * definitions the pipeline runs around it (migrations) and the config publisher.
 */
export class ApiStack extends FocusStack {
  readonly cluster: ecs.Cluster;
  readonly service: ecs.FargateService;
  readonly loadBalancer: elbv2.ApplicationLoadBalancer;
  readonly targetGroup: elbv2.ApplicationTargetGroup;
  readonly api: FocusTaskDefinition;
  readonly migrate: FocusTaskDefinition;
  readonly publish: FocusTaskDefinition;
  readonly image: ecs.ContainerImage;
  readonly webAcl: wafv2.CfnWebACL;

  constructor(scope: Construct, props: ApiStackProps) {
    super(scope, 'Api', props);
    const { config, naming: n } = this;
    const { network, keys, secrets, data, registry } = props;

    const zone = route53.HostedZone.fromHostedZoneAttributes(this, 'Zone', {
      hostedZoneId: config.hostedZoneId,
      zoneName: config.hostedZoneName,
    });

    // The live tag is resolved by CloudFormation at deploy time from the parameter the pipeline
    // writes, so infrastructure deploys never roll the image back.
    const imageTag = ssm.StringParameter.valueForStringParameter(this, registry.imageTagParameterName);
    this.image = ecs.ContainerImage.fromEcrRepository(registry.repository, imageTag);
    const taskEnvironment = buildTaskEnvironment({ config, keys, data, secrets });

    this.cluster = new ecs.Cluster(this, 'Cluster', {
      clusterName: n.clusterName,
      vpc: network.vpc,
      containerInsightsV2: ecs.ContainerInsights.ENABLED,
      enableFargateCapacityProviders: true,
    });

    // ---------------------------------------------------------------- task definitions
    this.api = new FocusTaskDefinition(this, 'ApiTask', {
      config,
      family: 'api',
      description: 'the HTTP API',
      image: this.image,
      cpu: config.api.cpu,
      memoryMiB: config.api.memoryMiB,
      containerPort: config.api.containerPort,
      environment: taskEnvironment.environment,
      secrets: taskEnvironment.secrets,
      readonlyRootFilesystem: true,
    });
    this.migrate = new FocusTaskDefinition(this, 'MigrateTask', {
      config,
      family: 'migrate',
      description: 'forward-only database migrations, run by the pipeline before each rollout',
      image: this.image,
      cpu: config.jobs.cpu,
      memoryMiB: config.jobs.memoryMiB,
      command: config.commands.migrate,
      environment: taskEnvironment.environment,
      secrets: taskEnvironment.secrets,
      readonlyRootFilesystem: true,
    });
    this.publish = new FocusTaskDefinition(this, 'PublishTask', {
      config,
      family: 'publish',
      description: 'signs and publishes config and copy decks (the only user of the config signing key)',
      image: this.image,
      cpu: config.jobs.cpu,
      memoryMiB: config.jobs.memoryMiB,
      command: config.commands.publish,
      environment: taskEnvironment.environment,
      secrets: taskEnvironment.secrets,
      readonlyRootFilesystem: false,
    });

    this.grantApiPermissions(this.api.taskRole, props);
    this.grantPublisherPermissions(this.publish.taskRole, props);
    // The migrate task role has no AWS permissions at all: migrations only talk to PostgreSQL.

    for (const task of [this.api, this.migrate, this.publish]) {
      task.acknowledgeExecutionRoleWildcards();
    }

    // ---------------------------------------------------------------- load balancer
    this.loadBalancer = new elbv2.ApplicationLoadBalancer(this, 'LoadBalancer', {
      loadBalancerName: n.resource('api'),
      vpc: network.vpc,
      internetFacing: true,
      vpcSubnets: { subnetType: ec2.SubnetType.PUBLIC },
      securityGroup: network.loadBalancerSecurityGroup,
      dropInvalidHeaderFields: true,
      deletionProtection: config.isProduction,
      idleTimeout: Duration.seconds(60),
      http2Enabled: true,
    });
    this.loadBalancer.logAccessLogs(data.accessLogs, 'alb/api');

    const certificate = new acm.Certificate(this, 'ApiCertificate', {
      certificateName: `${n.prefix}-api`,
      domainName: n.apiHost,
      validation: acm.CertificateValidation.fromDns(zone),
    });

    this.targetGroup = new elbv2.ApplicationTargetGroup(this, 'ApiTargets', {
      vpc: network.vpc,
      port: config.api.containerPort,
      protocol: elbv2.ApplicationProtocol.HTTP,
      targetType: elbv2.TargetType.IP,
      deregistrationDelay: Duration.seconds(30),
      healthCheck: {
        path: config.api.healthCheckPath,
        healthyHttpCodes: '200',
        interval: Duration.seconds(15),
        timeout: Duration.seconds(5),
        healthyThresholdCount: 2,
        unhealthyThresholdCount: 3,
      },
    });

    this.loadBalancer.addListener('Https', {
      port: 443,
      protocol: elbv2.ApplicationProtocol.HTTPS,
      certificates: [certificate],
      // TLS 1.3 and TLS 1.2 with forward-secret AES-GCM suites only, plus hybrid post-quantum key
      // exchange. iOS, Apple's and AWS's webhook senders all support it.
      sslPolicy: elbv2.SslPolicy.TLS13_12_RES_PQ,
      open: false,
      defaultTargetGroups: [this.targetGroup],
    });
    this.loadBalancer.addListener('HttpRedirect', {
      port: 80,
      protocol: elbv2.ApplicationProtocol.HTTP,
      open: false,
      defaultAction: elbv2.ListenerAction.redirect({ protocol: 'HTTPS', port: '443', permanent: true }),
    });

    new route53.ARecord(this, 'ApiRecord', {
      zone,
      recordName: n.apiHost,
      target: route53.RecordTarget.fromAlias(new route53Targets.LoadBalancerTarget(this.loadBalancer)),
    });

    // ---------------------------------------------------------------- service
    this.service = new ecs.FargateService(this, 'ApiService', {
      serviceName: n.apiServiceName,
      cluster: this.cluster,
      taskDefinition: this.api.taskDefinition,
      desiredCount: config.api.desiredCount,
      minHealthyPercent: 100,
      maxHealthyPercent: 200,
      circuitBreaker: { enable: true, rollback: true },
      vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS },
      securityGroups: [network.apiSecurityGroup],
      assignPublicIp: false,
      healthCheckGracePeriod: Duration.seconds(60),
      platformVersion: ecs.FargatePlatformVersion.LATEST,
      propagateTags: ecs.PropagatedTagSource.SERVICE,
      enableECSManagedTags: true,
      availabilityZoneRebalancing: ecs.AvailabilityZoneRebalancing.ENABLED,
    });
    this.service.attachToApplicationTargetGroup(this.targetGroup);

    // ---------------------------------------------------------------- WAF
    this.webAcl = this.createWebAcl();
    new wafv2.CfnWebACLAssociation(this, 'WebAclAssociation', {
      resourceArn: this.loadBalancer.loadBalancerArn,
      webAclArn: this.webAcl.attrArn,
    });

    // ---------------------------------------------------------------- rotation follow-up
    this.redeployAfterSecretRotation();

    // ---------------------------------------------------------------- values for the pipeline
    // Names follow conventions (scripts/lib.sh); only the network ids are looked up.
    new ssm.StringParameter(this, 'DeployNetworkParameter', {
      parameterName: n.parameterName('deploy/network'),
      description: 'Subnets and security group for one-off tasks (migrations, publisher). Read by backend/infra/scripts.',
      stringValue: Stack.of(this).toJsonString({
        subnets: network.vpc.selectSubnets({ subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS }).subnetIds,
        securityGroups: [network.tasksSecurityGroup.securityGroupId],
      }),
    });

    new CfnOutput(this, 'LoadBalancerDnsName', { value: this.loadBalancer.loadBalancerDnsName });
    new CfnOutput(this, 'ApiUrl', { value: n.publicApiUrl });
    new CfnOutput(this, 'ClusterName', { value: this.cluster.clusterName });
    new CfnOutput(this, 'ServiceName', { value: this.service.serviceName });
  }

  /** Least-privilege identity policy for the API task role. */
  private grantApiPermissions(role: iam.Role, props: ApiStackProps): void {
    const { keys, data } = props;
    const n = this.naming;
    const region = this.config.primaryRegion;

    keys.appEnvelope.grant(role, 'kms:Encrypt', 'kms:Decrypt', 'kms:GenerateDataKey');
    keys.magicLinkHmac.grant(role, 'kms:GenerateMac', 'kms:VerifyMac');
    keys.receiptHmac.grant(role, 'kms:GenerateMac', 'kms:VerifyMac');
    // Public key only: the API never signs config.
    keys.configSigning.grant(role, 'kms:GetPublicKey', 'kms:DescribeKey');
    // Presigned snapshot uploads and downloads run with the API role, through S3 only.
    role.addToPolicy(
      new iam.PolicyStatement({
        sid: 'SnapshotObjectsKmsThroughS3',
        actions: ['kms:GenerateDataKey', 'kms:Decrypt'],
        resources: [keys.s3.keyArn],
        conditions: { StringEquals: { 'kms:ViaService': `s3.${region}.amazonaws.com` } },
      }),
    );

    role.addToPolicy(
      new iam.PolicyStatement({
        sid: 'SnapshotObjects',
        actions: [
          's3:PutObject',
          's3:GetObject',
          's3:GetObjectVersion',
          's3:GetObjectAttributes',
          's3:GetObjectVersionAttributes',
          's3:DeleteObject',
          's3:DeleteObjectVersion',
        ],
        resources: [n.bucketArn('snapshots', 'accounts/*')],
      }),
    );
    role.addToPolicy(
      new iam.PolicyStatement({
        sid: 'SnapshotBucket',
        actions: ['s3:ListBucket', 's3:ListBucketVersions', 's3:GetEncryptionConfiguration'],
        resources: [n.bucketArn('snapshots')],
      }),
    );
    role.addToPolicy(
      new iam.PolicyStatement({ sid: 'CrashReportUploads', actions: ['s3:PutObject'], resources: [n.bucketArn('diagnostics', '*')] }),
    );
    role.addToPolicy(new iam.PolicyStatement({ sid: 'ReadContent', actions: ['s3:GetObject'], resources: [n.bucketArn('content', '*')] }));
    role.addToPolicy(new iam.PolicyStatement({ sid: 'ListContent', actions: ['s3:ListBucket'], resources: [n.bucketArn('content')] }));
    role.addToPolicy(this.sendEmailStatement());

    acknowledge(
      role.node.findChild('DefaultPolicy'),
      'Object keys are made per account at run time: snapshots are limited to the accounts/ prefix (CONTRACT.md), crash reports and signed content to their own buckets.',
      `AwsSolutions-IAM5[Resource::${n.bucketArn('snapshots', 'accounts/*')}]`,
      `AwsSolutions-IAM5[Resource::${n.bucketArn('diagnostics', '*')}]`,
      `AwsSolutions-IAM5[Resource::${n.bucketArn('content', '*')}]`,
    );
    void data;
  }

  private grantPublisherPermissions(role: iam.Role, props: ApiStackProps): void {
    const { keys } = props;
    const n = this.naming;
    keys.configSigning.grant(role, 'kms:Sign', 'kms:GetPublicKey', 'kms:DescribeKey');
    role.addToPolicy(
      new iam.PolicyStatement({
        sid: 'ContentKmsThroughS3',
        actions: ['kms:GenerateDataKey', 'kms:Decrypt'],
        resources: [keys.s3.keyArn],
        conditions: { StringEquals: { 'kms:ViaService': `s3.${this.config.primaryRegion}.amazonaws.com` } },
      }),
    );
    role.addToPolicy(
      new iam.PolicyStatement({ sid: 'WriteContent', actions: ['s3:PutObject', 's3:GetObject'], resources: [n.bucketArn('content', '*')] }),
    );
    role.addToPolicy(new iam.PolicyStatement({ sid: 'ListContent', actions: ['s3:ListBucket'], resources: [n.bucketArn('content')] }));
    acknowledge(
      role.node.findChild('DefaultPolicy'),
      'The publisher writes new config and copy deck objects whose keys include their version, so it needs the whole content bucket.',
      `AwsSolutions-IAM5[Resource::${n.bucketArn('content', '*')}]`,
    );
  }

  /** SES v2 SendEmail from the two transactional addresses only, through the Focus configuration set. */
  sendEmailStatement(): iam.PolicyStatement {
    const n = this.naming;
    const { primaryRegion: region, account } = this.config;
    return new iam.PolicyStatement({
      sid: 'SendTransactionalEmail',
      actions: ['ses:SendEmail', 'ses:SendRawEmail'],
      resources: [
        `arn:aws:ses:${region}:${account}:identity/${this.config.domainName}`,
        `arn:aws:ses:${region}:${account}:configuration-set/${n.sesConfigurationSetName}`,
      ],
      conditions: { StringEquals: { 'ses:FromAddress': [n.signInAddress, n.supportAddress] } },
    });
  }

  private createWebAcl(): wafv2.CfnWebACL {
    const n = this.naming;
    const visibility = (metricName: string): wafv2.CfnWebACL.VisibilityConfigProperty => ({
      cloudWatchMetricsEnabled: true,
      metricName,
      sampledRequestsEnabled: true,
    });
    const managed = (priority: number, name: string, extra: Partial<wafv2.CfnWebACL.ManagedRuleGroupStatementProperty> = {}): wafv2.CfnWebACL.RuleProperty => ({
      name: `aws-${name}`,
      priority,
      overrideAction: { none: {} },
      statement: { managedRuleGroupStatement: { vendorName: 'AWS', name, ...extra } },
      visibilityConfig: visibility(`${n.prefix}-${name}`),
    });

    const webAcl = new wafv2.CfnWebACL(this, 'WebAcl', {
      name: n.resource('api'),
      description: 'Focus API: per-IP rate limit and AWS managed rules',
      scope: 'REGIONAL',
      defaultAction: { allow: {} },
      visibilityConfig: visibility(`${n.prefix}-api`),
      customResponseBodies: {
        'rate-limited': { contentType: 'APPLICATION_JSON', content: RATE_LIMITED_BODY },
      },
      rules: [
        {
          // 02-backend.md, Rate limits: "Anything: 2,000 per 5 minutes, keyed by IP at the WAF".
          name: 'rate-limit-per-ip',
          priority: 0,
          action: {
            block: {
              customResponse: {
                responseCode: 429,
                customResponseBodyKey: 'rate-limited',
                responseHeaders: [{ name: 'Retry-After', value: '300' }],
              },
            },
          },
          statement: {
            rateBasedStatement: {
              limit: this.config.wafRateLimitPer5Minutes,
              evaluationWindowSec: 300,
              aggregateKeyType: 'IP',
            },
          },
          visibilityConfig: visibility(`${n.prefix}-rate-limit-per-ip`),
        },
        managed(1, 'AWSManagedRulesAmazonIpReputationList'),
        managed(2, 'AWSManagedRulesKnownBadInputsRuleSet'),
        managed(3, 'AWSManagedRulesCommonRuleSet', {
          // The core set blocks bodies over 8 KB. The API accepts up to 64 KB (256 KB for crash
          // reports) and enforces those limits itself, so this one rule only counts.
          ruleActionOverrides: [{ name: 'SizeRestrictions_BODY', actionToUse: { count: {} } }],
        }),
      ],
    });

    // WAF logs hold client IP addresses: 14 days (02-backend.md). Only blocked and counted
    // requests are logged, and the Authorization and device proof headers are redacted.
    const wafLogs = new logs.LogGroup(this, 'WafLogs', {
      // WAF requires the aws-waf-logs- prefix.
      logGroupName: `aws-waf-logs-${n.prefix}-api`,
      retention: retention(this.config.edgeLogRetentionDays),
      removalPolicy: RemovalPolicy.DESTROY,
    });
    new wafv2.CfnLoggingConfiguration(this, 'WafLogging', {
      resourceArn: webAcl.attrArn,
      logDestinationConfigs: [wafLogs.logGroupArn],
      redactedFields: [
        { singleHeader: { Name: 'authorization' } },
        { singleHeader: { Name: 'x-device-signature' } },
        { singleHeader: { Name: 'cookie' } },
      ],
      loggingFilter: {
        DefaultBehavior: 'DROP',
        Filters: [
          {
            Behavior: 'KEEP',
            Requirement: 'MEETS_ANY',
            Conditions: [{ ActionCondition: { Action: 'BLOCK' } }, { ActionCondition: { Action: 'COUNT' } }],
          },
        ],
      },
    });
    return webAcl;
  }

  /**
   * Single-user rotation changes the database password in place. Running tasks keep their open
   * connections, but new connections need the new password, which ECS only injects at task start.
   * After each successful rotation this forces a new deployment so fresh tasks replace old ones
   * within a few minutes (README, "Database credential rotation").
   */
  private redeployAfterSecretRotation(): void {
    const n = this.naming;
    const logGroup = new logs.LogGroup(this, 'RedeployLogs', {
      logGroupName: n.logGroupName('api-redeploy'),
      retention: retention(this.config.logRetentionDays),
      removalPolicy: RemovalPolicy.DESTROY,
    });
    const forceNewDeployment = new tasks.CallAwsService(this, 'ForceNewDeployment', {
      service: 'ecs',
      action: 'updateService',
      parameters: { Cluster: this.cluster.clusterName, Service: this.service.serviceName, ForceNewDeployment: true },
      iamResources: [this.service.serviceArn],
    });
    const stateMachine = new sfn.StateMachine(this, 'RedeployAfterRotation', {
      stateMachineName: n.resource('api-redeploy'),
      stateMachineType: sfn.StateMachineType.EXPRESS,
      definitionBody: sfn.DefinitionBody.fromChainable(forceNewDeployment),
      timeout: Duration.minutes(1),
      tracingEnabled: true,
      logs: { destination: logGroup, level: sfn.LogLevel.ALL, includeExecutionData: false },
    });
    acknowledge(
      stateMachine.role.node.findChild('DefaultPolicy'),
      'CloudWatch Logs delivery (logs:CreateLogDelivery and friends) and X-Ray (xray:PutTraceSegments) have no resource-level permissions. The only other action, ecs:UpdateService, names the API service.',
      'AwsSolutions-IAM5[Resource::*]',
    );
    new events.Rule(this, 'DatabaseSecretRotated', {
      ruleName: n.resource('db-secret-rotated'),
      description: 'Redeploys the API after a Secrets Manager rotation so new tasks read the new database password',
      eventPattern: {
        source: ['aws.secretsmanager'],
        detailType: ['AWS Service Event via CloudTrail'],
        detail: { eventSource: ['secretsmanager.amazonaws.com'], eventName: ['RotationSucceeded'] },
      },
      targets: [new eventsTargets.SfnStateMachine(stateMachine)],
    });
  }
}
