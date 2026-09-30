import type { Node } from 'constructs';

/**
 * Typed configuration for one Focus environment.
 *
 * Values come from, in order of precedence:
 *   1. environment variables, for example FOCUS_PRODUCTION_ACCOUNT or FOCUS_PRODUCTION_APPLE_TEAM_ID
 *   2. flat CDK context keys, for example `-c focus:production:account=123456789012`
 *   3. the `focus` object in cdk.json (placeholders in the repository)
 *   4. the defaults below
 *
 * Nothing secret ever lives here. Secret values go into Secrets Manager (see README).
 */

export const PRIMARY_REGION = 'ap-southeast-2';
export const BACKUP_REGION = 'ap-southeast-4';
export const GLOBAL_REGION = 'us-east-1';
export const SYDNEY_TIME_ZONE = 'Australia/Sydney';

export const ENVIRONMENT_NAMES = ['staging', 'production'] as const;
export type EnvName = (typeof ENVIRONMENT_NAMES)[number];

export type AppStoreEnvironment = 'Production' | 'Sandbox' | 'Xcode' | 'LocalTesting';

export interface AppleConfig {
  readonly teamId: string;
  readonly bundleId: string;
  readonly appAppleId: string;
  readonly siwaKeyId: string;
  readonly appStoreIssuerId: string;
  readonly appStoreKeyId: string;
  readonly appStoreEnvironment: AppStoreEnvironment;
}

export interface DatabaseConfig {
  /** RDS instance class without the `db.` prefix, for example `t4g.micro`. */
  readonly instanceClass: string;
  readonly allocatedStorageGiB: number;
  readonly maxAllocatedStorageGiB: number;
  readonly multiAz: boolean;
  readonly deletionProtection: boolean;
  /** Off by default: Performance Insights is a cost we do not need at launch. */
  readonly performanceInsights: boolean;
  /** Point-in-time recovery window. 35 days is the RDS maximum and the spec's promise. */
  readonly backupRetentionDays: number;
  readonly credentialRotationDays: number;
}

export interface NetworkConfig {
  readonly cidr: string;
  /** Explicit zones, so synth never needs an AWS lookup. */
  readonly availabilityZones: string[];
  readonly natGateways: number;
  /** Interface endpoints cost per zone per hour. 1 halves the cost; 2 keeps zone independence. */
  readonly interfaceEndpointAzCount: number;
}

export interface ServiceConfig {
  readonly desiredCount: number;
  /** Fargate CPU units: 256 is 0.25 vCPU. */
  readonly cpu: number;
  readonly memoryMiB: number;
  readonly containerPort: number;
  readonly healthCheckPath: string;
  readonly logLevel: string;
  readonly cpuArchitecture: 'X86_64' | 'ARM64';
}

export interface TaskSizeConfig {
  readonly cpu: number;
  readonly memoryMiB: number;
}

/**
 * Container commands. The image is the same for every task; only the command changes.
 * Each is a single config value so the API engineer can change it in one place.
 */
export interface CommandsConfig {
  /** Runs forward-only migrations and exits 0 on success. */
  readonly migrate: string[];
  /** The job name from the Jobs table is appended as the last argument. */
  readonly jobs: string[];
  /** Default command of the publisher task; override it per run (publish-config or publish-copy). */
  readonly publish: string[];
}

export interface MonitoringConfig {
  /** GuardDuty allows one detector per account and region: turn off if one already exists. */
  readonly enableGuardDuty: boolean;
  /** Turn off if an organisation trail already covers this account. */
  readonly enableCloudTrail: boolean;
  readonly healthCheckRegions: string[];
}

export interface GithubConfig {
  /** `owner/repo` of the GitHub repository allowed to deploy. */
  readonly repository: string;
  /** IAM allows one GitHub OIDC provider per account: turn off if it already exists. */
  readonly createOidcProvider: boolean;
}

