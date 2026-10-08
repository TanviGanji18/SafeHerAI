"""
SafeHer AI - Safety Scoring Engine
===================================
Main evaluation service for scoring and comparing travel routes in Hyderabad.

Integrates real spatial feature extraction with mathematical normalization
and multi-criteria evaluation. Strictly enforces 0-100 clamping, project-defined
analytical weights, and clear comparative terminology.
"""

from typing import List, Tuple, Dict, Any, Optional
from .spatial_features import SpatialDataLoader, SpatialFeatureExtractor
from .normalization import (
    normalize_police,
    normalize_medical,
    normalize_transit,
    normalize_arterial,
    normalize_crime,
    normalize_blackspot,
    normalize_exposure,
    calculate_safety_score,
)


class SafetyScorer:
    """
    Evaluates one or more candidate route polylines against genuine Hyderabad
    spatial infrastructure and official police statistics.
    """

    def __init__(self, data_loader: Optional[SpatialDataLoader] = None):
        if data_loader is not None:
            self.loader = data_loader
        else:
            self.loader = SpatialDataLoader()
            self.loader.load_all()
        self.extractor = SpatialFeatureExtractor(self.loader)

    def score_route(
        self,
        route_coords: List[Tuple[float, float]],
        route_distance_km: Optional[float] = None,
        route_duration_min: Optional[float] = None,
        route_id: str = "route_1",
    ) -> Dict[str, Any]:
        """
        Evaluates a single route polyline and computes its unified Safety Score (0-100).

        Parameters:
            route_coords: Sequence of (lat, lon) GPS points defining the route path.
            route_distance_km: Optional explicit route road distance.
            route_duration_min: Optional travel duration in minutes.
            route_id: Identifier label for the route.
        """
        # 1. Extract raw spatial features from real datasets
        raw = self.extractor.extract_features(
            route_coords=route_coords, route_distance_km=route_distance_km
        )

        route_len = raw["route_distance_km"]
        straight_dist = raw["straight_distance_km"]

        # 2. Normalize every component to [0, 1] using strict logical order
        s_police = normalize_police(
            avg_dist_km=raw["avg_police_dist_km"],
            count_within_1km=raw["police_within_1km_count"],
        )
        s_medical = normalize_medical(min_dist_km=raw["min_hospital_dist_km"])
        s_transit = normalize_transit(
            transit_count=raw["transit_count"], route_len_km=route_len
        )
        s_arterial = normalize_arterial(
            arterial_len_km=raw["arterial_len_km"], route_len_km=route_len
        )
        p_crime = normalize_crime(zone_risk_weighted=raw["weighted_crime_risk"])
        p_blackspot = normalize_blackspot(blackspot_count=raw["blackspot_count"])
        p_exposure = normalize_exposure(
            route_dist_km=route_len, straight_dist_km=straight_dist
        )

        # 3. Calculate final unified Safety Score (0.0 to 100.0)
        score_data = calculate_safety_score(
            s_police=s_police,
            s_medical=s_medical,
            s_transit=s_transit,
            s_arterial=s_arterial,
            p_crime=p_crime,
            p_blackspot=p_blackspot,
            p_exposure=p_exposure,
        )

        # 4. Compile detailed evaluation report
        return {
            "route_id": route_id,
            "route_distance_km": round(route_len, 2),
            "straight_distance_km": round(straight_dist, 2),
            "route_duration_min": route_duration_min,
            "safety_score": score_data["safety_score"],
            "comparative_tier": score_data["comparative_tier"],
            "components": score_data["components"],
            "contributions": score_data["contributions"],
            "raw_features": {
                "avg_police_dist_km": round(raw["avg_police_dist_km"], 2),
                "police_within_1km_count": raw["police_within_1km_count"],
                "min_hospital_dist_km": round(raw["min_hospital_dist_km"], 2),
                "transit_count_within_500m": raw["transit_count"],
                "arterial_length_km": round(raw["arterial_len_km"], 2),
                "traversed_zones": raw["traversed_zones"],
                "blackspot_count": raw["blackspot_count"],
            },
        }

    def compare_routes(
        self, candidate_routes: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Compares multiple candidate routes and recommends the comparatively safer route.

        Each candidate route must have:
            'coords': List of (lat, lon)
            'route_id': str (optional)
            'distance_km': float (optional)
            'duration_min': float (optional)
        """
        if not candidate_routes:
            raise ValueError("At least one candidate route must be provided.")

        evaluations: List[Dict[str, Any]] = []
        for idx, route_spec in enumerate(candidate_routes):
            rid = route_spec.get("route_id", f"Route_{idx + 1}")
            coords = route_spec["coords"]
            dist_km = route_spec.get("distance_km")
            dur_min = route_spec.get("duration_min")

            ev = self.score_route(
                route_coords=coords,
                route_distance_km=dist_km,
                route_duration_min=dur_min,
                route_id=rid,
            )
            evaluations.append(ev)

        # Sort routes by safety score descending
        ranked = sorted(evaluations, key=lambda x: x["safety_score"], reverse=True)
        recommended = ranked[0]

        # Generate comparative rationale
        rationale = []
        if len(ranked) > 1:
            diff = recommended["safety_score"] - ranked[1]["safety_score"]
            rationale.append(
                f"Selected as comparatively safer by +{diff:.1f} points over alternative."
            )
            rec_c = recommended["components"]
            alt_c = ranked[1]["components"]
            if rec_c["S_police"] > alt_c["S_police"]:
                rationale.append("Superior police station proximity along corridor.")
            if rec_c["S_medical"] > alt_c["S_medical"]:
                rationale.append("Closer emergency healthcare access.")
            if rec_c["S_transit"] > alt_c["S_transit"]:
                rationale.append("Higher public transit infrastructure presence.")
            if rec_c["P_blackspot"] < alt_c["P_blackspot"]:
                rationale.append("Avoids identified traffic accident black spots.")
            if rec_c["P_crime"] < alt_c["P_crime"]:
                rationale.append("Lower jurisdictional reported crime volume in traversed zones.")

        return {
            "recommended_route_id": recommended["route_id"],
            "recommendation_tier": recommended["comparative_tier"],
            "comparative_rationale": rationale,
            "routes": ranked,
        }
