# Deployment Pipeline Architecture

## End-to-End Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         Developer                               │
│                      Pushes to GitHub                           │
└────────────────────────────┬────────────────────────────────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
        ┌───────▼────────┐        ┌──────▼──────────┐
        │ Push to Main   │        │ Push to Develop│
        │   (Production) │        │   (Staging)    │
        └───────┬────────┘        └──────┬──────────┘
                │                        │
        ┌───────▼────────────────────────▼────────┐
        │  GitHub Actions: CI/CD Workflow Starts  │
        └───────┬──────────────────────────────────┘
                │
        ┌───────▼──────────────────┐
        │  1. Build & Test         │
        │     - Run tests          │
        │     - Build images       │
        └───────┬──────────────────┘
                │
        ┌───────▼──────────────────┐
        │  2. Security Scan        │
        │     - Trivy scan         │
        │     - Docker Scout       │
        └───────┬──────────────────┘
                │
        ┌───────▼──────────────────┐
        │  3. Push to Registry     │
        │     - Docker Hub push    │
        │     - Tag with version   │
        └───────┬──────────────────┘
                │
        ┌───────┴──────────────────────────────┐
        │                                      │
    ┌───▼────────────┐            ┌──────────▼────────┐
    │ Deploy Staging │            │ Deploy Production│
    │ (Develop)      │            │ (Main - Approved) │
    └───┬────────────┘            └──────────┬────────┘
        │                                    │
    ┌───▼──────────────────┐    ┌──────────▼──────────────┐
    │ SSH to Staging Server│    │ SSH to Prod Server &   │
    │ Pull Images          │    │ Deploy K8s Manifests   │
    │ Run docker compose   │    │                        │
    └───┬──────────────────┘    └──────────┬──────────────┘
        │                                   │
    ┌───▼──────────────────┐    ┌──────────▼──────────────┐
    │ Health Checks        │    │ Health Checks          │
    │ Service Verification │    │ Service Verification   │
    └───┬──────────────────┘    └──────────┬──────────────┘
        │                                   │
    ┌───▼──────────────────┐    ┌──────────▼──────────────┐
    │ ✓ Staging Ready      │    │ ✓ Production Ready     │
    │ (Development)        │    │ (Live Traffic)         │
    └──────────────────────┘    └────────────────────────┘
```

## Multi-Environment Deployment Strategy

### Environment: Staging
- **Branch**: develop
- **Trigger**: On push to develop
- **Duration**: ~5-10 minutes
- **Approval**: None (automatic)
- **Rollback**: Manual via GitHub Actions

### Environment: Production
- **Branch**: main
- **Trigger**: On push to main
- **Duration**: ~10-15 minutes
- **Approval**: Environment-based (required)
- **Rollback**: Manual via GitHub Actions or script

## Deployment Methods

### 1. Automated (GitHub Actions - Recommended)

**Pros:**
- Zero manual intervention
- Consistent deployments
- Audit trail in GitHub
- Integrated security scanning
- Rollback history

**Workflow:**
```
Push to main → CI/CD runs → Deploys production
```

### 2. Manual (GitHub Actions UI)

**Use Case:** Override automatic process, deploy specific version

**Steps:**
1. Actions → Manual Deployment
2. Select environment
3. Enter version
4. Click Run

### 3. Local Script (Server-based)

**Use Case:** Emergency deployment, testing

**Commands:**
```bash
# Rolling deployment
./deploy-advanced.sh rolling production

# Blue-green deployment
./deploy-advanced.sh blue-green production

# Simple deployment
./deploy.sh
```

### 4. Kubernetes (Cluster-based)

**Use Case:** High availability, auto-scaling, multi-region

**Commands:**
```bash
kubectl apply -f k8s-deployment.yaml
```

## Service Architecture

```
┌──────────────────────────────────────────────┐
│          Docker Compose Production           │
│         (docker-compose.prod.yml)            │
├──────────────────────────────────────────────┤
│                                              │
│  ┌──────────────┐  ┌──────────────┐          │
│  │   Backend    │  │     Web      │          │
│  │   (FastAPI)  │  │  (Vite/React)│          │
│  │  :8000       │  │  :5173       │          │
│  └──────────────┘  └──────────────┘          │
│         │                  │                  │
│  ┌──────────────────────────────────┐        │
│  │   Frontend (Streamlit)           │        │
│  │   :8501                          │        │
│  └──────────────────────────────────┘        │
│                                              │
└──────────────────────────────────────────────┘
         └─ All on geodetic-network
