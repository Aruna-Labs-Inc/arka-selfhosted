# Arka Self-Hosted Installation

This repository contains instructions for deploying the self-hosted version of [Arka](https://arka.so).

## Prerequisites

- Docker installed on your system
- AWS CLI configured (for ECR access)
- Access permissions to the Arka ECR repository

## Installation Instructions

### 1. Request ECR Access

Contact the Aruna Labs team to request permission to pull from the Arka ECR repository:

**Email:** devops@arunalabs.io

**Request:** Access to pull from ECR repository:
```
634018648842.dkr.ecr.us-west-2.amazonaws.com/arka:2307f6e
```

Note: The version tag (e.g., `2307f6e`) keeps updating. The team will provide you with the latest version tag.

### 2. Authenticate with ECR

Once you have been granted access, authenticate Docker with the Arka ECR:

```bash
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 634018648842.dkr.ecr.us-west-2.amazonaws.com
```

### 3. Pull the Arka Image

Pull the latest Arka image (replace `<version>` with the version tag provided by the team):

```bash
docker pull 634018648842.dkr.ecr.us-west-2.amazonaws.com/arka:<version>
```

### 4. Run the Container

Run the Arka container:

```bash
docker run -d -p 8080:8080 634018648842.dkr.ecr.us-west-2.amazonaws.com/arka:<version>
```

Adjust the port mapping and add any necessary environment variables as needed for your deployment.

## Support

For issues or questions, contact the Aruna Labs team at devops@arunalabs.io.

## License

See [LICENSE](LICENSE) file for details.
