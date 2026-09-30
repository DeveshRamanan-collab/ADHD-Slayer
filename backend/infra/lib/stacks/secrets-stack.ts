import { RemovalPolicy } from 'aws-cdk-lib/core';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import type { Construct } from 'constructs';
import { FocusStack, type FocusStackProps } from '../focus-stack';
import { acknowledge } from '../nag';
import { pascal } from '../util';

/** Secrets the owner pastes by hand. Names are fixed by CONTRACT.md. */
export const PLACEHOLDER_SECRETS = {
  appleSiwaKey: {
    name: 'apple-siwa-key',
    description: 'Sign in with Apple private key: the full .p8 PEM text. Paste with scripts/secrets.sh (README).',
  },
  appStoreKey: {
    name: 'appstore-key',
    description: 'App Store Server API (In-App Purchase) private key: the full .p8 PEM text. Paste with scripts/secrets.sh (README).',
  },
  helpdeskApiKey: {
    name: 'helpdesk-api-key',
    description: 'Helpdesk API key, or the word "unset" while there is no helpdesk. Paste with scripts/secrets.sh (README).',
  },
} as const;

export type PlaceholderSecretKey = keyof typeof PLACEHOLDER_SECRETS;

/**
 * Empty Secrets Manager secrets for keys issued outside AWS.
 *
 * They are created without a value on purpose: CloudFormation never holds or overwrites the key,
 * so a later deploy can't wipe what the owner pasted. ECS can't start a task that references a
 * secret with no value, so `scripts/secrets.sh init <env>` fills any empty one with "unset" before
 * the first deploy of the Api stack, and the API treats "unset" as not configured.
 */
export class SecretsStack extends FocusStack {
  readonly secrets: Record<PlaceholderSecretKey, secretsmanager.ISecret>;

  constructor(scope: Construct, props: FocusStackProps) {
    super(scope, 'Secrets', props);
    const n = this.naming;

    const entries = Object.entries(PLACEHOLDER_SECRETS).map(([key, spec]) => {
      const secret = new secretsmanager.CfnSecret(this, pascal(spec.name), {
        name: n.secretName(spec.name),
        description: spec.description,
        // No SecretString and no GenerateSecretString: Secrets Manager creates an empty secret.
      });
      secret.applyRemovalPolicy(RemovalPolicy.RETAIN);
      acknowledge(
        secret,
        'Keys issued by Apple and the helpdesk can only be rotated by reissuing them there; the rotation runbook in backend/infra/README.md covers each one.',
        'AwsSolutions-SMG4',
      );
      return [key, secretsmanager.Secret.fromSecretCompleteArn(this, `${pascal(spec.name)}Ref`, secret.ref)] as const;
    });
    this.secrets = Object.fromEntries(entries) as Record<PlaceholderSecretKey, secretsmanager.ISecret>;
  }
}
