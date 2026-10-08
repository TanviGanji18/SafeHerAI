"""
SafeHer AI - Safety Scoring Engine Demo
=======================================
Demonstration and software verification script using strictly synthetic
test route geometries.

IMPORTANT NOTICE:
The coordinates below are SYNTHETIC TEST GEOMETRIES created solely for
verifying that the mathematical scoring pipeline, data joins, and route
comparison logic execute properly without error.
These are NOT real user navigation paths and MUST NOT be presented as
empirical project results.
"""

import sys
import os

# Add project root to sys.path so 'backend' package resolves cleanly
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

from backend.app.ml.safety_scorer import SafetyScorer


def run_demo():
    print("=" * 70)
    print("SAFEHER AI - SAFETY SCORING ENGINE DEMONSTRATION")
    print("=" * 70)
    print("Loading verified spatial datasets from disk...")

    scorer = SafetyScorer()
    print("Datasets loaded successfully:")
    print(f"  - Police Stations: {len(scorer.loader.police_stations)}")
    print(f"  - Hospitals: {len(scorer.loader.hospitals)}")
    print(f"  - Transit Stations: {len(scorer.loader.transit_stops)}")
    print(f"  - Accident Black Spots: {len(scorer.loader.black_spots)}")
    print(f"  - Major Road Segments: {len(scorer.loader.major_roads)}")
    print(f"  - Zone Crime Risk Map: {scorer.loader.zone_crime_risk_map}")

    print("\n" + "-" * 70)
    print("EVALUATING SYNTHETIC TEST GEOMETRIES (SOFTWARE TESTING ONLY)")
    print("-" * 70)

    # --------------------------------------------------------------------------
    # SYNTHETIC TEST ROUTE ALPHA (Simulating an urban corridor with dense civic infrastructure)
    # NOTE: Strictly for software testing. Not a real travel path.
    # --------------------------------------------------------------------------
    synthetic_route_alpha = [
        (17.4100, 78.4500),
        (17.4150, 78.4550),
        (17.4200, 78.4600),
        (17.4250, 78.4650),
        (17.4300, 78.4700),
    ]

    # --------------------------------------------------------------------------
    # SYNTHETIC TEST ROUTE BETA (Simulating a corridor near a known black spot / lower infrastructure)
    # NOTE: Strictly for software testing. Not a real travel path.
    # --------------------------------------------------------------------------
    synthetic_route_beta = [
        (17.4800, 78.4100),
        (17.4842, 78.4138),  # Synthetic sample near Kukatpally Y-Junction black spot
        (17.4900, 78.4180),
        (17.4950, 78.4220),
    ]

    candidate_test_routes = [
        {
            "route_id": "Synthetic_Test_Route_Alpha",
            "coords": synthetic_route_alpha,
            "duration_min": 18.5,
        },
        {
            "route_id": "Synthetic_Test_Route_Beta",
            "coords": synthetic_route_beta,
            "duration_min": 24.0,
        },
    ]

    comparison_result = scorer.compare_routes(candidate_test_routes)

    print(f"\nRecommended Route: {comparison_result['recommended_route_id']}")
    print(f"Tier: {comparison_result['recommendation_tier']}")
    print("Comparative Rationale:")
    for point in comparison_result["comparative_rationale"]:
        print(f"  * {point}")

    print("\n" + "=" * 70)
    print("DETAILED ROUTE BREAKDOWN (Strictly Synthetic Test Results)")
    print("=" * 70)

    for r in comparison_result["routes"]:
        print(f"\n--- {r['route_id']} ---")
        print(f"  Distance: {r['route_distance_km']} km | Straight Line: {r['straight_distance_km']} km")
        print(f"  Safety Score: {r['safety_score']} / 100.0 [{r['comparative_tier']}]")
        print("  Normalized Components (Logical Order):")
        comp = r["components"]
        print(f"    1. S_police:     {comp['S_police']:.4f}")
        print(f"    2. S_medical:    {comp['S_medical']:.4f}")
        print(f"    3. S_transit:    {comp['S_transit']:.4f} (Contextual Proxy)")
        print(f"    4. S_arterial:   {comp['S_arterial']:.4f} (Contextual Proxy)")
        print(f"    5. P_crime:      {comp['P_crime']:.4f} (Penalty)")
        print(f"    6. P_blackspot:  {comp['P_blackspot']:.4f} (Road Hazard Penalty)")
        print(f"    7. P_exposure:   {comp['P_exposure']:.4f} (Detour Penalty)")
        print("  Score Contributions (Points out of 100):")
        for k, v in r["contributions"].items():
            print(f"    * {k}: {v:+.2f} pts")

    print("\n" + "=" * 70)
    print("DEMO COMPLETE: All calculations verified successfully.")
    print("=" * 70)


if __name__ == "__main__":
    run_demo()
