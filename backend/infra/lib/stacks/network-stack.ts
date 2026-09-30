import { RemovalPolicy } from 'aws-cdk-lib/core';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as logs from 'aws-cdk-lib/aws-logs';
import type { Construct } from 'constructs';
import { FocusStack, type FocusStackProps } from '../focus-stack';
import { acknowledge } from '../nag';
import { retention } from '../util';

/**
 * VPC across two zones with one NAT gateway (Apple and Google calls leave through it) and VPC
 * endpoints for the AWS services the tasks use, so AWS traffic never crosses the NAT.
 *
 * Subnets:
 *   public   load balancer and the NAT gateway
 *   app      Fargate tasks and the rotation function (egress through NAT)
 *   data     PostgreSQL (no route out at all)
 *
 * Every security group lives here, so rules between them never create cross-stack cycles.
 */
export class NetworkStack extends FocusStack {
  readonly vpc: ec2.Vpc;
  readonly loadBalancerSecurityGroup: ec2.SecurityGroup;
  readonly apiSecurityGroup: ec2.SecurityGroup;
  /** Jobs, migrations and the publisher: no inbound at all. */
  readonly tasksSecurityGroup: ec2.SecurityGroup;
  readonly databaseSecurityGroup: ec2.SecurityGroup;
  readonly rotationSecurityGroup: ec2.SecurityGroup;
  readonly endpointsSecurityGroup: ec2.SecurityGroup;

  constructor(scope: Construct, props: FocusStackProps) {
    super(scope, 'Network', props);
    const { config, naming: n } = this;

    const flowLogGroup = new logs.LogGroup(this, 'RejectedFlowLogs', {
      logGroupName: n.logGroupName('vpc-rejected-flows'),
      // Flow logs hold IP addresses, so they follow the 14-day edge log rule.
      retention: retention(config.edgeLogRetentionDays),
      removalPolicy: RemovalPolicy.DESTROY,
    });

    this.vpc = new ec2.Vpc(this, 'Vpc', {
      vpcName: n.prefix,
      ipAddresses: ec2.IpAddresses.cidr(config.network.cidr),
      availabilityZones: config.network.availabilityZones,
      natGateways: config.network.natGateways,
      subnetConfiguration: [
        { name: 'public', subnetType: ec2.SubnetType.PUBLIC, cidrMask: 24, mapPublicIpOnLaunch: false },
        { name: 'app', subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS, cidrMask: 22 },
        { name: 'data', subnetType: ec2.SubnetType.PRIVATE_ISOLATED, cidrMask: 24 },
      ],
      restrictDefaultSecurityGroup: true,
      flowLogs: {
        rejected: {
          destination: ec2.FlowLogDestination.toCloudWatchLogs(flowLogGroup),
          trafficType: ec2.FlowLogTrafficType.REJECT,
        },
      },
    });

    // Security groups. Egress is limited to what the tasks actually use: HTTPS out (AWS endpoints,
    // Apple, Google, the helpdesk) and PostgreSQL to the database. DNS and time sync use
    // link-local services that security groups don't govern.
    const sg = (id: string, description: string): ec2.SecurityGroup =>
      new ec2.SecurityGroup(this, id, { vpc: this.vpc, description, allowAllOutbound: false });

    this.loadBalancerSecurityGroup = sg('LoadBalancerSecurityGroup', 'API load balancer: HTTPS, and HTTP for the redirect, from the internet');
    this.apiSecurityGroup = sg('ApiSecurityGroup', 'API tasks: the container port from the load balancer only');
    this.tasksSecurityGroup = sg('TasksSecurityGroup', 'Jobs, migrations and publisher tasks: no inbound');
    this.rotationSecurityGroup = sg('RotationSecurityGroup', 'Database credential rotation function: no inbound');
    this.databaseSecurityGroup = sg('DatabaseSecurityGroup', 'PostgreSQL: from the API, tasks and rotation function only');
    this.endpointsSecurityGroup = sg('EndpointsSecurityGroup', 'VPC interface endpoints: HTTPS from inside the VPC');

    this.loadBalancerSecurityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(443), 'HTTPS from anywhere');
    this.loadBalancerSecurityGroup.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(80), 'HTTP from anywhere, redirected to HTTPS');
    this.loadBalancerSecurityGroup.addEgressRule(this.apiSecurityGroup, ec2.Port.tcp(config.api.containerPort), 'To the API tasks');
    this.apiSecurityGroup.addIngressRule(this.loadBalancerSecurityGroup, ec2.Port.tcp(config.api.containerPort), 'From the load balancer');

    for (const [group, label] of [
      [this.apiSecurityGroup, 'API tasks'],
      [this.tasksSecurityGroup, 'jobs, migrations and publisher'],
      [this.rotationSecurityGroup, 'rotation function'],
    ] as const) {
      group.addEgressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(443), 'HTTPS to AWS endpoints, Apple, Google and the helpdesk');
      group.addEgressRule(this.databaseSecurityGroup, ec2.Port.tcp(5432), 'PostgreSQL');
      this.databaseSecurityGroup.addIngressRule(group, ec2.Port.tcp(5432), `PostgreSQL from the ${label}`);
    }
    this.endpointsSecurityGroup.addIngressRule(ec2.Peer.ipv4(config.network.cidr), ec2.Port.tcp(443), 'HTTPS from inside the VPC');

    acknowledge(
      this.loadBalancerSecurityGroup,
      'The public API load balancer must accept HTTPS from any address; AWS WAF on the load balancer filters it. Port 80 only redirects to HTTPS.',
      'AwsSolutions-EC23',
    );

    // Endpoints. S3 is a free gateway endpoint; the rest are interface endpoints with private DNS,
    // so the SDKs reach them without any configuration in the app.
    this.vpc.addGatewayEndpoint('S3Endpoint', {
      service: ec2.GatewayVpcEndpointAwsService.S3,
      subnets: [{ subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS }, { subnetType: ec2.SubnetType.PRIVATE_ISOLATED }],
    });
    const endpointSubnets: ec2.SubnetSelection = {
      subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      availabilityZones: config.network.availabilityZones.slice(0, config.network.interfaceEndpointAzCount),
    };
    const interfaceEndpoints: Record<string, ec2.InterfaceVpcEndpointAwsService> = {
      Kms: ec2.InterfaceVpcEndpointAwsService.KMS,
      SecretsManager: ec2.InterfaceVpcEndpointAwsService.SECRETS_MANAGER,
      EcrApi: ec2.InterfaceVpcEndpointAwsService.ECR,
      EcrDocker: ec2.InterfaceVpcEndpointAwsService.ECR_DOCKER,
      CloudWatchLogs: ec2.InterfaceVpcEndpointAwsService.CLOUDWATCH_LOGS,
      Ssm: ec2.InterfaceVpcEndpointAwsService.SSM,
      Sts: ec2.InterfaceVpcEndpointAwsService.STS,
    };
    for (const [id, service] of Object.entries(interfaceEndpoints)) {
      this.vpc.addInterfaceEndpoint(`${id}Endpoint`, {
        service,
        subnets: endpointSubnets,
        privateDnsEnabled: true,
        securityGroups: [this.endpointsSecurityGroup],
        open: false,
      });
    }
  }
}
