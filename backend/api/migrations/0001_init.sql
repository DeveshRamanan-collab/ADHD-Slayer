-- 0001_init: every server table in docs/build-spec/03-data-model.md "Server tables",
-- plus device_proof_replays (backend/CONTRACT.md "Device keys and proofs").
--
-- Times are timestamptz in UTC. Ids are UUIDv7 made by the application unless noted.
-- Every account_id references accounts(id) ON DELETE CASCADE and is indexed (a primary key
-- or unique index that starts with account_id counts). Binary values are bytea; hashes of
-- tokens are lowercase hex text. `_enc` columns hold envelope-encrypted bytes (kms.encrypt).
-- Beyond the listed columns: sessions.grace_pair_sealed (the 30-second refresh retry) and
-- the indexes the core's own lookups and retention sweeps need.

CREATE TABLE accounts (
  id                    uuid PRIMARY KEY,
  created_at            timestamptz NOT NULL DEFAULT now(),
  status                text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'deleting')),
  last_seen_on          date,
  deletion_requested_at timestamptz,
  CHECK ((status = 'deleting') = (deletion_requested_at IS NOT NULL))
);

CREATE TABLE auth_identities (
  id                      uuid PRIMARY KEY,
  account_id              uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
  provider                text NOT NULL CHECK (provider IN ('apple', 'google', 'email')),
  subject                 text NOT NULL,
  email                   text,
  email_verified          boolean NOT NULL DEFAULT false,
  is_private_relay        boolean NOT NULL DEFAULT false,
  apple_refresh_token_enc bytea,
  created_at              timestamptz NOT NULL DEFAULT now(),
  last_used_at            timestamptz,
  UNIQUE (provider, subject)
);
CREATE INDEX auth_identities_account_id_idx ON auth_identities (account_id);

-- id is made by the phone at install.
CREATE TABLE devices (
  id            uuid PRIMARY KEY,
  account_id    uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
  model         text NOT NULL,
  os_version    text NOT NULL,
  app_version   text NOT NULL,
  signing_key   bytea NOT NULL CHECK (octet_length(signing_key) = 65),   -- X9.63 P-256 point
  agreement_key bytea NOT NULL CHECK (octet_length(agreement_key) = 65), -- X9.63 P-256 point
  enrolled_at   timestamptz NOT NULL DEFAULT now(),
  last_seen_on  date,
  revoked_at    timestamptz
);
CREATE INDEX devices_account_id_idx ON devices (account_id);

-- Tokens are stored as SHA-256 hex of the token string. grace_pair_sealed holds the pair
-- made at the last rotation, sealed under a key derived from the refresh token it replaced
-- (see src/core/sessions.ts), so an exact retry within 30 seconds gets the same pair.
CREATE TABLE sessions (
  id                  uuid PRIMARY KEY,
  account_id          uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
  device_id           uuid NOT NULL,
  access_hash         text NOT NULL UNIQUE CHECK (access_hash ~ '^[0-9a-f]{64}$'),
  access_expires_at   timestamptz NOT NULL,
  refresh_hash        text NOT NULL UNIQUE CHECK (refresh_hash ~ '^[0-9a-f]{64}$'),
  prev_refresh_hash   text UNIQUE CHECK (prev_refresh_hash ~ '^[0-9a-f]{64}$'),
  rotated_at          timestamptz,
  grace_pair_sealed   bytea,
  idle_expires_at     timestamptz NOT NULL,
  absolute_expires_at timestamptz NOT NULL,
  revoked_at          timestamptz,
  revoke_reason       text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  last_used_at        timestamptz
);
CREATE INDEX sessions_account_id_idx ON sessions (account_id);
CREATE INDEX sessions_device_id_idx ON sessions (device_id);

