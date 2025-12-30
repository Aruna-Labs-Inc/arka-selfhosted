import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecs_patterns from 'aws-cdk-lib/aws-ecs-patterns';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as route53_targets from 'aws-cdk-lib/aws-route53-targets';
import * as logs from 'aws-cdk-lib/aws-logs';
import { Construct } from 'constructs';

export interface ArkaStackProps extends cdk.StackProps {
  endpointName?: string;
  domainName?: string;
  hostedZoneId?: string;
  anthropicApiKey: string;
  ecrImageUri: string;
  databaseInstanceType?: ec2.InstanceType;
  fargateTaskCpu?: number;
  fargateTaskMemory?: number;
  desiredTaskCount?: number;
  maxTaskCount?: number;
}

export class ArkaStack extends cdk.Stack {
  public readonly loadBalancerDnsName: string;
  public readonly databaseEndpoint: string;
  public readonly applicationUrl: string;

  constructor(scope: Construct, id: string, props: ArkaStackProps) {
    super(scope, id, props);

    const endpointName = props.endpointName || 'arka';

    // VPC with public and private subnets across 2 AZs
    const vpc = new ec2.Vpc(this, 'ArkaVpc', {
      maxAzs: 2,
      natGateways: 1, // Cost optimization: use 1 NAT gateway
      subnetConfiguration: [
        {
          cidrMask: 24,
          name: 'Public',
          subnetType: ec2.SubnetType.PUBLIC,
        },
        {
          cidrMask: 24,
          name: 'Private',
          subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
        },
      ],
    });

    // S3 bucket for file uploads
    const uploadsBucket = new s3.Bucket(this, 'ArkaUploadsBucket', {
      bucketName: `${endpointName}-uploads-${this.account}`,
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      lifecycleRules: [
        {
          id: 'DeleteOldUploads',
          enabled: true,
          expiration: cdk.Duration.days(90),
        },
      ],
    });

    // RDS PostgreSQL Database
    const databaseSecurityGroup = new ec2.SecurityGroup(this, 'DatabaseSecurityGroup', {
      vpc,
      description: 'Security group for Arka RDS database',
      allowAllOutbound: false,
    });

    const dbCredentials = new secretsmanager.Secret(this, 'DatabaseCredentials', {
      secretName: `${endpointName}/database/credentials`,
      generateSecretString: {
        secretStringTemplate: JSON.stringify({ username: 'arka_admin' }),
        generateStringKey: 'password',
        excludePunctuation: true,
        includeSpace: false,
        passwordLength: 32,
      },
    });

    const database = new rds.DatabaseInstance(this, 'ArkaDatabase', {
      engine: rds.DatabaseInstanceEngine.postgres({
        version: rds.PostgresEngineVersion.VER_15_4,
      }),
      instanceType: props.databaseInstanceType || ec2.InstanceType.of(
        ec2.InstanceClass.T4G,
        ec2.InstanceSize.SMALL
      ),
      vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      },
      securityGroups: [databaseSecurityGroup],
      credentials: rds.Credentials.fromSecret(dbCredentials),
      databaseName: 'arka',
      allocatedStorage: 20,
      maxAllocatedStorage: 100,
      storageEncrypted: true,
      backupRetention: cdk.Duration.days(7),
      deleteAutomatedBackups: false,
      removalPolicy: cdk.RemovalPolicy.SNAPSHOT,
      deletionProtection: true,
      multiAz: false, // Set to true for production
      publiclyAccessible: false,
      cloudwatchLogsExports: ['postgresql'],
      cloudwatchLogsRetention: logs.RetentionDays.ONE_WEEK,
    });

