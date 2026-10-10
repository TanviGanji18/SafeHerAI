"""
SafeHer AI - Application Configuration
======================================
Loads environment variables and system settings for Google Maps APIs,
Firebase credentials, server host/port, and datasets directories.
Provides safe defaults so the application operates seamlessly in offline/development mode.
"""

import os
from typing import Optional
from dotenv import load_dotenv

# Load .env from project root (two levels above this file: app/core -> app -> backend -> root)
_ROOT_DIR_FOR_ENV = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
_env_path = os.path.join(_ROOT_DIR_FOR_ENV, ".env")
if os.path.exists(_env_path):
    load_dotenv(dotenv_path=_env_path, override=False)

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
FIREBASE_PROJECT_ID: str = os.getenv("FIREBASE_PROJECT_ID", "")
FIREBASE_CREDENTIALS_JSON: str = os.getenv("FIREBASE_CREDENTIALS_JSON", "")

# Configurable CORS allowed origins (comma-separated list via ALLOWED_ORIGINS environment variable)
_raw_cors = os.getenv("ALLOWED_ORIGINS", "")
ALLOWED_ORIGINS: list = [o.strip() for o in _raw_cors.split(",") if o.strip()] if _raw_cors else [
    "http://localhost",
    "http://localhost:3000",
    "http://localhost:8000",
    "http://localhost:8080",
    "http://127.0.0.1",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:8000",
    "http://127.0.0.1:8080",
    "http://10.0.2.2",         # Android Studio emulator host loopback
    "http://10.0.2.2:8000",
]


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
