import { ConfigError, envVarSuffix, loadConfigs, Naming, OVERRIDABLE_FIELDS } from '../lib/config';
import { sourcesFor } from './helpers';

describe('config', () => {
  test('cdk.json placeholders load both environments with the spec defaults', () => {
    const [staging, production] = loadConfigs(sourcesFor());
    expect(staging.envName).toBe('staging');
    expect(production.envName).toBe('production');
    expect(staging.domainName).toBe('staging.focus.adhdslayer.au');
    expect(production.domainName).toBe('focus.adhdslayer.au');
    for (const config of [staging, production]) {
      expect(config.primaryRegion).toBe('ap-southeast-2');
      expect(config.backupRegion).toBe('ap-southeast-4');
      expect(config.globalRegion).toBe('us-east-1');
      expect(config.database.backupRetentionDays).toBe(35);
      expect(config.database.multiAz).toBe(true);
      expect(config.database.performanceInsights).toBe(false);
      expect(config.api).toMatchObject({ desiredCount: 2, cpu: 256, memoryMiB: 512, containerPort: 8080, healthCheckPath: '/healthz' });
      expect(config.network.natGateways).toBe(1);
      expect(config.network.availabilityZones).toHaveLength(2);
      expect(config.wafRateLimitPer5Minutes).toBe(2000);
      expect(config.logRetentionDays).toBe(30);
      expect(config.edgeLogRetentionDays).toBe(14);
    }
    expect(production.database.deletionProtection).toBe(true);
    expect(staging.database.deletionProtection).toBe(false);
    expect(production.apple.bundleId).toBe('au.adhdslayer.focus');
    expect(staging.apple.bundleId).toBe('au.adhdslayer.focus.staging');
  });

  test('the migrate and job commands are single config values', () => {
    const [, production] = loadConfigs(sourcesFor());
    expect(production.commands.migrate).toEqual(['node', 'dist/db/migrate.js']);
    expect(production.commands.jobs).toEqual(['node', 'dist/jobs/run.js']);
    const [, custom] = loadConfigs({ ...sourcesFor(), focus: withProduction({ commands: { migrate: ['npm', 'run', 'migrate'] } }) });
    expect(custom.commands.migrate).toEqual(['npm', 'run', 'migrate']);
  });

  test('environment variables override cdk.json, then flat context keys', () => {
    const [, production] = loadConfigs(
      sourcesFor(
        { 'focus:production:account': '333333333333', 'focus:production:apple.teamId': 'ZZZZZ99999' },
        { FOCUS_PRODUCTION_ACCOUNT: '444444444444', FOCUS_PRODUCTION_HOSTED_ZONE_ID: 'Z1234567890ABC' },
      ),
    );
    expect(production.account).toBe('444444444444');
    expect(production.hostedZoneId).toBe('Z1234567890ABC');
    expect(production.apple.teamId).toBe('ZZZZZ99999');
  });

  test('environment variable names follow the field paths', () => {
    expect(envVarSuffix('account')).toBe('ACCOUNT');
    expect(envVarSuffix('hostedZoneId')).toBe('HOSTED_ZONE_ID');
    expect(envVarSuffix('apple.teamId')).toBe('APPLE_TEAM_ID');
    expect(envVarSuffix('googleIosClientId')).toBe('GOOGLE_IOS_CLIENT_ID');
    expect(OVERRIDABLE_FIELDS).toContain('alertEmail');
  });

  test('staging lets production pull images, and production copies from staging', () => {
    const [staging, production] = loadConfigs(sourcesFor());
    expect(staging.imageReaderAccountIds).toEqual([production.account]);
    expect(production.imageSourceRepositoryArn).toBe(`arn:aws:ecr:ap-southeast-2:${staging.account}:repository/focus-staging-api`);
  });

  test('FOCUS_ENVIRONMENTS limits which environments are built', () => {
    const configs = loadConfigs(sourcesFor({}, { FOCUS_ENVIRONMENTS: 'production' }));
    expect(configs.map((c) => c.envName)).toEqual(['production']);
    expect(() => loadConfigs(sourcesFor({}, { FOCUS_ENVIRONMENTS: 'dev' }))).toThrow(ConfigError);
  });

  test.each([
    ['a short account id', { FOCUS_PRODUCTION_ACCOUNT: '1234' }, /account must be 12 digits/],
    ['a zone id without the Z prefix', { FOCUS_PRODUCTION_HOSTED_ZONE_ID: 'ABC' }, /hostedZoneId/],
    ['a domain outside the hosted zone', { FOCUS_PRODUCTION_DOMAIN_NAME: 'focus.example.com' }, /must be inside hosted zone/],
    ['a bad alert email', { FOCUS_PRODUCTION_ALERT_EMAIL: 'nobody' }, /alertEmail/],
    ['a bad Apple Team ID', { FOCUS_PRODUCTION_APPLE_TEAM_ID: 'short' }, /teamId/],
    ['an http helpdesk URL', { FOCUS_PRODUCTION_HELPDESK_WEBHOOK_URL: 'http://helpdesk.example.com' }, /helpdeskWebhookUrl/],
    ['the same account for both environments', { FOCUS_PRODUCTION_ACCOUNT: '111111111111' }, /different AWS accounts/],
  ])('rejects %s', (_label, env, message) => {
    expect(() => loadConfigs(sourcesFor({}, env))).toThrow(message);
  });

  test('naming conventions shared with the scripts', () => {
    const [staging, production] = loadConfigs(sourcesFor());
    const p = new Naming(production);
    const s = new Naming(staging);
    expect(p.bucketName('snapshots')).toBe(`focus-prod-snapshots-${production.account}`);
    expect(s.bucketName('snapshots')).toBe(`focus-staging-snapshots-${staging.account}`);
    expect(p.kmsAlias('rds')).toBe('alias/focus/production/rds');
    expect(p.secretName('apple-siwa-key')).toBe('focus/production/apple-siwa-key');
    expect(p.imageTagParameterName).toBe('/focus/production/api/image-tag');
    expect(p.clusterName).toBe('focus-prod');
    expect(p.apiServiceName).toBe('focus-prod-api');
    expect(p.family('migrate')).toBe('focus-prod-migrate');
    expect(p.apiHost).toBe('api.focus.adhdslayer.au');
    expect(s.apiHost).toBe('api.staging.focus.adhdslayer.au');
    expect(s.cdnHost).toBe('cdn.staging.focus.adhdslayer.au');
    expect(p.publicApiUrl).toBe('https://api.focus.adhdslayer.au');
    expect(p.alertTopicArn).toBe(`arn:aws:sns:ap-southeast-2:${production.account}:focus-prod-alerts`);
    expect(p.stackName('Api')).toBe('Focus-Production-Api');
  });
});

/** The cdk.json `focus` object with extra production settings merged in. */
function withProduction(extra: Record<string, unknown>): unknown {
  const focus = structuredClone(sourcesFor().focus) as { environments: { production: Record<string, unknown> } };
  focus.environments.production = { ...focus.environments.production, ...extra };
  return focus;
}