```

## Deployment Stages Detail

### Stage 1: Build & Test (5 min)
- Checkout code
- Build images with layer caching
- Run unit/integration tests
- Parallel builds (backend, frontend, web)

**Failures**: Block deployment, notify developer

### Stage 2: Security Scan (3 min)
- Trivy: Scan for CVEs
- Docker Scout: Base image analysis
- SARIF upload to GitHub Security
- Warning-only (doesn't block)

### Stage 3: Push Images (2 min)
- Auth to Docker Hub
- Multi-tag strategy:
  - Branch tag (main, develop)
  - Semver tags (v1.0.0)
  - Commit SHA
- Cache layers on registry

**Failures**: Block production deployment

### Stage 4: Deploy Staging (3 min)
- SSH to staging server
- `git pull origin develop`
- `docker compose pull`
- `docker compose up -d`
- Health checks (30 retries × 1s)

### Stage 5: Deploy Production (5 min)
- Requires environment approval
- SSH to production server
- `git pull origin main`
- `docker compose pull`
- `docker compose up -d`
- Health checks (30 retries × 1s)
- Kubernetes manifests applied

## Rollback Strategy

### Automatic Rollback (Not Implemented)
- Would require version pinning
- Consider using Kubernetes for auto-rollback

### Manual Rollback (Available)

**Via GitHub Actions:**
1. Actions → Rollback Deployment
2. Choose environment
3. Enter previous version
4. Click Run

**Via Script:**
```bash
# Recreate with previous version
export VERSION=1.0.0
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

**Via Kubernetes:**
```bash
kubectl rollout undo deployment/backend -n geodetic-suite
kubectl rollout undo deployment/frontend -n geodetic-suite
```

## Health Check Strategy

### Docker Compose Health Checks

**Backend:**
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

**Frontend:**
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8501/_stcore/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### Kubernetes Health Checks

**Liveness Probe:** Restarts unhealthy containers
**Readiness Probe:** Removes from load balancer if unhealthy

## Monitoring & Debugging

### View Deployment Logs
```bash
# Docker Compose
docker compose -f docker-compose.prod.yml logs -f backend

# Kubernetes
kubectl logs -f deployment/backend -n geodetic-suite

# GitHub Actions
- Check Actions tab in GitHub
- View workflow run details
```

### Check Service Status
```bash
# Docker Compose
docker compose -f docker-compose.prod.yml ps

# Kubernetes
kubectl get pods -n geodetic-suite
kubectl describe pod POD_NAME -n geodetic-suite
```

## Performance Metrics

| Metric | Time | Notes |
|--------|------|-------|
| Build | ~5 min | Parallel builds for 3 services |
| Test | ~2 min | Included in build stage |
| Security Scan | ~3 min | Warning-only, non-blocking |
| Image Push | ~2 min | Upload to Docker Hub |
| Deploy Staging | ~3 min | Via SSH |
| Deploy Production | ~5 min | Includes health checks |
| **Total** | **~15-20 min** | End-to-end automation |

## Cost Optimization

- **BuildKit caching** reduces build time by ~60%
- **Layer caching** prevents rebuilding unchanged code
- **Image compression** reduces storage costs
- **Log rotation** prevents disk overflow
- **Automatic cleanup** removes dangling images

## Security Measures

✓ Secrets encrypted in GitHub (not in code)
✓ SSH keys for server authentication
✓ Container image scanning on every build
✓ Health checks prevent crashed containers
✓ Log rotation and compression
✓ Network isolation (geodetic-network)
✓ Healthcheck timeouts prevent hanging
✓ Environment-based production approval

## Next Steps

1. **Setup GitHub Secrets**: Run `./setup-github-secrets.sh`
2. **Configure Servers**: Run `./server-setup.sh` on staging/prod
3. **First Deployment**: Push to develop/main and watch GitHub Actions
4. **Monitor**: Check Actions tab for deployment status
5. **Verify**: Test endpoints on staging/production
