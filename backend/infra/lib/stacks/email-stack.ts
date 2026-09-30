import { CfnOutput, Duration } from 'aws-cdk-lib/core';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as ses from 'aws-cdk-lib/aws-ses';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as subscriptions from 'aws-cdk-lib/aws-sns-subscriptions';
import * as sqs from 'aws-cdk-lib/aws-sqs';
import type { Construct } from 'constructs';
import { FocusStack, type FocusStackProps } from '../focus-stack';
import { acknowledge } from '../nag';
import type { ApiStack } from './api-stack';
import type { KeysStack } from './keys-stack';

export interface EmailStackProps extends FocusStackProps {
  readonly keys: KeysStack;
  readonly api: ApiStack;
}

/** Path of the API endpoint that receives SNS bounce and complaint notifications. */
export const EMAIL_EVENTS_WEBHOOK_PATH = '/v1/webhooks/email-events';

/**
 * Transactional email through SES in Sydney (02-backend.md, "Email magic links").
 *
 *  - Domain identity with Easy DKIM (2048-bit), a custom MAIL FROM (SPF aligns) and DMARC at
 *    p=quarantine to start.
 *  - Configuration set `focus-transactional`: no open or click tracking, TLS required to the
 *    receiving server, bounces and complaints on the account suppression list.
 *  - Bounce and complaint events go to an SNS topic that posts to the API over HTTPS
 *    (raw delivery off, so the API can verify each SNS signature).
 *
 * New SES accounts start in the sandbox: request production access (README, SES).
 */
export class EmailStack extends FocusStack {
  readonly identity: ses.EmailIdentity;
  readonly configurationSet: ses.ConfigurationSet;
  readonly eventsTopic: sns.Topic;
  readonly eventsDeadLetterQueue: sqs.Queue;

