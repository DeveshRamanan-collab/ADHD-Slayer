import type { FastifyError, FastifyReply, FastifyRequest } from 'fastify';
import { hasZodFastifySchemaValidationErrors } from 'fastify-type-provider-zod';
import { errorFields } from './log-fields.js';

/** Every error code and its HTTP status, from 02-backend.md "Error codes". */
export const ERROR_STATUS = {
  VALIDATION_ERROR: 422,
  UNAUTHENTICATED: 401,
  TOKEN_EXPIRED: 401,
  SESSION_REVOKED: 401,
  DEVICE_PROOF_INVALID: 401,
  DEVICE_REVOKED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  PROVIDER_TOKEN_INVALID: 401,
  NONCE_MISMATCH: 401,
  ADULT_CONFIRMATION_REQUIRED: 422,
  LINK_INVALID: 410,
  CODE_ATTEMPTS_EXCEEDED: 429,
  LINK_WRONG_DEVICE: 403,
  ACCOUNT_DELETION_PENDING: 409,
  SNAPSHOT_CONFLICT: 409,
  EPOCH_MISMATCH: 409,
  UPLOAD_INCOMPLETE: 409,
  CHECKSUM_MISMATCH: 422,
  TRANSFER_EXPIRED: 410,
  TRANSFER_ALREADY_SEALED: 409,
  SEQ_CONFLICT: 409,
  SEQ_GAP: 409,
  IDEMPOTENCY_MISMATCH: 422,
  PAYLOAD_TOO_LARGE: 413,
  QUOTA_EXCEEDED: 413,
  JWS_INVALID: 422,
  UPSTREAM_UNAVAILABLE: 503,
  SERVICE_PAUSED: 503,
  RATE_LIMITED: 429,
  UPGRADE_REQUIRED: 426,
  INTERNAL: 500,
} as const;

export type ErrorCode = keyof typeof ERROR_STATUS;

export const ERROR_CODES = Object.keys(ERROR_STATUS) as [ErrorCode, ...ErrorCode[]];

/** Developer text for `error.message`. The app never shows it; it shows its own copy. */
const MESSAGES: Record<ErrorCode, string> = {
  VALIDATION_ERROR: 'The request does not match the schema.',
  UNAUTHENTICATED: 'A valid access token is required.',
  TOKEN_EXPIRED: 'The access token has expired.',
  SESSION_REVOKED: 'The session has ended.',
  DEVICE_PROOF_INVALID: 'The device proof is missing, skewed or wrong.',
  DEVICE_REVOKED: 'This device was removed from the account.',
  FORBIDDEN: 'Not allowed for this account.',
  NOT_FOUND: 'Not found.',
  PROVIDER_TOKEN_INVALID: 'The sign-in provider token failed its checks.',
  NONCE_MISMATCH: 'The sign-in nonce does not match.',
  ADULT_CONFIRMATION_REQUIRED: 'The 18+ confirmation is missing.',
  LINK_INVALID: 'The link has expired, was used or was replaced.',
  CODE_ATTEMPTS_EXCEEDED: 'Too many wrong codes for this link.',
  LINK_WRONG_DEVICE: 'The link was requested on another device.',
  ACCOUNT_DELETION_PENDING: 'The account is being deleted.',
  SNAPSHOT_CONFLICT: 'Another device committed first.',
  EPOCH_MISMATCH: 'The key epoch changed.',
  UPLOAD_INCOMPLETE: 'The uploaded object is missing.',
  CHECKSUM_MISMATCH: 'The uploaded object does not match its checksum.',
  TRANSFER_EXPIRED: 'The key transfer has expired.',
  TRANSFER_ALREADY_SEALED: 'The key transfer was already sealed.',
  SEQ_CONFLICT: 'The batch sequence number conflicts.',
  SEQ_GAP: 'The batch sequence number skips ahead.',
  IDEMPOTENCY_MISMATCH: 'The Idempotency-Key was used with another body.',
  PAYLOAD_TOO_LARGE: 'The payload is too large.',
  QUOTA_EXCEEDED: 'The account storage quota is exceeded.',
  JWS_INVALID: 'The signed transaction failed its checks.',
  UPSTREAM_UNAVAILABLE: 'An upstream service is unavailable.',
  SERVICE_PAUSED: 'This feature is paused.',
  RATE_LIMITED: 'Too many requests.',
  UPGRADE_REQUIRED: 'This app version is no longer supported.',
  INTERNAL: 'Internal error.',
};

/**
 * The one error type handlers throw. The status must match the table, which the type
 * checker enforces: `new ApiError('NOT_FOUND', 404)` compiles, `new ApiError('NOT_FOUND', 400)`
 * does not. `details` must never hold personal data; it is sent to the client.
 */
export class ApiError<C extends ErrorCode = ErrorCode> extends Error {
  override readonly name = 'ApiError';

  constructor(
    readonly code: C,
    readonly httpStatus: (typeof ERROR_STATUS)[C],
    readonly details: Record<string, unknown> = {},
    readonly retryAfterSeconds?: number,
  ) {
    super(MESSAGES[code]);
    if (ERROR_STATUS[code] !== httpStatus) throw new TypeError(`${code} is HTTP ${String(ERROR_STATUS[code])}`);
  }
}

export interface ErrorBody {
  error: {
    code: ErrorCode;
    message: string;
    details: Record<string, unknown>;
    retryAfterSeconds?: number;
  };
}

export function errorBody(error: ApiError): ErrorBody {
  return {
    error: {
      code: error.code,
      message: error.message,
      details: error.details,
      ...(error.retryAfterSeconds === undefined ? {} : { retryAfterSeconds: error.retryAfterSeconds }),
    },
  };
}

/** Maps anything thrown to an ApiError. Unknown errors become INTERNAL and never leak their message. */
export function toApiError(error: unknown): ApiError {
  if (error instanceof ApiError) return error;
  if (hasZodFastifySchemaValidationErrors(error)) {
    return new ApiError('VALIDATION_ERROR', 422, {
      in: error.validationContext,
      issues: error.validation.map((issue) => ({ path: issue.instancePath, message: issue.message })),
    });
  }
  const { code, statusCode } = error as Partial<FastifyError>;
  // Fastify's own request errors: bad media type, empty or oversized body, bad URL.
  if (typeof code === 'string' && code.startsWith('FST_') && statusCode !== undefined && statusCode < 500) {
    if (statusCode === 413) return new ApiError('PAYLOAD_TOO_LARGE', 413);
    if (statusCode === 404) return new ApiError('NOT_FOUND', 404);
    return new ApiError('VALIDATION_ERROR', 422, { reason: code });
  }
  // The JSON body parser rejects malformed JSON with a SyntaxError marked 400.
  if (error instanceof SyntaxError && statusCode === 400) {
    return new ApiError('VALIDATION_ERROR', 422, { reason: 'INVALID_JSON' });
  }
  return new ApiError('INTERNAL', 500);
}

export function sendError(error: unknown, request: FastifyRequest, reply: FastifyReply): FastifyReply {
  const apiError = toApiError(error);
  if (apiError.httpStatus >= 500) request.log.error({ errorCode: apiError.code, ...errorFields(error) }, 'request failed');
  request.errorCode = apiError.code;
  if (apiError.code === 'RATE_LIMITED' && apiError.retryAfterSeconds !== undefined) {
    reply.header('retry-after', String(apiError.retryAfterSeconds));
  }
  return reply.code(apiError.httpStatus).send(errorBody(apiError));
}
