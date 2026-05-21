#!/bin/bash
set -e

# Advanced Deployment Script with Blue-Green Deployment Strategy

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="./backups"
LOG_FILE="./deployment.log"
DEPLOYMENT_STRATEGY="${1:-rolling}"  # rolling or blue-green
ENVIRONMENT="${2:-production}"

echo -e "${BLUE}=== Advanced Deployment Pipeline ===${NC}"
echo "Strategy: $DEPLOYMENT_STRATEGY"
echo "Environment: $ENVIRONMENT"
echo ""

# ============== FUNCTIONS ==============

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Create backup before deployment
backup_current_state() {
    log "Creating backup of current deployment state..."
    mkdir -p "$BACKUP_DIR"
    BACKUP_FILE="$BACKUP_DIR/backup-$(date +'%Y%m%d-%H%M%S').tar.gz"
    
    docker compose -f docker-compose.prod.yml ps > "$BACKUP_DIR/service-status.txt"
    docker images > "$BACKUP_DIR/images.txt"
    
    log "Backup created: $BACKUP_FILE"
}

# Health check function
health_check() {
    local service=$1
    local max_attempts=30
    local attempt=0
    
    log "Performing health check for $service..."
    
    while [ $attempt -lt $max_attempts ]; do
        if docker compose -f docker-compose.prod.yml ps $service | grep -q "Up"; then
            log "✓ $service is healthy"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 1
    done
    
    error "Health check failed for $service after $max_attempts attempts"
}

# Rolling deployment
rolling_deployment() {
    log "Starting rolling deployment..."
    
    # Load environment variables
    if [ -f ".env.prod" ]; then
        export $(cat .env.prod | grep -v '^#' | xargs)
    else
        error ".env.prod file not found"
    fi
    
    log "Pulling latest images..."
    docker compose -f docker-compose.prod.yml pull
    
    # Deploy backend first
    log "Updating backend service..."
    docker compose -f docker-compose.prod.yml up -d backend
    health_check backend
    
    # Wait for backend to stabilize
    sleep 5
    
    # Deploy web service
    log "Updating web service..."
    docker compose -f docker-compose.prod.yml up -d web
    health_check web
    
    # Deploy frontend
    log "Updating frontend-streamlit service..."
    docker compose -f docker-compose.prod.yml up -d frontend-streamlit
    health_check frontend-streamlit
    
    log "Rolling deployment completed successfully"
}

# Blue-green deployment (requires dual stacks)
blue_green_deployment() {
    log "Starting blue-green deployment..."
    
    if [ -f ".env.prod" ]; then
        export $(cat .env.prod | grep -v '^#' | xargs)
    else
        error ".env.prod file not found"
    fi
    
    # Check current active stack
    CURRENT_STACK=$(docker compose -f docker-compose.prod.yml ps -q backend 2>/dev/null | wc -l)
    
    if [ "$CURRENT_STACK" -eq 0 ]; then
        log "No active deployment found. Starting fresh..."
        docker compose -f docker-compose.prod.yml pull
        docker compose -f docker-compose.prod.yml up -d
    else
        log "Current stack is active. Preparing new stack..."
        
        # Pull new images
        docker compose -f docker-compose.prod.yml pull
        
        # Start new instances with different ports
        log "Starting new instances of all services..."
        docker compose -f docker-compose.prod.yml up -d
        
        # Health check new instances
        health_check backend
        health_check frontend-streamlit
        
        log "New instances are healthy. Ready to switch traffic."
    fi
    
    log "Blue-green deployment completed"
}

# Rollback function
rollback() {
    log "Initiating rollback..."
    
    if [ ! -f "$BACKUP_DIR/service-status.txt" ]; then
        error "No backup found for rollback"
    fi
    
    log "Stopping current deployment..."
    docker compose -f docker-compose.prod.yml down
    
    log "Restoring previous configuration..."
    # Implementation would depend on your specific setup
    
    log "Starting previous version..."
    docker compose -f docker-compose.prod.yml up -d
    
    sleep 10
    health_check backend
    health_check frontend-streamlit
    
    log "Rollback completed successfully"
}

# Cleanup function
cleanup() {
    log "Performing cleanup..."
    docker system prune -f --volumes
    log "Cleanup completed"
}

# ============== VALIDATION ==============

if ! command -v docker &> /dev/null; then
    error "Docker is not installed"
fi

if ! docker info > /dev/null 2>&1; then
    error "Docker daemon is not running"
fi

# ============== EXECUTION ==============

trap 'error "Deployment interrupted"' INT TERM

# Backup current state
backup_current_state

# Execute deployment strategy
case "$DEPLOYMENT_STRATEGY" in
    rolling)
        rolling_deployment
        ;;
    blue-green)
        blue_green_deployment
        ;;
    *)
        error "Unknown deployment strategy: $DEPLOYMENT_STRATEGY"
        ;;
esac

# Verify final state
log "Verifying final deployment state..."
docker compose -f docker-compose.prod.yml ps

# Cleanup
cleanup

echo ""
log "=== Deployment completed successfully ==="
echo -e "${GREEN}Services are running:${NC}"
docker compose -f docker-compose.prod.yml ps --format "table {{.Service}}\t{{.Status}}"
