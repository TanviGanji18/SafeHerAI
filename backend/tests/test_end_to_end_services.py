"""
SafeHer AI - End-to-End Services Integration Tests
===================================================
Tests all newly added features:
- Route planning & multi-route scoring (POST /api/v1/routes/plan)
- Places autocomplete (GET /api/v1/places/autocomplete)
- Nearby safe spots (GET /api/v1/safety/nearby-safe-spots)
- Emergency SOS broadcast (POST /api/v1/sos/trigger)
- Trusted contacts management (GET/POST /api/v1/user/contacts)
- Authentication (POST /api/v1/auth/register, /login, /firebase)
- Polyline encoder/decoder utility functions
"""

import sys
import os
import unittest

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

from fastapi.testclient import TestClient
from backend.app.main import app
from backend.app.services.navigation_service import decode_polyline, encode_polyline

client = TestClient(app, raise_server_exceptions=False)


class TestPolylineUtilities(unittest.TestCase):
    """Verifies pure-Python polyline encoding and decoding."""

    def test_polyline_encode_decode_symmetry(self):
        original_points = [
            (17.41000, 78.45000),
            (17.41500, 78.45500),
            (17.42000, 78.46000),
        ]
        encoded = encode_polyline(original_points)
        self.assertIsInstance(encoded, str)
        self.assertGreater(len(encoded), 0)

        decoded = decode_polyline(encoded)
        self.assertEqual(len(decoded), len(original_points))
        for p_orig, p_dec in zip(original_points, decoded):
            self.assertAlmostEqual(p_orig[0], p_dec[0], places=4)
            self.assertAlmostEqual(p_orig[1], p_dec[1], places=4)


