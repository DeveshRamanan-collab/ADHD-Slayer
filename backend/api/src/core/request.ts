import type { Deps } from '../deps.js';

/**
 * Auth column of the endpoint tables in 02-backend.md, declared per route as
 * `config: { auth }`. Every route must declare one; startup fails otherwise.
 *
 * - `N`  no credentials.
 * - `B`  `Authorization: Bearer <access token>`; sets `req.auth`.
 * - `B?` bearer when the header is present, anonymous otherwise (support requests).
 * - `P`  device proof only (refresh); sets `req.deviceProof`. The handler must still
 *        check that the proof's device owns the refresh token's session (rotateSession does).
 * - `BP` bearer and a device proof from the session's own device; sets both.
 * - `W`  webhook: no core check, the handler verifies the sender's signature itself.
 */
export type AuthMode = 'N' | 'B' | 'B?' | 'P' | 'BP' | 'W';

/**
 * What a bearer check does when the account is being deleted (its sessions were ended).
 * - `SESSION_REVOKED` (default) answers 401 SESSION_REVOKED.
 * - `ACCOUNT_DELETION_PENDING` answers 409 with `details.deletionRequestedAt`.
 * - `allow` lets the handler run with `req.auth.accountStatus === 'deleting'`, even with
 *   the ended session, so `DELETE /account` can answer a repeat with the same completesBy.
 */
export type DeletingAccountMode = 'SESSION_REVOKED' | 'ACCOUNT_DELETION_PENDING' | 'allow';

export interface AuthContext {
  accountId: string;
  sessionId: string;
  deviceId: string;
  accountStatus: 'active' | 'deleting';
}

export interface DeviceProofContext {
  deviceId: string;
  /** The account the device belongs to. */
  accountId: string;
}

/** Parsed from `User-Agent: Focus/<version> (<build>; iOS <os>)`. */
export interface ClientInfo {
  appVersion: string;
  build: string;
  osVersion: string;
}

export interface IdempotencyClaim {
  scope: string;
  key: string;
}

declare module 'fastify' {
  interface FastifyInstance {
    /** The shared dependencies, also reachable from a request as `req.server.deps`. */
    deps: Deps;
  }

  interface FastifyRequest {
    /** Set on B, BP and authenticated B? routes. */
    auth: AuthContext | null;
    /** Set on P and BP routes. */
    deviceProof: DeviceProofContext | null;
    /** Null when the User-Agent is not the Focus app's. */
    client: ClientInfo | null;
    /** Exact request body bytes (JSON and octet-stream), for proofs and idempotency. */
    rawBody: Buffer | null;
    /** The error code sent, for the request log line. */
    errorCode: string | null;
    /** Internal: the Idempotency-Key this request holds until it replies. */
    idempotency: IdempotencyClaim | null;
  }

  interface FastifyContextConfig {
    auth?: AuthMode;
    /** Creating POSTs: honour `Idempotency-Key` (CONTRACT.md "General"). */
    idempotent?: boolean;
    onDeletingAccount?: DeletingAccountMode;
    /** Skip the 426 minimumAppVersion check (config, copy, health, object transfers). */
    allowOldApp?: boolean;
  }
}
