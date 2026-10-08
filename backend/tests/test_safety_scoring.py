"""
Unit Tests for SafeHer AI Safety Scoring Engine
================================================
Verifies mathematical correctness of normalization, bounds enforcement [0, 100],
spatial feature calculations, and route comparison ranking using Python's
built-in unittest framework.
"""

import sys
import os
import unittest

# Ensure project root is in sys.path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

from backend.app.ml.normalization import (
    clamp,
    normalize_police,
    normalize_medical,
    normalize_transit,
    normalize_arterial,
    normalize_crime,
    normalize_blackspot,
    normalize_exposure,
    calculate_safety_score,
)
from backend.app.ml.spatial_features import (
    haversine_km,
    polyline_length_km,
    sample_polyline,
)
from backend.app.ml.safety_scorer import SafetyScorer


class TestMathematicalNormalization(unittest.TestCase):
    """Tests normalization functions for every individual component."""

    def test_clamp_function(self):
        self.assertEqual(clamp(0.5, 0.0, 1.0), 0.5)
        self.assertEqual(clamp(-0.2, 0.0, 1.0), 0.0)
        self.assertEqual(clamp(1.5, 0.0, 1.0), 1.0)
        self.assertEqual(clamp(120.0, 0.0, 100.0), 100.0)
        self.assertEqual(clamp(-10.0, 0.0, 100.0), 0.0)

    def test_normalize_police(self):
        # Perfect accessibility: 0 km distance, 3 stations nearby
        self.assertEqual(normalize_police(0.0, 3), 1.0)
        # Beyond threshold distance: 4.5 km distance, 0 stations
        self.assertEqual(normalize_police(4.5, 0), 0.0)
        # Intermediate values
        score = normalize_police(2.0, 1)
        expected = 0.70 * (1.0 - 2.0 / 4.0) + 0.30 * (1.0 / 3.0)
        self.assertAlmostEqual(score, expected, places=4)
        self.assertTrue(0.0 <= score <= 1.0)

    def test_normalize_medical(self):
        # 0 distance to hospital
        self.assertEqual(normalize_medical(0.0), 1.0)
        # 1.5 km distance
        self.assertAlmostEqual(normalize_medical(1.5), 0.5, places=4)
        # 3.5 km distance (beyond 3.0 km threshold)
        self.assertEqual(normalize_medical(3.5), 0.0)

    def test_normalize_transit(self):
        # High transit density (6 stops / 1 km)
        self.assertEqual(normalize_transit(6, 1.0), 1.0)
        # Medium transit density (3 stops / 1 km)
        self.assertAlmostEqual(normalize_transit(3, 1.0), 0.5, places=4)
        # Zero transit stops
        self.assertEqual(normalize_transit(0, 5.0), 0.0)

    def test_normalize_arterial(self):
        # 100% on primary road
        self.assertEqual(normalize_arterial(5.0, 5.0), 1.0)
        # 50% on primary road
        self.assertAlmostEqual(normalize_arterial(2.5, 5.0), 0.5, places=4)
        # 0% on primary road
        self.assertEqual(normalize_arterial(0.0, 5.0), 0.0)

    def test_normalize_crime(self):
        self.assertEqual(normalize_crime(0.0), 0.0)
        self.assertEqual(normalize_crime(0.55), 0.55)
        self.assertEqual(normalize_crime(1.0), 1.0)
        self.assertEqual(normalize_crime(1.5), 1.0)  # Clamped

    def test_normalize_blackspot(self):
        # 0 black spots
        self.assertEqual(normalize_blackspot(0), 0.0)
        # 1 black spot (+0.50)
        self.assertEqual(normalize_blackspot(1), 0.50)
        # 2 black spots (+1.00)
        self.assertEqual(normalize_blackspot(2), 1.00)
        # 3 black spots (clamped at 1.00)
        self.assertEqual(normalize_blackspot(3), 1.00)

    def test_normalize_exposure(self):
        # Direct route: detour ratio 1.1 (< 1.25 baseline)
        self.assertEqual(normalize_exposure(11.0, 10.0), 0.0)
        # Detour ratio 1.75
        expected = (1.75 - 1.25) / 1.00
        self.assertAlmostEqual(normalize_exposure(17.5, 10.0), expected, places=4)
        # Heavy winding route: detour ratio 2.50 (> 2.25)
        self.assertEqual(normalize_exposure(25.0, 10.0), 1.0)


