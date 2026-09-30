import * as path from 'node:path';
import { CfnOutput, Duration } from 'aws-cdk-lib/core';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as route53Targets from 'aws-cdk-lib/aws-route53-targets';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import type { Construct } from 'constructs';
import { FocusStack, type FocusStackProps } from '../focus-stack';
import { acknowledge } from '../nag';
import type { ApiStack } from './api-stack';
import type { DataStack } from './data-stack';
import type { GlobalStack } from './global-stack';

export interface EdgeStackProps extends FocusStackProps {
  readonly data: DataStack;
  readonly global: GlobalStack;
  readonly api: ApiStack;
}

const FUNCTIONS_DIR = path.join(__dirname, '..', '..', 'functions');

/** The website makes no third-party requests and runs no scripts at all. */
export const WEBSITE_CONTENT_SECURITY_POLICY = [
  "default-src 'none'",
  "style-src 'self'",
  "img-src 'self'",
  "font-src 'self'",
  "base-uri 'none'",
  "form-action 'none'",
  "frame-ancestors 'none'",
  'upgrade-insecure-requests',
].join('; ');

/** Path of the Apple app site association file. It must be JSON and must never redirect. */
export const AASA_PATH = '/.well-known/apple-app-site-association';

/**
 * CloudFront for the website (`<domain>` and `www.`) and the config CDN (`cdn.`), plus their DNS.
 *
 * The CDN's only origin is the API load balancer, reached by its public name so TLS matches the
 * API certificate, and only `/v1/config*` and `/v1/copy/*` reach it. Everything else on the CDN
 * gets a 404 from a CloudFront Function.
 */
export class EdgeStack extends FocusStack {
  readonly webDistribution: cloudfront.Distribution;
  readonly cdnDistribution: cloudfront.Distribution;

