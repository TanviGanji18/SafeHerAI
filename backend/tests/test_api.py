"""
SafeHer AI – FastAPI Endpoint Tests
=====================================
Tests the REST API endpoints using FastAPI's TestClient (ASGI transport).

IMPORTANT:
All route coordinates used in these tests are SYNTHETIC TEST GEOMETRIES
generated solely for software testing purposes.
They are NOT real Hyderabad navigation routes.
They MUST NOT be used as project results or presented as real-world evaluations.
"""

import sys
import os
import unittest

# Ensure project root is discoverable
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

from fastapi.testclient import TestClient
from backend.app.main import app

client = TestClient(app, raise_server_exceptions=False)

# ---------------------------------------------------------------------------
# Synthetic test coordinate sets — SOFTWARE TESTING ONLY
# These coordinates are artificial and serve only to exercise the API pipeline.
# ---------------------------------------------------------------------------
SYNTHETIC_VALID_COORDS = [
    {"latitude": 17.4100, "longitude": 78.4500},
    {"latitude": 17.4150, "longitude": 78.4550},
    {"latitude": 17.4200, "longitude": 78.4600},
    {"latitude": 17.4250, "longitude": 78.4650},
]

SYNTHETIC_TWO_POINT_COORDS = [
    {"latitude": 17.3900, "longitude": 78.4600},
    {"latitude": 17.4000, "longitude": 78.4700},
]


class TestHealthEndpoint(unittest.TestCase):
    """Tests GET /health endpoint."""

    def test_health_returns_200(self):
        response = client.get("/health")
        self.assertEqual(response.status_code, 200)

    def test_health_response_structure(self):
        response = client.get("/health")
        body = response.json()
        self.assertIn("status", body)
        self.assertIn("service", body)
        self.assertEqual(body["status"], "ok")
        self.assertEqual(body["service"], "SafeHer AI backend")


class TestScoringEndpointValidRequests(unittest.TestCase):
    """Tests valid scoring requests return correct structure and bounded scores."""

    def test_valid_route_returns_200(self):
        payload = {
            "route_id": "synthetic_test_route",
            "route_coords": SYNTHETIC_VALID_COORDS,
        }
        response = client.post("/api/v1/safety/score", json=payload)
        self.assertEqual(response.status_code, 200)

    def test_valid_route_contains_safety_score(self):
        payload = {
            "route_id": "synthetic_test_route",
            "route_coords": SYNTHETIC_VALID_COORDS,
        }
        response = client.post("/api/v1/safety/score", json=payload)
        body = response.json()
        self.assertIn("safety_score", body)

    def test_safety_score_is_bounded_0_to_100(self):
        payload = {
            "route_id": "bounds_test",
            "route_coords": SYNTHETIC_VALID_COORDS,
        }
        response = client.post("/api/v1/safety/score", json=payload)
        body = response.json()
        score = body["safety_score"]
        self.assertGreaterEqual(score, 0.0)
        self.assertLessEqual(score, 100.0)

    def test_response_contains_all_required_fields(self):
        payload = {
            "route_id": "structure_test",
            "route_coords": SYNTHETIC_VALID_COORDS,
            "route_distance_km": 2.5,
            "route_duration_min": 12.0,
        }
        response = client.post("/api/v1/safety/score", json=payload)
        body = response.json()
        required_fields = [
            "route_id",
            "safety_score",
            "safety_tier",
            "route_distance_km",
            "straight_line_distance_km",
            "detour_ratio",
            "components",
            "contributions",
            "raw_features",
            "limitations_and_proxies",
        ]
        for field in required_fields:
            self.assertIn(field, body, msg=f"Missing required field: '{field}'")

    def test_components_follow_logical_order(self):
        payload = {
            "route_id": "component_order_test",
            "route_coords": SYNTHETIC_VALID_COORDS,
        }
        response = client.post("/api/v1/safety/score", json=payload)
        body = response.json()
        components = body["components"]
        expected_keys = [
            "S_police", "S_medical", "S_transit",
            "S_arterial", "P_crime", "P_blackspot", "P_exposure",
        ]
        for key in expected_keys:
            self.assertIn(key, components, msg=f"Missing component key: '{key}'")

    def test_component_values_are_bounded_0_to_1(self):
        payload = {
            "route_id": "component_bounds_test",
            "route_coords": SYNTHETIC_VALID_COORDS,
        }
        response = client.post("/api/v1/safety/score", json=payload)
        body = response.json()
        for key, val in body["components"].items():
            self.assertGreaterEqual(val, 0.0, msg=f"{key} below 0")
            self.assertLessEqual(val, 1.0, msg=f"{key} above 1")

    def test_safety_tier_is_valid_string(self):
        payload = {
            "route_id": "tier_test",
            "route_coords": SYNTHETIC_VALID_COORDS,
        }
        response = client.post("/api/v1/safety/score", json=payload)
        body = response.json()
        valid_tiers = [
            "Comparatively Safer Route",
            "Moderate Safety Corridor",
            "Caution Advised Corridor",
        ]
        self.assertIn(body["safety_tier"], valid_tiers)

    def test_limitations_and_proxies_is_non_empty_list(self):
        payload = {
            "route_id": "limitations_test",
            "route_coords": SYNTHETIC_VALID_COORDS,
        }
        response = client.post("/api/v1/safety/score", json=payload)
        body = response.json()
        self.assertIsInstance(body["limitations_and_proxies"], list)
        self.assertGreater(len(body["limitations_and_proxies"]), 0)

    def test_two_point_route_is_accepted(self):
        payload = {
            "route_id": "two_point_test",
            "route_coords": SYNTHETIC_TWO_POINT_COORDS,
        }
        response = client.post("/api/v1/safety/score", json=payload)
        self.assertEqual(response.status_code, 200)

    def test_optional_fields_can_be_omitted(self):
        payload = {
            "route_coords": SYNTHETIC_VALID_COORDS,
        }
        response = client.post("/api/v1/safety/score", json=payload)
        self.assertEqual(response.status_code, 200)


