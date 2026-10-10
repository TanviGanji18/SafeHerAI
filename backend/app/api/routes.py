"""
SafeHer AI - API Endpoints
==========================
Registers REST API routes for:
1. Health check (GET /health)
2. Direct polyline safety score evaluation (POST /api/v1/safety/score)
3. Multi-route planning & safer route recommendation (POST /api/v1/routes/plan)
4. Location search & places autocomplete (GET /api/v1/places/autocomplete)
5. Nearby safe spots & civic amenities (GET /api/v1/safety/nearby-safe-spots)
6. Emergency SOS broadcast & incident alert (POST /api/v1/sos/trigger)
7. Trusted emergency contacts management (GET/POST /api/v1/user/contacts)
8. User registration & authentication (POST /api/v1/auth/register, /login, /firebase)
"""

from typing import List, Optional, Dict, Any
from fastapi import APIRouter, HTTPException, Query, status

from ..schemas.route import RouteScoreRequest
from ..schemas.safety import RouteScoreResponse, HealthResponse
from ..schemas.navigation import (
    RoutePlanRequest,
    RoutePlanResponse,
    PlaceSuggestion,
    NavigationRouteRequest,
    NavigationRouteResponse,
)
from ..schemas.amenity import NearbySafeSpotsResponse
from ..schemas.sos import (
    SOSTriggerRequest,
    SOSTriggerResponse,
    TrustedContact,
)
from ..schemas.user import (
    UserRegisterRequest,
    UserLoginRequest,
    FirebaseAuthTokenRequest,
    UserProfile,
    UserProfileUpdateRequest,
    AuthResponse,
)

from ..schemas.journey import (
    JourneyStartRequest,
    JourneyStartResponse,
    JourneyEventRequest,
    JourneyEventResponse,
    JourneyCompleteRequest,
    JourneyCompleteResponse,
    FeedbackDatasetItem,
)
from ..services.route_service import RouteSafetyService
from ..services.navigation_service import NavigationService
from ..services.amenities_service import AmenitiesService
from ..services.sos_service import SOSService
from ..services.auth_service import AuthService
from ..services.journey_service import JourneyService

router = APIRouter()


# ==============================================================================
# Health Check
# ==============================================================================
@router.get(
    "/health",
    response_model=HealthResponse,
    summary="Backend Health Check",
    description="Returns backend service operational health status.",
    tags=["Health"],
)
async def health_check() -> HealthResponse:
    """Returns basic backend health check response."""
    return HealthResponse(status="ok", service="SafeHer AI backend")


# ==============================================================================
# Route Safety Scoring (Polyline Evaluation)
# ==============================================================================
@router.post(
    "/api/v1/safety/score",
    response_model=RouteScoreResponse,
    status_code=status.HTTP_200_OK,
    summary="Evaluate Route Safety Score",
    description=(
        "Evaluates a client-supplied route polyline against genuine Hyderabad spatial "
        "infrastructure (police stations, hospitals, transit hubs, black spots) and official "
        "police zone crime statistics. Returns a bounded [0.0, 100.0] comparative score, "
        "qualitative safety tier, and complete component point contributions."
    ),
    tags=["Safety Scoring"],
)
async def score_route(request: RouteScoreRequest) -> RouteScoreResponse:
    """Evaluates safety factors for a client-provided route polyline."""
    try:
        response = RouteSafetyService.evaluate_route(request)
        return response
    except ValueError as val_err:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid route geometry: {str(val_err)}",
        )
    except Exception as err:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An error occurred while evaluating the route safety score. Please check the route geometry.",
        )


# ==============================================================================
# Route Planning & Multi-Route Comparison (Origin & Destination)
# ==============================================================================
@router.post(
    "/api/v1/routes/plan",
    response_model=RoutePlanResponse,
    status_code=status.HTTP_200_OK,
    summary="Plan and Compare Routes",
    description=(
        "Plans candidate travel routes between origin and destination via Google Directions "
        "or verified Hyderabad road corridors, evaluates each route through the multi-criteria "
        "SafetyScorer engine, and recommends the comparatively safer route with full factor breakdown."
    ),
    tags=["Navigation & Routing"],
)
def plan_routes(request: RoutePlanRequest) -> RoutePlanResponse:
    """Plans routes, scores alternatives, and identifies the safer route."""
    try:
        response = NavigationService.plan_and_score_routes(request)
        return response
    except ValueError as val_err:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(val_err),
        )
    except Exception as err:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An error occurred during route planning. Please verify location parameters.",
        )


@router.post(
    "/api/v1/navigation/route",
    response_model=NavigationRouteResponse,
    summary="Real-Time Turn-By-Turn Navigation Route & Maneuvers",
    description=(
        "Returns road geometry and sequential turn-by-turn instructions (e.g. Turn right in 200m) "
        "powered by OSRM real-world road network with automatic fallback."
    ),
    tags=["Navigation & Routing"],
)
def get_navigation_route(request: NavigationRouteRequest) -> NavigationRouteResponse:
    """Provides turn-by-turn maneuvers and route polyline for live navigation."""
    try:
        return NavigationService.get_navigation_route(request)
    except Exception as err:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Navigation route error: {str(err)}",
        )



