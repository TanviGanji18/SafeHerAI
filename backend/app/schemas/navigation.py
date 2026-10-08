"""
SafeHer AI - Navigation & Route Planning Schemas
================================================
Pydantic models defining input requests and enriched multi-route responses
for origin/destination route planning, Google Directions integration,
and safety score comparisons.
"""

from typing import List, Optional
from pydantic import BaseModel, Field, field_validator
from .route import CoordinatePoint
from .safety import (
    ComponentScores,
    ComponentContributions,
    RawFeatures,
)


class LocationQuery(BaseModel):
    """Represents a location either by GPS coordinates or descriptive name."""
    latitude: Optional[float] = Field(None, ge=-90.0, le=90.0, description="Latitude in decimal degrees")
    longitude: Optional[float] = Field(None, ge=-180.0, le=180.0, description="Longitude in decimal degrees")
    address: Optional[str] = Field(None, description="Street address or landmark name")

    @field_validator("latitude")
    @classmethod
    def validate_lat(cls, v, info):
        return v


class RoutePlanRequest(BaseModel):
    """
    Request to plan and compare routes between an origin and destination.
    Accepts coordinates or landmark queries.
    """
    origin: LocationQuery = Field(..., description="Starting point coordinates or landmark")
    destination: LocationQuery = Field(..., description="Destination coordinates or landmark")
    travel_mode: str = Field(default="driving", description="Travel mode: 'driving' or 'walking'")
    alternatives: bool = Field(default=True, description="Whether to request alternative routes")


class PlaceSuggestion(BaseModel):
    """Search suggestion / geocoded landmark result."""
    place_id: str = Field(..., description="Unique identifier for place")
    description: str = Field(..., description="Full descriptive name")
    latitude: float = Field(..., description="Latitude")
    longitude: float = Field(..., description="Longitude")
    category: Optional[str] = Field(None, description="Category (e.g. Metro, Landmark, Area)")


class EnrichedRoute(BaseModel):
    """Complete route alternative enriched with safety scoring and navigation metrics."""
    route_id: str = Field(..., description="Route identifier")
    summary: str = Field(default="Via primary corridor", description="Summary/via roadway description")
    safety_score: float = Field(..., ge=0.0, le=100.0, description="Comparative safety score 0-100")
    safety_tier: str = Field(..., description="Qualitative tier classification")
    is_recommended_safer: bool = Field(default=False, description="True if recommended as the safer route")
    is_fastest: bool = Field(default=False, description="True if route has the shortest duration")
    distance_km: float = Field(..., description="Total road distance in kilometers")
    duration_min: float = Field(..., description="Estimated travel duration in minutes")
    polyline_coords: List[CoordinatePoint] = Field(..., description="GPS coordinates sequence along polyline")
    encoded_polyline: Optional[str] = Field(None, description="Google Encoded Polyline string")
    components: ComponentScores = Field(..., description="Normalized component values")
    contributions: ComponentContributions = Field(..., description="Points awarded per factor out of 100")
    raw_features: RawFeatures = Field(..., description="Raw spatial dataset measurements")


class RoutePlanResponse(BaseModel):
    """Multi-route response comparing candidate routes with safety metrics."""
    origin: CoordinatePoint = Field(..., description="Resolved origin coordinates")
    destination: CoordinatePoint = Field(..., description="Resolved destination coordinates")
    origin_name: Optional[str] = Field(None, description="Resolved origin name")
    destination_name: Optional[str] = Field(None, description="Resolved destination name")
    recommended_safer_route_id: str = Field(..., description="ID of route recommended for higher safety")
    fastest_route_id: str = Field(..., description="ID of route with shortest duration")
    is_safer_different_from_fastest: bool = Field(..., description="True if safer route differs from fastest")
    comparative_rationale: List[str] = Field(default_factory=list, description="Rationale for safety recommendation")
    routes: List[EnrichedRoute] = Field(..., description="All candidate routes scored and ranked")
    limitations_and_proxies: List[str] = Field(..., description="Project disclosures & limitations")
