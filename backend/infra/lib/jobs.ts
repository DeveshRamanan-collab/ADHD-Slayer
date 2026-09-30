/**
 * Scheduled jobs from backend/CONTRACT.md, "Jobs". A test parses CONTRACT.md and fails if a job is
 * added there without a schedule here (or the other way round).
 *
 * Every job runs `<commands.jobs> <name>` in the jobs task definition. Jobs are idempotent and safe
 * to run twice at once (CONTRACT.md), so retries and overlapping runs are harmless.
 *
 * Schedules are evaluated in Australia/Sydney time, so "03:00" stays 03:00 across daylight saving.
 */
export interface JobDefinition {
  readonly name: string;
  /** EventBridge Scheduler expression, evaluated in Australia/Sydney. */
  readonly schedule: string;
  /** Human cadence, as written in CONTRACT.md. */
  readonly cadence: string;
  readonly description: string;
  /** Retries of the RunTask call itself (not of the job's own work). */
  readonly maximumRetryAttempts: number;
  readonly maximumEventAgeSeconds: number;
}

export const JOBS: readonly JobDefinition[] = [
  {
    name: 'process-store-notifications',
    schedule: 'rate(1 minute)',
    cadence: 'every 1 minute',
    description: 'Processes stored App Store notifications not yet processed.',
    // The next run is a minute away, so a late start is worth little.
    maximumRetryAttempts: 1,
    maximumEventAgeSeconds: 60,
  },
  {
    name: 'reconcile-app-store',
    schedule: 'cron(0 3 * * ? *)',
    cadence: 'daily 03:00 Sydney',
    description: 'Gets App Store notification history for the last 26 hours and fills gaps.',
    maximumRetryAttempts: 3,
    maximumEventAgeSeconds: 3600,
  },
  {
    name: 'app-store-test-notification',
    schedule: 'cron(10 3 * * ? *)',
    cadence: 'daily 03:10 Sydney',
    description: 'Requests an App Store test notification and alerts if none arrived in 48 hours.',
    maximumRetryAttempts: 3,
    maximumEventAgeSeconds: 3600,
  },
  {
    name: 'process-deletions',
    schedule: 'rate(5 minutes)',
    cadence: 'every 5 minutes',
    description: 'Runs account deletions, retries Apple revocation, writes receipts, alerts past 24 hours.',
    maximumRetryAttempts: 2,
    maximumEventAgeSeconds: 240,
  },
  {
    name: 'retention',
    // Quarter past each hour keeps it clear of the 03:00 and 04:00 daily jobs.
    schedule: 'cron(15 * * * ? *)',
    cadence: 'hourly',
    description: 'Runs the retention sweeps from 03-data-model.md.',
    maximumRetryAttempts: 3,
    maximumEventAgeSeconds: 1800,
  },
  {
    name: 'dormant-accounts',
    schedule: 'cron(0 4 * * ? *)',
    cadence: 'daily 04:00 Sydney',
    description: 'Sends the 30-day notice at 23 months and deletes at 24 months.',
    maximumRetryAttempts: 3,
    maximumEventAgeSeconds: 3600,
  },
];