export interface EnvironmentConfig {
  readonly envName: EnvName;
  /** Used in resource names: focus-prod-snapshots, focus-staging-api. */
  readonly shortName: string;
  /** CloudFormation stack name prefix: Focus-Production, Focus-Staging. */
  readonly stackPrefix: string;
  readonly isProduction: boolean;
  readonly account: string;
  readonly primaryRegion: string;
  readonly backupRegion: string;
  readonly globalRegion: string;
  /** The website apex for this environment. api., cdn. and www. hang off it. */
  readonly domainName: string;
  readonly hostedZoneId: string;
  readonly hostedZoneName: string;
  readonly alertEmail: string;
  /** Optional mailbox for DMARC aggregate reports. */
  readonly dmarcReportEmail: string;
  readonly apple: AppleConfig;
  readonly googleIosClientId: string;
  readonly helpdeskWebhookUrl: string;
  readonly database: DatabaseConfig;
  readonly network: NetworkConfig;
  readonly api: ServiceConfig;
  readonly jobs: TaskSizeConfig;
  readonly commands: CommandsConfig;
  readonly monitoring: MonitoringConfig;
  readonly github: GithubConfig;
  /** Application log retention (spec: 30 days). */
  readonly logRetentionDays: number;
  /** Logs that hold IP addresses: WAF, load balancer, CloudFront, S3 access (spec: 14 days). */
  readonly edgeLogRetentionDays: number;
  readonly wafRateLimitPer5Minutes: number;
  /** Other accounts allowed to pull from this registry (staging lets production copy tested images). */
  readonly imageReaderAccountIds: string[];
  /** Registry the production pipeline copies tested images from. */
  readonly imageSourceRepositoryArn?: string;
}

/** Fields that may be overridden with flat context keys or environment variables. */
export const OVERRIDABLE_FIELDS = [
  'account',
  'domainName',
  'hostedZoneId',
  'hostedZoneName',
  'alertEmail',
  'dmarcReportEmail',
  'googleIosClientId',
  'helpdeskWebhookUrl',
  'apple.teamId',
  'apple.bundleId',
  'apple.appAppleId',
  'apple.siwaKeyId',
  'apple.appStoreIssuerId',
  'apple.appStoreKeyId',
  'apple.appStoreEnvironment',
] as const;

export class ConfigError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ConfigError';
  }
}

type Json = Record<string, unknown>;

/** `apple.teamId` becomes `APPLE_TEAM_ID`. */
export function envVarSuffix(path: string): string {
  return path
    .split('.')
    .map((part) => part.replace(/([a-z0-9])([A-Z])/g, '$1_$2').toUpperCase())
    .join('_');
}

