"""
SafeHer AI - Journey & Feedback Service
=======================================
Manages active navigation journeys, records telemetry and emergency SOS events,
persists completed journey feedback into Firebase Firestore and structured feedback
datasets for future periodic ML model analysis and retraining.
"""

import os
import csv
import uuid
import datetime
from typing import List, Dict, Any, Optional

from ..schemas.journey import (
    JourneyStartRequest,
    JourneyStartResponse,
    JourneyEventRequest,
    JourneyEventResponse,
    JourneyCompleteRequest,
    JourneyCompleteResponse,
    FeedbackDatasetItem,
)
from ..services.auth_service import _init_firebase_if_possible

# In-memory journey registry
_ACTIVE_JOURNEYS: Dict[str, Dict[str, Any]] = {}
_JOURNEY_EVENTS: Dict[str, List[Dict[str, Any]]] = {}

# Feedback dataset file path for future model learning
DATASETS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "datasets"))
FEEDBACK_DATASET_CSV = os.path.join(DATASETS_DIR, "journey_feedback.csv")


def _ensure_feedback_dataset_exists():
    """Initializes the feedback dataset CSV with headers if it does not yet exist."""
    if not os.path.exists(FEEDBACK_DATASET_CSV):
        try:
            with open(FEEDBACK_DATASET_CSV, mode="w", newline="", encoding="utf-8") as f:
                writer = csv.writer(f)
                writer.writerow([
                    "journey_id",
                    "timestamp",
                    "user_id",
                    "origin_name",
                    "destination_name",
                    "route_id",
                    "distance_km",
                    "duration_min",
                    "safety_score",
                    "route_experience",
                    "issues",
                    "comments",
                    "emergency_occurred",
                ])
        except Exception as e:
            print(f"[JourneyService] Note: Could not create feedback CSV header: {e}")


_ensure_feedback_dataset_exists()