  constructor(scope: Construct, props: EdgeStackProps) {
    super(scope, 'Edge', props);
    const { config, naming: n } = this;
    const { global } = props;
    // Bucket names are fixed, so the buckets are referenced by name. These dependencies keep the
    // deploy order right: buckets and the API origin exist before the distributions.
    this.addStackDependency(props.data, 'reads the website and access log buckets by name');
    this.addStackDependency(props.api, 'the CDN origin is the API host name');

    const zone = route53.HostedZone.fromHostedZoneAttributes(this, 'Zone', {
      hostedZoneId: config.hostedZoneId,
      zoneName: config.hostedZoneName,
    });
    const websiteBucket = s3.Bucket.fromBucketAttributes(this, 'WebsiteBucket', {
      bucketName: n.bucketName('website'),
      region: config.primaryRegion,
    });
    const accessLogs = s3.Bucket.fromBucketAttributes(this, 'AccessLogs', {
      bucketName: n.bucketName('access-logs'),
      region: config.primaryRegion,
    });

    // ---------------------------------------------------------------- website
    const securityHeaders: cloudfront.ResponseSecurityHeadersBehavior = {
      contentSecurityPolicy: { contentSecurityPolicy: WEBSITE_CONTENT_SECURITY_POLICY, override: true },
      contentTypeOptions: { override: true },
      frameOptions: { frameOption: cloudfront.HeadersFrameOption.DENY, override: true },
      referrerPolicy: { referrerPolicy: cloudfront.HeadersReferrerPolicy.NO_REFERRER, override: true },
      strictTransportSecurity: { accessControlMaxAge: Duration.days(730), includeSubdomains: true, override: true },
    };
    const commonCustomHeaders: cloudfront.ResponseCustomHeader[] = [
      { header: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=(), payment=(), usb=()', override: true },
      { header: 'Cross-Origin-Opener-Policy', value: 'same-origin', override: true },
      ...(config.isProduction ? [] : [{ header: 'X-Robots-Tag', value: 'noindex, nofollow', override: true }]),
    ];

    const webHeaders = new cloudfront.ResponseHeadersPolicy(this, 'WebHeaders', {
      responseHeadersPolicyName: n.resource('web-headers'),
      comment: 'Focus website: strict CSP (no scripts, no third parties) and security headers',
      securityHeadersBehavior: securityHeaders,
      customHeadersBehavior: { customHeaders: commonCustomHeaders },
      removeHeaders: ['x-amz-server-side-encryption', 'x-amz-version-id'],
    });
    const aasaHeaders = new cloudfront.ResponseHeadersPolicy(this, 'AasaHeaders', {
      responseHeadersPolicyName: n.resource('aasa-headers'),
      comment: 'apple-app-site-association: always application/json',
      securityHeadersBehavior: securityHeaders,
      customHeadersBehavior: {
        customHeaders: [{ header: 'Content-Type', value: 'application/json', override: true }, ...commonCustomHeaders],
      },
      removeHeaders: ['x-amz-server-side-encryption', 'x-amz-version-id'],
    });

    const webRewrite = new cloudfront.Function(this, 'WebViewerRequest', {
      functionName: n.resource('web-viewer-request'),
      comment: 'www to apex redirect and clean URLs; never touches /.well-known/',
      code: cloudfront.FunctionCode.fromFile({ filePath: path.join(FUNCTIONS_DIR, 'web-viewer-request.js') }),
      runtime: cloudfront.FunctionRuntime.JS_2_0,
    });

    const websiteOrigin = origins.S3BucketOrigin.withOriginAccessControl(websiteBucket, {
      originAccessLevels: [cloudfront.AccessLevel.READ],
    });

    this.webDistribution = new cloudfront.Distribution(this, 'WebDistribution', {
      comment: `Focus ${config.envName} website`,
      domainNames: [n.webHost, n.wwwHost],
      certificate: global.webCertificate,
      minimumProtocolVersion: cloudfront.SecurityPolicyProtocol.TLS_V1_2_2021,
      httpVersion: cloudfront.HttpVersion.HTTP2_AND_3,
      // Australia and New Zealand edge locations are only in the "All" price class.
      priceClass: cloudfront.PriceClass.PRICE_CLASS_ALL,
      defaultRootObject: 'index.html',
      enableLogging: true,
      logBucket: accessLogs,
      logFilePrefix: 'cloudfront/web/',
      logIncludesCookies: false,
      defaultBehavior: {
        origin: websiteOrigin,
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
        allowedMethods: cloudfront.AllowedMethods.ALLOW_GET_HEAD,
        cachedMethods: cloudfront.CachedMethods.CACHE_GET_HEAD,
        cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
        responseHeadersPolicy: webHeaders,
        compress: true,
        functionAssociations: [{ function: webRewrite, eventType: cloudfront.FunctionEventType.VIEWER_REQUEST }],
      },
      additionalBehaviors: {
        // No function, no redirect of any kind (HTTPS only rather than redirect-to-HTTPS).
        [AASA_PATH]: {
          origin: websiteOrigin,
          viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.HTTPS_ONLY,
          allowedMethods: cloudfront.AllowedMethods.ALLOW_GET_HEAD,
          cachedMethods: cloudfront.CachedMethods.CACHE_GET_HEAD,
          cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
          responseHeadersPolicy: aasaHeaders,
          compress: true,
        },
      },
      errorResponses: [
        // Without s3:ListBucket, S3 answers 403 for a missing key.
        { httpStatus: 403, responseHttpStatus: 404, responsePagePath: '/404.html', ttl: Duration.minutes(1) },
        { httpStatus: 404, responseHttpStatus: 404, responsePagePath: '/404.html', ttl: Duration.minutes(1) },
      ],
    });

    acknowledge(
      this.webDistribution,
      'The website bucket lives in the Data stack; this stack writes its bucket policy itself (WebsiteBucketPolicy below), naming this distribution in AWS:SourceArn.',
      'Annotation::@aws-cdk/aws-cloudfront-origins:updateImportedBucketPolicyOac',
    );

    // The website bucket's only policy: TLS 1.2 or later, and read access for this distribution.
    const websiteArn = n.bucketArn('website');
    new s3.CfnBucketPolicy(this, 'WebsiteBucketPolicy', {
      bucket: n.bucketName('website'),
      policyDocument: new iam.PolicyDocument({
        statements: [
          new iam.PolicyStatement({
            sid: 'DenyInsecureTransport',
            effect: iam.Effect.DENY,
            principals: [new iam.AnyPrincipal()],
            actions: ['s3:*'],
            resources: [websiteArn, `${websiteArn}/*`],
            conditions: { Bool: { 'aws:SecureTransport': 'false' } },
          }),
          new iam.PolicyStatement({
            sid: 'DenyOutdatedTls',
            effect: iam.Effect.DENY,
            principals: [new iam.AnyPrincipal()],
            actions: ['s3:*'],
            resources: [websiteArn, `${websiteArn}/*`],
            conditions: { NumericLessThan: { 's3:TlsVersion': 1.2 } },
          }),
          new iam.PolicyStatement({
            sid: 'AllowCloudFrontOriginAccessControlRead',
            principals: [new iam.ServicePrincipal('cloudfront.amazonaws.com')],
            actions: ['s3:GetObject'],
            resources: [`${websiteArn}/*`],
            conditions: {
              StringEquals: {
                'AWS:SourceArn': `arn:aws:cloudfront::${this.account}:distribution/${this.webDistribution.distributionId}`,
              },
            },
          }),
        ],
      }),
    });

    // ---------------------------------------------------------------- cdn (config and copy)
    const apiOrigin = new origins.HttpOrigin(n.apiHost, {
      protocolPolicy: cloudfront.OriginProtocolPolicy.HTTPS_ONLY,
      originSslProtocols: [cloudfront.OriginSslPolicy.TLS_V1_2],
      connectionAttempts: 3,
      connectionTimeout: Duration.seconds(5),
      readTimeout: Duration.seconds(10),
      keepaliveTimeout: Duration.seconds(5),
    });

    // Default TTL 0 and a positive maximum: CloudFront caches exactly as long as the API's
    // Cache-Control says (max-age=3600 for config, immutable decks), and not at all without it.
    const configCache = new cloudfront.CachePolicy(this, 'ConfigCachePolicy', {
      cachePolicyName: n.resource('cdn-config'),
      comment: 'GET /v1/config: honours the API Cache-Control; the documented query parameters form the key',
      minTtl: Duration.seconds(0),
      defaultTtl: Duration.seconds(0),
      maxTtl: Duration.days(1),
      queryStringBehavior: cloudfront.CacheQueryStringBehavior.allowList('appVersion', 'build', 'locale', 'region'),
      headerBehavior: cloudfront.CacheHeaderBehavior.none(),
      cookieBehavior: cloudfront.CacheCookieBehavior.none(),
      enableAcceptEncodingGzip: true,
      enableAcceptEncodingBrotli: true,
    });
    const copyCache = new cloudfront.CachePolicy(this, 'CopyCachePolicy', {
      cachePolicyName: n.resource('cdn-copy'),
      comment: 'GET /v1/copy/*: honours the API Cache-Control; decks are immutable',
      minTtl: Duration.seconds(0),
      defaultTtl: Duration.seconds(0),
      maxTtl: Duration.days(365),
      queryStringBehavior: cloudfront.CacheQueryStringBehavior.none(),
      headerBehavior: cloudfront.CacheHeaderBehavior.none(),
      cookieBehavior: cloudfront.CacheCookieBehavior.none(),
      enableAcceptEncodingGzip: true,
      enableAcceptEncodingBrotli: true,
    });
    const cdnHeaders = new cloudfront.ResponseHeadersPolicy(this, 'CdnHeaders', {
      responseHeadersPolicyName: n.resource('cdn-headers'),
      comment: 'Focus CDN: security headers; Signature, Signature-Key-Id and ETag pass through from the API',
      securityHeadersBehavior: {
        contentTypeOptions: { override: true },
        frameOptions: { frameOption: cloudfront.HeadersFrameOption.DENY, override: true },
        referrerPolicy: { referrerPolicy: cloudfront.HeadersReferrerPolicy.NO_REFERRER, override: true },
        strictTransportSecurity: { accessControlMaxAge: Duration.days(730), includeSubdomains: true, override: true },
      },
    });
    const notFound = new cloudfront.Function(this, 'CdnNotFound', {
      functionName: n.resource('cdn-not-found'),
      comment: 'Everything outside /v1/config* and /v1/copy/* is a 404 at the edge',
      code: cloudfront.FunctionCode.fromFile({ filePath: path.join(FUNCTIONS_DIR, 'cdn-not-found.js') }),
      runtime: cloudfront.FunctionRuntime.JS_2_0,
    });

    const apiBehavior = (cachePolicy: cloudfront.ICachePolicy): cloudfront.BehaviorOptions => ({
      origin: apiOrigin,
      viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.HTTPS_ONLY,
      allowedMethods: cloudfront.AllowedMethods.ALLOW_GET_HEAD,
      cachedMethods: cloudfront.CachedMethods.CACHE_GET_HEAD,
      cachePolicy,
      responseHeadersPolicy: cdnHeaders,
      compress: true,
    });

    this.cdnDistribution = new cloudfront.Distribution(this, 'CdnDistribution', {
      comment: `Focus ${config.envName} config and copy CDN`,
      domainNames: [n.cdnHost],
      certificate: global.cdnCertificate,
      minimumProtocolVersion: cloudfront.SecurityPolicyProtocol.TLS_V1_2_2021,
      httpVersion: cloudfront.HttpVersion.HTTP2_AND_3,
      priceClass: cloudfront.PriceClass.PRICE_CLASS_ALL,
      enableLogging: true,
      logBucket: accessLogs,
      logFilePrefix: 'cloudfront/cdn/',
      logIncludesCookies: false,
      defaultBehavior: {
        origin: apiOrigin,
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.HTTPS_ONLY,
        allowedMethods: cloudfront.AllowedMethods.ALLOW_GET_HEAD,
        cachePolicy: cloudfront.CachePolicy.CACHING_DISABLED,
        functionAssociations: [{ function: notFound, eventType: cloudfront.FunctionEventType.VIEWER_REQUEST }],
      },
      additionalBehaviors: {
        '/v1/config*': apiBehavior(configCache),
        '/v1/copy/*': apiBehavior(copyCache),
      },
    });

    for (const distribution of [this.webDistribution, this.cdnDistribution]) {
      acknowledge(
        distribution,
        'Focus is Australia first but people travel, and blocking countries at the edge would break sign-in links and config fetches abroad.',
        'AwsSolutions-CFR1',
      );
    }
    acknowledge(
      this.webDistribution,
      'Static public pages with GET and HEAD only; a CloudFront web ACL (in us-east-1) would cost more than the risk it removes.',
      'AwsSolutions-CFR2',
    );
    acknowledge(
      this.cdnDistribution,
      'Only cacheable GETs for two paths reach the origin, and the origin load balancer has its own AWS WAF web ACL with the per-IP rate limit.',
      'AwsSolutions-CFR2',
    );

    // ---------------------------------------------------------------- DNS
    const webTarget = route53.RecordTarget.fromAlias(new route53Targets.CloudFrontTarget(this.webDistribution));
    const cdnTarget = route53.RecordTarget.fromAlias(new route53Targets.CloudFrontTarget(this.cdnDistribution));
    for (const [id, recordName, target] of [
      ['Web', n.webHost, webTarget],
      ['Www', n.wwwHost, webTarget],
      ['Cdn', n.cdnHost, cdnTarget],
    ] as const) {
      new route53.ARecord(this, `${id}A`, { zone, recordName, target });
      new route53.AaaaRecord(this, `${id}Aaaa`, { zone, recordName, target });
    }

    new ssm.StringParameter(this, 'WebDistributionIdParameter', {
      parameterName: n.parameterName('deploy/web-distribution-id'),
      description: 'Website CloudFront distribution id, for cache invalidation after a website deploy',
      stringValue: this.webDistribution.distributionId,
    });
    new CfnOutput(this, 'WebDistributionId', { value: this.webDistribution.distributionId });
    new CfnOutput(this, 'CdnDistributionId', { value: this.cdnDistribution.distributionId });
    new CfnOutput(this, 'WebsiteUrl', { value: n.publicWebUrl });
    new CfnOutput(this, 'CdnUrl', { value: `https://${n.cdnHost}` });
  }
}