function isObject(value: unknown): value is Json {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function getPath(obj: Json, path: string): unknown {
  return path.split('.').reduce<unknown>((acc, key) => (isObject(acc) ? acc[key] : undefined), obj);
}

function setPath(obj: Json, path: string, value: unknown): void {
  const keys = path.split('.');
  let cursor: Json = obj;
  for (const key of keys.slice(0, -1)) {
    if (!isObject(cursor[key])) cursor[key] = {};
    cursor = cursor[key] as Json;
  }
  cursor[keys[keys.length - 1]] = value;
}

function str(raw: Json, path: string, fallback?: string): string {
  const value = getPath(raw, path);
  if (value === undefined || value === null) {
    if (fallback !== undefined) return fallback;
    throw new ConfigError(`Missing required setting "${path}"`);
  }
  if (typeof value !== 'string') throw new ConfigError(`Setting "${path}" must be a string`);
  return value.trim();
}

function num(raw: Json, path: string, fallback: number): number {
  const value = getPath(raw, path);
  if (value === undefined || value === null || value === '') return fallback;
  const parsed = typeof value === 'number' ? value : Number(value);
  if (!Number.isFinite(parsed)) throw new ConfigError(`Setting "${path}" must be a number`);
  return parsed;
}

function bool(raw: Json, path: string, fallback: boolean): boolean {
  const value = getPath(raw, path);
  if (value === undefined || value === null || value === '') return fallback;
  if (typeof value === 'boolean') return value;
  if (value === 'true') return true;
  if (value === 'false') return false;
  throw new ConfigError(`Setting "${path}" must be true or false`);
}

function strList(raw: Json, path: string, fallback: string[]): string[] {
  const value = getPath(raw, path);
  if (value === undefined || value === null || value === '') return fallback;
  if (typeof value === 'string') return value.split(',').map((v) => v.trim()).filter(Boolean);
  if (Array.isArray(value) && value.every((v) => typeof v === 'string')) return value.map((v) => v.trim());
  throw new ConfigError(`Setting "${path}" must be a list of strings`);
}

const ACCOUNT_RE = /^\d{12}$/;
const ZONE_ID_RE = /^Z[A-Z0-9]{1,32}$/;
const DOMAIN_RE = /^(?=.{1,253}$)([a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$/;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function validate(config: EnvironmentConfig): void {
  const where = `environment "${config.envName}"`;
  if (!ACCOUNT_RE.test(config.account)) {
    throw new ConfigError(`${where}: account must be 12 digits, got "${config.account}"`);
  }
  if (!ZONE_ID_RE.test(config.hostedZoneId)) {
    throw new ConfigError(`${where}: hostedZoneId must look like Z0123456789ABC, got "${config.hostedZoneId}"`);
  }
  for (const [key, value] of [
    ['domainName', config.domainName],
    ['hostedZoneName', config.hostedZoneName],
  ] as const) {
    if (!DOMAIN_RE.test(value)) throw new ConfigError(`${where}: ${key} is not a valid lower case domain: "${value}"`);
  }
  if (config.domainName !== config.hostedZoneName && !config.domainName.endsWith(`.${config.hostedZoneName}`)) {
    throw new ConfigError(`${where}: domainName "${config.domainName}" must be inside hosted zone "${config.hostedZoneName}"`);
  }
  if (!EMAIL_RE.test(config.alertEmail)) throw new ConfigError(`${where}: alertEmail is not an email address`);
  if (config.dmarcReportEmail && !EMAIL_RE.test(config.dmarcReportEmail)) {
    throw new ConfigError(`${where}: dmarcReportEmail is not an email address`);
  }
  if (!/^[A-Z0-9]{10}$/.test(config.apple.teamId)) {
    throw new ConfigError(`${where}: apple.teamId must be the 10 character Apple Team ID`);
  }
  if (!['Production', 'Sandbox', 'Xcode', 'LocalTesting'].includes(config.apple.appStoreEnvironment)) {
    throw new ConfigError(`${where}: apple.appStoreEnvironment must be Production, Sandbox, Xcode or LocalTesting`);
  }
  if (config.helpdeskWebhookUrl && !config.helpdeskWebhookUrl.startsWith('https://')) {
    throw new ConfigError(`${where}: helpdeskWebhookUrl must be an https URL or empty`);
  }
  if (!/^[\w.-]+\/[\w.-]+$/.test(config.github.repository)) {
    throw new ConfigError(`github.repository must be "owner/repo", got "${config.github.repository}"`);
  }
  if (config.network.availabilityZones.length !== 2) {
    throw new ConfigError(`${where}: network.availabilityZones must list exactly 2 zones`);
  }
  if (![1, 2].includes(config.network.interfaceEndpointAzCount)) {
    throw new ConfigError(`${where}: network.interfaceEndpointAzCount must be 1 or 2`);
  }
  if (config.database.backupRetentionDays < 1 || config.database.backupRetentionDays > 35) {
    throw new ConfigError(`${where}: database.backupRetentionDays must be between 1 and 35`);
  }
  if (config.database.maxAllocatedStorageGiB < config.database.allocatedStorageGiB) {
    throw new ConfigError(`${where}: database.maxAllocatedStorageGiB must be at least allocatedStorageGiB`);
  }
  for (const [key, command] of Object.entries(config.commands)) {
    if (!Array.isArray(command) || command.length === 0) {
      throw new ConfigError(`${where}: commands.${key} must be a non-empty list`);
    }
  }
}

export interface ConfigSources {
  /** The `focus` object from cdk.json context. */
  readonly focus: unknown;
  /** Returns a flat context value such as `focus:production:account`, or undefined. */
  readonly context: (key: string) => unknown;
  readonly env: Record<string, string | undefined>;
}

function applyOverrides(envName: EnvName, raw: Json, sources: ConfigSources): Json {
  const merged: Json = structuredClone(raw);
  for (const field of OVERRIDABLE_FIELDS) {
    const fromContext = sources.context(`focus:${envName}:${field}`);
    const fromEnv = sources.env[`FOCUS_${envName.toUpperCase()}_${envVarSuffix(field)}`];
    const value = fromEnv ?? fromContext;
    if (value !== undefined && value !== '') setPath(merged, field, String(value));
  }
  return merged;
}

export function buildEnvironmentConfig(envName: EnvName, sources: ConfigSources): EnvironmentConfig {
  const focus = isObject(sources.focus) ? sources.focus : {};
  const environments = isObject(focus.environments) ? focus.environments : {};
  const base = isObject(environments[envName]) ? (environments[envName] as Json) : {};
  const raw = applyOverrides(envName, base, sources);
  const github: Json = isObject(focus.github) ? focus.github : {};
  const repository =
    sources.env.FOCUS_GITHUB_REPOSITORY ?? (sources.context('focus:github.repository') as string | undefined) ?? str(github, 'repository', '');

  const isProduction = envName === 'production';
  const shortName = isProduction ? 'prod' : 'staging';

  const config: EnvironmentConfig = {
    envName,
    shortName,
    stackPrefix: isProduction ? 'Focus-Production' : 'Focus-Staging',
    isProduction,
    account: str(raw, 'account'),
    primaryRegion: PRIMARY_REGION,
    backupRegion: BACKUP_REGION,
    globalRegion: GLOBAL_REGION,
    domainName: str(raw, 'domainName').toLowerCase(),
    hostedZoneId: str(raw, 'hostedZoneId'),
    hostedZoneName: str(raw, 'hostedZoneName').toLowerCase().replace(/\.$/, ''),
    alertEmail: str(raw, 'alertEmail'),
    dmarcReportEmail: str(raw, 'dmarcReportEmail', ''),
    apple: {
      teamId: str(raw, 'apple.teamId'),
      bundleId: str(raw, 'apple.bundleId', isProduction ? 'au.adhdslayer.focus' : 'au.adhdslayer.focus.staging'),
      appAppleId: str(raw, 'apple.appAppleId', ''),
      siwaKeyId: str(raw, 'apple.siwaKeyId', ''),
      appStoreIssuerId: str(raw, 'apple.appStoreIssuerId', ''),
      appStoreKeyId: str(raw, 'apple.appStoreKeyId', ''),
      appStoreEnvironment: str(raw, 'apple.appStoreEnvironment', isProduction ? 'Production' : 'Sandbox') as AppStoreEnvironment,
    },
    googleIosClientId: str(raw, 'googleIosClientId', ''),
    helpdeskWebhookUrl: str(raw, 'helpdeskWebhookUrl', ''),
    database: {
      instanceClass: str(raw, 'database.instanceClass', 't4g.micro'),
      allocatedStorageGiB: num(raw, 'database.allocatedStorageGiB', 20),
      maxAllocatedStorageGiB: num(raw, 'database.maxAllocatedStorageGiB', 100),
      multiAz: bool(raw, 'database.multiAz', true),
      deletionProtection: bool(raw, 'database.deletionProtection', isProduction),
      performanceInsights: bool(raw, 'database.performanceInsights', false),
      backupRetentionDays: num(raw, 'database.backupRetentionDays', 35),
      credentialRotationDays: num(raw, 'database.credentialRotationDays', 30),
    },
    network: {
      cidr: str(raw, 'network.cidr', isProduction ? '10.50.0.0/16' : '10.40.0.0/16'),
      availabilityZones: strList(raw, 'network.availabilityZones', [`${PRIMARY_REGION}a`, `${PRIMARY_REGION}b`]),
      natGateways: num(raw, 'network.natGateways', 1),
      interfaceEndpointAzCount: num(raw, 'network.interfaceEndpointAzCount', 2),
    },
    api: {
      desiredCount: num(raw, 'api.desiredCount', 2),
      cpu: num(raw, 'api.cpu', 256),
      memoryMiB: num(raw, 'api.memoryMiB', 512),
      containerPort: num(raw, 'api.containerPort', 8080),
      healthCheckPath: str(raw, 'api.healthCheckPath', '/healthz'),
      logLevel: str(raw, 'api.logLevel', 'info'),
      cpuArchitecture: str(raw, 'api.cpuArchitecture', 'X86_64') as 'X86_64' | 'ARM64',
    },
    jobs: {
      cpu: num(raw, 'jobs.cpu', 256),
      memoryMiB: num(raw, 'jobs.memoryMiB', 512),
    },
    commands: {
      migrate: strList(raw, 'commands.migrate', ['node', 'dist/db/migrate.js']),
      jobs: strList(raw, 'commands.jobs', ['node', 'dist/jobs/run.js']),
      publish: strList(raw, 'commands.publish', ['npm', 'run', 'publish-config']),
    },
    monitoring: {
      enableGuardDuty: bool(raw, 'monitoring.enableGuardDuty', true),
      enableCloudTrail: bool(raw, 'monitoring.enableCloudTrail', true),
      healthCheckRegions: strList(raw, 'monitoring.healthCheckRegions', ['ap-southeast-2', 'ap-southeast-1', 'ap-northeast-1', 'us-west-2']),
    },
    github: {
      repository,
      createOidcProvider: bool(github, 'createOidcProvider', true),
    },
    logRetentionDays: num(raw, 'logRetentionDays', 30),
    edgeLogRetentionDays: num(raw, 'edgeLogRetentionDays', 14),
    wafRateLimitPer5Minutes: num(raw, 'wafRateLimitPer5Minutes', 2000),
    imageReaderAccountIds: strList(raw, 'imageReaderAccountIds', []),
  };
  validate(config);
  return config;
}

/**
 * Loads every requested environment and links them: staging's registry lets the production
 * account pull, and production copies tested images from staging's registry.
 */
export function loadConfigs(sources: ConfigSources): EnvironmentConfig[] {
  const requested = (sources.env.FOCUS_ENVIRONMENTS ?? (sources.context('focus:environments') as string | undefined) ?? 'staging,production')
    .split(',')
    .map((v) => v.trim())
    .filter(Boolean);
  for (const name of requested) {
    if (!(ENVIRONMENT_NAMES as readonly string[]).includes(name)) {
      throw new ConfigError(`Unknown environment "${name}". Use staging, production or both.`);
    }
  }
  const byName = new Map<EnvName, EnvironmentConfig>();
  for (const name of ENVIRONMENT_NAMES) {
    byName.set(name, buildEnvironmentConfig(name, sources));
  }
  const staging = byName.get('staging')!;
  const production = byName.get('production')!;
  if (staging.account === production.account) {
    throw new ConfigError('staging and production must use different AWS accounts (one account per environment)');
  }
  const linkedStaging: EnvironmentConfig = {
    ...staging,
    imageReaderAccountIds: [...new Set([...staging.imageReaderAccountIds, production.account])],
  };
  const linkedProduction: EnvironmentConfig = {
    ...production,
    imageSourceRepositoryArn: `arn:aws:ecr:${staging.primaryRegion}:${staging.account}:repository/${new Naming(staging).repositoryName}`,
  };
  const linked: Record<EnvName, EnvironmentConfig> = { staging: linkedStaging, production: linkedProduction };
  return requested.map((name) => linked[name as EnvName]);
}

/** Reads configuration from a CDK node's context and the process environment. */
export function sourcesFromNode(node: Node, env: Record<string, string | undefined> = process.env): ConfigSources {
  return {
    focus: node.tryGetContext('focus'),
    context: (key) => node.tryGetContext(key),
    env,
  };
}

/**
 * Every name the stacks, scripts and pipeline agree on. Scripts in scripts/lib.sh follow the
 * same conventions, so a change here must be mirrored there.
 */
export class Naming {
  constructor(private readonly config: EnvironmentConfig) {}

  get prefix(): string {
    return `focus-${this.config.shortName}`;
  }

  bucketName(purpose: string): string {
    return `${this.prefix}-${purpose}-${this.config.account}`;
  }

  /** Bucket names are fixed, so their ARNs are known without a reference to the bucket. */
  bucketArn(purpose: string, objectPattern?: string): string {
    const arn = `arn:aws:s3:::${this.bucketName(purpose)}`;
    return objectPattern === undefined ? arn : `${arn}/${objectPattern}`;
  }

  kmsAlias(name: string): string {
    return `alias/focus/${this.config.envName}/${name}`;
  }

  secretName(name: string): string {
    return `focus/${this.config.envName}/${name}`;
  }

  parameterName(name: string): string {
    return `/focus/${this.config.envName}/${name}`;
  }

  logGroupName(name: string): string {
    return `/focus/${this.config.envName}/${name}`;
  }

  resource(name: string): string {
    return `${this.prefix}-${name}`;
  }

  get repositoryName(): string {
    return this.resource('api');
  }

  get imageTagParameterName(): string {
    return this.parameterName('api/image-tag');
  }

  get clusterName(): string {
    return this.prefix;
  }

  get apiServiceName(): string {
    return this.resource('api');
  }

  family(name: 'api' | 'migrate' | 'publish' | 'jobs'): string {
    return this.resource(name);
  }

  get alertTopicName(): string {
    return this.resource('alerts');
  }

  get alertTopicArn(): string {
    return `arn:aws:sns:${this.config.primaryRegion}:${this.config.account}:${this.alertTopicName}`;
  }

  get apiHost(): string {
    return `api.${this.config.domainName}`;
  }

  get cdnHost(): string {
    return `cdn.${this.config.domainName}`;
  }

  get webHost(): string {
    return this.config.domainName;
  }

  get wwwHost(): string {
    return `www.${this.config.domainName}`;
  }

  get publicApiUrl(): string {
    return `https://${this.apiHost}`;
  }

  get publicWebUrl(): string {
    return `https://${this.webHost}`;
  }

  get signInAddress(): string {
    return `signin@${this.config.domainName}`;
  }

  get supportAddress(): string {
    return `support@${this.config.domainName}`;
  }

  get mailFromDomain(): string {
    return `mail.${this.config.domainName}`;
  }

  /** CONTRACT.md: SES_CONFIGURATION_SET. Each environment has its own account, so the name repeats safely. */
  get sesConfigurationSetName(): string {
    return 'focus-transactional';
  }

  alarmName(name: string): string {
    return this.resource(name);
  }

  stackName(part: string): string {
    return `${this.config.stackPrefix}-${part}`;
  }
}
