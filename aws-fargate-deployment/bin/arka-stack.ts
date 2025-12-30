#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { ArkaStack } from '../lib/arka-stack';

const app = new cdk.App();

// Get configuration from context or environment variables
const endpointName = app.node.tryGetContext('endpointName') || process.env.ENDPOINT_NAME || 'arka';
const anthropicApiKey = app.node.tryGetContext('anthropicApiKey') || process.env.ANTHROPIC_API_KEY;
const ecrImageUri = app.node.tryGetContext('ecrImageUri') || process.env.ECR_IMAGE_URI || '634018648842.dkr.ecr.us-west-2.amazonaws.com/arka:latest';
const domainName = app.node.tryGetContext('domainName') || process.env.DOMAIN_NAME;
const hostedZoneId = app.node.tryGetContext('hostedZoneId') || process.env.HOSTED_ZONE_ID;

if (!anthropicApiKey) {
  throw new Error('ANTHROPIC_API_KEY is required. Set via --context anthropicApiKey=<key> or environment variable.');
}

new ArkaStack(app, `${endpointName}-stack`, {
  endpointName,
  anthropicApiKey,
  ecrImageUri,
  domainName,
  hostedZoneId,
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.AWS_REGION || process.env.CDK_DEFAULT_REGION || 'us-west-2',
  },
  description: `Arka deployment with endpoint name: ${endpointName}`,
  tags: {
    Project: 'Arka',
    EndpointName: endpointName,
    ManagedBy: 'CDK',
  },
});
