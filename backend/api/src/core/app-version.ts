import { ApiError } from './errors.js';
import type { ClientInfo } from './request.js';

/**
 * Where the minimum supported app version comes from. The content module provides it as
 * `src/providers/appVersionPolicy.ts` (reading the published config); until then there is
 * no minimum. It is called on every app request, so implementations must cache.
 */
export interface AppVersionPolicy {
  /** The lowest app version the API serves, or null for no minimum. */
  minimumAppVersion(): Promise<string | null>;
}

// Focus/<version> (<build>; iOS <os>)
const USER_AGENT = /^Focus\/(\d{1,5}(?:\.\d{1,5}){0,3}) \(([0-9A-Za-z._-]{1,32}); iOS (\d{1,3}(?:\.\d{1,3}){0,2})\)$/;

export function parseUserAgent(value: string | undefined): ClientInfo | null {
  const match = value === undefined ? null : USER_AGENT.exec(value);
  if (match === null) return null;
  const [, appVersion = '', build = '', osVersion = ''] = match;
  return { appVersion, build, osVersion };
}

/** Numeric dotted comparison; missing parts count as 0 (`1.2` equals `1.2.0`). */
export function compareVersions(a: string, b: string): number {
  const left = a.split('.').map(Number);
  const right = b.split('.').map(Number);
  for (let i = 0; i < Math.max(left.length, right.length); i += 1) {
    const difference = (left[i] ?? 0) - (right[i] ?? 0);
    if (difference !== 0) return Math.sign(difference);
  }
  return 0;
}

/** 426 UPGRADE_REQUIRED when a Focus app older than the minimum calls. Other callers pass. */
export async function checkAppVersion(client: ClientInfo | null, policy: AppVersionPolicy | undefined): Promise<void> {
  if (client === null || policy === undefined) return;
  const minimum = await policy.minimumAppVersion();
  if (minimum !== null && compareVersions(client.appVersion, minimum) < 0) {
    throw new ApiError('UPGRADE_REQUIRED', 426, { minimumAppVersion: minimum });
  }
}
