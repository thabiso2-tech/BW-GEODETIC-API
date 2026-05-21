"""
Botswana Geodetic Suite API
FastAPI application entry point
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# Import routers
try:
    from api.v1 import adjust
except ImportError:
    adjust = None

try:
    from api.auth_routes import router as auth_router
except ImportError:
    auth_router = None

# Create FastAPI app
app = FastAPI(
    title="Botswana Geodetic Engine API",
    description="API for geodetic calculations and coordinate transformations",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def read_root():
    """Root endpoint"""
    return {
        "message": "Botswana Geodetic Suite API",
        "version": "1.0.0",
        "docs": "/docs"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint for container orchestration"""
    return {
        "status": "healthy",
        "service": "backend",
        "version": "1.0.0"
    }


@app.get("/ready")
async def readiness_check():
    """Readiness check endpoint"""
    return {
        "ready": True,
        "service": "backend"
    }


# Include API routers
if auth_router:
    try:
        app.include_router(auth_router, prefix="/api/v1", tags=["authentication"])
    except Exception as e:
        print(f"Warning: Could not include auth router: {e}")

if adjust:
    try:
        app.include_router(adjust.router, prefix="/api/v1", tags=["adjustment"])
    except Exception:
        pass


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
