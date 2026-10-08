"""
SafeHer AI - Journey & Feedback API Integration Tests
======================================================
Tests the full lifecycle of navigation journeys:
1. Journey start (POST /api/v1/journey/start)
2. Journey telemetry / SOS event logging (POST /api/v1/journey/event)
3. Journey completion and feedback submission (POST /api/v1/journey/complete)
4. Feedback dataset retrieval for future model learning (GET /api/v1/journey/feedback)
"""

import unittest
from fastapi.testclient import TestClient

from backend.app.main import app

client = TestClient(app)


class TestJourneyEndpoints(unittest.TestCase):
    """Test suite for Journey lifecycle and feedback collection."""

    def test_complete_journey_lifecycle(self):
        # 1. Start Journey
        start_payload = {
            "user_id": "test_user_001",
            "origin": {"address": "Secunderabad Railway Station", "lat": 17.4334, "lon": 78.5015},
            "destination": {"address": "Charminar, Old City", "lat": 17.3616, "lon": 78.4747},
            "selected_route_id": "Route_A_Safer",
            "route_summary": "Safer Route via Arterial Corridor",
            "distance_km": 11.8,
            "duration_min": 23.0,
            "safety_score": 85.8,
            "safety_tier": "High Safety",
            "is_recommended_safer": True,
            "polyline_coords": [
                {"latitude": 17.4334, "longitude": 78.5015},
                {"latitude": 17.3616, "longitude": 78.4747},
            ],
            "contributions": {"police_pts": 23.5, "medical_pts": 14.8},
            "raw_features": {"avg_police_dist_km": 0.35, "blackspot_count": 0},
        }

        resp_start = client.post("/api/v1/journey/start", json=start_payload)
        self.assertEqual(resp_start.status_code, 201)
        data_start = resp_start.json()
        self.assertIn("journey_id", data_start)
        self.assertEqual(data_start["status"], "active")
        journey_id = data_start["journey_id"]

        # 2. Log an SOS event during journey
        event_payload = {
            "journey_id": journey_id,
            "event_type": "sos_trigger",
            "latitude": 17.4000,
            "longitude": 78.4800,
            "details": {"battery": 82, "triggered_by": "user_button"},
        }
        resp_event = client.post("/api/v1/journey/event", json=event_payload)
        self.assertEqual(resp_event.status_code, 200)
        data_event = resp_event.json()
        self.assertEqual(data_event["status"], "recorded")

        # 3. Complete Journey with User Feedback
        complete_payload = {
            "journey_id": journey_id,
            "completed_status": "completed",
            "final_distance_km": 11.8,
            "route_experience": "Comfortable",
            "issues_noticed": ["Poor lighting"],
            "comments": "Felt secure along Tank Bund road with visible police patrols.",
        }
        resp_complete = client.post("/api/v1/journey/complete", json=complete_payload)
        self.assertEqual(resp_complete.status_code, 200)
        data_complete = resp_complete.json()
        self.assertEqual(data_complete["status"], "completed")
        self.assertTrue(data_complete["feedback_saved"])

        # 4. Query Feedback Dataset
        resp_feedback = client.get("/api/v1/journey/feedback")
        self.assertEqual(resp_feedback.status_code, 200)
        dataset = resp_feedback.json()
        self.assertIsInstance(dataset, list)
        self.assertTrue(any(item.get("journey_id") == journey_id for item in dataset))


if __name__ == "__main__":
    unittest.main()
