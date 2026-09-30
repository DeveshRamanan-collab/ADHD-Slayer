import { loadConfig } from '../config.js';
import { errorFields } from '../core/log-fields.js';
import { listSourceFiles, sourceFile } from '../core/loader.js';
import { createLogger } from '../core/logging.js';
import { closeDeps, createDeps, type Deps } from '../deps.js';

/**
 * `node dist/jobs/run.js <name>` (`npm run jobs -- <name>`) runs `src/jobs/<name>.ts`,
 * which exports `run(deps)`. EventBridge Scheduler starts each job as an ECS task with the
 * API image. Jobs must be idempotent and safe to run twice at once (CONTRACT.md "Jobs").
 * Exit code 0 on success, 1 on failure, 2 for an unknown job.
 */
const JOBS_DIR = new URL('./', import.meta.url);
const name = process.argv[2] ?? '';
const jobs = (await listSourceFiles(JOBS_DIR)).filter((job) => job !== 'run');

if (!jobs.includes(name)) {
  process.stderr.write(`usage: jobs <name>\nknown jobs: ${jobs.join(', ')}\n`);
  process.exit(2);
}

const config = loadConfig();
const logger = createLogger(config).child({ job: name });
const started = Date.now();
let deps: Deps | undefined;
try {
  deps = await createDeps(config, logger);
  const job = (await import(sourceFile(JOBS_DIR, name).href)) as { run?: (deps: Deps) => Promise<void> };
  if (typeof job.run !== 'function') throw new Error(`job ${name} must export run(deps)`);
  await job.run(deps);
  logger.info({ durationMs: Date.now() - started }, 'job finished');
} catch (error) {
  logger.error({ durationMs: Date.now() - started, ...errorFields(error) }, 'job failed');
  process.exitCode = 1;
} finally {
  if (deps !== undefined) await closeDeps(deps);
}
