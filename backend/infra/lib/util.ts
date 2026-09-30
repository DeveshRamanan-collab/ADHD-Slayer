import * as logs from 'aws-cdk-lib/aws-logs';

/** Maps a number of days onto the CloudWatch Logs retention enum, refusing values it can't store. */
export function retention(days: number): logs.RetentionDays {
  const allowed = Object.values(logs.RetentionDays).filter((v): v is number => typeof v === 'number');
  if (!allowed.includes(days)) {
    throw new Error(`CloudWatch Logs can't keep logs for ${days} days. Allowed: ${allowed.join(', ')}`);
  }
  return days as logs.RetentionDays;
}

/** PascalCase an id such as `apple-siwa-key` into `AppleSiwaKey` for construct ids. */
export function pascal(value: string): string {
  return value
    .split(/[^a-zA-Z0-9]+/)
    .filter(Boolean)
    .map((part) => part[0].toUpperCase() + part.slice(1))
    .join('');
}
