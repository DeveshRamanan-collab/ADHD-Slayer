import { z } from 'zod';
import type { App } from '../../app.js';
import { ApiError } from '../../core/errors.js';
import type { Deps } from '../../deps.js';

/** `/healthz` sits outside `/v1` (CONTRACT.md "Hosts and base URLs"). */
export const prefix = '';

const DATABASE_TIMEOUT_MS = 2_000;

/** `GET /healthz`: 200 `{"status":"ok"}` when the database answers within 2 seconds, else 503. */
export default async function register(app: App, deps: Deps): Promise<void> {
  app.get(
    '/healthz',
    {
      config: { auth: 'N', allowOldApp: true },
      // Load balancer checks every few seconds: only failures reach the log.
      logLevel: 'warn',
      schema: {
        summary: 'Liveness and database check',
        response: { 200: z.object({ status: z.literal('ok') }) },
      },
    },
    async () => {
      if (!(await databaseAnswers(deps))) throw new ApiError('UPSTREAM_UNAVAILABLE', 503);
      return { status: 'ok' as const };
    },
  );
}

async function databaseAnswers(deps: Deps): Promise<boolean> {
  let timer: NodeJS.Timeout | undefined;
  const timeout = new Promise<false>((resolve) => {
    timer = setTimeout(() => {
      resolve(false);
    }, DATABASE_TIMEOUT_MS);
  });
  try {
    return await Promise.race([deps.db.query('SELECT 1').then(() => true), timeout]);
  } catch {
    return false;
  } finally {
    clearTimeout(timer);
  }
}
