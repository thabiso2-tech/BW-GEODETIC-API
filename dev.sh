#!/bin/bash
set -e

# Development startup script

echo "=== Botswana Geodetic Suite - Development Setup ==="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker daemon is not running"
    exit 1
fi

echo "Building images..."
docker compose -f docker-compose.dev.yml build

echo "Starting services with hot reload..."
docker compose -f docker-compose.dev.yml up

echo ""
echo "=== Development Environment Started ==="
echo "Backend running on: http://localhost:8000"
echo "Frontend running on: http://localhost:8501"
echo "API docs available at: http://localhost:8000/docs"
echo ""
echo "Press Ctrl+C to stop services"
