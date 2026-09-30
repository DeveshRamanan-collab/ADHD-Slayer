import { Duration, RemovalPolicy, type CfnResource } from 'aws-cdk-lib/core';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as cwActions from 'aws-cdk-lib/aws-cloudwatch-actions';
import * as kms from 'aws-cdk-lib/aws-kms';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as subscriptions from 'aws-cdk-lib/aws-sns-subscriptions';
import type { Construct } from 'constructs';
import { FocusStack, type FocusStackProps } from '../focus-stack';
import { acknowledge } from '../nag';

/**
 * Everything AWS requires in us-east-1:
 *   - ACM certificates for the two CloudFront distributions (web and cdn)
 *   - the DNSSEC key signing key (Route 53 only accepts a KMS key in us-east-1)
 *   - the external /healthz check and its alarm (Route 53 health check metrics exist only here)
 *
 * The Edge stack in Sydney reads the certificate ARNs through weak cross-region references
 * (Fn::GetStackOutput), so no custom resources are involved.
 */
export class GlobalStack extends FocusStack {
  readonly webCertificate: acm.Certificate;
  readonly cdnCertificate: acm.Certificate;
  readonly healthCheckId: string;

  constructor(scope: Construct, props: FocusStackProps) {
    super(scope, 'Global', props, 'global');
    const { config, naming: n } = this;

    const zone = route53.HostedZone.fromHostedZoneAttributes(this, 'Zone', {
      hostedZoneId: config.hostedZoneId,
      zoneName: config.hostedZoneName,
    });

    this.webCertificate = new acm.Certificate(this, 'WebCertificate', {
      certificateName: `${n.prefix}-web`,
      domainName: n.webHost,
      subjectAlternativeNames: [n.wwwHost],
      validation: acm.CertificateValidation.fromDns(zone),
    });
    this.cdnCertificate = new acm.Certificate(this, 'CdnCertificate', {
      certificateName: `${n.prefix}-cdn`,
      domainName: n.cdnHost,
      validation: acm.CertificateValidation.fromDns(zone),
    });

    // DNSSEC signing. After the first deploy the owner adds the DS record at the parent zone
    // (README, "DNSSEC"). The key signing key needs an asymmetric P-256 KMS key in us-east-1;
    // the KeySigningKey construct adds the Route 53 service statements to its key policy.
    const dnssecKey = new kms.Key(this, 'DnssecKey', {
      alias: n.kmsAlias('dnssec'),
      description: `DNSSEC key signing key for ${config.hostedZoneName}`,
      keySpec: kms.KeySpec.ECC_NIST_P256,
      keyUsage: kms.KeyUsage.SIGN_VERIFY,
      removalPolicy: RemovalPolicy.RETAIN,
    });
    const keySigningKey = new route53.KeySigningKey(this, 'KeySigningKey', {
      hostedZone: zone,
      kmsKey: dnssecKey,
      keySigningKeyName: `focus_${config.shortName}_ksk`,
    });
    const dnssec = new route53.CfnDNSSEC(this, 'Dnssec', { hostedZoneId: config.hostedZoneId });
    dnssec.addResourceDependency(keySigningKey.node.defaultChild as CfnResource);

    // Alarms here can only notify a topic in this region, so the owner gets a second
    // subscription confirmation email for this topic.
    const topic = new sns.Topic(this, 'GlobalAlerts', {
      topicName: n.resource('alerts-global'),
      displayName: `Focus ${config.envName} alerts (us-east-1)`,
      enforceSSL: true,
    });
    topic.addSubscription(new subscriptions.EmailSubscription(config.alertEmail));
    acknowledge(
      topic,
      'Carries only alarm state changes for the health check and DNSSEC, never personal data. A customer managed key here would add a second KMS key for no data worth protecting.',
      'AwsSolutions-SNS2',
    );
    const page = new cwActions.SnsAction(topic);

    // External check of /healthz from four Route 53 regions. Route 53 probes every 30 seconds
    // (the standard interval), and the alarm pages after 3 failing minutes.
    const healthCheck = new route53.CfnHealthCheck(this, 'ApiHealthCheck', {
      healthCheckConfig: {
        type: 'HTTPS',
        fullyQualifiedDomainName: n.apiHost,
        port: 443,
        resourcePath: config.api.healthCheckPath,
        requestInterval: 30,
        failureThreshold: 3,
        enableSni: true,
        regions: config.monitoring.healthCheckRegions,
      },
      healthCheckTags: [
        { key: 'Name', value: n.resource('api-healthz') },
        { key: 'environment', value: config.envName },
      ],
    });
    this.healthCheckId = healthCheck.attrHealthCheckId;

    const alarm = (id: string, props: cloudwatch.AlarmProps): cloudwatch.Alarm => {
      const created = new cloudwatch.Alarm(this, id, props);
      created.addAlarmAction(page);
      created.addOkAction(page);
      return created;
    };

    alarm('HealthzAlarm', {
      alarmName: n.alarmName('api-healthz-external'),
      alarmDescription: `[PAGE] https://${n.apiHost}${config.api.healthCheckPath} failing from outside AWS for 3 minutes. Runbook: backend/infra/README.md#api-healthz-external`,
      metric: new cloudwatch.Metric({
        namespace: 'AWS/Route53',
        metricName: 'HealthCheckStatus',
        dimensionsMap: { HealthCheckId: healthCheck.attrHealthCheckId },
        statistic: cloudwatch.Stats.MINIMUM,
        period: Duration.minutes(1),
      }),
      comparisonOperator: cloudwatch.ComparisonOperator.LESS_THAN_THRESHOLD,
      threshold: 1,
      evaluationPeriods: 3,
      datapointsToAlarm: 3,
      treatMissingData: cloudwatch.TreatMissingData.BREACHING,
    });

    const zoneMetric = (metricName: string) =>
      new cloudwatch.Metric({
        namespace: 'AWS/Route53',
        metricName,
        dimensionsMap: { HostedZoneId: config.hostedZoneId },
        statistic: cloudwatch.Stats.MAXIMUM,
        period: Duration.minutes(5),
      });
    alarm('DnssecInternalFailureAlarm', {
      alarmName: n.alarmName('dnssec-internal-failure'),
      alarmDescription: `[PAGE] Route 53 can't sign ${config.hostedZoneName}. Validating resolvers will stop resolving the domain. Runbook: backend/infra/README.md#dnssec`,
      metric: zoneMetric('DNSSECInternalFailure'),
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      threshold: 0,
      evaluationPeriods: 1,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });
    alarm('DnssecKeyActionAlarm', {
      alarmName: n.alarmName('dnssec-ksk-needs-action'),
      alarmDescription: `[PAGE] The DNSSEC key signing key for ${config.hostedZoneName} needs action (usually its KMS key was disabled or its policy changed). Runbook: backend/infra/README.md#dnssec`,
      metric: zoneMetric('DNSSECKeySigningKeysNeedingAction'),
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      threshold: 0,
      evaluationPeriods: 1,
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    });
  }
}
