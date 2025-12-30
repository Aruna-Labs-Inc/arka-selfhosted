# Arka AWS Fargate Deployment

Deploy Arka to AWS in minutes using **AWS CDK** (Cloud Development Kit) with serverless **Fargate** containers, managed **RDS PostgreSQL**, and auto-scaling **Application Load Balancer**.

## 🚀 Quick Start

### Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured: `aws configure`
3. **Node.js 18+** installed
4. **Anthropic API Key** from https://console.anthropic.com

### One-Command Deploy

```bash
./deploy-fargate.sh \
  --account-id 123456789012 \
  --endpoint-name arka \
  --anthropic-key sk-ant-...
```

That's it! The script will:
- ✅ Create a complete production environment (10-15 min)
- ✅ Give you a public HTTPS URL instantly
- ✅ Auto-scale from 2-10 containers based on load
- ✅ Handle database backups automatically

## 📖 Usage Modes

### Interactive Mode (Recommended)

Just run the script and answer the prompts:

```bash
./deploy-fargate.sh
```

### Command-Line Mode

Pass all options as arguments:

```bash
./deploy-fargate.sh \
  --account-id 123456789012 \
  --region us-west-2 \
  --endpoint-name arka \
  --anthropic-key sk-ant-...
```

### With Custom Domain

If you own a domain managed in Route53:

```bash
./deploy-fargate.sh \
  --account-id 123456789012 \
  --endpoint-name chat \
  --anthropic-key sk-ant-... \
  --domain-name chat.company.com \
  --hosted-zone-id Z1234567890ABC
```

## 🏗️ What Gets Created

### Networking
- **VPC** with public and private subnets across 2 availability zones
- **Internet Gateway** for public access
- **NAT Gateway** for private subnet internet access
- **Security Groups** with least-privilege access

### Compute (Serverless)
- **ECS Fargate Cluster** - no EC2 servers to manage
- **Fargate Tasks** - 2 containers (0.5 vCPU, 1GB RAM each)
- **Auto Scaling** - scales 2-10 tasks based on CPU/memory
- **Application Load Balancer** - internet-facing with HTTPS

### Database
- **RDS PostgreSQL** - db.t4g.small instance
- **Automated Backups** - 7 day retention
- **Encryption** at rest and in transit
- **Multi-AZ** option for high availability

### Storage & Secrets
- **S3 Bucket** - encrypted file uploads with 90-day lifecycle
- **Secrets Manager** - encrypted API keys and credentials
- **CloudWatch Logs** - 7-day retention for debugging

### DNS & SSL (Optional)
- **ACM Certificate** - free SSL/TLS certificate
- **Route53 Record** - automatic DNS configuration
- **HTTPS Redirect** - forces secure connections

## 🎯 Endpoint Name Configuration

The `--endpoint-name` parameter controls:

### Resource Naming
All AWS resources are prefixed with your endpoint name:
- Stack: `{endpoint-name}-stack`
- Cluster: `{endpoint-name}-cluster`
- Service: `{endpoint-name}-service`
- ALB: `{endpoint-name}-alb`
- S3 Bucket: `{endpoint-name}-uploads-{account-id}`

### URL Generation

**Without custom domain:**
```bash
--endpoint-name arka
# Creates: http://arka-alb-1234567890.us-west-2.elb.amazonaws.com
```

**With custom domain:**
```bash
--endpoint-name chat --domain-name chat.company.com
# Creates: https://chat.company.com
```

### Best Practices
- Use lowercase letters, numbers, and hyphens only
- Keep it short and descriptive: `arka`, `chat`, `ai-assistant`
- Use different names for dev/staging/prod environments

## 📋 Command Reference

### Deploy New Environment

```bash
./deploy-fargate.sh \
  --account-id YOUR_ACCOUNT_ID \
  --region us-west-2 \
  --endpoint-name arka \
  --anthropic-key YOUR_API_KEY
```

### Update Existing Deployment

Deploy with a new ECR image:

```bash
./deploy-fargate.sh \
  --account-id YOUR_ACCOUNT_ID \
  --endpoint-name arka \
  --anthropic-key YOUR_API_KEY \
  --ecr-image 123456789012.dkr.ecr.us-west-2.amazonaws.com/arka:v2.0.0
```

### View Application Logs

```bash
aws logs tail /ecs/arka-service --follow --region us-west-2
```