class TestScoringEndpointInvalidRequests(unittest.TestCase):
    """Tests invalid inputs are rejected with appropriate 4xx responses."""

    def test_missing_route_coords_returns_422(self):
        payload = {"route_id": "missing_coords"}
        response = client.post("/api/v1/safety/score", json=payload)
        self.assertEqual(response.status_code, 422)

    def test_empty_route_coords_returns_422(self):
        payload = {"route_coords": []}
        response = client.post("/api/v1/safety/score", json=payload)
        self.assertEqual(response.status_code, 422)

    def test_single_coordinate_returns_422(self):
        payload = {
            "route_coords": [{"latitude": 17.4100, "longitude": 78.4500}]
        }
        response = client.post("/api/v1/safety/score", json=payload)
        self.assertEqual(response.status_code, 422)

    def test_latitude_out_of_range_returns_422(self):
        # Latitude > 90 is invalid
        payload = {
            "route_coords": [
                {"latitude": 95.0, "longitude": 78.4500},
                {"latitude": 17.4200, "longitude": 78.4600},
            ]
        }
        response = client.post("/api/v1/safety/score", json=payload)
        self.assertEqual(response.status_code, 422)

    def test_longitude_out_of_range_returns_422(self):
        # Longitude > 180 is invalid
        payload = {
            "route_coords": [
                {"latitude": 17.4100, "longitude": 200.0},
                {"latitude": 17.4200, "longitude": 78.4600},
            ]
        }
        response = client.post("/api/v1/safety/score", json=payload)
        self.assertEqual(response.status_code, 422)

    def test_string_coordinates_return_422(self):
        # String values instead of floats
        payload = {
            "route_coords": [
                {"latitude": "not_a_number", "longitude": "also_invalid"},
                {"latitude": 17.4200, "longitude": 78.4600},
            ]
        }
        response = client.post("/api/v1/safety/score", json=payload)
        self.assertEqual(response.status_code, 422)

    def test_missing_latitude_field_returns_422(self):
        payload = {
            "route_coords": [
                {"longitude": 78.4500},       # latitude missing
                {"latitude": 17.4200, "longitude": 78.4600},
            ]
        }
        response = client.post("/api/v1/safety/score", json=payload)
        self.assertEqual(response.status_code, 422)

    def test_validation_error_response_contains_detail(self):
        payload = {"route_coords": []}
        response = client.post("/api/v1/safety/score", json=payload)
        body = response.json()
        # Should be clean structured JSON, not a Python traceback
        self.assertNotIn("Traceback", str(body))
        self.assertNotIn("backend\\app", str(body))


if __name__ == "__main__":
    unittest.main()
