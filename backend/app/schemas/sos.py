"""
SafeHer AI - Emergency SOS & Incident Alert Schemas
===================================================
Pydantic models for triggering instant SOS distress broadcasts,
managing emergency trusted contacts, and querying emergency assistance.
"""

from typing import List, Dict, Optional
from pydantic import BaseModel, Field
from .route import CoordinatePoint
from .amenity import AmenityItem


class TrustedContact(BaseModel):
    """User emergency contact."""
    id: Optional[str] = Field(None, description="Contact ID")
    name: str = Field(..., description="Full Name")
    phone: str = Field(..., description="Phone number with country code")
    relationship: str = Field(default="Family", description="Relationship (e.g. Parent, Sibling, Friend)")
    is_primary: bool = Field(default=False, description="Primary contact flag")


class SOSTriggerRequest(BaseModel):
    """Distress signal broadcast request."""
    user_id: Optional[str] = Field(default="anonymous_user", description="User ID or device ID")
    latitude: float = Field(..., ge=-90.0, le=90.0, description="Current GPS latitude")
    longitude: float = Field(..., ge=-180.0, le=180.0, description="Current GPS longitude")
    battery_level: Optional[int] = Field(None, ge=0, le=100, description="Current device battery percentage")
    message: Optional[str] = Field(default="EMERGENCY: I need immediate assistance! Here is my live location.", description="Custom distress note")
    current_route_id: Optional[str] = Field(None, description="ID of current navigation route if navigating")


class SOSTriggerResponse(BaseModel):
    """Distress signal dispatch confirmation and response."""
    alert_id: str = Field(..., description="Unique emergency incident tracking ID")
    status: str = Field(..., description="Alert processing status")
    timestamp: str = Field(..., description="ISO 8601 timestamp of alert registration")
    user_location: CoordinatePoint = Field(..., description="User GPS coordinates")
    maps_location_url: str = Field(..., description="Sharable Google Maps live location URL")
    nearest_police_station: AmenityItem = Field(..., description="Nearest operational police station to call immediately")
    dispatched_contacts_count: int = Field(..., description="Number of trusted contacts alerted")
    contacts_notified: List[str] = Field(default_factory=list, description="Names of contacts notified")
    emergency_helplines: Dict[str, Dict[str, str]] = Field(..., description="Statutory Emergency Helplines (112, 100, SHE Teams)")
    safety_guidance: List[str] = Field(..., description="Immediate tactical safety instructions")