### Check Stack Status

```bash
cd scripts/aws-fargate-deployment
npm run cdk diff
```

### Destroy Everything

**⚠️ Warning: This deletes all resources including the database!**

```bash
cd scripts/aws-fargate-deployment
npm run destroy
```

## 🌐 Custom Domain Setup

### Option 1: Route53 Hosted Zone

If you manage your domain in Route53:

```bash
# Get your hosted zone ID
aws route53 list-hosted-zones --query "HostedZones[?Name=='company.com.'].Id" --output text

# Deploy with domain
./deploy-fargate.sh \
  --account-id 123456789012 \
  --endpoint-name chat \
  --anthropic-key sk-ant-... \
  --domain-name chat.company.com \
  --hosted-zone-id Z1234567890ABC
```

The script will:
- ✅ Create ACM certificate
- ✅ Validate via DNS automatically
- ✅ Create Route53 A record
- ✅ Configure HTTPS redirect

### Option 2: External DNS (Manual)

Deploy without `--domain-name`, then manually create a CNAME:

```bash
# 1. Deploy and get ALB DNS
./deploy-fargate.sh --account-id 123456789012 --endpoint-name arka --anthropic-key sk-ant-...

# 2. Create CNAME in your DNS provider
# chat.company.com -> arka-alb-1234567890.us-west-2.elb.amazonaws.com

# 3. Request ACM certificate manually for chat.company.com
# 4. Add certificate to ALB listener
```

## 💰 Cost Breakdown

### Minimal Setup (~$50-70/month)

| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| Fargate | 2 tasks × 0.5 vCPU × 1GB | ~$30 |
| RDS PostgreSQL | db.t4g.small | ~$18 |
| Application Load Balancer | Always on | ~$18 |
| NAT Gateway | 1 gateway | ~$32 |
| S3 + Logs + Secrets | Light usage | ~$2-5 |
| **Total** | | **~$100-105/mo** |

### Production Setup (~$300-500/month)

| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| Fargate | 4-10 tasks × 1 vCPU × 2GB | ~$120-300 |
| RDS PostgreSQL | db.t4g.medium (Multi-AZ) | ~$160 |
| Application Load Balancer | Always on | ~$18 |
| NAT Gateway | 2 gateways (Multi-AZ) | ~$64 |
| S3 + Backups + Logs | Medium usage | ~$10-20 |
| **Total** | | **~$372-562/mo** |

### Cost Optimization Tips

1. **Use 1 NAT Gateway** instead of 2 (single AZ)
2. **Use Aurora Serverless v2** for variable workloads
3. **Enable S3 Lifecycle** to delete old uploads (already configured)
4. **Use Fargate Spot** for non-critical tasks (50-70% discount)
5. **Schedule scaling** to reduce tasks during off-hours

## 🔧 Configuration Options

### All Available Flags

```bash
./deploy-fargate.sh \
  --account-id 123456789012           # AWS account ID (required)
  --region us-west-2                  # AWS region (default: us-west-2)
  --endpoint-name arka                # Resource prefix (required)
  --anthropic-key sk-ant-...          # Anthropic API key (required)
  --ecr-image <URI>                   # ECR image (default: shared repo)
  --domain-name chat.company.com      # Custom domain (optional)
  --hosted-zone-id Z1234567890ABC     # Route53 zone (with domain)
  --skip-prompts                      # Non-interactive mode
  --help                              # Show help
```

### Environment Variables (Alternative)

```bash
export AWS_ACCOUNT="123456789012"
export AWS_REGION="us-west-2"
export ENDPOINT_NAME="arka"
export ANTHROPIC_API_KEY="sk-ant-..."
export ECR_IMAGE_URI="123456789012.dkr.ecr.us-west-2.amazonaws.com/arka:latest"

./deploy-fargate.sh
```

## 🛠️ Advanced Configuration

### Modify Infrastructure

Edit `lib/arka-stack.ts` to customize:

**Database size:**
```typescript
databaseInstanceType: ec2.InstanceType.of(
  ec2.InstanceClass.T4G,
  ec2.InstanceSize.MEDIUM  // Change from SMALL to MEDIUM
)
```

**Fargate task size:**
```typescript
cpu: 1024,              // 1 vCPU (was 512)
memoryLimitMiB: 2048,   // 2GB (was 1024)
desiredCount: 4,        // 4 tasks (was 2)
```

