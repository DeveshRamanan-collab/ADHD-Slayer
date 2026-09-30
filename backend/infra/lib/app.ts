import { Validations, type App } from 'aws-cdk-lib/core';
import { AwsSolutionsChecks } from 'cdk-nag';
import type { EnvironmentConfig } from './config';
import { ApiStack } from './stacks/api-stack';
import { CiStack } from './stacks/ci-stack';
import { DataStack } from './stacks/data-stack';
import { DrStack } from './stacks/dr-stack';
import { EdgeStack } from './stacks/edge-stack';
import { EmailStack } from './stacks/email-stack';
import { GlobalStack } from './stacks/global-stack';
import { JobsStack } from './stacks/jobs-stack';
import { KeysStack } from './stacks/keys-stack';
import { MonitoringStack } from './stacks/monitoring-stack';
import { NetworkStack } from './stacks/network-stack';
import { RegistryStack } from './stacks/registry-stack';
import { SecretsStack } from './stacks/secrets-stack';

export interface FocusEnvironment {
  readonly config: EnvironmentConfig;
  readonly ci: CiStack;
  readonly registry: RegistryStack;
  readonly network: NetworkStack;
  readonly keys: KeysStack;
  readonly secrets: SecretsStack;
  readonly dr: DrStack;
  readonly global: GlobalStack;
  readonly data: DataStack;
  readonly api: ApiStack;
  readonly jobs: JobsStack;
  readonly edge: EdgeStack;
  readonly email: EmailStack;
  readonly monitoring: MonitoringStack;
}

/**
 * Builds every stack for each environment and registers cdk-nag (AwsSolutions). Any finding that
 * isn't acknowledged with a reason fails `cdk synth` and the tests.
 *
 * Deploy order (CDK works it out from references; listed for humans):
 *   Ci, Registry, Network, Keys, Secrets, Dr (Melbourne), Global (us-east-1)
 *   Data, Api, Jobs, Edge, Email, Monitoring
 */
export function buildFocusApp(app: App, configs: EnvironmentConfig[]): FocusEnvironment[] {
  Validations.of(app).addPlugins(new AwsSolutionsChecks(app, { verbose: true }));

  return configs.map((config) => {
    const props = { config };
    const ci = new CiStack(app, props);
    const registry = new RegistryStack(app, props);
    const network = new NetworkStack(app, props);
    const keys = new KeysStack(app, props);
    const secrets = new SecretsStack(app, props);
    const dr = new DrStack(app, props);
    const global = new GlobalStack(app, props);
    const data = new DataStack(app, { ...props, network, keys, dr });
    const api = new ApiStack(app, { ...props, network, keys, secrets, data, registry });
    const jobs = new JobsStack(app, { ...props, network, keys, secrets, data, registry, api });
    const edge = new EdgeStack(app, { ...props, data, global, api });
    const email = new EmailStack(app, { ...props, keys, api });
    const monitoring = new MonitoringStack(app, { ...props, keys, data, api, jobs, email });

    return { config, ci, registry, network, keys, secrets, dr, global, data, api, jobs, edge, email, monitoring };
  });
}