CREATE TABLE account_keys (
  account_id        uuid PRIMARY KEY REFERENCES accounts (id) ON DELETE CASCADE,
  epoch             integer NOT NULL CHECK (epoch >= 0),
  rotation_required boolean NOT NULL DEFAULT false,
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE key_slots (
  account_id uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
  epoch      integer NOT NULL CHECK (epoch >= 0),
  device_id  uuid NOT NULL,
  enc        bytea NOT NULL,
  ciphertext bytea NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (account_id, epoch, device_id)
);

CREATE TABLE recovery_slots (
  account_id uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
  epoch      integer NOT NULL CHECK (epoch >= 0),
  nonce      bytea NOT NULL CHECK (octet_length(nonce) = 12),
  ciphertext bytea NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (account_id, epoch)
);

CREATE TABLE key_transfers (
  id                  uuid PRIMARY KEY,
  account_id          uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
  requester_device_id uuid NOT NULL,
  agreement_key       bytea NOT NULL CHECK (octet_length(agreement_key) = 65),
  sealed_enc          bytea,
  sealed_ciphertext   bytea,
  sealed_by           uuid,
  created_at          timestamptz NOT NULL DEFAULT now(),
  expires_at          timestamptz NOT NULL,
  completed_at        timestamptz,
  CHECK ((sealed_enc IS NULL) = (sealed_ciphertext IS NULL))
);
CREATE INDEX key_transfers_account_id_idx ON key_transfers (account_id);

-- "the sealed_* columns are written once": sealing sets sealed_enc, sealed_ciphertext and
-- sealed_by together, once. Afterwards the sealed key may only be cleared (read, or
-- 10 minutes passed); it can never be replaced or sealed again.
CREATE FUNCTION key_transfers_sealed_write_once() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.sealed_by IS NULL THEN
    IF NEW.sealed_enc IS NOT NULL AND NEW.sealed_by IS NULL THEN
      RAISE EXCEPTION 'key_transfers: sealing must set sealed_by';
    END IF;
    RETURN NEW;
  END IF;
  IF NEW.sealed_by IS DISTINCT FROM OLD.sealed_by
     OR (NEW.sealed_enc IS NOT NULL AND NEW.sealed_enc IS DISTINCT FROM OLD.sealed_enc)
     OR (NEW.sealed_ciphertext IS NOT NULL AND NEW.sealed_ciphertext IS DISTINCT FROM OLD.sealed_ciphertext) THEN
    RAISE EXCEPTION 'key_transfers: sealed columns are written once';
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER key_transfers_sealed_write_once
  BEFORE UPDATE ON key_transfers
  FOR EACH ROW EXECUTE FUNCTION key_transfers_sealed_write_once();

-- id is made by the phone. A pending upload has no version; commit assigns
-- base_version + 1, so versions rise by one per commit.
CREATE TABLE sync_snapshots (
  id           uuid PRIMARY KEY,
  account_id   uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
  version      integer,
  base_version integer NOT NULL CHECK (base_version >= 0),
  device_id    uuid NOT NULL,
  epoch        integer NOT NULL CHECK (epoch >= 0),
  schema       integer NOT NULL CHECK (schema >= 1),
  size_bytes   integer NOT NULL CHECK (size_bytes > 0),
  sha256       bytea NOT NULL CHECK (octet_length(sha256) = 32),
  s3_key       text NOT NULL,
  state        text NOT NULL DEFAULT 'pending' CHECK (state IN ('pending', 'committed', 'superseded')),
  created_at   timestamptz NOT NULL DEFAULT now(),
  committed_at timestamptz,
  UNIQUE (account_id, version),
  CHECK (version IS NULL OR version = base_version + 1),
  CHECK ((state = 'pending') = (version IS NULL))
);
CREATE INDEX sync_snapshots_account_id_created_at_idx ON sync_snapshots (account_id, created_at);

-- Later: encrypted change batches between snapshots (endpoints reserved).
CREATE TABLE sync_batches (
  account_id  uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
  device_id   uuid NOT NULL,
  seq         bigint NOT NULL CHECK (seq >= 1),
  cursor      bigint GENERATED ALWAYS AS IDENTITY UNIQUE,
  epoch       integer NOT NULL CHECK (epoch >= 0),
  schema      integer NOT NULL CHECK (schema >= 1),
  nonce       bytea NOT NULL,
  ciphertext  bytea NOT NULL,
  aad_hash    bytea NOT NULL,
  received_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (account_id, device_id, seq)
);

CREATE TABLE entitlements (
  account_id              uuid PRIMARY KEY REFERENCES accounts (id) ON DELETE CASCADE,
  original_transaction_id text,
  product_id              text,
  status                  text NOT NULL DEFAULT 'none'
                          CHECK (status IN ('none', 'trial', 'active', 'grace', 'billingRetry', 'expired', 'revoked')),
  expires_at              timestamptz,
  grace_expires_at        timestamptz,
  will_auto_renew         boolean NOT NULL DEFAULT false,
  is_trial                boolean NOT NULL DEFAULT false,
  environment             text,
  updated_at              timestamptz NOT NULL DEFAULT now()
);

-- Apple's ids. account_id is null until the transaction is linked to an account.
CREATE TABLE store_transactions (
  transaction_id          text PRIMARY KEY,
  original_transaction_id text NOT NULL,
  account_id              uuid REFERENCES accounts (id) ON DELETE CASCADE,
  app_account_token       uuid,
  product_id              text NOT NULL,
  purchase_date           timestamptz NOT NULL,
  expires_date            timestamptz,
  offer_type              integer,
  revocation_date         timestamptz,
  revocation_reason       integer,
  environment             text NOT NULL
);
CREATE INDEX store_transactions_original_transaction_id_idx ON store_transactions (original_transaction_id);
CREATE INDEX store_transactions_app_account_token_idx ON store_transactions (app_account_token);
CREATE INDEX store_transactions_account_id_idx ON store_transactions (account_id);

-- notification_uuid is Apple's notificationUUID; the store module defines status values.
CREATE TABLE store_notifications (
  notification_uuid       uuid PRIMARY KEY,
  type                    text NOT NULL,
  subtype                 text,
  environment             text NOT NULL,
  original_transaction_id text,
  received_at             timestamptz NOT NULL DEFAULT now(),
  processed_at            timestamptz,
  status                  text NOT NULL,
  signed_payload          text NOT NULL
);

CREATE TABLE magic_links (
  id             uuid PRIMARY KEY,
  email          text NOT NULL,
  device_id      uuid NOT NULL,
  secret_hash    text NOT NULL,
  code_hmac      text NOT NULL,
  link_challenge text NOT NULL,
  attempts       integer NOT NULL DEFAULT 0 CHECK (attempts BETWEEN 0 AND 5),
  created_at     timestamptz NOT NULL DEFAULT now(),
  expires_at     timestamptz NOT NULL,
  used_at        timestamptz
);
CREATE INDEX magic_links_expires_at_idx ON magic_links (expires_at);

-- The server keeps only terms, privacy, notice and adult (06-compliance-and-safety.md).
CREATE TABLE account_consents (
  account_id   uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
  kind         text NOT NULL CHECK (kind IN ('terms', 'privacy', 'notice', 'adult')),
  version      integer NOT NULL CHECK (version >= 1),
  accepted_at  timestamptz NOT NULL,
  withdrawn_at timestamptz,
  PRIMARY KEY (account_id, kind, version)
);

-- account_id is null for a request sent without signing in (reply email only).
CREATE TABLE support_requests (
  id              uuid PRIMARY KEY,
  account_id      uuid REFERENCES accounts (id) ON DELETE CASCADE,
  reference       text NOT NULL UNIQUE,
  topic           text NOT NULL,
  message_enc     bytea NOT NULL,
  reply_email_enc bytea,
  diagnostics     jsonb,
  helpdesk_id     text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  last_message_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX support_requests_account_id_idx ON support_requests (account_id);

-- account_hmac is a keyed hash of the account id, so receipts outlive the account.
CREATE TABLE deletion_receipts (
  account_hmac text PRIMARY KEY,
  requested_at timestamptz NOT NULL,
  completed_at timestamptz,
  steps        jsonb NOT NULL DEFAULT '{}'::jsonb
);

-- details never holds personal data.
CREATE TABLE audit_log (
  id         bigserial PRIMARY KEY,
  at         timestamptz NOT NULL DEFAULT now(),
  actor      text NOT NULL CHECK (actor IN ('system', 'account', 'staff')),
  account_id uuid REFERENCES accounts (id) ON DELETE CASCADE,
  action     text NOT NULL,
  target     text,
  request_id text,
  details    jsonb NOT NULL DEFAULT '{}'::jsonb
);
CREATE INDEX audit_log_account_id_idx ON audit_log (account_id);
CREATE INDEX audit_log_at_idx ON audit_log (at);

-- status and response are null while the first request holds the key (src/core/idempotency.ts).
CREATE TABLE idempotency_keys (
  scope      text NOT NULL,
  key        text NOT NULL,
  body_hash  text NOT NULL,
  status     integer,
  response   jsonb,
  expires_at timestamptz NOT NULL,
  PRIMARY KEY (scope, key)
);
CREATE INDEX idempotency_keys_expires_at_idx ON idempotency_keys (expires_at);

-- key is `<limit name>:<keyed hash>` (src/core/rate-limit.ts); expires_at ends the window.
CREATE TABLE rate_limits (
  key          text PRIMARY KEY,
  window_start timestamptz NOT NULL,
  count        integer NOT NULL CHECK (count >= 1),
  expires_at   timestamptz NOT NULL
);
CREATE INDEX rate_limits_expires_at_idx ON rate_limits (expires_at);

CREATE TABLE analytics_daily (
  day       date NOT NULL,
  metric    text NOT NULL,
  dimension text NOT NULL DEFAULT '',
  value     bigint NOT NULL DEFAULT 0,
  installs  integer NOT NULL DEFAULT 0,
  PRIMARY KEY (day, metric, dimension)
);

-- id is the phone's reportId.
CREATE TABLE crash_reports (
  id           uuid PRIMARY KEY,
  received_at  timestamptz NOT NULL DEFAULT now(),
  app_version  text NOT NULL,
  build        text NOT NULL,
  os_version   text NOT NULL,
  model        text NOT NULL,
  kind         text NOT NULL,
  s3_key       text NOT NULL,
  symbolicated boolean NOT NULL DEFAULT false
);

-- Seen device proof signatures (low-S form), refused again until expires_at (10 minutes).
CREATE TABLE device_proof_replays (
  device_id  uuid NOT NULL,
  signature  bytea NOT NULL CHECK (octet_length(signature) = 64),
  expires_at timestamptz NOT NULL,
  PRIMARY KEY (device_id, signature)
);
CREATE INDEX device_proof_replays_expires_at_idx ON device_proof_replays (expires_at);
