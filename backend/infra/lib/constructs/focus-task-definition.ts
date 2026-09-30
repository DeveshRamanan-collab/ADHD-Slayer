import { Duration, RemovalPolicy, Size, Stack } from 'aws-cdk-lib/core';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as logs from 'aws-cdk-lib/aws-logs';
import { Construct } from 'constructs';
import { Naming, type EnvironmentConfig } from '../config';
import { acknowledge } from '../nag';
import { retention } from '../util';

export type TaskFamily = 'api' | 'migrate' | 'publish' | 'jobs';

export interface FocusTaskDefinitionProps {
  readonly config: EnvironmentConfig;
  readonly family: TaskFamily;
  readonly image: ecs.ContainerImage;
  readonly cpu: number;
  readonly memoryMiB: number;
  readonly environment: Record<string, string>;
  readonly secrets: Record<string, ecs.Secret>;
  /** Overrides the image's CMD. */
  readonly command?: string[];
  readonly containerPort?: number;
  /**
   * Read-only root filesystem with a writable /tmp. On for node processes; off for the publisher,
   * whose `npm run` writes a cache under the home directory.
   */
  readonly readonlyRootFilesystem: boolean;
  readonly description: string;
}

/**
 * One Fargate task definition family (`focus-<env>-<family>`) with one container of the same name.
 *
 * Role names are fixed (`focus-<env>-<family>-task` and `-exec`) so the pipeline's PassRole
 * permission can be scoped by name, and the family name is fixed so the pipeline can register new
 * revisions of it. The pipeline clones the latest revision and swaps only the image.
 */
export class FocusTaskDefinition extends Construct {
  readonly taskDefinition: ecs.FargateTaskDefinition;
  readonly container: ecs.ContainerDefinition;
  readonly taskRole: iam.Role;
  readonly executionRole: iam.Role;
  readonly logGroup: logs.LogGroup;
  readonly containerName: string;

  constructor(scope: Construct, id: string, props: FocusTaskDefinitionProps) {
    super(scope, id);
    const { config, family } = props;
    const n = new Naming(config);
    const stack = Stack.of(this);

    this.logGroup = new logs.LogGroup(this, 'Logs', {
      logGroupName: n.logGroupName(family),
      retention: retention(config.logRetentionDays),
      removalPolicy: RemovalPolicy.DESTROY,
    });

    this.taskRole = new iam.Role(this, 'TaskRole', {
      roleName: n.resource(`${family}-task`),
      description: `Focus ${config.envName} ${family} task: ${props.description}`,
      // Confused-deputy protection: only ECS tasks in this account and region may assume it.
      assumedBy: new iam.ServicePrincipal('ecs-tasks.amazonaws.com', {
        conditions: {
          ArnLike: { 'aws:SourceArn': `arn:aws:ecs:${stack.region}:${stack.account}:*` },
          StringEquals: { 'aws:SourceAccount': stack.account },
        },
      }),
    });
    this.executionRole = new iam.Role(this, 'ExecutionRole', {
      roleName: n.resource(`${family}-exec`),
      description: `Focus ${config.envName} ${family} task execution: pulls the image, reads its secrets, writes its logs`,
      assumedBy: new iam.ServicePrincipal('ecs-tasks.amazonaws.com'),
    });

    this.taskDefinition = new ecs.FargateTaskDefinition(this, 'TaskDefinition', {
      family: n.family(family),
      cpu: props.cpu,
      memoryLimitMiB: props.memoryMiB,
      taskRole: this.taskRole,
      executionRole: this.executionRole,
      runtimePlatform: {
        operatingSystemFamily: ecs.OperatingSystemFamily.LINUX,
        cpuArchitecture: config.api.cpuArchitecture === 'ARM64' ? ecs.CpuArchitecture.ARM64 : ecs.CpuArchitecture.X86_64,
      },
    });

    this.containerName = family;
    this.container = this.taskDefinition.addContainer(family, {
      containerName: family,
      image: props.image,
      command: props.command,
      environment: props.environment,
      secrets: props.secrets,
      essential: true,
      readonlyRootFilesystem: props.readonlyRootFilesystem,
      stopTimeout: Duration.seconds(30),
      linuxParameters: new ecs.LinuxParameters(this, 'LinuxParameters', { initProcessEnabled: true }),
      logging: ecs.LogDrivers.awsLogs({
        logGroup: this.logGroup,
        streamPrefix: family,
        // Never block the app on log back-pressure; drop instead.
        mode: ecs.AwsLogDriverMode.NON_BLOCKING,
        maxBufferSize: Size.mebibytes(25),
      }),
      portMappings: props.containerPort ? [{ containerPort: props.containerPort, protocol: ecs.Protocol.TCP, name: 'http' }] : undefined,
    });

    if (props.readonlyRootFilesystem) {
      this.taskDefinition.addVolume({ name: 'tmp' });
      this.container.addMountPoints({ sourceVolume: 'tmp', containerPath: '/tmp', readOnly: false });
    }

    acknowledge(
      this.taskDefinition,
      'Only non-secret configuration is passed as plain environment variables (bucket names, key ARNs, URLs, ids). Every secret uses ECS secrets from Secrets Manager.',
      'AwsSolutions-ECS2',
    );
  }

  /** Acknowledges the wildcard that every ECS execution role needs to log in to ECR. */
  acknowledgeExecutionRoleWildcards(extraFindings: string[] = []): void {
    acknowledge(
      this.executionRole.node.findChild('DefaultPolicy'),
      'ecr:GetAuthorizationToken has no resource-level permissions, so AWS requires Resource "*". Everything else in this policy names its resources.',
      'AwsSolutions-IAM5[Resource::*]',
      ...extraFindings,
    );
  }
}
