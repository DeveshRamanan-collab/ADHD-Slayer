import { CfnOutput, Duration, RemovalPolicy } from 'aws-cdk-lib/core';
import * as iam from 'aws-cdk-lib/aws-iam';
import type { Construct } from 'constructs';
import { FocusStack, type FocusStackProps } from '../focus-stack';
import { acknowledge } from '../nag';

const GITHUB_OIDC_HOST = 'token.actions.githubusercontent.com';

/**
 * The role GitHub Actions assumes (OIDC, no stored keys) to ship a new image: push to ECR, run
 * migrations, register task definition revisions, roll the service, watch the 5xx alarm, roll
 * back, and publish the website.
 *
 * It can't change infrastructure. `cdk deploy` stays a human step with SSO credentials.
 *
 * Trust: staging accepts the main branch (and the `staging` GitHub environment); production
 * accepts only jobs running in the `production` GitHub environment, which has required reviewers.
 *
 * Every resource is named by convention, so this stack has no references to the others and can be
 * deployed first (its role ARN goes into the GitHub repository variables).
 */
export class CiStack extends FocusStack {
  readonly deployRole: iam.Role;

  constructor(scope: Construct, props: FocusStackProps) {
    super(scope, 'Ci', props);
    const { config, naming: n } = this;
    const { account, primaryRegion: region, envName } = config;

    const providerArn = `arn:aws:iam::${account}:oidc-provider/${GITHUB_OIDC_HOST}`;
    if (config.github.createOidcProvider) {
      const provider = new iam.OidcProviderNative(this, 'GithubOidcProvider', {
        url: `https://${GITHUB_OIDC_HOST}`,
        clientIds: ['sts.amazonaws.com'],
        removalPolicy: RemovalPolicy.RETAIN,
      });
      void provider;
    }

    const repo = config.github.repository;
    const subjects = config.isProduction
      ? [`repo:${repo}:environment:production`]
      : [`repo:${repo}:ref:refs/heads/main`, `repo:${repo}:environment:staging`];

    this.deployRole = new iam.Role(this, 'DeployRole', {
      roleName: n.resource('github-deploy'),
      description: `GitHub Actions deploys for Focus ${envName} (${repo})`,
      maxSessionDuration: Duration.hours(1),
      assumedBy: new iam.WebIdentityPrincipal(providerArn, {
        StringEquals: {
          [`${GITHUB_OIDC_HOST}:aud`]: 'sts.amazonaws.com',
          [`${GITHUB_OIDC_HOST}:sub`]: subjects,
        },
      }),
    });

    const ecs = (resource: string) => `arn:aws:ecs:${region}:${account}:${resource}`;
    const cluster = ecs(`cluster/${n.clusterName}`);
    const families = (['api', 'migrate', 'publish', 'jobs'] as const).map((f) => ecs(`task-definition/${n.family(f)}:*`));
    const repository = `arn:aws:ecr:${region}:${account}:repository/${n.repositoryName}`;
    const statements: iam.PolicyStatement[] = [
      new iam.PolicyStatement({ sid: 'EcrLogin', actions: ['ecr:GetAuthorizationToken'], resources: ['*'] }),
      new iam.PolicyStatement({
        sid: 'PushImages',
        actions: [
          'ecr:BatchCheckLayerAvailability',
          'ecr:BatchGetImage',
          'ecr:CompleteLayerUpload',
          'ecr:DescribeImages',
          'ecr:GetDownloadUrlForLayer',
          'ecr:InitiateLayerUpload',
          'ecr:PutImage',
          'ecr:UploadLayerPart',
        ],
        resources: [repository],
      }),
      // Register, describe and deregister have no resource-level permissions in ECS.
      new iam.PolicyStatement({
        sid: 'TaskDefinitions',
        actions: ['ecs:RegisterTaskDefinition', 'ecs:DescribeTaskDefinition', 'ecs:DeregisterTaskDefinition', 'ecs:ListTaskDefinitions'],
        resources: ['*'],
      }),
      new iam.PolicyStatement({
        sid: 'TagNewRevisionsAndTasks',
        actions: ['ecs:TagResource'],
        resources: [ecs('task-definition/*'), ecs(`task/${n.clusterName}/*`)],
        conditions: { StringEquals: { 'ecs:CreateAction': ['RegisterTaskDefinition', 'RunTask'] } },
      }),
      new iam.PolicyStatement({
        sid: 'RollTheApiService',
        actions: ['ecs:UpdateService', 'ecs:DescribeServices'],
        resources: [ecs(`service/${n.clusterName}/${n.apiServiceName}`)],
      }),
      new iam.PolicyStatement({
        sid: 'RunMigrationsAndPublisher',
        actions: ['ecs:RunTask'],
        resources: families,
        conditions: { ArnEquals: { 'ecs:cluster': cluster } },
      }),
      new iam.PolicyStatement({
        sid: 'WatchTasks',
        actions: ['ecs:DescribeTasks', 'ecs:StopTask'],
        resources: [ecs(`task/${n.clusterName}/*`)],
      }),
      new iam.PolicyStatement({
        sid: 'PassTaskRoles',
        actions: ['iam:PassRole'],
        resources: [`arn:aws:iam::${account}:role/${n.prefix}-*-task`, `arn:aws:iam::${account}:role/${n.prefix}-*-exec`],
        conditions: { StringEquals: { 'iam:PassedToService': 'ecs-tasks.amazonaws.com' } },
      }),
      new iam.PolicyStatement({
        sid: 'ReadDeployParameters',
        actions: ['ssm:GetParameter', 'ssm:GetParameters'],
        resources: [`arn:aws:ssm:${region}:${account}:parameter/focus/${envName}/*`],
      }),
      new iam.PolicyStatement({
        sid: 'RecordLiveImage',
        actions: ['ssm:PutParameter'],
        resources: [`arn:aws:ssm:${region}:${account}:parameter${n.imageTagParameterName}`],
      }),
      new iam.PolicyStatement({
        sid: 'WatchTheErrorAlarm',
        actions: ['cloudwatch:DescribeAlarms'],
        resources: [`arn:aws:cloudwatch:${region}:${account}:alarm:${n.alarmName('api-5xx')}`],
      }),
      new iam.PolicyStatement({
        sid: 'ReadTaskLogs',
        actions: ['logs:GetLogEvents', 'logs:FilterLogEvents'],
        resources: (['migrate', 'publish', 'api'] as const).map((f) => `arn:aws:logs:${region}:${account}:log-group:${n.logGroupName(f)}:*`),
      }),
      new iam.PolicyStatement({
        sid: 'PublishWebsite',
        actions: ['s3:PutObject', 's3:DeleteObject', 's3:GetObject'],
        resources: [n.bucketArn('website', '*')],
      }),
      new iam.PolicyStatement({ sid: 'ListWebsite', actions: ['s3:ListBucket'], resources: [n.bucketArn('website')] }),
      new iam.PolicyStatement({
        sid: 'InvalidateWebsiteCache',
        actions: ['cloudfront:CreateInvalidation', 'cloudfront:GetInvalidation'],
        resources: [`arn:aws:cloudfront::${account}:distribution/*`],
      }),
    ];
    if (config.imageSourceRepositoryArn) {
      // Production copies the exact image that passed staging (the staging registry allows it).
      statements.push(
        new iam.PolicyStatement({
          sid: 'PullTestedImagesFromStaging',
          actions: ['ecr:BatchGetImage', 'ecr:GetDownloadUrlForLayer', 'ecr:BatchCheckLayerAvailability', 'ecr:DescribeImages'],
          resources: [config.imageSourceRepositoryArn],
        }),
      );
    }
    const policy = new iam.Policy(this, 'DeployPolicy', { policyName: 'deploy', statements });
    policy.attachToRole(this.deployRole);

    acknowledge(
      policy,
      'ecr:GetAuthorizationToken and ECS RegisterTaskDefinition, DescribeTaskDefinition, DeregisterTaskDefinition and ListTaskDefinitions have no resource-level permissions. Every other wildcard stays inside this environment: its four task families (new revisions each deploy), its cluster tasks, its focus-<env>-*-task and -exec roles, its /focus/<env>/ parameters, its log groups, its website objects and its CloudFront distributions.',
      'AwsSolutions-IAM5[Resource::*]',
      ...families.map((f) => `AwsSolutions-IAM5[Resource::${f}]`),
      `AwsSolutions-IAM5[Resource::${ecs('task-definition/*')}]`,
      `AwsSolutions-IAM5[Resource::${ecs(`task/${n.clusterName}/*`)}]`,
      `AwsSolutions-IAM5[Resource::arn:aws:iam::${account}:role/${n.prefix}-*-task]`,
      `AwsSolutions-IAM5[Resource::arn:aws:iam::${account}:role/${n.prefix}-*-exec]`,
      `AwsSolutions-IAM5[Resource::arn:aws:ssm:${region}:${account}:parameter/focus/${envName}/*]`,
      ...(['migrate', 'publish', 'api'] as const).map((f) => `AwsSolutions-IAM5[Resource::arn:aws:logs:${region}:${account}:log-group:${n.logGroupName(f)}:*]`),
      `AwsSolutions-IAM5[Resource::${n.bucketArn('website', '*')}]`,
      `AwsSolutions-IAM5[Resource::arn:aws:cloudfront::${account}:distribution/*]`,
    );

    new CfnOutput(this, 'DeployRoleArn', {
      value: this.deployRole.roleArn,
      description: `Set as the GitHub repository variable AWS_${envName.toUpperCase()}_DEPLOY_ROLE_ARN`,
    });
  }
}
