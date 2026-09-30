/**
 * The only fields application logs may carry (02-backend.md "Monitoring and logging").
 * Anything else passed to a logger is dropped before it is written, so a stray body,
 * header, token, email or IP address never reaches CloudWatch. Messages must be constant
 * strings: never build a message from data.
 */
export const LOG_FIELDS = [
  // Request line, written once per request by AccessLogController.
  'reqId',
  'route',
  'method',
  'status',
  'latencyMs',
  'errorCode',
  'accountId',
  'deviceId',
  'appVersion',
  // Errors: the type and stack frames, never the message (messages can carry data).
  'errType',
  'errStack',
  // Jobs, migrations and startup.
  'job',
  'sweep',
  'count',
  'durationMs',
  'migration',
  'module',
] as const;

/**
 * Written only when FOCUS_ENV=local, for developer conveniences such as the outbox
 * mailer's recipient and subject or a local sign-in link. Dropped everywhere else.
 */
export const LOCAL_ONLY_LOG_FIELDS = ['dev'] as const;

export interface ErrorFields {
  errType: string;
  errStack?: string;
}

const SAFE_TOKEN = /^[A-Za-z0-9_.:-]{1,64}$/;

/**
 * Loggable view of an error: `name` (plus `code` such as a SQLSTATE or FST_ code) and
 * up to 12 stack frames. The message line is removed because driver and library errors
 * can quote values (a duplicate key error quotes the key).
 */
export function errorFields(error: unknown): ErrorFields {
  if (!(error instanceof Error)) return { errType: 'NonError' };
  const name = SAFE_TOKEN.test(error.name) ? error.name : 'Error';
  const code: unknown = (error as { code?: unknown }).code;
  const errType = typeof code === 'string' && SAFE_TOKEN.test(code) ? `${name}:${code}` : name;
  const frames = (error.stack ?? '')
    .split('\n')
    .map((line) => line.trim())
    .filter((line) => line.startsWith('at '))
    .slice(0, 12);
  return frames.length > 0 ? { errType, errStack: frames.join('\n') } : { errType };
}
