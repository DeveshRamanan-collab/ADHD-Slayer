import { Stack, type StackProps } from 'aws-cdk-lib/core';
import type { Construct } from 'constructs';
import { Naming, type EnvironmentConfig } from './config';

export interface FocusStackProps extends StackProps {
  readonly config: EnvironmentConfig;
}

/** Which of the three regions a stack lives in. */
export type RegionRole = 'primary' | 'backup' | 'global';

/**
 * Base for every Focus stack: pins account and region (so synth needs no lookups), names the
 * CloudFormation stack `Focus-<Env>-<Part>`, tags it, and turns on termination protection in
 * production.
 */
export abstract class FocusStack extends Stack {
  readonly config: EnvironmentConfig;
  readonly naming: Naming;

  protected constructor(scope: Construct, part: string, props: FocusStackProps, regionRole: RegionRole = 'primary') {
    const { config } = props;
    const region = regionRole === 'primary' ? config.primaryRegion : regionRole === 'backup' ? config.backupRegion : config.globalRegion;
    const naming = new Naming(config);
    super(scope, naming.stackName(part), {
      ...props,
      stackName: naming.stackName(part),
      env: { account: config.account, region },
      terminationProtection: config.isProduction,
      tags: {
        project: 'focus',
        environment: config.envName,
        'managed-by': 'cdk',
        ...props.tags,
      },
    });
    this.config = config;
    this.naming = naming;
    this.regionRole = regionRole;
  }

  private readonly regionRole: RegionRole;

  /**
   * Sydney stacks use the zones from config instead of an AWS lookup, so `cdk synth` works with no
   * credentials. Other regions never place anything by zone.
   */
  override get availabilityZones(): string[] {
    if (this.regionRole === 'primary' && this.config) return [...this.config.network.availabilityZones];
    return super.availabilityZones;
  }
}
