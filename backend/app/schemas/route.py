"""
SafeHer AI - Route Request Schemas
==================================
Pydantic schemas for validating route coordinates and evaluation inputs.
Rejects missing geometries, empty lists, malformed coordinates, out-of-bounds
lat/lon values, and polylines with fewer than two coordinate points.
"""

from typing import List, Optional
from pydantic import BaseModel, Field, field_validator


class CoordinatePoint(BaseModel):
    """
    Represents a single GPS coordinate point.
    Validates that latitude is within [-90.0, 90.0] and longitude is within [-180.0, 180.0].
    """

    latitude: float = Field(
        ...,
        ge=-90.0,
        le=90.0,
        description="Latitude in decimal degrees (between -90.0 and +90.0)",
        examples=[17.4100],
    )
    longitude: float = Field(
        ...,
        ge=-180.0,
        le=180.0,
        description="Longitude in decimal degrees (between -180.0 and +180.0)",
        examples=[78.4500],
    )

    def to_tuple(self) -> tuple[float, float]:
        """Returns coordinate as (latitude, longitude) tuple."""
        return (self.latitude, self.longitude)


class RouteScoreRequest(BaseModel):
    """
    Request payload containing route polyline geometry and optional navigation metadata.
    Must contain at least two coordinate points representing a traversable path.
    """

    route_coords: List[CoordinatePoint] = Field(
        ...,
        min_length=2,
        description="Ordered sequence of GPS coordinates defining the route polyline (minimum 2 points required)",
    )
    route_distance_km: Optional[float] = Field(
        default=None,
        ge=0.0,
        description="Optional pre-calculated total route distance in kilometers (e.g. from Directions API)",
        examples=[3.07],
    )
    route_duration_min: Optional[float] = Field(
        default=None,
        ge=0.0,
        description="Optional expected travel duration in minutes",
        examples=[18.5],
    )
    route_id: Optional[str] = Field(
        default="route_1",
        description="Optional unique identifier or label for this candidate route",
        examples=["route_alpha"],
    )

    @field_validator("route_coords")
    @classmethod
    def validate_min_points(cls, v: List[CoordinatePoint]) -> List[CoordinatePoint]:
        if not v or len(v) < 2:
            raise ValueError(
                "A route polyline must contain at least 2 distinct coordinate points."
            )
        return v

    model_config = {
        "json_schema_extra": {
            "example": {
                "route_id": "test_route_1",
                "route_coords": [
                    {"latitude": 17.4100, "longitude": 78.4500},
                    {"latitude": 17.4150, "longitude": 78.4550},
                    {"latitude": 17.4200, "longitude": 78.4600},
                ],
                "route_distance_km": 1.85,
                "route_duration_min": 8.0,
            }
        }
    }