# ==============================================================================
# Places Autocomplete & Search
# ==============================================================================
@router.get(
    "/api/v1/places/autocomplete",
    response_model=List[PlaceSuggestion],
    summary="Search Hyderabad Places & Landmarks",
    description="Returns autocompletion suggestions for Hyderabad locations and landmarks.",
    tags=["Navigation & Routing"],
)
def autocomplete_places(
    q: str = Query(..., min_length=1, description="Search query string"),
    limit: int = Query(6, ge=1, le=20, description="Maximum number of results"),
) -> List[PlaceSuggestion]:
    """Provides search autocomplete suggestions for Hyderabad locations."""
    return NavigationService.search_places(query=q, limit=limit)


@router.get(
    "/api/v1/places/reverse-geocode",
    summary="Reverse Geocode Coordinates",
    description="Resolves latitude and longitude coordinates to a recognizable location name in Hyderabad.",
    tags=["Navigation & Routing"],
)
def reverse_geocode(
    lat: float = Query(..., ge=-90.0, le=90.0, description="Latitude"),
    lon: float = Query(..., ge=-180.0, le=180.0, description="Longitude"),
) -> Dict[str, Any]:
    """Reverse geocodes device GPS coordinates to a recognized address or landmark."""
    address = NavigationService.reverse_geocode(lat, lon)
    return {"address": address, "latitude": lat, "longitude": lon}


# ==============================================================================
# Nearby Safe Spots & Civic Amenities
# ==============================================================================
@router.get(
    "/api/v1/safety/nearby-safe-spots",
    response_model=NearbySafeSpotsResponse,
    summary="Locate Nearby Safe Spots",
    description=(
        "Queries loaded genuine datasets to locate the closest police stations, emergency hospitals, "
        "transit hubs, and accident black spots relative to user coordinates."
    ),
    tags=["Safe Spots & Amenities"],
)
def nearby_safe_spots(
    lat: float = Query(..., ge=-90.0, le=90.0, description="Latitude"),
    lon: float = Query(..., ge=-180.0, le=180.0, description="Longitude"),
    radius_km: float = Query(5.0, ge=0.5, le=25.0, description="Search radius in kilometers"),
    limit: int = Query(5, ge=1, le=15, description="Max results per category"),
) -> NearbySafeSpotsResponse:
    """Returns nearest emergency civic infrastructure."""
    return AmenitiesService.get_nearby_safe_spots(
        latitude=lat, longitude=lon, radius_km=radius_km, limit_per_category=limit
    )


# ==============================================================================
# Emergency SOS & Distress Alert
# ==============================================================================
@router.post(
    "/api/v1/sos/trigger",
    response_model=SOSTriggerResponse,
    status_code=status.HTTP_200_OK,
    summary="Trigger Emergency SOS",
    description=(
        "Broadcasts an emergency distress signal with live GPS coordinates, identifies "
        "the closest operational police station, notifies trusted contacts, and provides emergency guidance."
    ),
    tags=["Emergency SOS"],
)
async def trigger_sos(request: SOSTriggerRequest) -> SOSTriggerResponse:
    """Processes an immediate emergency distress alert."""
    try:
        return SOSService.trigger_sos(request)
    except Exception as err:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to register SOS alert. Please dial 100 or 112 immediately.",
        )


@router.get(
    "/api/v1/user/contacts",
    response_model=List[TrustedContact],
    summary="List Trusted Emergency Contacts",
    description="Retrieves registered trusted emergency contacts for a user.",
    tags=["Emergency SOS"],
)
async def list_trusted_contacts(
    user_id: str = Query("anonymous_user", description="User ID"),
) -> List[TrustedContact]:
    """Returns trusted contacts for user."""
    return SOSService.get_contacts(user_id)


@router.post(
    "/api/v1/user/contacts",
    response_model=TrustedContact,
    status_code=status.HTTP_201_CREATED,
    summary="Add Trusted Emergency Contact",
    description="Registers a new trusted emergency contact for alerts.",
    tags=["Emergency SOS"],
)
async def add_trusted_contact(
    contact: TrustedContact,
    user_id: str = Query("anonymous_user", description="User ID"),
) -> TrustedContact:
    """Adds a new emergency contact."""
    return SOSService.add_contact(user_id, contact)


@router.put(
    "/api/v1/user/contacts/{contact_id}",
    response_model=TrustedContact,
    status_code=status.HTTP_200_OK,
    summary="Update Trusted Emergency Contact",
    description="Updates an existing trusted emergency contact.",
    tags=["Emergency SOS"],
)
async def update_trusted_contact(
    contact_id: str,
    contact: TrustedContact,
    user_id: str = Query("anonymous_user", description="User ID"),
) -> TrustedContact:
    """Updates an existing emergency contact."""
    updated = SOSService.update_contact(user_id, contact_id, contact)
    if not updated:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contact not found")
    return updated