class JourneyService:
    """Handles the lifecycle of safe navigation journeys and feedback storage."""

    @classmethod
    def start_journey(cls, request: JourneyStartRequest) -> JourneyStartResponse:
        """Starts an active journey, stores its initial parameters, and returns a unique journey ID."""
        now = datetime.datetime.now(datetime.timezone.utc)
        iso_start = request.start_time or now.isoformat()
        journey_id = f"JRN-HYD-{now.strftime('%Y%m%d%H%M%S')}-{uuid.uuid4().hex[:6].upper()}"

        record = {
            "journey_id": journey_id,
            "user_id": request.user_id,
            "origin": request.origin,
            "destination": request.destination,
            "selected_route_id": request.selected_route_id,
            "route_summary": request.route_summary,
            "distance_km": request.distance_km,
            "duration_min": request.duration_min,
            "safety_score": request.safety_score,
            "safety_tier": request.safety_tier,
            "is_recommended_safer": request.is_recommended_safer,
            "polyline_coords": request.polyline_coords or [],
            "contributions": request.contributions or {},
            "raw_features": request.raw_features or {},
            "start_time": iso_start,
            "end_time": None,
            "status": "active",
            "emergency_occurred": False,
            "events": [],
            "feedback": None,
        }

        _ACTIVE_JOURNEYS[journey_id] = record
        _JOURNEY_EVENTS[journey_id] = []

        # Optional Firestore synchronization if Firebase is configured
        cls._sync_to_firestore_if_available("journeys", journey_id, record)

        return JourneyStartResponse(
            journey_id=journey_id,
            user_id=request.user_id,
            status="active",
            start_time=iso_start,
            message="Active navigation journey initiated successfully.",
        )

    @classmethod
    def record_event(cls, request: JourneyEventRequest) -> JourneyEventResponse:
        """Records an event occurring during an active journey (e.g., SOS trigger or waypoint)."""
        now = datetime.datetime.now(datetime.timezone.utc)
        iso_time = request.timestamp or now.isoformat()
        event_id = f"EVT-{uuid.uuid4().hex[:8]}"

        event_data = {
            "event_id": event_id,
            "journey_id": request.journey_id,
            "event_type": request.event_type,
            "latitude": request.latitude,
            "longitude": request.longitude,
            "timestamp": iso_time,
            "details": request.details or {},
        }

        if request.journey_id in _ACTIVE_JOURNEYS:
            journey = _ACTIVE_JOURNEYS[request.journey_id]
            if request.event_type in ("sos", "sos_trigger", "emergency"):
                journey["emergency_occurred"] = True
            journey["events"].append(event_data)

        if request.journey_id not in _JOURNEY_EVENTS:
            _JOURNEY_EVENTS[request.journey_id] = []
        _JOURNEY_EVENTS[request.journey_id].append(event_data)

        return JourneyEventResponse(
            journey_id=request.journey_id,
            event_id=event_id,
            event_type=request.event_type,
            recorded_at=iso_time,
            status="recorded",
        )

    @classmethod
    def complete_journey(cls, request: JourneyCompleteRequest) -> JourneyCompleteResponse:
        """
        Completes an active journey, stores user feedback, and appends the record
        to the feedback dataset for future periodic analysis and model improvement.
        """
        now = datetime.datetime.now(datetime.timezone.utc)
        iso_end = request.end_time or now.isoformat()

        journey = _ACTIVE_JOURNEYS.get(request.journey_id, {})
        journey["end_time"] = iso_end
        journey["status"] = request.completed_status

        # Extract origin and destination display names
        orig_data = journey.get("origin", {})
        origin_name = orig_data.get("address") or orig_data.get("name") or "Origin"

        dest_data = journey.get("destination", {})
        destination_name = dest_data.get("address") or dest_data.get("name") or "Destination"

        feedback_data = {
            "route_experience": request.route_experience,
            "issues_noticed": request.issues_noticed or [],
            "comments": request.comments,
            "submitted_at": iso_end,
        }
        journey["feedback"] = feedback_data

        # Append to feedback dataset CSV for future periodic retraining
        feedback_saved = False
        try:
            with open(FEEDBACK_DATASET_CSV, mode="a", newline="", encoding="utf-8") as f:
                writer = csv.writer(f)
                writer.writerow([
                    request.journey_id,
                    iso_end,
                    journey.get("user_id", "anonymous_user"),
                    origin_name,
                    destination_name,
                    journey.get("selected_route_id", "unknown_route"),
                    journey.get("distance_km", 0.0),
                    journey.get("duration_min", 0.0),
                    journey.get("safety_score", 0.0),
                    request.route_experience or "Unspecified",
                    ";".join(request.issues_noticed or []),
                    (request.comments or "").replace("\n", " "),
                    journey.get("emergency_occurred", False),
                ])
            feedback_saved = True
        except Exception as err:
            print(f"[JourneyService] Error saving feedback to CSV dataset: {err}")

        # Sync completed journey & feedback to Firestore if enabled
        cls._sync_to_firestore_if_available("journeys", request.journey_id, journey)
        if request.route_experience or request.issues_noticed or request.comments:
            cls._sync_to_firestore_if_available("journey_feedback", request.journey_id, {
                "journey_id": request.journey_id,
                "user_id": journey.get("user_id", "anonymous_user"),
                "timestamp": iso_end,
                "feedback": feedback_data,
                "route_id": journey.get("selected_route_id"),
                "safety_score": journey.get("safety_score"),
                "emergency_occurred": journey.get("emergency_occurred", False),
            })

        return JourneyCompleteResponse(
            journey_id=request.journey_id,
            status=request.completed_status,
            feedback_saved=feedback_saved,
            feedback_dataset_entry_id=request.journey_id,
            message="Journey completed and feedback recorded for future safety analysis.",
        )

    @classmethod
    def get_journey(cls, journey_id: str) -> Optional[Dict[str, Any]]:
        """Retrieves stored journey details."""
        return _ACTIVE_JOURNEYS.get(journey_id)

    @classmethod
    def get_user_journeys(cls, user_id: str) -> List[Dict[str, Any]]:
        """Retrieves stored journey records for a user from in-memory store and Firestore."""
        journeys = [j for j in _ACTIVE_JOURNEYS.values() if j.get("user_id") == user_id]
        try:
            if _init_firebase_if_possible():
                from firebase_admin import firestore
                db = firestore.client()
                docs = db.collection("journeys").where("user_id", "==", user_id).stream()
                existing_ids = {j.get("journey_id") for j in journeys}
                for doc in docs:
                    data = doc.to_dict()
                    if data and data.get("journey_id") not in existing_ids:
                        journeys.append(data)
                        existing_ids.add(data.get("journey_id"))
        except Exception:
            pass
        journeys.sort(key=lambda x: str(x.get("start_time", "")), reverse=True)
        return journeys

    @classmethod
    def get_all_feedback_dataset(cls) -> List[Dict[str, Any]]:
        """Reads and returns the compiled feedback dataset records for periodic analysis."""
        records = []
        if os.path.exists(FEEDBACK_DATASET_CSV):
            try:
                with open(FEEDBACK_DATASET_CSV, mode="r", encoding="utf-8") as f:
                    reader = csv.DictReader(f)
                    for row in reader:
                        records.append(dict(row))
            except Exception as e:
                print(f"[JourneyService] Error reading feedback dataset: {e}")
        return records

    @staticmethod
    def _sync_to_firestore_if_available(collection: str, doc_id: str, data: Dict[str, Any]):
        """Persists document to Firestore if Firebase Admin SDK is initialized."""
        try:
            if _init_firebase_if_possible():
                from firebase_admin import firestore
                db = firestore.client()
                db.collection(collection).document(doc_id).set(data, merge=True)
        except Exception as e:
            # Non-blocking fallback: in-memory and CSV datasets ensure reliability even without active cloud keys
            pass
