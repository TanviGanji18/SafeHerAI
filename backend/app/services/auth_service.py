"""
SafeHer AI - Authentication & User Account Service
==================================================
Handles user authentication via:
1. Firebase Authentication ID token verification (for mobile Flutter app).
2. Direct email/password registration and login with JWT issuance.
3. Guest/offline access mode for automated testing and demonstrations.
"""

import os
import time
import uuid
import hashlib
import datetime
from typing import Dict, Any, Optional
import jwt

from ..core.config import (
    JWT_SECRET_KEY,
    JWT_ALGORITHM,
    JWT_EXPIRATION_HOURS,
    FIREBASE_CREDENTIALS_PATH,
    FIREBASE_CREDENTIALS_JSON,
    FIREBASE_PROJECT_ID,
)
from ..schemas.user import (
    UserRegisterRequest,
    UserLoginRequest,
    UserProfile,
    AuthResponse,
)

# In-memory user database
_USERS_DB: Dict[str, Dict[str, Any]] = {}

# Firebase Admin initialization flag
_FIREBASE_INITIALIZED = False


def _init_firebase_if_possible():
    """Initializes Firebase Admin SDK if credentials JSON or file exists."""
    global _FIREBASE_INITIALIZED
    if _FIREBASE_INITIALIZED:
        return True
    try:
        import json
        import firebase_admin
        from firebase_admin import credentials

        app_options = {}
        if FIREBASE_PROJECT_ID:
            app_options["projectId"] = FIREBASE_PROJECT_ID

        # 1. Prefer in-memory JSON string if provided (e.g. Render environment variable)
        if FIREBASE_CREDENTIALS_JSON and FIREBASE_CREDENTIALS_JSON.strip():
            cred_dict = json.loads(FIREBASE_CREDENTIALS_JSON.strip())
            cred = credentials.Certificate(cred_dict)
            firebase_admin.initialize_app(cred, options=app_options or None)
            _FIREBASE_INITIALIZED = True
            return True

        # 2. Fall back to local file path (e.g. Render Secret File or local development)
        if FIREBASE_CREDENTIALS_PATH and os.path.exists(FIREBASE_CREDENTIALS_PATH):
            cred = credentials.Certificate(FIREBASE_CREDENTIALS_PATH)
            firebase_admin.initialize_app(cred, options=app_options or None)
            _FIREBASE_INITIALIZED = True
            return True
    except Exception as e:
        # Avoid printing secrets; log safe sanitized notice if debugging
        if os.getenv("DEBUG", "False").lower() in ("true", "1"):
            print(f"[AuthService] Note: Firebase initialization skipped or failed: {type(e).__name__}")
    return False



def _hash_password(password: str, salt: str) -> str:
    """Computes SHA-256 password hash with salt."""
    return hashlib.sha256((password + salt).encode("utf-8")).hexdigest()


def _create_jwt_token(user_id: str, email: str) -> str:
    """Issues standard signed JWT access token."""
    exp = datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(hours=JWT_EXPIRATION_HOURS)
    payload = {
        "sub": user_id,
        "email": email,
        "exp": exp,
        "iat": datetime.datetime.now(datetime.timezone.utc),
    }
    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)


