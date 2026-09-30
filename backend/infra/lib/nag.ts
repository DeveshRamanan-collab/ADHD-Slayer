import { Validations } from 'aws-cdk-lib/core';
import type { IConstruct } from 'constructs';

/**
 * Acknowledges (suppresses) cdk-nag findings on one construct, with a reason that lands in the
 * validation report. cdk-nag v3 needs one acknowledgment per finding, for example
 * `AwsSolutions-IAM5[Resource::*]`, so wildcard findings are listed one by one on purpose:
 * a new wildcard fails synth until someone writes down why it is needed.
 */
export function acknowledge(scope: IConstruct, reason: string, ...ids: string[]): void {
  if (ids.length === 0) throw new Error('acknowledge() needs at least one rule id');
  if (reason.trim().length < 20) throw new Error(`Acknowledgment reasons must explain the decision: "${reason}"`);
  for (const id of ids) {
    Validations.of(scope).acknowledge({ id, reason });
  }
}