  constructor(scope: Construct, props: EmailStackProps) {
    super(scope, 'Email', props);
    const { config, naming: n } = this;
    // The subscription's confirmation request goes to the API, so the API must be up first.
    this.addStackDependency(props.api, 'SNS confirms the webhook subscription against the running API');

    const zone = route53.HostedZone.fromHostedZoneAttributes(this, 'Zone', {
      hostedZoneId: config.hostedZoneId,
      zoneName: config.hostedZoneName,
    });

    // ---------------------------------------------------------------- events topic
    this.eventsTopic = new sns.Topic(this, 'EmailEvents', {
      topicName: n.resource('email-events'),
      displayName: `Focus ${config.envName} email bounces and complaints`,
      // Bounce and complaint notices contain email addresses.
      masterKey: props.keys.messaging,
      enforceSSL: true,
    });
    this.eventsTopic.addToResourcePolicy(
      new iam.PolicyStatement({
        sid: 'AllowSesPublish',
        principals: [new iam.ServicePrincipal('ses.amazonaws.com')],
        actions: ['sns:Publish'],
        resources: [this.eventsTopic.topicArn],
        conditions: { StringEquals: { 'aws:SourceAccount': this.account } },
      }),
    );

    this.eventsDeadLetterQueue = new sqs.Queue(this, 'EmailEventsDeadLetterQueue', {
      queueName: n.resource('email-events-dlq'),
      encryption: sqs.QueueEncryption.SQS_MANAGED,
      enforceSSL: true,
      retentionPeriod: Duration.days(14),
    });
    acknowledge(
      this.eventsDeadLetterQueue,
      'This queue is the dead-letter queue for the email events subscription; an alarm raises a ticket when anything lands here.',
      'AwsSolutions-SQS3',
    );

    this.eventsTopic.addSubscription(
      new subscriptions.UrlSubscription(`${n.publicApiUrl}${EMAIL_EVENTS_WEBHOOK_PATH}`, {
        protocol: sns.SubscriptionProtocol.HTTPS,
        // Off: the API receives the full SNS envelope and verifies its signature (v2).
        rawMessageDelivery: false,
        deadLetterQueue: this.eventsDeadLetterQueue,
        // About 35 minutes of retries in total, so a deploy or short outage loses nothing.
        deliveryPolicy: {
          healthyRetryPolicy: {
            numRetries: 12,
            numNoDelayRetries: 0,
            numMinDelayRetries: 2,
            numMaxDelayRetries: 5,
            minDelayTarget: Duration.seconds(10),
            maxDelayTarget: Duration.seconds(300),
            backoffFunction: sns.BackoffFunction.EXPONENTIAL,
          },
          throttlePolicy: { maxReceivesPerSecond: 10 },
        },
      }),
    );

    // ---------------------------------------------------------------- configuration set
    this.configurationSet = new ses.ConfigurationSet(this, 'ConfigurationSet', {
      configurationSetName: n.sesConfigurationSetName,
      sendingEnabled: true,
      reputationMetrics: true,
      // Sign-in links never travel in clear text between mail servers.
      tlsPolicy: ses.ConfigurationSetTlsPolicy.REQUIRE,
      suppressionReasons: ses.SuppressionReasons.BOUNCES_AND_COMPLAINTS,
      // No customTrackingRedirectDomain, no engagement metrics, no OPEN or CLICK events: SES
      // adds no tracking pixel and rewrites no links.
    });
    this.configurationSet.addEventDestination('BouncesAndComplaints', {
      configurationSetEventDestinationName: 'bounces-and-complaints',
      destination: ses.EventDestination.snsTopic(this.eventsTopic),
      events: [ses.EmailSendingEvent.BOUNCE, ses.EmailSendingEvent.COMPLAINT],
    });

    // ---------------------------------------------------------------- identity and DNS
    this.identity = new ses.EmailIdentity(this, 'DomainIdentity', {
      identity: ses.Identity.domain(config.domainName),
      configurationSet: this.configurationSet,
      dkimSigning: true,
      dkimIdentity: ses.DkimIdentity.easyDkim(ses.EasyDkimSigningKeyLength.RSA_2048_BIT),
      mailFromDomain: n.mailFromDomain,
      mailFromBehaviorOnMxFailure: ses.MailFromBehaviorOnMxFailure.USE_DEFAULT_VALUE,
    });

    this.identity.dkimRecords.forEach((record, index) => {
      new route53.CnameRecord(this, `DkimRecord${index + 1}`, {
        zone,
        recordName: record.name,
        domainName: record.value,
        ttl: Duration.hours(1),
      });
    });
    new route53.MxRecord(this, 'MailFromMx', {
      zone,
      recordName: n.mailFromDomain,
      values: [{ priority: 10, hostName: `feedback-smtp.${config.primaryRegion}.amazonses.com` }],
      ttl: Duration.hours(1),
    });
    new route53.TxtRecord(this, 'MailFromSpf', {
      zone,
      recordName: n.mailFromDomain,
      values: ['v=spf1 include:amazonses.com ~all'],
      ttl: Duration.hours(1),
    });
    new route53.TxtRecord(this, 'Dmarc', {
      zone,
      recordName: `_dmarc.${config.domainName}`,
      values: [dmarcRecord(config.dmarcReportEmail)],
      ttl: Duration.hours(1),
    });

    new CfnOutput(this, 'SesIdentity', { value: config.domainName });
    new CfnOutput(this, 'SignInFrom', { value: `Focus <${n.signInAddress}>` });
    new CfnOutput(this, 'EmailEventsWebhook', { value: `${n.publicApiUrl}${EMAIL_EVENTS_WEBHOOK_PATH}` });
  }
}

/** DMARC starts at quarantine (02-backend.md); move to reject once reports look clean. */
export function dmarcRecord(reportEmail: string): string {
  const parts = ['v=DMARC1', 'p=quarantine', 'pct=100', 'adkim=r', 'aspf=r'];
  if (reportEmail) parts.push(`rua=mailto:${reportEmail}`);
  return parts.join('; ');
}
