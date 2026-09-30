import { mkdir, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import type { Logger } from 'pino';
import type { Config } from '../../config.js';
import type { Clock } from '../clock.js';
import type { Random } from '../random.js';
import type { MailMessage, Mailer } from './types.js';

/**
 * Local mailer: writes each message as an `.eml` file (opens in Mail) under
 * `LOCAL_DATA_DIR/outbox/`, and logs the recipient, subject and file at debug through the
 * local-only `dev` log field. Nothing leaves the machine.
 */
export class OutboxMailer implements Mailer {
  private readonly dir: string;

  constructor(
    dataDir: string,
    private readonly ses: Config['ses'],
    private readonly logger: Logger,
    private readonly clock: Clock,
    private readonly random: Random,
  ) {
    this.dir = join(dataDir, 'outbox');
  }

  async send(message: MailMessage): Promise<{ messageId: string }> {
    const now = this.clock.now();
    const messageId = this.random.bytes(12).toString('hex');
    const file = join(this.dir, `${now.toISOString().replace(/[:.]/g, '-')}-${messageId}.eml`);
    await mkdir(this.dir, { recursive: true });
    await writeFile(file, toEml(message, message.from ?? this.ses.from, now, messageId));
    this.logger.debug({ dev: { to: message.to, subject: message.subject, file } }, 'email written to the local outbox');
    return { messageId };
  }
}

function toEml(message: MailMessage, from: string, date: Date, messageId: string): string {
  const headers = [
    `From: ${from}`,
    `To: ${message.to}`,
    `Subject: ${encodeHeader(message.subject)}`,
    `Date: ${date.toUTCString()}`,
    `Message-ID: <${messageId}@focus.local>`,
    'MIME-Version: 1.0',
  ];
  const part = (type: string, body: string): string =>
    [`Content-Type: ${type}; charset=utf-8`, 'Content-Transfer-Encoding: 8bit', '', body].join('\r\n');
  if (message.html === undefined) return [...headers, part('text/plain', message.text)].join('\r\n');
  const boundary = `focus-${messageId}`;
  return [
    ...headers,
    `Content-Type: multipart/alternative; boundary="${boundary}"`,
    '',
    `--${boundary}`,
    part('text/plain', message.text),
    `--${boundary}`,
    part('text/html', message.html),
    `--${boundary}--`,
    '',
  ].join('\r\n');
}

/** RFC 2047 encoding for a non-ASCII subject. */
function encodeHeader(value: string): string {
  return /^[\x20-\x7e]*$/.test(value) ? value : `=?UTF-8?B?${Buffer.from(value, 'utf8').toString('base64')}?=`;
}
