import { loadConfig } from '../config.js';
import { errorFields } from '../core/log-fields.js';
import { createLogger } from '../core/logging.js';
import { createDb } from '../db/index.js';
import { migrate } from '../db/migrate.js';

/** `npm run migrate`: applies pending migrations and exits. Deploys run it before the new tasks start. */
const config = loadConfig();
const logger = createLogger(config);
const db = await createDb(config.databaseUrl, logger);
try {
  const applied = await migrate(db, logger);
  logger.info({ count: applied.length }, 'migrations finished');
} catch (error) {
  logger.fatal(errorFields(error), 'migrations failed');
  process.exitCode = 1;
} finally {
  await db.close();
}