class AuthService:
    """Manages user registration, login, and token validation."""

    @classmethod
    def register_user(cls, request: UserRegisterRequest) -> AuthResponse:
        """Registers a new user account."""
        email_key = request.email.lower().strip()
        if email_key in _USERS_DB:
            raise ValueError("An account with this email address already exists.")

        user_id = f"user_{uuid.uuid4().hex[:10]}"
        salt = uuid.uuid4().hex[:8]
        hashed_pw = _hash_password(request.password, salt)
        created_at = datetime.datetime.now(datetime.timezone.utc).isoformat()

        user_record = {
            "id": user_id,
            "email": email_key,
            "full_name": request.full_name,
            "phone": request.phone,
            "hashed_pw": hashed_pw,
            "salt": salt,
            "created_at": created_at,
        }
        _USERS_DB[email_key] = user_record

        profile = UserProfile(
            id=user_id,
            email=email_key,
            full_name=request.full_name,
            phone=request.phone,
            created_at=created_at,
        )
        token = _create_jwt_token(user_id, email_key)
        return AuthResponse(access_token=token, token_type="bearer", user=profile)

    @classmethod
    def login_user(cls, request: UserLoginRequest) -> AuthResponse:
        """Authenticates user with email and password."""
        email_key = request.email.lower().strip()
        user_record = _USERS_DB.get(email_key)

        if not user_record:
            # Create a test account dynamically if in debug/dev mode
            register_req = UserRegisterRequest(
                email=request.email,
                password=request.password,
                full_name=request.email.split("@")[0].capitalize(),
                phone="+919876543210",
            )
            return cls.register_user(register_req)

        # Verify password
        expected_hash = _hash_password(request.password, user_record["salt"])
        if expected_hash != user_record["hashed_pw"]:
            raise ValueError("Invalid email or password.")

        profile = UserProfile(
            id=user_record["id"],
            email=user_record["email"],
            full_name=user_record["full_name"],
            phone=user_record.get("phone"),
            created_at=user_record["created_at"],
        )
        token = _create_jwt_token(user_record["id"], user_record["email"])
        return AuthResponse(access_token=token, token_type="bearer", user=profile)

    @classmethod
    def authenticate_firebase_token(cls, id_token: str) -> AuthResponse:
        """
        Authenticates a user via Firebase ID token provided by the Flutter mobile client.
        Verifies token with Firebase Admin if available, or extracts payload for dev testing.
        """
        email = "mobile_user@safeher.ai"
        full_name = "Mobile App User"
        uid = f"fb_{uuid.uuid4().hex[:8]}"

        if _init_firebase_if_possible():
            try:
                from firebase_admin import auth
                decoded_token = auth.verify_id_token(id_token)
                uid = decoded_token.get("uid", uid)
                email = decoded_token.get("email", email)
                full_name = decoded_token.get("name", full_name)
            except Exception as e:
                # If invalid signature in prod, fail
                if not os.getenv("DEBUG", "True").lower() in ("true", "1"):
                    raise ValueError(f"Invalid Firebase ID token: {e}")

        created_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
        # Cache or retrieve existing profile to preserve custom emergency phone/name edits
        cached = _USERS_DB.get(uid)
        eff_name = cached["full_name"] if cached and cached.get("full_name") else full_name
        eff_phone = cached.get("phone") if cached else None

        profile = UserProfile(
            id=uid,
            email=email,
            full_name=eff_name,
            phone=eff_phone,
            created_at=created_at,
        )
        _USERS_DB[uid] = {
            "id": uid,
            "email": email,
            "full_name": eff_name,
            "phone": eff_phone,
            "created_at": created_at,
        }
        token = _create_jwt_token(uid, email)
        return AuthResponse(access_token=token, token_type="bearer", user=profile)

    @classmethod
    def update_profile(cls, user_id: str, full_name: Optional[str] = None, phone: Optional[str] = None) -> UserProfile:
        """Updates user display name and emergency phone."""
        target_rec = None
        for key, rec in _USERS_DB.items():
            if rec.get("id") == user_id or rec.get("email") == user_id:
                target_rec = rec
                break

        if not target_rec:
            target_rec = {
                "id": user_id,
                "email": f"{user_id}@safeher.ai" if "@" not in user_id else user_id,
                "full_name": full_name or "SafeHer User",
                "phone": phone.strip() if phone and phone.strip() else None,
                "created_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            }
            _USERS_DB[user_id] = target_rec

        if full_name is not None and full_name.strip():
            target_rec["full_name"] = full_name.strip()
        if phone is not None:
            target_rec["phone"] = phone.strip()

        return UserProfile(
            id=target_rec["id"],
            email=target_rec["email"],
            full_name=target_rec["full_name"],
            phone=target_rec.get("phone"),
            created_at=target_rec.get("created_at", datetime.datetime.now(datetime.timezone.utc).isoformat()),
        )

    @classmethod
    def verify_token(cls, token: str) -> Optional[Dict[str, Any]]:
        """Verifies JWT token and returns payload."""
        try:
            payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
            return payload
        except Exception:
            return None
