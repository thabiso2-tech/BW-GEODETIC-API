"""
Authentication routes for Botswana Geodetic Suite
"""

from datetime import timedelta
from fastapi import APIRouter, HTTPException, status
from app.auth import (
    authenticate_user,
    create_access_token,
    register_user,
    get_current_user,
    UserLogin,
    UserRegister,
    Token,
    User,
    ACCESS_TOKEN_EXPIRE_MINUTES,
)

router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/register", response_model=dict)
async def register(user_data: UserRegister):
    """Register a new user"""
    try:
        user = register_user(
            username=user_data.username,
            email=user_data.email,
            full_name=user_data.full_name,
            password=user_data.password
        )
        return {
            "message": "User registered successfully",
            "user": user
        }
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.post("/login", response_model=Token)
async def login(user_credentials: UserLogin):
    """Login user and return access token"""
    user = authenticate_user(user_credentials.username, user_credentials.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "username": user.username,
            "email": user.email,
            "full_name": user.full_name,
            "role": user.role
        }
    }

@router.get("/me", response_model=User)
async def get_me(current_user: User = None):
    """Get current user info (requires authentication)"""
    # In a real app, this would use the get_current_user dependency
    # For now, we're returning a mock
    if not current_user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated"
        )
    return current_user

@router.post("/logout")
async def logout():
    """Logout user (client-side token deletion)"""
    return {
        "message": "Logged out successfully"
    }