class TestScoreRangeAndBounds(unittest.TestCase):
    """Verifies strict 0-100 clamping and mathematical proofs."""

    def test_best_case_scenario(self):
        # All positive components = 1.0, all penalties = 0.0
        result = calculate_safety_score(
            s_police=1.0,
            s_medical=1.0,
            s_transit=1.0,
            s_arterial=1.0,
            p_crime=0.0,
            p_blackspot=0.0,
            p_exposure=0.0,
        )
        self.assertEqual(result["safety_score"], 100.0)
        self.assertEqual(result["comparative_tier"], "Comparatively Safer Route")

    def test_worst_case_scenario(self):
        # All positive components = 0.0, all penalties = 1.0
        result = calculate_safety_score(
            s_police=0.0,
            s_medical=0.0,
            s_transit=0.0,
            s_arterial=0.0,
            p_crime=1.0,
            p_blackspot=1.0,
            p_exposure=1.0,
        )
        self.assertEqual(result["safety_score"], 0.0)
        self.assertEqual(result["comparative_tier"], "Caution Advised Corridor")

    def test_intermediate_score(self):
        # Balanced intermediate test
        result = calculate_safety_score(
            s_police=0.60,
            s_medical=0.70,
            s_transit=0.50,
            s_arterial=0.80,
            p_crime=0.20,
            p_blackspot=0.0,
            p_exposure=0.10,
        )
        score = result["safety_score"]
        self.assertTrue(0.0 <= score <= 100.0)
        sum_pts = sum(result["contributions"].values())
        self.assertAlmostEqual(score, sum_pts, delta=0.2)


class TestSpatialGeometry(unittest.TestCase):
    """Verifies Haversine and polyline utilities."""

    def test_haversine_known_distance(self):
        # Charminar (17.3616, 78.4747) to Secunderabad Station (17.4334, 78.5015)
        # Expected great-circle distance is ~8.4 km
        d = haversine_km(17.3616, 78.4747, 17.4334, 78.5015)
        self.assertTrue(8.0 < d < 9.0)

    def test_polyline_sampling(self):
        line = [(17.3616, 78.4747), (17.4334, 78.5015)]
        samples = sample_polyline(line, step_km=0.5)
        self.assertTrue(len(samples) > 10)
        self.assertEqual(samples[0], line[0])
        self.assertEqual(samples[-1], line[-1])


class TestScorerIntegration(unittest.TestCase):
    """Tests the full SafetyScorer pipeline using real datasets."""

    def test_scorer_synthetic_routes_comparison(self):
        scorer = SafetyScorer()

        # Two synthetic test polylines in Hyderabad (for software testing only)
        synth_route_central = [
            (17.4000, 78.4500),
            (17.4100, 78.4600),
            (17.4200, 78.4700),
        ]
        synth_route_peripheral = [
            (17.5800, 78.2000),
            (17.5900, 78.2100),
            (17.6000, 78.2200),
        ]

        eval_1 = scorer.score_route(synth_route_central, route_id="Test_Central")
        eval_2 = scorer.score_route(synth_route_peripheral, route_id="Test_Peripheral")

        self.assertTrue(0.0 <= eval_1["safety_score"] <= 100.0)
        self.assertTrue(0.0 <= eval_2["safety_score"] <= 100.0)
        self.assertIn("components", eval_1)
        self.assertIn("contributions", eval_1)

        comparison = scorer.compare_routes([
            {"route_id": "Test_Central", "coords": synth_route_central},
            {"route_id": "Test_Peripheral", "coords": synth_route_peripheral},
        ])

        self.assertIn("recommended_route_id", comparison)
        self.assertEqual(len(comparison["routes"]), 2)


if __name__ == "__main__":
    unittest.main()
