# Arka Self-Hosted

Deploy Arka to AWS in minutes using **AWS CDK** (Cloud Development Kit) with serverless **Fargate** containers, managed **RDS PostgreSQL**, and auto-scaling **Application Load Balancer**.

## 🚀 Quick Start

### Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured: `aws configure`
3. **Node.js 18+** installed
4. **Anthropic API Key** from https://console.anthropic.com

### Deploy in 3 Steps

#### 1. Clone the Repository

```bash
git clone https://github.com/Aruna-Labs-Inc/arka-selfhosted.git
cd arka-selfhosted
```

#### 2. Navigate to Deployment Folder

```bash
cd aws-fargate-deployment
```

#### 3. Run Deployment Script

```bash
./deploy-fargate.sh \
  --account-id 123456789012 \
  --endpoint-name arka \
  --anthropic-key sk-ant-...
```

#### 4. Access Your Arka Instance

After deployment completes (10-15 min), the script outputs your application URL:

```
✅ Deployment complete!
🌐 Application URL: http://arka-alb-1234567890.us-west-2.elb.amazonaws.com
```

Open the URL in your browser to access Arka.

**What you get:**
- ✅ Complete production environment
- ✅ Public HTTPS URL (or HTTP if no custom domain)
- ✅ Auto-scaling from 2-10 containers based on load
- ✅ Automatic database backups

## 📖 Full Documentation

See the [AWS Fargate Deployment Guide](aws-fargate-deployment/README.md) for:
- Interactive and command-line deployment modes
- Custom domain configuration
- Cost breakdown and optimization tips
- Monitoring and troubleshooting
- Security best practices
- CI/CD integration examples
