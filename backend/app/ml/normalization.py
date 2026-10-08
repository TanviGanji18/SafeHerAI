"""
SafeHer AI - Normalization & Core Score Calculation
===================================================
Provides mathematical normalization functions for every safety component
and evaluates the final unified Safety Score strictly bounded in [0.0, 100.0].

Logical component order enforced throughout:
S_police -> S_medical -> S_transit -> S_arterial -> P_crime -> P_blackspot -> P_exposure
"""

from typing import Dict, Any
from .config import (
    WEIGHT_POLICE,
    WEIGHT_MEDICAL,
    WEIGHT_TRANSIT,
    WEIGHT_ARTERIAL,
    WEIGHT_CRIME,
    WEIGHT_BLACKSPOT,
    WEIGHT_EXPOSURE,
    POLICE_MAX_DIST_KM,
    POLICE_SATURATION_COUNT,
    MEDICAL_MAX_DIST_KM,
    TRANSIT_SATURATION_PER_KM,
    BLACKSPOT_PENALTY_PER_SPOT,
    DETOUR_BASELINE,
    DETOUR_RANGE,
    TIER_HIGH_THRESHOLD,
    TIER_MODERATE_THRESHOLD,
    TIER_HIGH_LABEL,
    TIER_MODERATE_LABEL,
    TIER_LOW_LABEL,
)


def clamp(value: float, min_val: float = 0.0, max_val: float = 1.0) -> float:
    """Clamps a floating point value to the closed interval [min_val, max_val]."""
    return max(min_val, min(max_val, float(value)))


def normalize_police(avg_dist_km: float, count_within_1km: int) -> float:
    """
    Component 1: Police Station Accessibility Score (S_police in [0, 1]).
    Combines average proximity along the route (70% weight) with local station
    density within a 1km corridor buffer (30% weight).
    """
    if avg_dist_km < 0.0:
        avg_dist_km = 0.0
    dist_term = max(0.0, 1.0 - (avg_dist_km / POLICE_MAX_DIST_KM))
    count_term = min(1.0, max(0, count_within_1km) / POLICE_SATURATION_COUNT)
    combined = 0.70 * dist_term + 0.30 * count_term
    return clamp(combined, 0.0, 1.0)


def normalize_medical(min_dist_km: float) -> float:
    """
    Component 2: Emergency Medical Access Score (S_medical in [0, 1]).
    Evaluates proximity to the nearest registered emergency hospital/facility.
    Decays linearly to 0 beyond MEDICAL_MAX_DIST_KM.
    """
    if min_dist_km < 0.0:
        min_dist_km = 0.0
    score = 1.0 - (min_dist_km / MEDICAL_MAX_DIST_KM)
    return clamp(score, 0.0, 1.0)


def normalize_transit(transit_count: int, route_len_km: float) -> float:
    """
    Component 3: Public Transit Presence Score (S_transit in [0, 1]).
    Contextual infrastructure proxy measuring density of metro and bus stops per km.
    Saturates at TRANSIT_SATURATION_PER_KM (default: 6 stops/km).
    """
    if route_len_km <= 0.01:
        return 0.0
    density = max(0, transit_count) / route_len_km
    score = density / TRANSIT_SATURATION_PER_KM
    return clamp(score, 0.0, 1.0)


def normalize_arterial(arterial_len_km: float, route_len_km: float) -> float:
    """
    Component 4: Arterial Road Hierarchy Alignment Score (S_arterial in [0, 1]).
    Contextual infrastructure proxy measuring the proportion of route travel
    on designated primary, trunk, or motorway corridors.
    """
    if route_len_km <= 0.01:
        return 0.0
    ratio = max(0.0, arterial_len_km) / route_len_km
    return clamp(ratio, 0.0, 1.0)


def normalize_crime(zone_risk_weighted: float) -> float:
    """
    Component 5: Jurisdictional Crime Volume Penalty (P_crime in [0, 1]).
    Evaluates relative reported FIR volume in the traversed Hyderabad police zones.
    Calculated as a distance-weighted sum of Min-Max normalized zone FIR counts.
    """
    return clamp(zone_risk_weighted, 0.0, 1.0)


