"""
SafeHer AI - Safety Scoring Configuration
==========================================
Defines configurable analytical weights, spatial thresholds, and dataset paths
for the multi-criteria route safety scoring engine.

IMPORTANT:
These weights are project-defined analytical parameters designed for comparative
route evaluation. They are NOT official government statutory safety ratings.
All parameters remain configurable in code.
"""

import os
from typing import Dict

# Base dataset directory relative to project root
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
DATASETS_DIR = os.path.join(BASE_DIR, "datasets")

# File paths to verified genuine datasets
PATH_POLICE_STATIONS = os.path.join(DATASETS_DIR, "police_stations.geojson")
PATH_HOSPITALS = os.path.join(DATASETS_DIR, "hospitals.csv")
PATH_TRANSPORT = os.path.join(DATASETS_DIR, "transport_stations.csv")
PATH_ROADS = os.path.join(DATASETS_DIR, "roads", "hyderabad_major_roads.geojson")
PATH_CRIME_DATA = os.path.join(DATASETS_DIR, "crime_data.csv")
PATH_WOMEN_SAFETY = os.path.join(DATASETS_DIR, "hyderabad_women_safety.csv")
PATH_ROAD_ACCIDENTS = os.path.join(DATASETS_DIR, "road_accidents.csv")
PATH_AREA_ZONE = os.path.join(DATASETS_DIR, "area_zone_mapping.csv")
PATH_DEMOGRAPHICS = os.path.join(DATASETS_DIR, "demographics.csv")
PATH_GHMC_ZONES = os.path.join(DATASETS_DIR, "boundaries", "ghmc_zones.kml")

# ==============================================================================
# 1. APPROVED COMPONENT WEIGHTS (Strictly summing to 1.000)
# ==============================================================================
# The logical order must be maintained consistently across all calculations:
# S_police -> S_medical -> S_transit -> S_arterial -> P_crime -> P_blackspot -> P_exposure
WEIGHT_POLICE: float = 0.25      # Police station accessibility & density (25%)
WEIGHT_MEDICAL: float = 0.15     # Emergency hospital proximity (15%)
WEIGHT_TRANSIT: float = 0.15     # Public transit presence (Contextual Proxy) (15%)
WEIGHT_ARTERIAL: float = 0.15    # Primary arterial road hierarchy (Contextual Proxy) (15%)
WEIGHT_CRIME: float = 0.15       # Relative jurisdictional crime volume penalty (15%)
WEIGHT_BLACKSPOT: float = 0.10   # Traffic accident black spot road hazard penalty (10%)
WEIGHT_EXPOSURE: float = 0.05    # Route detour and exposure penalty (5%)

TOTAL_WEIGHT = (
    WEIGHT_POLICE
    + WEIGHT_MEDICAL
    + WEIGHT_TRANSIT
    + WEIGHT_ARTERIAL
    + WEIGHT_CRIME
    + WEIGHT_BLACKSPOT
    + WEIGHT_EXPOSURE
)
assert abs(TOTAL_WEIGHT - 1.0) < 1e-6, f"Weights must sum to 1.0, got {TOTAL_WEIGHT}"

# ==============================================================================
# 2. SPATIAL THRESHOLDS & CALIBRATION PARAMETERS
# ==============================================================================
# Police accessibility thresholds
POLICE_MAX_DIST_KM: float = 4.0        # Distance beyond which police support decays to 0
POLICE_BUFFER_KM: float = 1.0          # Buffer radius for counting nearby police stations
POLICE_SATURATION_COUNT: int = 3       # Count of stations within buffer for full density score

# Hospital proximity thresholds
MEDICAL_MAX_DIST_KM: float = 3.0       # Distance beyond which medical support decays to 0

# Public transit infrastructure proxy thresholds
TRANSIT_BUFFER_KM: float = 0.5         # Buffer radius for nearby transit stops (500m)
TRANSIT_SATURATION_PER_KM: float = 6.0 # Transit stops per km for full transit score

# Road corridor proxy thresholds
ROAD_BUFFER_METERS: float = 50.0       # Proximity threshold to match route to arterial corridor

# Road hazard black spot thresholds
BLACKSPOT_BUFFER_KM: float = 0.25      # Buffer radius for identified black spots (250m)
BLACKSPOT_PENALTY_PER_SPOT: float = 0.50 # Penalty increment per intersecting black spot

# Route detour exposure thresholds
DETOUR_BASELINE: float = 1.25          # Typical direct urban route detour ratio (D_route / D_straight)
DETOUR_RANGE: float = 1.00             # Denominator scaling detour penalty: (R - 1.25) / 1.00

# Sampling parameters for route polylines
ROUTE_SAMPLE_STEP_KM: float = 0.10     # Sample route every 100 meters for spatial analysis

# ==============================================================================
# 3. QUALITATIVE SAFETY SCORE TIERS
# ==============================================================================
TIER_HIGH_THRESHOLD: float = 75.0      # Score >= 75.0: Comparatively Safer Route
TIER_MODERATE_THRESHOLD: float = 50.0  # 50.0 <= Score < 75.0: Moderate Safety Corridor
# Score < 50.0: Caution Advised Corridor

TIER_HIGH_LABEL: str = "Comparatively Safer Route"
TIER_MODERATE_LABEL: str = "Moderate Safety Corridor"
TIER_LOW_LABEL: str = "Caution Advised Corridor"
