# Deployment Pipeline - Quick Reference

## Automatic Workflows

### On Push to `main` (Production)
```
Code → Test → Build → Security Scan → Push Images → Deploy Production → Deploy K8s
```

### On Push to `develop` (Staging)
```
Code → Test → Build → Security Scan → Push Images → Deploy Staging
```

## Manual Triggers

### Manual Deployment
- UI: Actions → Manual Deployment
- Select environment (staging/production)
- Enter version tag
- Click "Run workflow"

### Manual Rollback
- UI: Actions → Rollback Deployment
- Select environment
- Enter previous version
- Click "Run workflow"

### Security Scan
- UI: Actions → Docker Security Scan
- Click "Run workflow"
- Runs on schedule (weekly by default)

## Local Commands

### Docker Compose
```bash
# Development
docker compose -f docker-compose.yml up -d

# Production
docker compose -f docker-compose.prod.yml up -d

# Logs
docker compose -f docker-compose.prod.yml logs -f backend

# Status
docker compose -f docker-compose.prod.yml ps
```

### Advanced Deploy Script
```bash
# Rolling deployment (default)
./deploy-advanced.sh rolling production

# Blue-green deployment
./deploy-advanced.sh blue-green production
```

### Original Deploy Script
```bash
./deploy.sh
```

## Kubernetes

### Apply Manifests
```bash
kubectl apply -f k8s-deployment.yaml

# Verify
kubectl get pods -n geodetic-suite
kubectl get svc -n geodetic-suite

# Access
kubectl port-forward -n geodetic-suite svc/backend 8000:8000
kubectl port-forward -n geodetic-suite svc/frontend 8501:8501
```

## Environment Variables

### .env.prod
```
DOCKER_USERNAME=your-username
VERSION=1.0.0
ENVIRONMENT=production
LOG_LEVEL=info
BACKEND_PORT=8000
BACKEND_WORKERS=4
FRONTEND_PORT=8501
APP_NAME=BotswanaGeodeticEngine
```

## Key Features

- **Multi-stage builds** for optimized images
- **BuildKit caching** for faster rebuilds
- **Health checks** on all services
- **Automatic image tagging** (branch, semver, sha)
- **Security scanning** (Trivy + Docker Scout)
- **Zero-downtime deployments**
- **Automatic rollback** capability
- **Kubernetes ready**

## Troubleshooting

### Build Fails
```bash
# Check Dockerfile
docker build -f backend/Dockerfile backend/

# Check context
ls -la backend/
```

### Deployment Fails
```bash
# Check logs
docker compose -f docker-compose.prod.yml logs

# Check .env.prod
cat .env.prod

# Test SSH connection
ssh -i ~/.ssh/id_rsa user@host
```

### Health Check Fails
```bash
# Check service is running
docker ps -a

# Check logs
docker logs container-name

# Test endpoint
curl http://localhost:8000/health
```

## Security

- ✓ Secrets stored in GitHub (not in code)
- ✓ SSH keys encrypted in transit
- ✓ Container images scanned automatically
- ✓ Base images from official Docker Hub
- ✓ Health checks prevent crashed containers
- ✓ Logging configured with size limits

## Resources

- [CI/CD Workflow](../.github/workflows/ci-cd.yml)
- [Manual Deploy](../.github/workflows/manual-deploy.yml)
- [Security Scan](../.github/workflows/docker-security.yml)
- [Rollback](../.github/workflows/rollback.yml)
- [Advanced Deploy Script](../deploy-advanced.sh)
- [Setup Guide](./DEPLOYMENT_PIPELINE_GUIDE.md)
