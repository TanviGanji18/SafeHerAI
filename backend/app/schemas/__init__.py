"""
SafeHer AI Pydantic Request & Response Schemas
"""

from .route import CoordinatePoint, RouteScoreRequest
from .safety import (
    ComponentScores,
    ComponentContributions,
    RawFeatures,
    RouteScoreResponse,
    HealthResponse,
)
from .navigation import (
    LocationQuery,
    RoutePlanRequest,
    RoutePlanResponse,
    EnrichedRoute,
    PlaceSuggestion,
)
from .amenity import AmenityItem, NearbySafeSpotsResponse
from .sos import TrustedContact, SOSTriggerRequest, SOSTriggerResponse
from .user import (
    UserRegisterRequest,
    UserLoginRequest,
    FirebaseAuthTokenRequest,
    UserProfile,
    AuthResponse,
)

__all__ = [
    "CoordinatePoint",
    "RouteScoreRequest",
    "ComponentScores",
    "ComponentContributions",
    "RawFeatures",
    "RouteScoreResponse",
    "HealthResponse",
    "LocationQuery",
    "RoutePlanRequest",
    "RoutePlanResponse",
    "EnrichedRoute",
    "PlaceSuggestion",
    "AmenityItem",
    "NearbySafeSpotsResponse",
    "TrustedContact",
    "SOSTriggerRequest",
    "SOSTriggerResponse",
    "UserRegisterRequest",
    "UserLoginRequest",
    "FirebaseAuthTokenRequest",
    "UserProfile",
    "AuthResponse",
]
