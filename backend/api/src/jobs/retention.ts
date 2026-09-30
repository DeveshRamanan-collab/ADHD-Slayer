import { errorFields } from '../core/log-fields.js';
import { loadFeatureModules } from '../core/modules.js';
import { coreSweeps } from '../core/retention.js';
import type { Deps } from '../deps.js';

/**
 * Hourly: the core sweeps, then every module's `sweeps` (03-data-model.md "Retention").
 * One failing sweep does not stop the others; the job fails at the end if any did.
 */
export async function run(deps: Deps): Promise<void> {
  const modules = await loadFeatureModules();
  const sweeps = [...coreSweeps, ...modules.flatMap((module) => module.sweeps)];
  let failed = 0;
  for (const sweep of sweeps) {
    const started = Date.now();
    try {
      const count = await sweep.run(deps);
      deps.logger.info({ sweep: sweep.name, count, durationMs: Date.now() - started }, 'sweep finished');
    } catch (error) {
      failed += 1;
      deps.logger.error({ sweep: sweep.name, ...errorFields(error) }, 'sweep failed');
    }
  }
  if (failed > 0) throw new Error(`${String(failed)} retention sweeps failed`);
}
