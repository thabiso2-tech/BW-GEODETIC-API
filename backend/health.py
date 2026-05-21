"""
Health check endpoints for monitoring and orchestration
"""

from fastapi import APIRouter

router = APIRouter()


@router.get("/health")
async def health_check():
    """
    Health check endpoint for container orchestration
    Returns service health status
    """
    return {
        "status": "healthy",
        "service": "backend",
        "version": "1.0.0"
    }


@router.get("/ready")
async def readiness_check():
    """
    Readiness check endpoint
    Indicates if service is ready to receive traffic
    """
    return {
        "ready": True,
        "service": "backend"
    }
