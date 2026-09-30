import { SendEmailCommand, SESv2Client } from '@aws-sdk/client-sesv2';
import type { Config } from '../../config.js';
import type { MailMessage, Mailer } from './types.js';

/** Amazon SES v2 in `AWS_REGION`, through `SES_CONFIGURATION_SET` (bounces, complaints, no tracking). */
export class SesMailer implements Mailer {
  private readonly client: SESv2Client;

  constructor(
    private readonly ses: Config['ses'],
    region: string,
    client?: SESv2Client,
  ) {
    this.client = client ?? new SESv2Client({ region });
  }

  async send(message: MailMessage): Promise<{ messageId: string }> {
    const out = await this.client.send(
      new SendEmailCommand({
        FromEmailAddress: message.from ?? this.ses.from,
        Destination: { ToAddresses: [message.to] },
        ConfigurationSetName: this.ses.configurationSet,
        Content: {
          Simple: {
            Subject: { Data: message.subject, Charset: 'UTF-8' },
            Body: {
              Text: { Data: message.text, Charset: 'UTF-8' },
              ...(message.html === undefined ? {} : { Html: { Data: message.html, Charset: 'UTF-8' } }),
            },
          },
        },
      }),
    );
    if (out.MessageId === undefined) throw new Error('SES returned no message id');
    return { messageId: out.MessageId };
  }
}