def normalize_blackspot(blackspot_count: int) -> float:
    """
    Component 6: Traffic Accident Black Spot Penalty (P_blackspot in [0, 1]).
    Road hazard penalty reflecting intersection with officially identified crash junctions.
    Each black spot within 250m adds BLACKSPOT_PENALTY_PER_SPOT (0.50).
    """
    penalty = max(0, blackspot_count) * BLACKSPOT_PENALTY_PER_SPOT
    return clamp(penalty, 0.0, 1.0)


def normalize_exposure(route_dist_km: float, straight_dist_km: float) -> float:
    """
    Component 7: Route Detour and Exposure Penalty (P_exposure in [0, 1]).
    Penalizes indirect or detour-heavy routes that unnecessarily extend travel time.
    Calculated via detour_ratio = route_dist / straight_dist.
    Penalty begins when detour_ratio > DETOUR_BASELINE (1.25) and reaches 1.0 at 2.25.
    """
    if straight_dist_km < 0.10:
        return 0.0
    detour_ratio = max(1.0, route_dist_km / straight_dist_km)
    penalty = (detour_ratio - DETOUR_BASELINE) / DETOUR_RANGE
    return clamp(penalty, 0.0, 1.0)


def calculate_safety_score(
    s_police: float,
    s_medical: float,
    s_transit: float,
    s_arterial: float,
    p_crime: float,
    p_blackspot: float,
    p_exposure: float,
) -> Dict[str, Any]:
    """
    Calculates the final unified Safety Score bounded strictly to [0.0, 100.0].

    Formula:
    Safety Score = 100 * (
        0.25 * S_police +
        0.15 * S_medical +
        0.15 * S_transit +
        0.15 * S_arterial +
        0.15 * (1 - P_crime) +
        0.10 * (1 - P_blackspot) +
        0.05 * (1 - P_exposure)
    )

    Returns a structured dictionary with the score, qualitative tier, and factor breakdown.
    """
    # Enforce input normalization bounds
    s_pol = clamp(s_police)
    s_med = clamp(s_medical)
    s_trn = clamp(s_transit)
    s_art = clamp(s_arterial)
    p_crm = clamp(p_crime)
    p_blk = clamp(p_blackspot)
    p_exp = clamp(p_exposure)

    # Inverted penalty compliance factors
    c_crime = 1.0 - p_crm
    c_blackspot = 1.0 - p_blk
    c_exposure = 1.0 - p_exp

    # Weighted contribution calculation (Strict mathematical convex sum)
    weighted_sum = (
        WEIGHT_POLICE * s_pol
        + WEIGHT_MEDICAL * s_med
        + WEIGHT_TRANSIT * s_trn
        + WEIGHT_ARTERIAL * s_art
        + WEIGHT_CRIME * c_crime
        + WEIGHT_BLACKSPOT * c_blackspot
        + WEIGHT_EXPOSURE * c_exposure
    )

    # Scale to 0-100 and apply mathematical clamping
    raw_score = 100.0 * weighted_sum
    final_score = clamp(raw_score, 0.0, 100.0)
    final_score = round(final_score, 1)

    # Determine comparative qualitative tier
    if final_score >= TIER_HIGH_THRESHOLD:
        tier = TIER_HIGH_LABEL
    elif final_score >= TIER_MODERATE_THRESHOLD:
        tier = TIER_MODERATE_LABEL
    else:
        tier = TIER_LOW_LABEL

    return {
        "safety_score": final_score,
        "comparative_tier": tier,
        "components": {
            "S_police": round(s_pol, 4),
            "S_medical": round(s_med, 4),
            "S_transit": round(s_trn, 4),
            "S_arterial": round(s_art, 4),
            "P_crime": round(p_crm, 4),
            "P_blackspot": round(p_blk, 4),
            "P_exposure": round(p_exp, 4),
        },
        "contributions": {
            "police_pts": round(100.0 * WEIGHT_POLICE * s_pol, 2),
            "medical_pts": round(100.0 * WEIGHT_MEDICAL * s_med, 2),
            "transit_pts": round(100.0 * WEIGHT_TRANSIT * s_trn, 2),
            "arterial_pts": round(100.0 * WEIGHT_ARTERIAL * s_art, 2),
            "crime_compliance_pts": round(100.0 * WEIGHT_CRIME * c_crime, 2),
            "blackspot_compliance_pts": round(100.0 * WEIGHT_BLACKSPOT * c_blackspot, 2),
            "exposure_compliance_pts": round(100.0 * WEIGHT_EXPOSURE * c_exposure, 2),
        },
    }
