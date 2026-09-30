import { z } from 'zod';
import type { App } from '../../app.js';
import { isBucketName, LocalObjectStore } from '../../adapters/object-store/local.js';
import { isSafeObjectKey, type BucketName } from '../../adapters/object-store/types.js';
import { safeEqual, sha256 } from '../../core/encoding.js';
import { ApiError } from '../../core/errors.js';
import { uuidv7 } from '../../core/ids.js';
import { DeviceInput, SessionOutput, Uuid } from '../../core/schemas.js';
import { issueSession, revokeSessions } from '../../core/sessions.js';
import type { Deps } from '../../deps.js';

/**
 * Development-only routes, registered only when FOCUS_ENV=local (404 everywhere else):
 *
 * - `POST /v1/_local/auth/session` makes an account (or reuses `accountId`), registers the
 *   device with its keys and starts a session, so the simulator can test without Apple,
 *   Google or email.
 * - `PUT|GET /v1/_local/objects/<bucket>/<key>` are the targets of the local object store's
 *   presigned URLs.
 */

/** Presigned uploads carry snapshots of up to 10 MB. */
const OBJECT_BODY_LIMIT = 16 * 1024 * 1024;

const PresignQuery = z.object({ exp: z.string().optional(), sig: z.string().optional() });

export default async function register(app: App, deps: Deps): Promise<void> {
  if (deps.config.env !== 'local') return;
  const store = deps.objectStore;
  if (!(store instanceof LocalObjectStore)) throw new Error('the local module needs the local object store');

  app.post(
    '/_local/auth/session',
    {
      config: { auth: 'N' },
      schema: {
        hide: true,
        body: z.object({ device: DeviceInput, accountId: Uuid.optional() }),
        response: { 200: z.object({ accountId: z.string(), isNewAccount: z.boolean(), session: SessionOutput }) },
      },
    },
    async (request) => {
      const { device } = request.body;
      const now = deps.clock.now();
      return deps.db.tx(async (tx) => {
        let accountId = request.body.accountId;
        const isNewAccount = accountId === undefined;
        if (accountId === undefined) {
          accountId = uuidv7(now.getTime());
          await tx.query('INSERT INTO accounts (id, created_at) VALUES ($1, $2)', [accountId, now]);
        } else {
          const { rowCount } = await tx.query(`SELECT 1 FROM accounts WHERE id = $1 AND status = 'active'`, [accountId]);
          if (rowCount === 0) throw new ApiError('NOT_FOUND', 404);
        }
        // Registering again (new keys or another account) ends the device's earlier sessions.
        await revokeSessions(tx, deps, { deviceId: device.deviceId }, 'signed_in_again');
        await tx.query(
          `INSERT INTO devices (id, account_id, model, os_version, app_version, signing_key, agreement_key, enrolled_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
           ON CONFLICT (id) DO UPDATE SET
             account_id = EXCLUDED.account_id, model = EXCLUDED.model, os_version = EXCLUDED.os_version,
             app_version = EXCLUDED.app_version, signing_key = EXCLUDED.signing_key,
             agreement_key = EXCLUDED.agreement_key, enrolled_at = EXCLUDED.enrolled_at, revoked_at = NULL`,
          [
            device.deviceId,
            accountId,
            device.model,
            device.osVersion,
            device.appVersion,
            device.signingKey,
            device.agreementKey,
            now,
          ],
        );
        const { session } = await issueSession(tx, deps, { accountId, deviceId: device.deviceId });
        return { accountId, isNewAccount, session };
      });
    },
  );

  await app.register(async (objects) => {
    // Raw bytes, as S3 takes them. Scoped to these routes only.
    objects.addContentTypeParser('application/octet-stream', { parseAs: 'buffer' }, (request, body, done) => {
      request.rawBody = body as Buffer;
      done(null, body);
    });

    objects.put(
      '/_local/objects/*',
      {
        config: { auth: 'N', allowOldApp: true },
        bodyLimit: OBJECT_BODY_LIMIT,
        schema: { hide: true, querystring: PresignQuery },
      },
      async (request, reply) => {
        const { bucket, key } = parseObjectPath(request.params);
        const headers = request.headers as Record<string, string | undefined>;
        const check = store.checkPresignedPut(bucket, key, request.query, headers);
        if (check !== 'ok') throw new ApiError('FORBIDDEN', 403, { reason: check });
        const body = request.rawBody ?? Buffer.alloc(0);
        const declared = Buffer.from(headers['x-amz-checksum-sha256'] ?? '', 'base64');
        if (!safeEqual(sha256(body), declared)) throw new ApiError('CHECKSUM_MISMATCH', 422);
        await store.putObject(bucket, key, body);
        return reply.code(200).send();
      },
    );

    objects.get(
      '/_local/objects/*',
      { config: { auth: 'N', allowOldApp: true }, schema: { hide: true, querystring: PresignQuery } },
      async (request, reply) => {
        const { bucket, key } = parseObjectPath(request.params);
        const check = store.checkPresignedGet(bucket, key, request.query);
        if (check !== 'ok') throw new ApiError('FORBIDDEN', 403, { reason: check });
        const body = await store.getObject(bucket, key);
        if (body === null) throw new ApiError('NOT_FOUND', 404);
        return reply.type('application/octet-stream').send(body);
      },
    );
  });
}

function parseObjectPath(params: unknown): { bucket: BucketName; key: string } {
  const path = (params as { '*'?: string })['*'] ?? '';
  const slash = path.indexOf('/');
  const bucket = path.slice(0, slash);
  const key = path.slice(slash + 1);
  if (slash < 0 || !isBucketName(bucket) || !isSafeObjectKey(key)) throw new ApiError('NOT_FOUND', 404);
  return { bucket, key };
}
