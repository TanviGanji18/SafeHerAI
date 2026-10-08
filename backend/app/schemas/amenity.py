"""
SafeHer AI - Emergency Amenities & Safe Spots Schemas
=====================================================
Pydantic schemas for retrieving nearby emergency infrastructure:
police stations, trauma hospitals, metro stations, and accident black spots.
"""

from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field
from .route import CoordinatePoint


class AmenityItem(BaseModel):
    """Represents a single nearby civic or safety amenity."""
    id: str = Field(..., description="Unique amenity identifier")
    name: str = Field(..., description="Official facility or junction name")
    category: str = Field(..., description="Amenity category: Police, Hospital, Metro, Bus, Blackspot")
    distance_km: float = Field(..., description="Great-circle distance from user in km")
    latitude: float = Field(..., description="Latitude")
    longitude: float = Field(..., description="Longitude")
    phone: Optional[str] = Field(None, description="Contact helpline / phone number")
    zone_or_circle: Optional[str] = Field(None, description="Jurisdictional zone or GHMC circle")
    extra_details: Optional[str] = Field(None, description="Additional context or hazard warning")


class NearbySafeSpotsResponse(BaseModel):
    """Response containing closest safety infrastructure around a coordinate."""
    user_location: CoordinatePoint = Field(..., description="User query coordinate")
    radius_km: float = Field(..., description="Search radius in kilometers")
    police_stations: List[AmenityItem] = Field(..., description="Nearest operational police stations")
    hospitals: List[AmenityItem] = Field(..., description="Nearest registered healthcare & trauma facilities")
    transit_stations: List[AmenityItem] = Field(..., description="Nearest metro stations and bus hubs")
    accident_blackspots: List[AmenityItem] = Field(..., description="Identified traffic collision junctions within proximity")
    emergency_helplines: Dict[str, Dict[str, str]] = Field(..., description="Statutory Telangana & National Helplines")
