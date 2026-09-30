import { Duration, RemovalPolicy } from 'aws-cdk-lib/core';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import type { Construct } from 'constructs';
import { FocusStack, type FocusStackProps } from '../focus-stack';

/** Value of the image tag parameter before the first image is pushed. */
export const NO_IMAGE_YET = 'none';

/**
 * The container registry and the "live image" pointer.
 *
 * This is its own stack so it can be deployed before anything that runs the image: on day one the
 * owner deploys this stack, pushes the first image, then deploys the rest (README, First deploy).
 *
 * The pipeline owns the image tag parameter's value: it writes the commit SHA after every good
 * rollout. CloudFormation reads it at deploy time (never at synth), so a later `cdk deploy` keeps
 * running whatever is live instead of rolling the service back to an old image.
 */
export class RegistryStack extends FocusStack {
  readonly repository: ecr.Repository;
  readonly imageTagParameterName: string;

  constructor(scope: Construct, props: FocusStackProps) {
    super(scope, 'Registry', props);
    const { config, naming: n } = this;

    this.repository = new ecr.Repository(this, 'ApiRepository', {
      repositoryName: n.repositoryName,
      imageScanOnPush: true,
      imageTagMutability: ecr.TagMutability.IMMUTABLE,
      encryption: ecr.RepositoryEncryption.AES_256,
      removalPolicy: RemovalPolicy.RETAIN,
      lifecycleRules: [
        { rulePriority: 1, description: 'Drop untagged layers after a week', tagStatus: ecr.TagStatus.UNTAGGED, maxImageAge: Duration.days(7) },
        // Enough history to roll back weeks of deploys.
        { rulePriority: 2, description: 'Keep the newest 100 images', tagStatus: ecr.TagStatus.ANY, maxImageCount: 100 },
      ],
    });

    if (config.imageReaderAccountIds.length > 0) {
      // Staging's registry lets production pull the exact image that passed staging.
      this.repository.addToResourcePolicy(
        new iam.PolicyStatement({
          sid: 'PromotionPull',
          principals: config.imageReaderAccountIds.map((account) => new iam.AccountPrincipal(account)),
          actions: ['ecr:BatchGetImage', 'ecr:GetDownloadUrlForLayer', 'ecr:BatchCheckLayerAvailability', 'ecr:DescribeImages'],
        }),
      );
    }

    this.imageTagParameterName = n.imageTagParameterName;
    // DO NOT change this resource's properties. CloudFormation would write the literal value back,
    // and the next deploy of the Api and Jobs stacks would try to run an image called "none" (the
    // ECS circuit breaker would then roll the service back, but nothing new would deploy).
    // A test pins these properties.
    new ssm.StringParameter(this, 'ImageTag', {
      parameterName: this.imageTagParameterName,
      stringValue: NO_IMAGE_YET,
      description: 'Live API image tag (commit SHA). Written by the deploy pipeline; read by CloudFormation at deploy time.',
      tier: ssm.ParameterTier.STANDARD,
    });
  }
}
