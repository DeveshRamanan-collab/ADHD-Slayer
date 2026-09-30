import type { App } from '../app.js';
import type { Deps } from '../deps.js';
import { checkAppVersion, parseUserAgent } from './app-version.js';
import { requireDeviceProof, requireSession } from './auth.js';
import { ApiError, sendError } from './errors.js';
import { isUuid, uuidv7 } from './ids.js';
import { beginIdempotency, finishIdempotency } from './idempotency.js';
import type { AuthMode } from './request.js';
import { ErrorEnvelope } from './schemas.js';

/** Request bodies are limited to 64 KB unless a route sets its own `bodyLimit` (02-backend.md). */
export const DEFAULT_BODY_LIMIT = 64 * 1024;

const AUTH_MODES: readonly AuthMode[] = ['N', 'B', 'B?', 'P', 'BP', 'W'];

/** OpenAPI security for each auth mode. */
const SECURITY: Record<AuthMode, Record<string, string[]>[] | undefined> = {
  N: undefined,
  W: undefined,
  B: [{ bearer: [] }],
  'B?': [{ bearer: [] }, {}],
  P: [{ deviceProof: [] }],
  BP: [{ bearer: [], deviceProof: [] }],
};

/** `X-Request-Id` from the client when it is a UUID (so it can't smuggle data into logs), else a new UUIDv7. */
export function requestId(header: string | string[] | undefined): string {
  return typeof header === 'string' && isUuid(header) ? header.toLowerCase() : uuidv7();
}

/** Decorations, parsers, hooks and error handlers every route gets. Call before registering routes. */
export function registerCore(app: App, deps: Deps): void {
  app.decorate('deps', deps);
  app.decorateRequest('auth', null);
  app.decorateRequest('deviceProof', null);
  app.decorateRequest('client', null);
  app.decorateRequest('rawBody', null);
  app.decorateRequest('errorCode', null);
  app.decorateRequest('idempotency', null);

  // JSON keeps its exact bytes for device proofs and idempotency hashes. An empty body
  // with a JSON content type counts as no body rather than an error.
  const parseJson = app.getDefaultJsonParser('error', 'error');
  app.removeContentTypeParser('application/json');
  app.addContentTypeParser('application/json', { parseAs: 'buffer' }, (request, body, done) => {
    const bytes = body as Buffer;
    request.rawBody = bytes;
    if (bytes.length === 0) {
      done(null, undefined);
      return;
    }
    parseJson(request, bytes.toString('utf8'), done);
  });

  app.addHook('onRoute', (route) => {
    const auth = route.config?.auth;
    if (auth === undefined || !AUTH_MODES.includes(auth)) {
      throw new Error(`${String(route.method)} ${route.url} must declare config.auth (${AUTH_MODES.join(', ')})`);
    }
    const schema = route.schema ?? {};
    route.schema = {
      ...schema,
      ...(schema.security === undefined && SECURITY[auth] !== undefined ? { security: SECURITY[auth] } : {}),
      response: { '4xx': ErrorEnvelope, '5xx': ErrorEnvelope, ...(schema.response as object | undefined) },
    };
  });

  app.addHook('onRequest', async (request, reply) => {
    reply.header('x-request-id', request.id);
    request.client = parseUserAgent(request.headers['user-agent']);
    const { auth, allowOldApp, onDeletingAccount } = request.routeOptions.config;
    if (auth === undefined) return; // no route matched; the 404 handler answers
    if (allowOldApp !== true) await checkAppVersion(request.client, deps.providers.appVersionPolicy);
    if (auth === 'B' || auth === 'BP' || (auth === 'B?' && request.headers.authorization !== undefined)) {
      await requireSession(request, { onDeletingAccount });
    }
  });

  // Proofs sign the body, so they run once it is parsed but before schema validation.
  app.addHook('preValidation', async (request) => {
    const { auth } = request.routeOptions.config;
    if (auth === 'P' || auth === 'BP') await requireDeviceProof(request);
  });

  app.addHook('preHandler', async (request, reply) =>
    request.routeOptions.config.idempotent === true ? beginIdempotency(request, reply) : undefined,
  );

  app.addHook('onSend', async (request, reply, payload) => {
    if (!reply.hasHeader('cache-control')) reply.header('cache-control', 'no-store');
    await finishIdempotency(request, reply, payload);
    return payload;
  });

  app.setErrorHandler((error, request, reply) => sendError(error, request, reply));
  app.setNotFoundHandler((request, reply) => sendError(new ApiError('NOT_FOUND', 404), request, reply));
}

/** Declared here so the OpenAPI document names the schemes used in `security`. */
export const SECURITY_SCHEMES = {
  bearer: { type: 'http', scheme: 'bearer', description: 'Access token from sign-in or refresh.' },
  deviceProof: {
    type: 'apiKey',
    in: 'header',
    name: 'X-Device-Signature',
    description:
      'Device proof: X-Device-Id, X-Device-Timestamp and X-Device-Signature (ES256 over the canonical string), as in backend/CONTRACT.md.',
  },
} as const;
