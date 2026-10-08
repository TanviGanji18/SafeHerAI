"""
SafeHer AI - Application Configuration
======================================
Loads environment variables and system settings for Google Maps APIs,
Firebase credentials, server host/port, and datasets directories.
Provides safe defaults so the application operates seamlessly in offline/development mode.
"""

import os
from typing import Optional

# Base directories
APP_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BACKEND_DIR = os.path.abspath(os.path.join(APP_DIR, ".."))
ROOT_DIR = os.path.abspath(os.path.join(BACKEND_DIR, ".."))
DATASETS_DIR = os.path.join(ROOT_DIR, "datasets")

# Environment variables
GOOGLE_MAPS_API_KEY: str = os.getenv("GOOGLE_MAPS_API_KEY", "")
_default_firebase_cred = os.path.join(ROOT_DIR, "firebase-service-account.json")
FIREBASE_CREDENTIALS_PATH: str = os.getenv(
    "FIREBASE_CREDENTIALS_PATH",
    _default_firebase_cred if os.path.exists(_default_firebase_cred) else "",
)

JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY", "safeherai_secret_key_hyderabad_2026_safe_routes")
JWT_ALGORITHM: str = "HS256"
JWT_EXPIRATION_HOURS: int = int(os.getenv("JWT_EXPIRATION_HOURS", "72"))

HOST: str = os.getenv("HOST", "0.0.0.0")
PORT: int = int(os.getenv("PORT", "8000"))
DEBUG: bool = os.getenv("DEBUG", "True").lower() in ("true", "1", "yes")

# Emergency contact numbers (Official Telangana & National Helplines)
EMERGENCY_HELPLINES = {
    "national_emergency": {"name": "National Emergency Helpline", "number": "112"},
    "police": {"name": "Telangana Police", "number": "100"},
    "she_teams": {"name": "Hyderabad SHE Teams", "number": "9490616555"},
    "women_helpline": {"name": "Women Helpline (All India)", "number": "181"},
    "traffic_police": {"name": "Hyderabad Traffic Police Helpdesk", "number": "04027852482"},
    "ambulance": {"name": "Medical Emergency (Ambulance)", "number": "108"},
}
