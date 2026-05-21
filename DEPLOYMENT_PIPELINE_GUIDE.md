# Deployment Pipeline Setup Guide

## Overview

This deployment pipeline includes:
- **Automated CI/CD** via GitHub Actions
- **Multi-environment deployments** (staging, production)
- **Kubernetes support** with kubectl deployment
- **Security scanning** with Trivy and Docker Scout
- **Blue-green and rolling deployments** for zero downtime
- **Rollback capability** for quick recovery

## Prerequisites

- Docker Desktop or Docker Engine
- GitHub repository with Actions enabled
- Docker Hub account for image registry
- SSH access to staging/production servers
- (Optional) Kubernetes cluster with kubeconfig

## Step 1: Configure GitHub Secrets

Navigate to your repository → Settings → Secrets and variables → Actions

### Required Secrets:

```
DOCKER_USERNAME         # Your Docker Hub username
DOCKER_PASSWORD         # Your Docker Hub PAT (Personal Access Token)
STAGING_HOST            # IP/hostname of staging server
STAGING_USER            # SSH user for staging server
STAGING_SSH_KEY         # Private SSH key (base64 encoded for safety)
PROD_HOST               # IP/hostname of production server
PROD_USER               # SSH user for production server
PROD_SSH_KEY            # Private SSH key (base64 encoded)
```

### Optional Secrets (for Kubernetes):
```
KUBECONFIG              # Base64 encoded kubeconfig file
```

### To encode SSH key for GitHub Secrets:
```bash
# On Linux/Mac
cat ~/.ssh/id_rsa | base64 -w 0

# On Windows PowerShell
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$env:USERPROFILE\.ssh\id_rsa"))
```

## Step 2: Server Setup

### On Staging/Production Server:

```bash
# Create deployment directory
sudo mkdir -p /opt/geodetic-suite
sudo chown $USER:$USER /opt/geodetic-suite

# Clone repository
cd /opt/geodetic-suite
git clone https://github.com/YOUR_ORG/YOUR_REPO.git .

# Create .env.prod file
cp .env.prod.example .env.prod
# Edit .env.prod with your configuration

# Install Docker if not present
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Create Docker network
docker network create geodetic-network

# Test deployment
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

## Step 3: Deployment Workflows

### Automatic Deployment (Main Branch)

When you push to `main`:
1. Code is tested and built
2. Security scanning runs
3. Docker images are pushed to registry
4. Production deployment is triggered
5. Kubernetes manifests are applied (if enabled)

### Automatic Deployment (Develop Branch)

When you push to `develop`:
1. Code is tested and built
2. Docker images are pushed to registry
3. Staging deployment is triggered

### Manual Deployment

Trigger via GitHub Actions UI:
- Go to Actions → Manual Deployment
- Choose environment (staging/production)
- Enter version/tag
- Click Run

### Manual Rollback

Trigger via GitHub Actions UI:
- Go to Actions → Rollback Deployment
- Choose environment
- Enter previous version
- Click Run

## Step 4: Local Deployment

### Using Docker Compose

```bash
# Development
docker compose -f docker-compose.yml up -d

# Production
export DOCKER_USERNAME=your-username
export VERSION=1.0.0
docker compose -f docker-compose.prod.yml up -d
```

### Using Advanced Deploy Script

```bash
# Rolling deployment
./deploy-advanced.sh rolling production

# Blue-green deployment
./deploy-advanced.sh blue-green production
```

### Using Original Deploy Script

```bash
./deploy.sh
```

## Step 5: Kubernetes Deployment

### Prerequisites:
- Kubernetes cluster running
- kubectl configured with valid kubeconfig
- Images pushed to accessible registry

### Manual Kubernetes Deployment:

```bash
# Update image references
sed -i 's|YOUR_DOCKER_USERNAME|your-username|g' k8s-deployment.yaml
sed -i 's|:latest|:v1.0.0|g' k8s-deployment.yaml

# Apply deployment
kubectl apply -f k8s-deployment.yaml

# Check deployment status
kubectl get deployments -n geodetic-suite
kubectl get pods -n geodetic-suite
kubectl get svc -n geodetic-suite

# Port forward to access services
kubectl port-forward -n geodetic-suite svc/backend 8000:8000
kubectl port-forward -n geodetic-suite svc/frontend 8501:8501
```

### Automated Kubernetes Deployment:
- Triggered automatically on `main` branch push
- Updates image tags with commit SHA
- Applies k8s-deployment.yaml
- Monitors rollout status

## Pipeline Stages Explained

### 1. Build & Test
- Builds Docker images for each service
- Runs unit/integration tests
- Uses Docker layer caching for speed

### 2. Security Scan
- Trivy: Filesystem and image scanning
- Docker Scout: CVE scanning
- Results uploaded to GitHub Security tab

### 3. Push Images
- Authenticated push to Docker Registry
- Multi-tag strategy (branch, semver, sha)
- BuildKit cache optimization

### 4. Deploy Staging
- Triggered on `develop` branch
- SSH into staging server
- Pulls latest images
- Runs `docker compose up -d`

### 5. Deploy Production
- Triggered on `main` branch
- Requires approval (environment protection)
- Full deployment with health checks
- Notifications sent

### 6. Deploy Kubernetes
- Triggered on `main` branch
- Updates manifests with current image tags
- Applies Kubernetes manifests
- Monitors rollout completion

## Monitoring & Verification

### Check Deployment Status:

```bash
# View running containers
docker compose -f docker-compose.prod.yml ps

# View service logs
docker compose -f docker-compose.prod.yml logs -f backend
docker compose -f docker-compose.prod.yml logs -f frontend-streamlit

# Check health
curl http://localhost:8000/health
curl http://localhost:8501/_stcore/health
```

### Kubernetes Status:

```bash
# Check deployment
kubectl get deployments -n geodetic-suite -w

# View pod logs
kubectl logs -f deployment/backend -n geodetic-suite

# Describe pod (for troubleshooting)
kubectl describe pod POD_NAME -n geodetic-suite
```

## Troubleshooting

### Images Not Building
- Check Dockerfile syntax: `docker build -f backend/Dockerfile backend/`
- Verify context directory exists
- Check Docker Hub quota and rate limits

### Deployment Fails
- View logs: `docker compose -f docker-compose.prod.yml logs`
- Check .env.prod exists with correct values
- Verify SSH key and permissions

### Health Checks Failing
- Check service is actually running: `docker ps`
- Verify health check endpoint is correct
- Review application logs for startup errors

### Kubernetes Deployment Issues
- Check image pull: `kubectl describe pod POD_NAME -n geodetic-suite`
- Verify kubeconfig is valid: `kubectl cluster-info`
- Check resource limits/requests

## Security Best Practices

1. **Never commit secrets** to Git
2. **Use GitHub Secrets** for sensitive data
3. **Rotate Docker Hub tokens** regularly
4. **Run security scans** on every build
5. **Review container images** before production
6. **Use specific image tags** (not latest)
7. **Enable branch protection** on main
8. **Require approvals** for production deployments

## Cost Optimization

1. **Use BuildKit cache** to avoid rebuilding
2. **Prune Docker images** regularly: `docker system prune`
3. **Compress logs**: Already configured with max-size and max-file
4. **Use Docker Build Cloud** for larger teams
5. **Implement image retention policies**

## References

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Build Cloud](https://docs.docker.com/build-cloud/)
- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Docker Scout](https://docs.docker.com/scout/)
- [Trivy Scanner](https://aquasecurity.github.io/trivy/)
