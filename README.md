# Docker Quickstart - Run Arka Locally

Get Arka running on your machine in 2 minutes.

## Prerequisites

- Docker installed
- AWS CLI configured

## Quick Start

### 1. Login to ECR

```bash
aws ecr get-login-password --region us-west-2 | \
  docker login --username AWS --password-stdin 634018648842.dkr.ecr.us-west-2.amazonaws.com
```

### 2. Pull the Image

```bash
docker pull 634018648842.dkr.ecr.us-west-2.amazonaws.com/arka:latest
```

### 3. Create docker-compose.yml

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: arka
      POSTGRES_USER: arka
      POSTGRES_PASSWORD: arka_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  arka:
    image: 634018648842.dkr.ecr.us-west-2.amazonaws.com/arka:latest
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: production
      AUTH_SECRET: change-me-in-production
      NEXTAUTH_SECRET: change-me-in-production
      DATABASE_URL: postgresql://arka:arka_password@postgres:5432/arka
      POSTGRES_URL: postgresql://arka:arka_password@postgres:5432/arka
      OPENAI_API_KEY: ${OPENAI_API_KEY}
      ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY}
      SSO_ONLY_MODE: "false"
      SUPERADMIN_USERNAME: admin
      SUPERADMIN_PASSWORD: admin123
      NEXTAUTH_URL: http://localhost:3000
    depends_on:
      - postgres

volumes:
  postgres_data:
```

### 4. Set Your API Keys

```bash
export OPENAI_API_KEY=sk-...
export ANTHROPIC_API_KEY=sk-ant-...
```

### 5. Start Arka

```bash
docker-compose up -d
```

### 6. Access Arka

Open http://localhost:3000

You should see the login screen:

![Arka Login Screen](Arka%20Login%20Screen.png)

Login with:
- Username: `admin`
- Password: `admin123`

## View Logs

```bash
docker-compose logs -f arka
```

## Stop Arka

```bash
docker-compose down
```

## Troubleshooting

**Container won't start?**
```bash
docker-compose logs arka
```

**Port 3000 already in use?**
```bash
# Change port in docker-compose.yml
ports:
  - "8080:3000"  # Use port 8080 instead
```

**Need to reset database?**
```bash
docker-compose down -v
docker-compose up -d
```
