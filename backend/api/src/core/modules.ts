import type { App } from '../app.js';
import type { Deps } from '../deps.js';
import { listDirectories, SOURCE_ROOT, sourceFile } from './loader.js';
import type { Sweep } from './retention.js';

/**
 * A feature module is a directory `src/modules/<name>/` whose `index.ts` exports:
 *
 *   export default async function register(app: App, deps: Deps): Promise<void>
 *   export const prefix = '/v1';            // optional; '' for routes outside /v1
 *   export const sweeps: Sweep[] = [...];    // optional; retention rules for its tables
 *
 * Every module directory is loaded at startup in name order, each in its own Fastify
 * encapsulation context: hooks, decorators and content type parsers a module adds stay
 * inside it, while the core hooks, error handler and schemas apply everywhere.
 */
export type RegisterModule = (app: App, deps: Deps) => Promise<void>;

export interface FeatureModule {
  name: string;
  register: RegisterModule;
  prefix: string;
  sweeps: readonly Sweep[];
}

const MODULE_NAME = /^[a-z][a-z0-9-]*$/;
const PREFIX = /^(|\/[a-z0-9_-]+(\/[a-z0-9_-]+)*)$/;

export async function loadFeatureModules(dir: URL = new URL('modules/', SOURCE_ROOT)): Promise<FeatureModule[]> {
  const modules: FeatureModule[] = [];
  for (const name of await listDirectories(dir)) {
    if (!MODULE_NAME.test(name)) throw new Error(`module directory names are lowercase with dashes: ${name}`);
    const exports = (await import(sourceFile(new URL(`${name}/`, dir), 'index').href)) as Record<string, unknown>;
    const register = exports.default;
    const prefix = exports.prefix ?? '/v1';
    const sweeps = exports.sweeps ?? [];
    if (typeof register !== 'function') throw new Error(`module ${name} must default-export register(app, deps)`);
    if (typeof prefix !== 'string' || !PREFIX.test(prefix)) throw new Error(`module ${name} has a bad prefix`);
    if (!Array.isArray(sweeps)) throw new Error(`module ${name}: sweeps must be an array`);
    modules.push({ name, register: register as RegisterModule, prefix, sweeps: sweeps as Sweep[] });
  }
  return modules;
}

export async function registerFeatureModules(app: App, deps: Deps, modules: readonly FeatureModule[]): Promise<void> {
  for (const module of modules) {
    deps.logger.debug({ module: module.name }, 'registering module');
    await app.register(
      async (scope) => {
        await module.register(scope, deps);
      },
      { prefix: module.prefix },
    );
  }
}
