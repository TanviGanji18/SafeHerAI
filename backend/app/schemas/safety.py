"""
SafeHer AI - Safety Response Schemas
====================================
Pydantic schemas defining the structured response for the route safety
scoring endpoint and health check service.
"""

from typing import List, Dict, Optional
from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    """Health check response."""

    status: str = Field(..., examples=["ok"])
    service: str = Field(..., examples=["SafeHer AI backend"])


class ComponentScores(BaseModel):
    """
    Normalized component values in the range [0.0, 1.0].
    Enforces the logical order:
    S_police -> S_medical -> S_transit -> S_arterial -> P_crime -> P_blackspot -> P_exposure
    """

    S_police: float = Field(
        ...,
        ge=0.0,
        le=1.0,
        description="Police accessibility score (proximity and density of operational stations)",
    )
    S_medical: float = Field(
        ...,
        ge=0.0,
        le=1.0,
        description="Emergency medical access score (proximity to nearest registered hospital)",
    )
    S_transit: float = Field(
        ...,
        ge=0.0,
        le=1.0,
        description="Public transit infrastructure presence (Contextual Proxy: metro and bus stops per km)",
    )
    S_arterial: float = Field(
        ...,
        ge=0.0,
        le=1.0,
        description="Arterial road hierarchy alignment (Contextual Proxy: fraction of travel on primary/trunk roads)",
    )
    P_crime: float = Field(
        ...,
        ge=0.0,
        le=1.0,
        description="Jurisdictional crime volume penalty (distance-weighted relative reported FIR volume in traversed zones)",
    )
    P_blackspot: float = Field(
        ...,
        ge=0.0,
        le=1.0,
        description="Traffic accident black spot road hazard penalty (proximity to officially identified crash junctions)",
    )
    P_exposure: float = Field(
        ...,
        ge=0.0,
        le=1.0,
        description="Route detour and nighttime exposure penalty (calculated from detour ratio D_route / D_straight)",
    )


class ComponentContributions(BaseModel):
    """
    Points contributed by each factor out of 100 maximum total points.
    Positive indicators reward points; penalty indicators reward points for compliance/avoidance.
    """

    police_pts: float = Field(..., description="Points awarded for police accessibility (max 25.0)")
    medical_pts: float = Field(..., description="Points awarded for emergency medical access (max 15.0)")
    transit_pts: float = Field(..., description="Points awarded for transit infrastructure presence (max 15.0)")
    arterial_pts: float = Field(..., description="Points awarded for arterial road alignment (max 15.0)")
    crime_compliance_pts: float = Field(
        ..., description="Points awarded for avoiding higher crime volume zones (max 15.0)"
    )
    blackspot_compliance_pts: float = Field(
        ..., description="Points awarded for avoiding accident black spots (max 10.0)"
    )
    exposure_compliance_pts: float = Field(
        ..., description="Points awarded for direct, non-detour route efficiency (max 5.0)"
    )


class RawFeatures(BaseModel):
    """Raw physical measurements extracted from genuine spatial datasets."""

    avg_police_dist_km: float = Field(..., description="Mean distance to nearest police station along route (km)")
    police_within_1km_count: int = Field(..., description="Count of operational police stations within 1 km")
    min_hospital_dist_km: float = Field(..., description="Distance to closest registered emergency hospital (km)")
    transit_count_within_500m: int = Field(..., description="Count of metro stations and bus stops within 500m")
    arterial_length_km: float = Field(..., description="Route length along primary arterial corridors (km)")
    traversed_zones: List[str] = Field(..., description="List of official Hyderabad Police zones traversed")
    blackspot_count: int = Field(..., description="Count of identified accident black spots within 250m")


class RouteScoreResponse(BaseModel):
    """
    Complete safety scoring evaluation response returned by POST /api/v1/safety/score.
    """

    route_id: str = Field(..., description="Identifier of the evaluated route")
    safety_score: float = Field(
        ...,
        ge=0.0,
        le=100.0,
        description="Comparative Safety Score bounded strictly between 0.0 and 100.0",
    )
    safety_tier: str = Field(
        ...,
        description="Qualitative comparative safety classification (e.g. Comparatively Safer Route)",
    )
    route_distance_km: float = Field(..., description="Total route road travel distance in kilometers")
    straight_line_distance_km: float = Field(..., description="Straight-line distance between origin and destination in km")
    detour_ratio: float = Field(..., description="Ratio of road travel distance to straight-line distance")
    route_duration_min: Optional[float] = Field(None, description="Travel duration in minutes if provided")
    components: ComponentScores = Field(..., description="Normalized [0, 1] component values")
    contributions: ComponentContributions = Field(..., description="Point contributions out of 100")
    raw_features: RawFeatures = Field(..., description="Raw spatial dataset measurements")
    limitations_and_proxies: List[str] = Field(
        ...,
        description="Explicit documentation of contextual proxies, aggregate crime data, and comparative nature",
    )
