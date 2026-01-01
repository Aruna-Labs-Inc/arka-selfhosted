# Arka Self-Hosted Demo

**Quick proof-of-concept deployment to evaluate Arka for your use case.**

This repository provides a simple, one-script deployment of [Arka](https://arka.so) using Docker. Use this demo to:

- ✅ Test Arka with your own data and workflows
- ✅ Evaluate performance and capabilities
- ✅ Verify it meets your requirements
- ✅ Quick proof-of-concept before production deployment

Run Arka locally with Docker - no cloud infrastructure needed!

> **Note:** This is an evaluation version. For production deployments or assistance, please contact us at billing@arunalabs.io

## Prerequisites

1. **Docker** installed and running
   - macOS/Windows: [Docker Desktop](https://www.docker.com/products/docker-desktop/)
   - Linux: [Docker Engine](https://docs.docker.com/engine/install/)

2. **docker-compose** (usually included with Docker Desktop)

3. **Arka Evaluation Key** - Get your evaluation key at https://arunadev7.gumroad.com/l/arkaevaluate

That's it! No AWS account, no cloud infrastructure, no SSH keys needed.

## Quick Start

### 1. Get your Evaluation Key

Purchase your evaluation key at https://arunadev7.gumroad.com/l/arkaevaluate

### 2. Clone this repository

```bash
git clone https://github.com/Aruna-Labs-Inc/arka-selfhosted.git
cd arka-selfhosted
```

### 3. Deploy Arka

Run the deployment script:

```bash
./deploy.sh
```

The script will automatically:
- ✅ Check Docker is installed and running
- ✅ Generate secure passwords and secrets
- ✅ Pull Arka Docker image
- ✅ Start Arka and PostgreSQL

### 4. Access Arka

Once deployment completes, open your browser to:

**http://localhost:3000**

Create an account and start testing!

## Management Commands

### View Logs

```bash
./logs.sh          # View all logs
./logs.sh arka     # View Arka app logs only
./logs.sh postgres # View database logs only
```

### Check Status

```bash
./status.sh
```

Shows running containers and their health status.

### Update to Latest Version

```bash
./update.sh
```

Pulls the latest Arka image and restarts services.

### Stop Arka

```bash
./stop.sh
```

Stops Arka services (data is preserved).

### Start Arka

```bash
./start.sh
```

Starts Arka services again after stopping.

### Terminate (Delete Everything)

```bash
./terminate.sh
```

⚠️ **Warning:** This permanently deletes all data, containers, and volumes!

## Configuration

### Auto-Generated (Default)

The deployment script automatically generates:
- PostgreSQL password (secure random string)
- NextAuth secret (secure random string)
- `.env` file with all configuration

### Custom Configuration (Optional)

If you want to customize settings, create a `.env` file before running `./deploy.sh`:

```bash
cp .env.ec2.example .env
```

Then edit `.env` with your custom values:

```bash
# Database
POSTGRES_PASSWORD=your_secure_password

# Authentication
AUTH_SECRET=your_nextauth_secret
NEXTAUTH_URL=http://localhost:3000

# Optional: AI Provider API Keys
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
XAI_API_KEY=xai-...

# Optional: S3 Storage
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
S3_BUCKET_NAME=...
```

## Port Conflicts

If port 3000 is already in use, the deployment script will:
1. Detect the conflict
2. Ask if you want to use a different port
3. Automatically configure Arka to use the new port

## Troubleshooting

### Docker not running

```
Error: Docker daemon is not running
```

**Solution:** Start Docker Desktop or run `sudo systemctl start docker`

### Port already in use

```
Port 3000 is already in use
```

**Solution:** The script will prompt you to choose a different port, or stop the service using port 3000

### Missing Evaluation Key

```
Arka requires a valid evaluation key
```

**Solution:** Get your evaluation key at https://arunadev7.gumroad.com/l/arkaevaluate

### Services not starting

View logs to diagnose:

```bash
./logs.sh
```

Common issues:
- Database connection errors: Check `.env` file for correct `POSTGRES_PASSWORD`
- Port conflicts: Use `./status.sh` to check what's running

## How It Works

### Architecture

```
Your Machine
┌──────────────────────────────────┐
│                                  │
│  Browser → http://localhost:3000 │
│                ↓                 │
│  ┌──────────────────────┐       │
│  │  Arka App            │       │
│  │  (Docker Container)  │       │
│  └──────────┬───────────┘       │
│             ↓                    │
│  ┌──────────────────────┐       │
│  │  PostgreSQL          │       │
│  │  (Docker Container)  │       │
│  └──────────────────────┘       │
│                                  │
└──────────────────────────────────┘
```

### What's Running

- **arka-app**: The Arka application (Node.js/Next.js)
- **arka-postgres**: PostgreSQL database for storing data
- **arka-network**: Isolated Docker network for containers to communicate
- **postgres_data**: Docker volume for persistent database storage

## File Structure

```
├── README.md              # This file
├── docker-compose.yml     # Docker services definition
├── .env.ec2.example      # Environment template
├── .env                  # Your configuration (auto-generated)
│
├── deploy.sh             # Deploy Arka
├── update.sh             # Update to latest version
├── start.sh              # Start services
├── stop.sh               # Stop services
├── terminate.sh          # Delete everything
├── logs.sh               # View logs
└── status.sh             # Check status
```

## Support

For issues or questions:
- Check logs: `./logs.sh`
- Review status: `./status.sh`
- GitHub Issues: [Create an issue](https://github.com/Aruna-Labs-Inc/arka-selfhosted/issues)
- Contact: billing@arunalabs.io

## License

Same as the main Arka project.
