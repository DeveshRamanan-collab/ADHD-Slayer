import { buildApp } from './app.js';
import { loadConfig } from './config.js';
import { errorFields } from './core/log-fields.js';
import { createLogger } from './core/logging.js';
import { migrate, pendingMigrations } from './db/migrate.js';
import { closeDeps, createDeps } from './deps.js';

/**
 * The API process. Locally it applies migrations itself; in staging and production they
 * run first as a one-off task (`npm run migrate`), and the server refuses to start while
 * any are pending.
 */
const config = loadConfig();
const logger = createLogger(config);

for (const event of ['uncaughtException', 'unhandledRejection'] as const) {
  process.on(event, (error: unknown) => {
    logger.fatal(errorFields(error), event);
    process.exit(1);
  });
}

const deps = await createDeps(config, logger);
if (config.env === 'local') {
  await migrate(deps.db, logger);
} else {
  const pending = await pendingMigrations(deps.db);
  if (pending.length > 0) {
    logger.fatal({ count: pending.length }, 'migrations are pending; run npm run migrate before starting the API');
    await closeDeps(deps);
    process.exit(1);
  }
}

const app = await buildApp(deps);
// Locally only this machine can reach the dev-only routes; in a container the load balancer must.
await app.listen({ port: config.port, host: config.env === 'local' ? 'localhost' : '0.0.0.0' });

let stopping = false;
for (const signal of ['SIGTERM', 'SIGINT'] as const) {
  process.on(signal, () => {
    if (stopping) return;
    stopping = true;
    // Finish in-flight requests (new ones get 503), then release the database.
    void app
      .close()
      .then(() => closeDeps(deps))
      .then(
        () => process.exit(0),
        (error: unknown) => {
          logger.error(errorFields(error), 'shutdown failed');
          process.exit(1);
        },
      );
  });
}
