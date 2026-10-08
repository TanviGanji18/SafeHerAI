"""
SafeHer AI - User & Authentication Schemas
==========================================
Pydantic models for user registration, login, Firebase Auth token exchange,
and user profile representation.
"""

from typing import Optional
from pydantic import BaseModel, Field


class UserRegisterRequest(BaseModel):
    """User account registration payload."""
    email: str = Field(..., description="User email address")
    password: str = Field(..., min_length=6, description="Password (minimum 6 characters)")
    full_name: str = Field(..., description="Full Name")
    phone: Optional[str] = Field(None, description="Phone number")


class UserLoginRequest(BaseModel):
    """User login payload."""
    email: str = Field(..., description="User email address")
    password: str = Field(..., description="Password")


class FirebaseAuthTokenRequest(BaseModel):
    """Firebase ID token payload from mobile client."""
    id_token: str = Field(..., description="Firebase Auth ID Token")


class UserProfile(BaseModel):
    """Public user profile data."""
    id: str = Field(..., description="User ID")
    email: str = Field(..., description="User email")
    full_name: str = Field(..., description="Full Name")
    phone: Optional[str] = Field(None, description="Phone number")
    created_at: str = Field(..., description="Account creation date")


class UserProfileUpdateRequest(BaseModel):
    """Payload to update editable user profile fields."""
    user_id: str = Field(..., description="User ID")
    full_name: Optional[str] = Field(None, description="Updated Full Name")
    phone: Optional[str] = Field(None, description="Updated Emergency Phone")


class AuthResponse(BaseModel):
    """Authentication success response."""
    access_token: str = Field(..., description="JWT access token")
    token_type: str = Field(default="bearer", description="Token type")
    user: UserProfile = Field(..., description="User profile information")