**Auto-scaling limits:**
```typescript
maxTaskCount: 20  // Scale up to 20 tasks (was 10)
```

After changes, redeploy:
```bash
cd scripts/aws-fargate-deployment
npm run deploy
```

### Use Custom ECR Repository

Build and push to your own ECR:

```bash
# 1. Create ECR repository
aws ecr create-repository --repository-name arka --region us-west-2

# 2. Build and push image
docker build -t arka:latest .
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-west-2.amazonaws.com
docker tag arka:latest 123456789012.dkr.ecr.us-west-2.amazonaws.com/arka:latest
docker push 123456789012.dkr.ecr.us-west-2.amazonaws.com/arka:latest

# 3. Deploy with custom image
./deploy-fargate.sh \
  --account-id 123456789012 \
  --endpoint-name arka \
  --anthropic-key sk-ant-... \
  --ecr-image 123456789012.dkr.ecr.us-west-2.amazonaws.com/arka:latest
```

## 📊 Monitoring & Troubleshooting

### View Application Logs

```bash
# Tail logs in real-time
aws logs tail /ecs/arka-service --follow --region us-west-2

# View last 100 lines
aws logs tail /ecs/arka-service --since 10m --region us-west-2
```

### Check Service Health

```bash
# Get service status
aws ecs describe-services \
  --cluster arka-cluster \
  --services arka-service \
  --region us-west-2 \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}'

# Get task details
aws ecs list-tasks --cluster arka-cluster --region us-west-2
```

### View Metrics in CloudWatch

```bash
# Open CloudWatch console
aws cloudwatch get-dashboard --dashboard-name arka-monitoring

# Or view in browser
https://console.aws.amazon.com/cloudwatch/home?region=us-west-2
```

### Common Issues

**Deployment Fails:**
```bash
# Check CloudFormation events
aws cloudformation describe-stack-events \
  --stack-name arka-stack \
  --region us-west-2 \
  --max-items 20
```

**Tasks Not Starting:**
```bash
# Check task logs
aws ecs describe-tasks \
  --cluster arka-cluster \
  --tasks $(aws ecs list-tasks --cluster arka-cluster --region us-west-2 --query 'taskArns[0]' --output text) \
  --region us-west-2
```

**Database Connection Issues:**
```bash
# Verify security group rules
aws ec2 describe-security-groups \
  --filters "Name=tag:aws:cloudformation:stack-name,Values=arka-stack" \
  --region us-west-2
```

## 🔐 Security Best Practices

### Secrets Management
- ✅ All secrets stored in AWS Secrets Manager (encrypted)
- ✅ No secrets in code or environment variables
- ✅ Automatic rotation supported

### Network Security
- ✅ Database in private subnet (no public access)
- ✅ Application in private subnet with ALB
- ✅ Security groups with least-privilege rules
- ✅ VPC endpoints for AWS services (optional)

### Data Protection
- ✅ RDS encryption at rest (AWS KMS)
- ✅ S3 bucket encryption (SSE-S3)
- ✅ HTTPS/TLS in transit
- ✅ Automated backups with 7-day retention

### Access Control
- ✅ IAM roles with minimal permissions
- ✅ No long-lived credentials
- ✅ CloudWatch Logs for audit trail

## 🚦 CI/CD Integration

### GitHub Actions

```yaml
name: Deploy to AWS Fargate

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-west-2
      
      - name: Deploy to Fargate
        run: |
          cd scripts/aws-fargate-deployment
          ./deploy-fargate.sh \
            --account-id ${{ secrets.AWS_ACCOUNT_ID }} \
            --endpoint-name arka \
            --anthropic-key ${{ secrets.ANTHROPIC_API_KEY }} \
            --skip-prompts
```

## 📚 Additional Resources

- [AWS CDK Documentation](https://docs.aws.amazon.com/cdk/)
- [ECS Fargate Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)
- [RDS PostgreSQL Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)

## 🆘 Support

For issues or questions:
- Check deployment logs: `aws logs tail /ecs/arka-service --follow`
- Verify stack status: `aws cloudformation describe-stacks --stack-name arka-stack`
- Review CDK diff: `cd scripts/aws-fargate-deployment && npm run cdk diff`

---

**Happy deploying! 🚀**
