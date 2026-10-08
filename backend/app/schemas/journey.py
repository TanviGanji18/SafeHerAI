"""
SafeHer AI - Journey & Feedback Schemas
=======================================
Pydantic data models for managing active navigation journeys, emergency tracking,
destination arrival, user journey feedback, and feedback datasets for future model learning.
"""

from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field


class JourneyStartRequest(BaseModel):
    """Payload to initiate an active navigation journey."""
    user_id: str = Field(default="anonymous_user", description="User identifier")
    origin: Dict[str, Any] = Field(..., description="Origin location details (address, lat, lon)")
    destination: Dict[str, Any] = Field(..., description="Destination location details (address, lat, lon)")
    selected_route_id: str = Field(..., description="Unique ID of the chosen candidate route")
    route_summary: str = Field(..., description="Human-readable route title or category")
    distance_km: float = Field(..., ge=0.0, description="Route total length in kilometers")
    duration_min: float = Field(..., ge=0.0, description="Estimated route duration in minutes")
    safety_score: float = Field(..., ge=0.0, le=100.0, description="Evaluated safety score")
    safety_tier: str = Field(default="Safe Corridor", description="Qualitative safety tier")
    is_recommended_safer: bool = Field(default=False, description="Whether this is the recommended safer route")
    polyline_coords: Optional[List[Dict[str, float]]] = Field(default=None, description="Route coordinate points")
    contributions: Optional[Dict[str, float]] = Field(default=None, description="7-factor point contributions")
    raw_features: Optional[Dict[str, Any]] = Field(default=None, description="Extracted spatial infrastructure metrics")
    start_time: Optional[str] = Field(default=None, description="ISO timestamp of journey start")


class JourneyStartResponse(BaseModel):
    """Response returned upon starting an active journey."""
    journey_id: str
    user_id: str
    status: str = "active"
    start_time: str
    message: str


class JourneyEventRequest(BaseModel):
    """Payload to record an event during active journey (e.g. SOS trigger, waypoint, deviation)."""
    journey_id: str
    event_type: str = Field(..., description="Event type: 'sos_trigger', 'waypoint_reached', 'route_deviation'")
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    timestamp: Optional[str] = None
    details: Optional[Dict[str, Any]] = Field(default=None, description="Contextual event metadata")


class JourneyEventResponse(BaseModel):
    """Response returned when an event is recorded."""
    journey_id: str
    event_id: str
    event_type: str
    recorded_at: str
    status: str = "recorded"


class JourneyCompleteRequest(BaseModel):
    """Payload to complete a journey and record user feedback."""
    journey_id: str
    end_time: Optional[str] = None
    completed_status: str = Field(default="completed", description="'completed', 'cancelled', 'emergency_ended'")
    final_distance_km: Optional[float] = None
    route_experience: Optional[str] = Field(default=None, description="'Comfortable', 'Average', 'Felt Unsafe'")
    issues_noticed: Optional[List[str]] = Field(default=None, description="List of observed issues during travel")
    comments: Optional[str] = Field(default=None, description="Optional free-form user feedback")


class JourneyCompleteResponse(BaseModel):
    """Response returned upon saving journey completion and feedback."""
    journey_id: str
    status: str
    feedback_saved: bool
    feedback_dataset_entry_id: Optional[str] = None
    message: str


class FeedbackDatasetItem(BaseModel):
    """Structured feedback record formatted for future dataset compilation and periodic retraining."""
    journey_id: str
    timestamp: str
    user_id: str
    origin_name: str
    destination_name: str
    route_id: str
    distance_km: float
    duration_min: float
    safety_score: float
    route_experience: Optional[str] = None
    issues: List[str] = []
    comments: Optional[str] = None
    emergency_occurred: bool = False
