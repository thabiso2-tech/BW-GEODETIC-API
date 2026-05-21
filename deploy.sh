#!/bin/bash
set -e

# Deployment script for production

echo "=== Botswana Geodetic Suite - Production Deployment ==="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker daemon is not running"
    exit 1
fi

# Load environment variables
if [ -f .env.prod ]; then
    export $(cat .env.prod | grep -v '^#' | xargs)
else
    echo "Error: .env.prod file not found"
    echo "Please create .env.prod with DOCKER_USERNAME and VERSION"
    exit 1
fi

echo "Pulling latest images..."
docker compose -f docker-compose.prod.yml pull

echo "Starting services..."
docker compose -f docker-compose.prod.yml up -d

echo "Waiting for backend health check..."
sleep 5

# Verify services are healthy
BACKEND_STATUS=$(docker compose -f docker-compose.prod.yml ps backend --format json 2>/dev/null | grep -q '"State":"running"' && echo "healthy" || echo "unhealthy")
FRONTEND_STATUS=$(docker compose -f docker-compose.prod.yml ps frontend --format json 2>/dev/null | grep -q '"State":"running"' && echo "healthy" || echo "unhealthy")

echo "Backend status: $BACKEND_STATUS"
echo "Frontend status: $FRONTEND_STATUS"

if [ "$BACKEND_STATUS" = "unhealthy" ]; then
    echo "Backend failed to start. Logs:"
    docker compose -f docker-compose.prod.yml logs backend
    exit 1
fi

if [ "$FRONTEND_STATUS" = "unhealthy" ]; then
    echo "Frontend failed to start. Logs:"
    docker compose -f docker-compose.prod.yml logs frontend
    exit 1
fi

echo ""
echo "=== Deployment Complete ==="
echo "Backend running on: http://localhost:8000"
echo "Frontend running on: http://localhost:8501"
echo "API docs available at: http://localhost:8000/docs"
