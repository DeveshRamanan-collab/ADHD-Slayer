import type { Logger } from 'pino';
import { createAdapters, type Clock, type Kms, type Mailer, type ObjectStore, type Random } from './adapters/index.js';
import { systemClock } from './adapters/clock.js';
import { cryptoRandom } from './adapters/random.js';
import type { Config } from './config.js';
import type { AppVersionPolicy } from './core/app-version.js';
import { listSourceFiles, SOURCE_ROOT, sourceFile } from './core/loader.js';
import { createDb, type Db } from './db/index.js';

/**
 * Clients for outside services (Apple, Google, the App Store Server API, the helpdesk).
 * Each lives in its own file, `src/providers/<key>.ts`, which adds its key here by
 * declaration merging and default-exports a factory:
 *
 *   declare module '../deps.js' { interface Providers { apple: AppleClient } }
 *   export default function create(deps: BaseDeps): AppleClient { ... }
 *
 * The file name is the key. Factories must not do I/O at construction (no network calls).
 */
export interface Providers {
  /** Filled by the content module; no minimum app version until then. */
  appVersionPolicy?: AppVersionPolicy;
}

/** Everything a module, job or provider needs. Built once per process. */
export interface Deps {
  config: Config;
  logger: Logger;
  db: Db;
  objectStore: ObjectStore;
  kms: Kms;
  mailer: Mailer;
  clock: Clock;
  random: Random;
  providers: Providers;
}

export type BaseDeps = Omit<Deps, 'providers'>;

export async function createDeps(config: Config, logger: Logger): Promise<Deps> {
  const clock = systemClock;
  const random = cryptoRandom;
  const db = await createDb(config.databaseUrl, logger);
  try {
    const adapters = await createAdapters(config, { logger, clock, random });
    const base: BaseDeps = { config, logger, db, clock, random, ...adapters };
    return { ...base, providers: await loadProviders(base) };
  } catch (error) {
    await db.close();
    throw error;
  }
}

export async function closeDeps(deps: Deps): Promise<void> {
  await deps.db.close();
}

const PROVIDER_KEY = /^[a-z][A-Za-z0-9]*$/;

/** Builds every provider in `src/providers/`, keyed by file name. */
export async function loadProviders(base: BaseDeps, dir: URL = new URL('providers/', SOURCE_ROOT)): Promise<Providers> {
  const providers: Record<string, unknown> = {};
  for (const key of await listSourceFiles(dir)) {
    if (!PROVIDER_KEY.test(key)) throw new Error(`provider file name must be camelCase: ${key}`);
    const exports = (await import(sourceFile(dir, key).href)) as { default?: unknown };
    if (typeof exports.default !== 'function') throw new Error(`provider ${key} must default-export a factory`);
    providers[key] = await (exports.default as (deps: BaseDeps) => unknown)(base);
  }
  return providers as Providers;
}
