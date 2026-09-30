export interface MailMessage {
  to: string;
  subject: string;
  text: string;
  html?: string;
  /** Defaults to `SES_FROM`; support replies pass `config.ses.supportFrom`. */
  from?: string;
}

export interface Mailer {
  /** Sends one transactional email. Never log the recipient or the content. */
  send(message: MailMessage): Promise<{ messageId: string }>;
}
