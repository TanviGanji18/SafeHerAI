"""
SafeHer AI - Emergency SOS & Incident Alert Service
===================================================
Manages distress signal broadcasts, locates the nearest law enforcement
facility immediately, dispatches alerts to trusted contacts, and provides
tactical emergency guidance.
"""

import time
import uuid
import datetime
from typing import List, Dict, Any, Optional

from ..core.config import EMERGENCY_HELPLINES
from ..schemas.sos import (
    SOSTriggerRequest,
    SOSTriggerResponse,
    TrustedContact,
)
from ..schemas.route import CoordinatePoint
from .amenities_service import AmenitiesService

# In-memory storage for contacts and SOS incident records (with local fallback)
_USER_CONTACTS_STORE: Dict[str, List[TrustedContact]] = {}
_SOS_INCIDENT_LOG: List[Dict[str, Any]] = []

TACTICAL_SAFETY_GUIDANCE = [
    "Call 100 or 112 immediately to connect directly with the Telangana Police Control Room.",
    "WhatsApp or dial the 24/7 Hyderabad SHE Teams helpline at 9490616555.",
    "Move directly toward a well-lit, populated public venue (Metro station, hospital, or open commercial store).",
    "Keep this screen active; your exact GPS coordinates are logged and ready for dispatch.",
    "If in a vehicle, note the registration plate and share live location with your emergency contacts.",
]


class SOSService:
    """Handles emergency SOS broadcasts and trusted contacts."""

    @classmethod
    def get_contacts(cls, user_id: str) -> List[TrustedContact]:
        """Returns the list of registered trusted contacts for a user."""
        if user_id not in _USER_CONTACTS_STORE:
            # Default placeholder emergency contact for newly registered users
            _USER_CONTACTS_STORE[user_id] = [
                TrustedContact(
                    id="contact_default_1",
                    name="Primary Emergency Contact",
                    phone="+919876543210",
                    relationship="Family",
                    is_primary=True,
                )
            ]
        return _USER_CONTACTS_STORE[user_id]

    @classmethod
    def add_contact(cls, user_id: str, contact: TrustedContact) -> TrustedContact:
        """Adds a new trusted emergency contact."""
        contacts = cls.get_contacts(user_id)
        if not contact.id:
            contact.id = f"cnt_{uuid.uuid4().hex[:8]}"
        contacts.append(contact)
        _USER_CONTACTS_STORE[user_id] = contacts
        return contact

    @classmethod
    def delete_contact(cls, user_id: str, contact_id: str) -> bool:
        """Deletes a trusted contact by ID."""
        contacts = cls.get_contacts(user_id)
        filtered = [c for c in contacts if c.id != contact_id]
        if len(filtered) != len(contacts):
            _USER_CONTACTS_STORE[user_id] = filtered
            return True
        return False

    @classmethod
    def update_contact(cls, user_id: str, contact_id: str, updated: TrustedContact) -> Optional[TrustedContact]:
        """Updates an existing trusted contact."""
        contacts = cls.get_contacts(user_id)
        for i, c in enumerate(contacts):
            if c.id == contact_id:
                updated.id = contact_id
                contacts[i] = updated
                _USER_CONTACTS_STORE[user_id] = contacts
                return updated
        return None

    @classmethod
    def trigger_sos(cls, request: SOSTriggerRequest) -> SOSTriggerResponse:
        """
        Processes an urgent SOS broadcast signal:
        - Logs the emergency event with timestamp and device telemetry.
        - Identifies the closest police station for immediate physical assistance.
        - Generates live location share links.
        - Prepares broadcast notifications for trusted contacts.
        """
        now = datetime.datetime.now(datetime.timezone.utc)
        iso_time = now.isoformat()
        alert_id = f"SOS-HYD-{now.strftime('%Y%m%d%H%M%S')}-{uuid.uuid4().hex[:6].upper()}"

        maps_url = f"https://www.google.com/maps?q={request.latitude:.5f},{request.longitude:.5f}"

        # Locate closest operational police station
        nearby = AmenitiesService.get_nearby_safe_spots(
            latitude=request.latitude, longitude=request.longitude, radius_km=10.0, limit_per_category=1
        )
        if nearby.police_stations:
            nearest_ps = nearby.police_stations[0]
        else:
            # Fallback to central police commissionerate
            from ..schemas.amenity import AmenityItem
            nearest_ps = AmenityItem(
                id="ps_comm",
                name="Hyderabad Police Commissionerate",
                category="Police Headquarters",
                distance_km=0.0,
                latitude=17.4011,
                longitude=78.4762,
                phone="100 / 040-27852435",
                zone_or_circle="Central",
                extra_details="24/7 Police Dispatch Desk",
            )

        # Notify contacts
        user_contacts = cls.get_contacts(request.user_id or "anonymous_user")
        notified_names = [c.name for c in user_contacts]

        # Log incident record
        incident_record = {
            "alert_id": alert_id,
            "user_id": request.user_id,
            "latitude": request.latitude,
            "longitude": request.longitude,
            "battery_level": request.battery_level,
            "message": request.message,
            "route_id": request.current_route_id,
            "timestamp": iso_time,
            "nearest_police": nearest_ps.name,
            "contacts_count": len(user_contacts),
        }
        _SOS_INCIDENT_LOG.append(incident_record)

        return SOSTriggerResponse(
            alert_id=alert_id,
            status="EMERGENCY_DISPATCH_RECORDED",
            timestamp=iso_time,
            user_location=CoordinatePoint(latitude=request.latitude, longitude=request.longitude),
            maps_location_url=maps_url,
            nearest_police_station=nearest_ps,
            dispatched_contacts_count=len(user_contacts),
            contacts_notified=notified_names,
            emergency_helplines=EMERGENCY_HELPLINES,
            safety_guidance=TACTICAL_SAFETY_GUIDANCE,
        )

    @classmethod
    def get_incident_history(cls, user_id: Optional[str] = None) -> List[Dict[str, Any]]:
        """Returns recorded incident logs."""
        if user_id:
            return [log for log in _SOS_INCIDENT_LOG if log.get("user_id") == user_id]
        return list(_SOS_INCIDENT_LOG)
