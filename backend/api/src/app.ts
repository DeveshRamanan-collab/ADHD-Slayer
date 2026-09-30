import type { IncomingMessage, ServerResponse } from 'node:http';
import swagger from '@fastify/swagger';
import { fastify, type FastifyBaseLogger, type FastifyInstance, type RawServerDefault } from 'fastify';
import {
  jsonSchemaTransform,
  jsonSchemaTransformObject,
  serializerCompiler,
  validatorCompiler,
  type ZodTypeProvider,
} from 'fastify-type-provider-zod';
import { sendError } from './core/errors.js';
import { DEFAULT_BODY_LIMIT, registerCore, requestId, SECURITY_SCHEMES } from './core/http.js';
import { AccessLogController } from './core/logging.js';
import { loadFeatureModules, registerFeatureModules, type FeatureModule } from './core/modules.js';
import type { Deps } from './deps.js';

/** The Fastify instance type every module receives: zod schemas type the handlers. */
export type App = FastifyInstance<RawServerDefault, IncomingMessage, ServerResponse, FastifyBaseLogger, ZodTypeProvider>;

export interface BuildOptions {
  /** Defaults to every directory in src/modules. Tests pass extra modules. */
  modules?: readonly FeatureModule[];
}

export async function buildApp(deps: Deps, options: BuildOptions = {}): Promise<App> {
  const app = fastify({
    loggerInstance: deps.logger as FastifyBaseLogger,
    logController: new AccessLogController(),
    bodyLimit: DEFAULT_BODY_LIMIT,
    requestIdHeader: false,
    genReqId: (raw) => requestId(raw.headers['x-request-id']),
    // Behind the ALB the client address is the last X-Forwarded-For entry (one trusted hop).
    trustProxy: deps.config.env === 'local' ? false : 1,
    frameworkErrors: (error, request, reply) => {
      sendError(error, request, reply);
    },
  }).withTypeProvider<ZodTypeProvider>();

  app.setValidatorCompiler(validatorCompiler);
  app.setSerializerCompiler(serializerCompiler);
  await app.register(swagger, {
    openapi: {
      openapi: '3.1.0',
      info: {
        title: 'Focus API',
        version: '1',
        description: 'Accounts, encrypted backup, subscription mirror and signed config for the Focus iPhone app.',
      },
      servers: [
        { url: 'https://api.focus.adhdslayer.au', description: 'production' },
        { url: 'https://api.staging.focus.adhdslayer.au', description: 'staging' },
        { url: 'http://localhost:8080', description: 'local' },
      ],
      components: { securitySchemes: SECURITY_SCHEMES },
    },
    transform: jsonSchemaTransform,
    transformObject: jsonSchemaTransformObject,
  });

  registerCore(app, deps);
  await registerFeatureModules(app, deps, options.modules ?? (await loadFeatureModules()));
  return app;
}
