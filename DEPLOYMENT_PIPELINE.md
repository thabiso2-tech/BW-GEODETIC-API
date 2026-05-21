# Deployment Pipeline

This repository includes a complete CI/CD deployment pipeline for the Botswana Geodetic Suite application.

## Pipeline Components

### 1. GitHub Actions Workflow (`.github/workflows/deploy.yml`)

The pipeline runs automatically on every push to `main` or `develop` branches and includes:

#### Testing Stage
- Installs dependencies for both backend and frontend
- Runs linting and basic tests
- Validates Python syntax

#### Build & Push Stage
- Builds Docker images using Docker Buildx with caching
- Pushes images to Docker Hub with semantic versioning
- Uses GitHub Actions cache to speed up builds

#### Deployment Stages
- **Staging**: Triggered on `develop` branch pushes
- **Production**: Triggered on `main` branch pushes

## Setup Instructions

### 1. Docker Hub Setup
```bash
# Create Docker Hub account at https://hub.docker.com
# Create two repositories:
# - your-username/backend
# - your-username/frontend
```

### 2. GitHub Secrets
Add the following secrets to your GitHub repository:
- `DOCKER_USERNAME`: Your Docker Hub username
- `DOCKER_PASSWORD`: Your Docker Hub access token (not password)

Go to: Settings → Secrets and variables → Actions → New repository secret

### 3. Clone and Configure
```bash
git clone <your-repo>
cd BW_Geodetic_Suite

# Copy environment templates
cp .env.prod.example .env.prod
cp .env.dev.example .env.dev

# Edit .env.prod with your Docker Hub username and desired version
nano .env.prod
```

## Local Development

### Quick Start with Hot Reload
```bash
./dev.sh
```

This starts both services with automatic code reloading:
- Backend: http://localhost:8000 (API docs at /docs)
- Frontend: http://localhost:8501

### Manual Development Setup
```bash
docker compose -f docker-compose.dev.yml up
```

## Production Deployment

### Prerequisites
- Docker and Docker Compose installed
- `.env.prod` file configured with Docker Hub credentials
- Images pushed to Docker Hub

### Deploy to Production
```bash
./deploy.sh
```

This will:
1. Pull latest images from Docker Hub
2. Start both services
3. Run health checks
4. Display service URLs

### Manual Production Setup
```bash
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

## Kubernetes Deployment

For multi-node or scalable deployments:

### Prerequisites
- kubectl configured to your cluster
- Images available on Docker Hub
- Namespace permissions

### Deploy to Kubernetes
```bash
# Update the image references in k8s-deployment.yaml
sed -i 's/YOUR_DOCKER_USERNAME/your-actual-username/g' k8s-deployment.yaml

# Deploy
kubectl apply -f k8s-deployment.yaml

# Check deployment status
kubectl -n geodetic-suite get pods
kubectl -n geodetic-suite get services

# View logs
kubectl -n geodetic-suite logs -f deployment/backend
kubectl -n geodetic-suite logs -f deployment/frontend

# Forward ports locally (if LoadBalancer not available)
kubectl -n geodetic-suite port-forward svc/frontend 8501:8501
kubectl -n geodetic-suite port-forward svc/backend 8000:8000
```

## Monitoring & Maintenance

### View Logs
```bash
# Docker Compose
docker compose -f docker-compose.prod.yml logs -f backend
docker compose -f docker-compose.prod.yml logs -f frontend

# Kubernetes
kubectl -n geodetic-suite logs -f deployment/backend
kubectl -n geodetic-suite logs -f deployment/frontend
```

### Health Checks
The pipeline includes health checks:
- Backend: `GET /health` endpoint
- Frontend: `GET /_stcore/health` endpoint

### Stop Services
```bash
# Docker Compose
docker compose -f docker-compose.prod.yml down

# Kubernetes
kubectl delete -f k8s-deployment.yaml
```

## CI/CD Pipeline Flow

```
Push to Repository
    ↓
Test Stage (Python linting & syntax validation)
    ↓
Build & Push Stage (Build Docker images, push to registry)
    ↓
├─ If main branch → Production Deployment
└─ If develop branch → Staging Deployment
```

## Environment Variables

### Production (.env.prod)
- `DOCKER_USERNAME`: Docker Hub username
- `VERSION`: Image version tag (e.g., 1.0.0)
- `LOG_LEVEL`: Logging level (info, debug)

### Development (.env.dev)
- `ENVIRONMENT`: Set to development
- `LOG_LEVEL`: Set to debug for verbose logging

## Troubleshooting

### Images Not Pushing
- Verify `DOCKER_PASSWORD` is an access token, not your actual password
- Check Docker Hub repository permissions
- Ensure `DOCKER_USERNAME` matches exactly

### Services Not Starting
```bash
# View detailed logs
docker compose -f docker-compose.prod.yml logs

# Check health status
docker compose -f docker-compose.prod.yml ps
```

### Port Already in Use
```bash
# Find process using port 8000 or 8501
lsof -i :8000
lsof -i :8501

# Kill the process
kill -9 <PID>
```

### Build Failures
```bash
# Clean Docker cache and rebuild
docker compose -f docker-compose.prod.yml down
docker system prune -a
./deploy.sh
```

## Adding Tests

To add automated tests to the pipeline, create test files and update `.github/workflows/deploy.yml`:

```yaml
- name: Run tests
  run: |
    cd backend
    pytest tests/ -v
```

## Rolling Back

To roll back to a previous version:

```bash
# Update .env.prod with previous VERSION
VERSION=1.0.0  # Previous version

# Redeploy
./deploy.sh
```

## Advanced Configuration

### Custom Registries
To use a private Docker registry instead of Docker Hub, update:
1. `.github/workflows/deploy.yml` - change `REGISTRY` variable
2. `docker-compose.prod.yml` - update image names
3. Docker login credentials in GitHub secrets

### Horizontal Scaling
For Kubernetes, increase replicas in `k8s-deployment.yaml`:

```yaml
spec:
  replicas: 5  # Increase from 2
```

## Support

For issues or questions:
1. Check logs: `docker compose -f docker-compose.prod.yml logs`
2. Verify Docker images exist: `docker images`
3. Test connectivity: `curl http://localhost:8000/docs`
