import { LogController, type FastifyReply, type FastifyRequest } from 'fastify';
import { pino, type DestinationStream, type Logger, type LogFn } from 'pino';
import type { Config } from '../config.js';
import { errorFields, LOCAL_ONLY_LOG_FIELDS, LOG_FIELDS } from './log-fields.js';

export type { Logger } from 'pino';

/**
 * Structured JSON logger that writes only allowlisted fields (see log-fields.ts).
 * Output: `{"level":"info","time":"...","reqId":"...","route":"/v1/...",...,"msg":"..."}`.
 */
export function createLogger(config: Pick<Config, 'env' | 'logLevel'>, destination?: DestinationStream): Logger {
  const allowed = new Set<string>(LOG_FIELDS);
  if (config.env === 'local') for (const field of LOCAL_ONLY_LOG_FIELDS) allowed.add(field);

  const pick = (fields: Record<string, unknown>): Record<string, unknown> => {
    const kept: Record<string, unknown> = {};
    for (const [key, value] of Object.entries(fields)) if (allowed.has(key)) kept[key] = value;
    return kept;
  };

  const options = {
    level: config.logLevel,
    base: undefined, // no pid or hostname
    messageKey: 'msg',
    timestamp: pino.stdTimeFunctions.isoTime,
    formatters: {
      level: (label: string) => ({ level: label }),
      bindings: pick,
      log: pick,
    },
    hooks: { logMethod },
  };
  return destination === undefined ? pino(options) : pino(options, destination);
}

/**
 * Runs before pino formats a line. Errors become `errType` and `errStack` (pino would
 * otherwise use the error message as the log message), and printf-style arguments are
 * dropped so data can't be interpolated into a message.
 */
function logMethod(this: Logger, args: Parameters<LogFn>, method: LogFn): void {
  const write = method as (this: Logger, ...values: unknown[]) => void;
  const [first, second] = args as unknown[];
  const message = typeof second === 'string' ? second : undefined;
  if (first instanceof Error) {
    write.call(this, errorFields(first), message ?? 'error');
    return;
  }
  if (typeof first === 'object' && first !== null) {
    const fields: Record<string, unknown> = { ...(first as Record<string, unknown>) };
    if ('err' in fields) {
      Object.assign(fields, errorFields(fields.err));
      delete fields.err;
    }
    write.call(this, fields, message);
    return;
  }
  write.call(this, first);
}

/**
 * Replaces Fastify's internal request logging: one allowlisted line per request when it
 * completes, and nothing that prints URLs, headers or error messages.
 */
export class AccessLogController extends LogController {
  override incomingRequest(): void {
    // One line per request, written in requestCompleted.
  }

  override routeNotFound(): void {
    // The default prints the raw URL; the completed line already records the 404.
  }

  override requestCompleted(error: Error | null | undefined, request: FastifyRequest, reply: FastifyReply): void {
    const fields = {
      route: request.routeOptions.url,
      method: request.method,
      status: reply.statusCode,
      latencyMs: Math.round(reply.elapsedTime),
      errorCode: request.errorCode ?? undefined,
      accountId: request.auth?.accountId ?? request.deviceProof?.accountId,
      deviceId: request.auth?.deviceId ?? request.deviceProof?.deviceId,
      appVersion: request.client?.appVersion,
      ...(error ? errorFields(error) : {}),
    };
    if (reply.statusCode >= 500 || error) request.log.error(fields, 'request completed');
    else request.log.info(fields, 'request completed');
  }

  override defaultErrorLog(error: Error, request: FastifyRequest): void {
    request.log.error(errorFields(error), 'unhandled error');
  }

  override streamError(error: Error, request: FastifyRequest): void {
    request.log.warn(errorFields(error), 'response stream failed');
  }

  override writeHeadError(error: Error, request: FastifyRequest): void {
    request.log.warn(errorFields(error), 'writing response headers failed');
  }

  override serializerError(error: Error, request: FastifyRequest): void {
    request.log.error(errorFields(error), 'response serialization failed');
  }
}