class TestNavigationAndRoutePlanning(unittest.TestCase):
    """Tests the /api/v1/routes/plan endpoint."""

    def test_plan_routes_with_coordinates(self):
        payload = {
            "origin": {"latitude": 17.4100, "longitude": 78.4500},
            "destination": {"latitude": 17.4400, "longitude": 78.4800},
            "travel_mode": "driving",
            "alternatives": True,
        }
        response = client.post("/api/v1/routes/plan", json=payload)
        self.assertEqual(response.status_code, 200)

        data = response.json()
        self.assertIn("routes", data)
        self.assertGreater(len(data["routes"]), 0)
        self.assertIn("recommended_safer_route_id", data)
        self.assertIn("fastest_route_id", data)
        self.assertIn("comparative_rationale", data)

        # Inspect the recommended route
        rec_id = data["recommended_safer_route_id"]
        rec_route = next(r for r in data["routes"] if r["route_id"] == rec_id)
        self.assertTrue(0.0 <= rec_route["safety_score"] <= 100.0)
        self.assertIn(rec_route["safety_tier"], [
            "Comparatively Safer Route",
            "Moderate Safety Corridor",
            "Caution Advised Corridor",
        ])
        self.assertGreater(len(rec_route["polyline_coords"]), 1)
        self.assertIsNotNone(rec_route["encoded_polyline"])

    def test_plan_routes_with_landmark_names(self):
        payload = {
            "origin": {"address": "Secunderabad Railway Station"},
            "destination": {"address": "Charminar, Old City"},
            "travel_mode": "driving",
        }
        response = client.post("/api/v1/routes/plan", json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("Secunderabad", data["origin_name"])
        self.assertIn("Charminar", data["destination_name"])
        self.assertGreaterEqual(len(data["routes"]), 1)

    def test_navigation_maneuver_distances_are_realistic_and_non_negative(self):
        """Regression test ensuring route steps have realistic, positive distances within Hyderabad."""
        payload = {
            "origin": {"address": "Secunderabad Railway Station"},
            "destination": {"address": "Charminar, Old City"},
            "travel_mode": "driving",
        }
        response = client.post("/api/v1/routes/plan", json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        routes = data["routes"]
        self.assertGreater(len(routes), 0)

        for route in routes:
            steps = route.get("steps", [])
            self.assertGreater(len(steps), 0, "Route must contain navigation steps")
            total_route_m = route["distance_km"] * 1000.0

            # Step 0 (depart) must have a realistic non-negative distance
            first_step = steps[0]
            self.assertGreaterEqual(first_step["distance_meters"], 0.0)
            self.assertLessEqual(first_step["distance_meters"], total_route_m)
            # Ensure not an astronomical or transatlantic distance like 13545 km
            self.assertLess(first_step["distance_meters"], 50000.0)

            # Check coordinate bounds (Hyderabad: lat ~ 17.x, lon ~ 78.x)
            for s in steps:
                self.assertGreaterEqual(s["distance_meters"], 0.0)
                self.assertTrue(17.0 <= s["latitude"] <= 18.0, f"Latitude {s['latitude']} outside Hyderabad")
                self.assertTrue(78.0 <= s["longitude"] <= 79.0, f"Longitude {s['longitude']} outside Hyderabad")

    def test_autocomplete_places(self):
        response = client.get("/api/v1/places/autocomplete?q=Hitec")
        self.assertEqual(response.status_code, 200)
        suggestions = response.json()
        self.assertIsInstance(suggestions, list)
        self.assertGreater(len(suggestions), 0)
        self.assertIn("Hitec", suggestions[0]["description"])

    def test_reverse_geocode_endpoint(self):
        # Coordinates near Charminar (17.3616, 78.4747)
        response = client.get("/api/v1/places/reverse-geocode?lat=17.3616&lon=78.4747")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("address", data)
        self.assertIn("Charminar", data["address"])
        self.assertEqual(data["latitude"], 17.3616)
        self.assertEqual(data["longitude"], 78.4747)

    def test_plan_routes_invalid_address_returns_400(self):
        payload = {
            "origin": {"address": "NonExistentPlaceXYZ987654321"},
            "destination": {"address": "Charminar, Old City"},
            "travel_mode": "driving",
        }
        response = client.post("/api/v1/routes/plan", json=payload)
        self.assertEqual(response.status_code, 400)
        self.assertIn("Unable to locate", response.json()["detail"])


class TestNearbySafeSpots(unittest.TestCase):
    """Tests /api/v1/safety/nearby-safe-spots endpoint."""

    def test_nearby_safe_spots_returns_infrastructure(self):
        # Query near Banjara Hills / Panjagutta
        response = client.get("/api/v1/safety/nearby-safe-spots?lat=17.4260&lon=78.4526&radius_km=5.0")
        self.assertEqual(response.status_code, 200)
        data = response.json()

        self.assertIn("police_stations", data)
        self.assertIn("hospitals", data)
        self.assertIn("transit_stations", data)
        self.assertIn("accident_blackspots", data)
        self.assertIn("emergency_helplines", data)

        self.assertGreater(len(data["police_stations"]), 0)
        self.assertGreater(len(data["hospitals"]), 0)
        self.assertGreater(len(data["transit_stations"]), 0)

        # Check police station properties
        ps = data["police_stations"][0]
        self.assertIn("name", ps)
        self.assertIn("distance_km", ps)
        self.assertLessEqual(ps["distance_km"], 5.0)


class TestEmergencySOS(unittest.TestCase):
    """Tests /api/v1/sos/trigger and contacts endpoints."""

    def test_trigger_sos_event(self):
        payload = {
            "user_id": "test_user_emergency",
            "latitude": 17.4200,
            "longitude": 78.4500,
            "battery_level": 75,
            "message": "Testing emergency broadcast",
        }
        response = client.post("/api/v1/sos/trigger", json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()

        self.assertIn("alert_id", data)
        self.assertTrue(data["alert_id"].startswith("SOS-HYD-"))
        self.assertIn("maps_location_url", data)
        self.assertIn("nearest_police_station", data)
        self.assertGreater(len(data["safety_guidance"]), 0)
        self.assertIn("100", str(data["emergency_helplines"]))

    def test_contacts_management(self):
        # Add contact
        new_contact = {
            "name": "Trusted Sister",
            "phone": "+919123456789",
            "relationship": "Sister",
            "is_primary": True,
        }
        post_resp = client.post("/api/v1/user/contacts?user_id=usr_test_1", json=new_contact)
        self.assertEqual(post_resp.status_code, 201)

        # List contacts
        get_resp = client.get("/api/v1/user/contacts?user_id=usr_test_1")
        self.assertEqual(get_resp.status_code, 200)
        contacts = get_resp.json()
        self.assertTrue(any(c["name"] == "Trusted Sister" for c in contacts))


class TestUserAuthentication(unittest.TestCase):
    """Tests /api/v1/auth/ endpoints."""

    def test_user_registration_and_login(self):
        test_email = f"user_{os.getpid()}@example.com"
        reg_payload = {
            "email": test_email,
            "password": "securePassword123!",
            "full_name": "Priya Sharma",
            "phone": "+919876543210",
        }
        reg_resp = client.post("/api/v1/auth/register", json=reg_payload)
        self.assertEqual(reg_resp.status_code, 201)
        reg_data = reg_resp.json()
        self.assertIn("access_token", reg_data)
        self.assertEqual(reg_data["user"]["full_name"], "Priya Sharma")

        # Login with same credentials
        login_payload = {
            "email": test_email,
            "password": "securePassword123!",
        }
        login_resp = client.post("/api/v1/auth/login", json=login_payload)
        self.assertEqual(login_resp.status_code, 200)
        login_data = login_resp.json()
        self.assertIn("access_token", login_data)

    def test_firebase_auth_endpoint(self):
        fb_payload = {"id_token": "mock_firebase_id_token_test"}
        response = client.post("/api/v1/auth/firebase", json=fb_payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("access_token", data)


if __name__ == "__main__":
    unittest.main()
