import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { buildApp } from './app.js';
import { loadConfig } from './config.js';
import { createLogger } from './core/logging.js';
import { closeDeps, createDeps } from './deps.js';

/**
 * The OpenAPI document for every route, built from the zod schemas. It is generated from a
 * fixed local configuration (in-memory database, throwaway data directory), so the output
 * depends only on the code. Development-only routes are hidden.
 */
export async function generateOpenApi(): Promise<string> {
  const dataDir = await mkdtemp(join(tmpdir(), 'focus-openapi-'));
  try {
    const config = loadConfig({ FOCUS_ENV: 'local', LOCAL_DATA_DIR: dataDir, DATABASE_URL: 'pglite://memory' });
    const deps = await createDeps(config, createLogger({ env: 'local', logLevel: 'silent' }));
    try {
      const app = await buildApp(deps);
      await app.ready();
      const document = app.swagger();
      await app.close();
      return `${JSON.stringify(document, null, 2)}\n`;
    } finally {
      await closeDeps(deps);
    }
  } finally {
    await rm(dataDir, { recursive: true, force: true });
  }
}
