# 🚀 Arka AWS Quick Start

Deploy Arka to AWS in **one command**. No Kubernetes knowledge required.

## Prerequisites

- AWS account
- AWS CLI configured (`aws configure`)
- Node.js 18+ installed
- Anthropic API key

## Deploy Now

```bash
./deploy-fargate.sh
```

The script will ask you for:
1. AWS account ID (auto-detected)
2. Endpoint name (e.g., "arka" or "chat")
3. Anthropic API key

That's it! In 10-15 minutes you'll have:
- ✅ Public HTTPS URL
- ✅ Auto-scaling containers (2-10 tasks)
- ✅ Managed PostgreSQL database
- ✅ Automatic backups
- ✅ CloudWatch monitoring

## What You Get

**Your URL:**
```
http://arka-alb-1234567890.us-west-2.elb.amazonaws.com
```

**Infrastructure:**
- ECS Fargate (serverless containers)
- RDS PostgreSQL (managed database)
- Application Load Balancer (HTTPS)
- S3 (file uploads)
- Auto-scaling (2-10 containers)

**Cost:**
~$100/month for production-ready setup

## Next Steps

### View Logs
```bash
aws logs tail /ecs/arka-service --follow
```

### Update Deployment
```bash
./deploy-fargate.sh --endpoint-name arka --ecr-image NEW_IMAGE
```

### Delete Everything
```bash
cd scripts/aws-fargate-deployment && npm run destroy
```

## Need Help?

See [README.md](./README.md) for:
- Custom domain setup
- Advanced configuration
- Cost optimization
- Troubleshooting
- CI/CD integration

---

**Questions?** Check the full README or deployment logs.