@router.delete(
    "/api/v1/user/contacts/{contact_id}",
    status_code=status.HTTP_200_OK,
    summary="Delete Trusted Emergency Contact",
    description="Deletes a registered trusted emergency contact.",
    tags=["Emergency SOS"],
)
async def delete_trusted_contact(
    contact_id: str,
    user_id: str = Query("anonymous_user", description="User ID"),
) -> Dict[str, Any]:
    """Deletes an emergency contact."""
    deleted = SOSService.delete_contact(user_id, contact_id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contact not found")
    return {"status": "deleted", "contact_id": contact_id}


# ==============================================================================
# Authentication & User Accounts
# ==============================================================================
@router.post(
    "/api/v1/auth/register",
    response_model=AuthResponse,
    status_code=status.HTTP_201_CREATED,
    summary="User Registration",
    description="Creates a new SafeHer AI user account.",
    tags=["Authentication"],
)
async def register(request: UserRegisterRequest) -> AuthResponse:
    """Registers a new user account."""
    try:
        return AuthService.register_user(request)
    except ValueError as ve:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(ve))


@router.post(
    "/api/v1/auth/login",
    response_model=AuthResponse,
    status_code=status.HTTP_200_OK,
    summary="User Login",
    description="Authenticates user with email and password.",
    tags=["Authentication"],
)
async def login(request: UserLoginRequest) -> AuthResponse:
    """Logs in an existing user."""
    try:
        return AuthService.login_user(request)
    except ValueError as ve:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(ve))


@router.post(
    "/api/v1/auth/firebase",
    response_model=AuthResponse,
    status_code=status.HTTP_200_OK,
    summary="Firebase Authentication",
    description="Exchanges a mobile client Firebase Auth ID token for a session.",
    tags=["Authentication"],
)
async def firebase_auth(request: FirebaseAuthTokenRequest) -> AuthResponse:
    """Authenticates via Firebase ID token."""
    try:
        return AuthService.authenticate_firebase_token(request.id_token)
    except ValueError as ve:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(ve))


@router.put(
    "/api/v1/user/profile",
    response_model=UserProfile,
    status_code=status.HTTP_200_OK,
    summary="Update User Profile",
    description="Updates user display name and emergency phone.",
    tags=["Authentication"],
)
async def update_user_profile(request: UserProfileUpdateRequest) -> UserProfile:
    """Updates user display name and emergency phone."""
    return AuthService.update_profile(
        user_id=request.user_id,
        full_name=request.full_name,
        phone=request.phone,
    )


# ==============================================================================
# Journey Navigation & Feedback Pipeline (Future Model Learning)
# ==============================================================================
@router.post(
    "/api/v1/journey/start",
    response_model=JourneyStartResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Start Active Navigation Journey",
    description="Initializes an active navigation journey record, locking in the chosen safer route.",
    tags=["Journey Navigation"],
)
async def start_journey(request: JourneyStartRequest) -> JourneyStartResponse:
    """Initiates an active navigation journey."""
    try:
        return JourneyService.start_journey(request)
    except Exception as err:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to initiate navigation journey: {str(err)}",
        )


@router.post(
    "/api/v1/journey/event",
    response_model=JourneyEventResponse,
    status_code=status.HTTP_200_OK,
    summary="Log Active Journey Event",
    description="Records telemetry or emergency SOS events during an active journey.",
    tags=["Journey Navigation"],
)
async def record_journey_event(request: JourneyEventRequest) -> JourneyEventResponse:
    """Records an event occurring during navigation."""
    try:
        return JourneyService.record_event(request)
    except Exception as err:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to record journey event: {str(err)}",
        )


@router.post(
    "/api/v1/journey/complete",
    response_model=JourneyCompleteResponse,
    status_code=status.HTTP_200_OK,
    summary="Complete Journey & Submit Feedback",
    description="Marks journey as completed and stores user feedback for future safety model learning.",
    tags=["Journey Navigation"],
)
async def complete_journey(request: JourneyCompleteRequest) -> JourneyCompleteResponse:
    """Concludes active journey and logs feedback into the retraining dataset."""
    try:
        return JourneyService.complete_journey(request)
    except Exception as err:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to complete journey record: {str(err)}",
        )


@router.get(
    "/api/v1/journey/feedback",
    response_model=List[Dict[str, Any]],
    summary="Get Feedback Dataset Entries",
    description="Returns accumulated journey feedback dataset entries for periodic analysis.",
    tags=["Journey Navigation"],
)
async def get_feedback_dataset() -> List[Dict[str, Any]]:
    """Returns stored feedback records."""
    return JourneyService.get_all_feedback_dataset()


@router.get(
    "/api/v1/journey/user",
    response_model=List[Dict[str, Any]],
    summary="Get User Navigation Journeys",
    description="Retrieves recorded navigation journeys for a user.",
    tags=["Journey Navigation"],
)
async def get_user_journeys(
    user_id: str = Query("anonymous_user", description="User ID"),
) -> List[Dict[str, Any]]:
    """Returns stored navigation journeys for a user."""
    return JourneyService.get_user_journeys(user_id)
