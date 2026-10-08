"""
SafeHer AI - Route Safety Service
=================================
Application service connecting FastAPI endpoints to the core SafetyScorer engine.
Maintains a single loaded instance of the spatial datasets in memory, eliminating
redundant disk I/O per HTTP request.

The existing SafetyScorer remains the SINGLE SOURCE OF TRUTH for all calculations.
No scoring formulas or weight logic are duplicated here.
"""

from typing import List, Tuple
from ..ml.safety_scorer import SafetyScorer
from ..schemas.route import RouteScoreRequest
from ..schemas.safety import (
    RouteScoreResponse,
    ComponentScores,
    ComponentContributions,
    RawFeatures,
)

# Standard limitations and proxy disclosures required by project specifications
STANDARD_LIMITATIONS_AND_PROXIES: List[str] = [
    "Transit Presence is a contextual infrastructure proxy based on metro and bus stop density; it is not a direct measurement of individual safety.",
    "Arterial Road Hierarchy reflects classified primary roadway proportion; it does not guarantee functional street lighting or active patrolling on any given night.",
    "Crime Volume is derived from official Hyderabad City Police annual reports at the jurisdictional zone level, not micro-level street coordinates.",
    "Traffic Accident Black Spots represent identified vehicular collision junctions and are evaluated as a road hazard separate from personal crime risk.",
    "The Safety Score is an analytical comparative estimate designed to rank travel alternatives; it does not guarantee absolute safety from incident.",
]


class RouteSafetyService:
    """Service wrapper managing SafetyScorer execution and response mapping."""

    _scorer_instance: SafetyScorer = None

    @classmethod
    def get_scorer(cls) -> SafetyScorer:
        """Lazy initialization of SafetyScorer singleton."""
        if cls._scorer_instance is None:
            cls._scorer_instance = SafetyScorer()
        return cls._scorer_instance

    @classmethod
    def evaluate_route(cls, request: RouteScoreRequest) -> RouteScoreResponse:
        """
        Evaluates a client-supplied route polyline using the verified spatial datasets.
        """
        scorer = cls.get_scorer()

        # Convert Pydantic coordinate points to (lat, lon) tuples
        coords: List[Tuple[float, float]] = [pt.to_tuple() for pt in request.route_coords]

        # Call the existing SafetyScorer
        eval_result = scorer.score_route(
            route_coords=coords,
            route_distance_km=request.route_distance_km,
            route_duration_min=request.route_duration_min,
            route_id=request.route_id or "route_1",
        )

        route_dist = eval_result["route_distance_km"]
        straight_dist = eval_result["straight_distance_km"]
        detour_ratio = round(route_dist / max(0.01, straight_dist), 2) if straight_dist > 0.05 else 1.0

        # Construct strongly-typed Pydantic response
        return RouteScoreResponse(
            route_id=eval_result["route_id"],
            safety_score=eval_result["safety_score"],
            safety_tier=eval_result["comparative_tier"],
            route_distance_km=route_dist,
            straight_line_distance_km=straight_dist,
            detour_ratio=detour_ratio,
            route_duration_min=eval_result.get("route_duration_min"),
            components=ComponentScores(**eval_result["components"]),
            contributions=ComponentContributions(**eval_result["contributions"]),
            raw_features=RawFeatures(**eval_result["raw_features"]),
            limitations_and_proxies=STANDARD_LIMITATIONS_AND_PROXIES,
        )