    // Application Secrets
    const appSecrets = new secretsmanager.Secret(this, 'AppSecrets', {
      secretName: `${endpointName}/app/secrets`,
      secretObjectValue: {
        ANTHROPIC_API_KEY: cdk.SecretValue.unsafePlainText(props.anthropicApiKey),
        AUTH_SECRET: cdk.SecretValue.unsafePlainText(
          // Generate random auth secret
          Buffer.from(Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15)).toString('base64')
        ),
      },
    });

    // ECS Cluster
    const cluster = new ecs.Cluster(this, 'ArkaCluster', {
      vpc,
      clusterName: `${endpointName}-cluster`,
      containerInsights: true,
    });

    // Certificate for HTTPS (optional)
    let certificate: acm.ICertificate | undefined;
    if (props.domainName && props.hostedZoneId) {
      const hostedZone = route53.HostedZone.fromHostedZoneAttributes(this, 'HostedZone', {
        hostedZoneId: props.hostedZoneId,
        zoneName: props.domainName,
      });

      certificate = new acm.Certificate(this, 'Certificate', {
        domainName: props.domainName,
        validation: acm.CertificateValidation.fromDns(hostedZone),
      });
    }

    // Fargate Service with Application Load Balancer
    const fargateService = new ecs_patterns.ApplicationLoadBalancedFargateService(
      this,
      'ArkaFargateService',
      {
        cluster,
        serviceName: `${endpointName}-service`,
        cpu: props.fargateTaskCpu || 512,
        memoryLimitMiB: props.fargateTaskMemory || 1024,
        desiredCount: props.desiredTaskCount || 2,
        taskImageOptions: {
          image: ecs.ContainerImage.fromRegistry(props.ecrImageUri),
          containerName: 'arka',
          containerPort: 3000,
          environment: {
            NODE_ENV: 'production',
            PORT: '3000',
            DATABASE_HOST: database.dbInstanceEndpointAddress,
            DATABASE_PORT: database.dbInstanceEndpointPort,
            DATABASE_NAME: 'arka',
            PGHOST: database.dbInstanceEndpointAddress,
            PGPORT: database.dbInstanceEndpointPort,
            PGDATABASE: 'arka',
            AWS_REGION: this.region,
            AWS_S3_BUCKET_NAME: uploadsBucket.bucketName,
            AWS_S3_REGION: this.region,
            USE_AWS_SECRETS_MANAGER: 'true',
            AWS_SECRET_NAME: appSecrets.secretName,
            AUTH_TRUST_HOST: 'true',
            ALLOW_GUEST_ACCESS: 'false',
            LOG_LEVEL: 'info',
          },
          secrets: {
            POSTGRES_URL: ecs.Secret.fromSecretsManager(dbCredentials, 'password').toString().includes('password')
              ? ecs.Secret.fromSecretsManager(dbCredentials)
              : ecs.Secret.fromSecretsManager(dbCredentials),
          },
          logDriver: ecs.LogDrivers.awsLogs({
            streamPrefix: 'arka',
            logRetention: logs.RetentionDays.ONE_WEEK,
          }),
        },
        publicLoadBalancer: true,
        certificate: certificate,
        redirectHTTP: certificate ? true : false,
        healthCheckGracePeriod: cdk.Duration.seconds(60),
        loadBalancerName: `${endpointName}-alb`,
      }
    );

    // Allow Fargate tasks to access the database
    database.connections.allowFrom(
      fargateService.service,
      ec2.Port.tcp(5432),
      'Allow Fargate tasks to access database'
    );

    // Allow Fargate tasks to access S3
    uploadsBucket.grantReadWrite(fargateService.taskDefinition.taskRole);

    // Allow Fargate tasks to read secrets
    appSecrets.grantRead(fargateService.taskDefinition.taskRole);
    dbCredentials.grantRead(fargateService.taskDefinition.taskRole);

    // Configure health check
    fargateService.targetGroup.configureHealthCheck({
      path: '/api/health',
      interval: cdk.Duration.seconds(30),
      timeout: cdk.Duration.seconds(10),
      healthyThresholdCount: 2,
      unhealthyThresholdCount: 3,
    });

    // Auto-scaling configuration
    const scaling = fargateService.service.autoScaleTaskCount({
      minCapacity: props.desiredTaskCount || 2,
      maxCapacity: props.maxTaskCount || 10,
    });

    scaling.scaleOnCpuUtilization('CpuScaling', {
      targetUtilizationPercent: 70,
      scaleInCooldown: cdk.Duration.seconds(60),
      scaleOutCooldown: cdk.Duration.seconds(60),
    });

    scaling.scaleOnMemoryUtilization('MemoryScaling', {
      targetUtilizationPercent: 80,
      scaleInCooldown: cdk.Duration.seconds(60),
      scaleOutCooldown: cdk.Duration.seconds(60),
    });

    // Route53 DNS record (if custom domain)
    if (props.domainName && props.hostedZoneId) {
      const hostedZone = route53.HostedZone.fromHostedZoneAttributes(this, 'HostedZoneForRecord', {
        hostedZoneId: props.hostedZoneId,
        zoneName: props.domainName,
      });

      new route53.ARecord(this, 'AliasRecord', {
        zone: hostedZone,
        recordName: props.domainName,
        target: route53.RecordTarget.fromAlias(
          new route53_targets.LoadBalancerTarget(fargateService.loadBalancer)
        ),
      });

      this.applicationUrl = `https://${props.domainName}`;
    } else {
      this.applicationUrl = `http://${fargateService.loadBalancer.loadBalancerDnsName}`;
    }

    this.loadBalancerDnsName = fargateService.loadBalancer.loadBalancerDnsName;
    this.databaseEndpoint = database.dbInstanceEndpointAddress;

    // Outputs
    new cdk.CfnOutput(this, 'LoadBalancerDNS', {
      value: this.loadBalancerDnsName,
      description: 'Application Load Balancer DNS name',
      exportName: `${endpointName}-alb-dns`,
    });

    new cdk.CfnOutput(this, 'ApplicationURL', {
      value: this.applicationUrl,
      description: 'Arka application URL',
      exportName: `${endpointName}-url`,
    });

    new cdk.CfnOutput(this, 'DatabaseEndpoint', {
      value: this.databaseEndpoint,
      description: 'RDS database endpoint',
      exportName: `${endpointName}-db-endpoint`,
    });

    new cdk.CfnOutput(this, 'S3BucketName', {
      value: uploadsBucket.bucketName,
      description: 'S3 bucket for file uploads',
      exportName: `${endpointName}-s3-bucket`,
    });

    new cdk.CfnOutput(this, 'ECSClusterName', {
      value: cluster.clusterName,
      description: 'ECS cluster name',
      exportName: `${endpointName}-cluster`,
    });

    new cdk.CfnOutput(this, 'ECSServiceName', {
      value: fargateService.service.serviceName,
      description: 'ECS service name',
      exportName: `${endpointName}-service`,
    });
  }
}
