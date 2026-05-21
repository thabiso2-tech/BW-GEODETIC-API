# Quick Reference Guide

## One-Time Setup

```bash
# 1. Create Docker Hub account and two repositories
# https://hub.docker.com

# 2. Add GitHub secrets (Settings → Secrets and variables → Actions)
# - DOCKER_USERNAME
# - DOCKER_PASSWORD (access token)

# 3. Configure environment files
cp .env.prod.example .env.prod
nano .env.prod  # Add your Docker username and version
```

## Development Workflow

```bash
# Start development environment with hot reload
./dev.sh

# Or manually
docker compose -f docker-compose.dev.yml up

# Backend: http://localhost:8000/docs
# Frontend: http://localhost:8501
```

## Local Testing

```bash
# Build images locally
docker compose -f docker-compose.prod.yml build

# Run production setup locally
docker compose -f docker-compose.prod.yml up

# View logs
docker compose -f docker-compose.prod.yml logs -f
```

## Push to Production

```bash
# 1. Push to main branch (triggers CI/CD)
git add .
git commit -m "Release v1.0.0"
git push origin main

# 2. GitHub Actions automatically:
#    - Tests code
#    - Builds Docker images
#    - Pushes to Docker Hub
#    - Deploys to production

# 3. Monitor workflow at: https://github.com/YOUR_REPO/actions
```

## Production Operations

```bash
# Deploy using script
./deploy.sh

# Or manually
export DOCKER_USERNAME=your-username
export VERSION=1.0.0
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d

# Check status
docker compose -f docker-compose.prod.yml ps

# View logs
docker compose -f docker-compose.prod.yml logs -f backend
docker compose -f docker-compose.prod.yml logs -f frontend

# Stop services
docker compose -f docker-compose.prod.yml down
```

## Kubernetes (Advanced)

```bash
# Deploy
kubectl apply -f k8s-deployment.yaml

# Check pods
kubectl -n geodetic-suite get pods
kubectl -n geodetic-suite get services

# View logs
kubectl -n geodetic-suite logs -f deployment/backend

# Forward ports
kubectl -n geodetic-suite port-forward svc/backend 8000:8000
kubectl -n geodetic-suite port-forward svc/frontend 8501:8501

# Delete deployment
kubectl delete -f k8s-deployment.yaml
```

## Pipeline Stages

| Stage | Trigger | Action |
|-------|---------|--------|
| Test | Any push | Lint, syntax check |
| Build | main/develop | Build and push images |
| Staging | develop branch | Deploy to staging |
| Production | main branch | Deploy to production |

## Useful Commands

```bash
# View all images
docker images

# View running containers
docker ps

# View all containers (including stopped)
docker ps -a

# Clean up unused resources
docker system prune

# Build specific service
docker compose -f docker-compose.prod.yml build backend

# Execute command in running container
docker compose -f docker-compose.prod.yml exec backend bash

# Stop specific service
docker compose -f docker-compose.prod.yml stop backend

# Scale service
docker compose -f docker-compose.prod.yml up -d --scale backend=3
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Port already in use | `lsof -i :8000` then `kill -9 <PID>` |
| Images not pushing | Verify DOCKER_PASSWORD is token, not password |
| Services won't start | `docker compose -f docker-compose.prod.yml logs` |
| Build failures | `docker system prune -a` then rebuild |
| Health check failing | `docker compose -f docker-compose.prod.yml logs backend` |

## File Structure

```
.
├── .github/workflows/
│   └── deploy.yml                 # CI/CD pipeline
├── backend/
│   ├── Dockerfile.dockerfile
│   ├── .dockerignore
│   ├── requirements.txt
│   └── health.py                  # Health check endpoints
├── frontend/
│   ├── Dockerfile.dockerfile
│   ├── .dockerignore
│   └── requirements.txt
├── docker-compose.yml             # Original compose (dev)
├── docker-compose.dev.yml         # Development with hot reload
├── docker-compose.prod.yml        # Production compose
├── k8s-deployment.yaml            # Kubernetes manifests
├── dev.sh                         # Development startup script
├── deploy.sh                      # Production deployment script
├── .env.prod.example              # Production env template
├── .env.dev.example               # Development env template
├── .gitignore
└── DEPLOYMENT_PIPELINE.md         # Full documentation
```

## Next Steps

1. ✅ Copy environment templates and configure credentials
2. ✅ Add GitHub repository secrets
3. ✅ Test locally with `./dev.sh`
4. ✅ Commit and push to `develop` branch
5. ✅ Monitor GitHub Actions workflow
6. ✅ Merge to `main` for production release
7. ✅ Monitor production deployment

For detailed information, see `DEPLOYMENT_PIPELINE.md`
