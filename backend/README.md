# SafeHer AI — FastAPI Backend API

**High-Performance Women-Safety Route-Scoring Engine & Navigation Service**

The SafeHer AI backend is a production-grade REST API built using **Python 3.12 and FastAPI**. It powers the multi-criteria route safety scoring engine, calculates turn-by-turn navigation maneuvers, searches Hyderabad landmarks, indexes emergency amenities, and manages user journeys.

---

## Live Cloud Deployment on Render

The backend is deployed as a Web Service on Render:

| Service | URL | Status / Notes |
|---|---|---|
| **Base URL** | `https://safeherai-4baw.onrender.com` | FastAPI ASGI Service |
| **Health Check** | `https://safeherai-4baw.onrender.com/health` | Returns `{"status":"ok","service":"SafeHer AI backend"}` |
| **Swagger UI** | `https://safeherai-4baw.onrender.com/docs` | Interactive OpenAPI documentation |
| **ReDoc UI** | `https://safeherai-4baw.onrender.com/redoc` | Static documentation view |
| **Web Client** | `https://safeherai-4baw.onrender.com/` | Interactive web interface |

> [!NOTE]
> On Render's free tier, containers spin down after 15 minutes of inactivity. When the backend receives a request while idle, Render triggers an automatic container spin-up (30–50 seconds). Once warm, endpoints respond in standard latency (<100ms).

---

## Architecture & Real Directory Structure

```
backend/
├── app/
│   ├── api/
│   │   ├── __init__.py
│   │   └── routes.py             # All 21 REST API endpoints
│   ├── core/
│   │   ├── __init__.py
│   │   └── config.py             # Env loading, CORS list, paths, helplines
│   ├── ml/
│   │   ├── __init__.py
│   │   ├── config.py             # 7-factor weights, spatial buffers, scoring tiers
│   │   ├── normalization.py      # Mathematical normalization & decay functions
│   │   ├── spatial_features.py   # Spatial queries, Haversine, GeoJSON parsing
│   │   ├── safety_scorer.py      # Core SafetyScorer engine & comparison logic
│   │   └── demo_scoring.py       # Standalone scoring demonstration script
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── amenity.py            # Nearest hospital/police schemas
│   │   ├── journey.py            # Journey start/event/complete models
│   │   ├── navigation.py         # Maneuver steps, routes, turn directions
│   │   ├── route.py              # CoordinatePoint, RouteScoreRequest
│   │   ├── safety.py             # Safety score breakdowns and tiers
│   │   ├── sos.py                # SOS alert and trusted contact schemas
│   │   └── user.py               # User profiles, login, and registration
│   ├── services/
│   │   ├── __init__.py
│   │   ├── amenities_service.py  # Spatial indexing of police, hospitals, transit
│   │   ├── auth_service.py       # Firebase ID token validation & JWT fallback
│   │   ├── journey_service.py    # Active journeys, telemetry, and CSV feedback
│   │   ├── navigation_service.py # Polyline decoding, turn maneuvers, offline routes
│   │   ├── route_service.py      # Adapter connecting REST routes to SafetyScorer
│   │   └── sos_service.py        # SOS incident logging & tactical safety tips
│   ├── static/
│   │   └── index.html            # Web preview and route visualization interface
│   └── main.py                   # FastAPI app instance, CORS middleware, startup events
├── tests/
│   ├── test_api.py               # 20 tests: Scoring endpoints and validation
│   ├── test_end_to_end_services.py # 12 tests: Navigation, places, SOS, and amenities
│   ├── test_journey_api.py       # 1 test: Journey lifecycle and telemetry logging
│   └── test_safety_scoring.py    # 14 tests: ML mathematical formulas and spatial features
├── requirements.txt              # Pinned production Python dependencies
└── README.md                     # Backend reference documentation
```

---

## Spatial Datasets & ML Scoring Engine

The scoring engine loads verified non-synthetic datasets for Hyderabad at startup from `datasets/`:
- **Police Accessibility (25%)**: `datasets/police_stations.geojson` (exponential decay beyond 4 km, buffer saturation).
- **Emergency Medical Coverage (15%)**: `datasets/hospitals.csv` (linear decay within 3 km).
- **Public Transit Presence (15%)**: `datasets/transport_stations.csv` (HMRL Metro & TSRTC stops per km).
- **Arterial Road Hierarchy (15%)**: `datasets/roads/hyderabad_major_roads.geojson` (OSM primary corridors).
- **Jurisdictional Crime Penalty (15%)**: `datasets/crime_data.csv` (official Hyderabad police zone crime review).
- **Accident Black Spot Hazard (10%)**: `datasets/road_accidents.csv` (GHMC/HMDA collision junctions).
- **Route Detour Ratio (5%)**: Ratio of road distance to straight-line Haversine distance.

$$\text{Safety Score} \in [0.0, 100.0]$$

---

## Registered REST API Endpoints (21 Endpoints)

Verified against [`backend/app/api/routes.py`](app/api/routes.py):

### 1. Health & Documentation
| Method | Path | Description |
|---|---|---|
| `GET` | `/health` | Returns service status: `{"status":"ok","service":"SafeHer AI backend"}` |
| `GET` | `/docs` | Interactive Swagger documentation |
| `GET` | `/redoc` | ReDoc OpenAPI documentation |

### 2. Safety Scoring & Proximity
| Method | Path | Description |
|---|---|---|
| `POST` | `/api/v1/safety/score` | Calculates 7-factor safety breakdown and score tier for route coordinates. |
| `GET` | `/api/v1/safety/nearby-safe-spots` | Returns closest police stations, emergency hospitals, and transit stops by GPS. |

### 3. Route Planning & Navigation
| Method | Path | Description |
|---|---|---|
| `POST` | `/api/v1/routes/plan` | Generates multiple route options between two points, ranks them by safety, and includes navigation steps. |
| `POST` | `/api/v1/navigation/route` | Generates turn-by-turn maneuvers (e.g. Turn Left, Turn Right) and encoded polylines. |
| `GET` | `/api/v1/places/autocomplete` | Searches Hyderabad landmarks, metro stations, and neighborhoods. |
| `GET` | `/api/v1/places/reverse-geocode` | Converts GPS coordinates into a readable landmark or street address. |

### 4. Emergency SOS & Contacts
| Method | Path | Description |
|---|---|---|
| `POST` | `/api/v1/sos/trigger` | Triggers SOS event, identifies nearest police station, and generates tactical advice. |
| `GET` | `/api/v1/user/contacts` | Lists registered trusted contacts for a user. |
| `POST` | `/api/v1/user/contacts` | Adds a new trusted emergency contact. |
| `PUT` | `/api/v1/user/contacts/{contact_id}` | Updates existing emergency contact details. |
| `DELETE` | `/api/v1/user/contacts/{contact_id}` | Removes a trusted contact. |

### 5. User Authentication & Profile
| Method | Path | Description |
|---|---|---|
| `POST` | `/api/v1/auth/firebase` | Verifies mobile client Firebase ID token and issues backend session profile. |
| `POST` | `/api/v1/auth/register` | Direct email/password registration (with SHA-256 salt/hash). |
| `POST` | `/api/v1/auth/login` | Direct login returning JWT access token. |
| `PUT` | `/api/v1/user/profile` | Updates user display name and emergency phone number. |

### 6. Journey Tracking & Observational Feedback
| Method | Path | Description |
|---|---|---|
| `POST` | `/api/v1/journey/start` | Registers an active navigation session. |
| `POST` | `/api/v1/journey/event` | Records off-route, delay, or emergency events during a journey. |
| `POST` | `/api/v1/journey/complete` | Completes journey and logs user safety rating and feedback. |
| `GET` | `/api/v1/journey/feedback` | Reads accumulated records from `datasets/journey_feedback.csv`. |
| `GET` | `/api/v1/journey/user` | Lists historical journeys for a user. |

---

## Local Setup & Execution

### 1. Requirements
- Python 3.10 to 3.12 (tested on Python 3.12.6)
- Windows, macOS, or Linux

### 2. Environment Setup
```powershell
# Navigate to backend directory
cd C:\SafeHerAI\backend

# Create virtual environment
python -m venv venv
.\venv\Scripts\Activate.ps1    # macOS/Linux: source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 3. Running the Server Locally
```powershell
# Run from backend directory:
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
Binds to `0.0.0.0` to permit connections from mobile emulators and physical devices on the local network.

---

## Running Backend Automated Tests

SafeHer AI includes 47 tests across 4 test modules:

```powershell
cd C:\SafeHerAI\backend
pytest -v
```

**Test Coverage Breakdown:**
- `tests/test_safety_scoring.py` (14 tests): Mathematical normalization functions, Haversine geometry, sampling, safety boundary conditions.
- `tests/test_api.py` (20 tests): Health check, valid scoring inputs, validation error handling (HTTP 422).
- `tests/test_end_to_end_services.py` (12 tests): Place autocomplete, turn-by-turn navigation maneuvers, reverse geocoding, SOS flow, authentication.
- `tests/test_journey_api.py` (1 test): Full journey start, event logging, and completion flow.

---

## Cloud Deployment Configuration (Render)

The backend is configured for deployment as a **Render Web Service**:

1. **Runtime:** Python 3
2. **Build Command:**
   ```bash
   pip install -r requirements.txt
   ```
3. **Start Command:**
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port $PORT
   ```
   *Note: In production on Render, `$PORT` is injected dynamically (typically port 10000).*
4. **Environment Variables on Render:**
   - `HOST`: `0.0.0.0`
   - `DEBUG`: `False`
   - `JWT_SECRET_KEY`: `<generated-secret-key>`
   - `ALLOWED_ORIGINS`: `*` (or your production frontend domain)
   - `FIREBASE_PROJECT_ID`: `safeher-ai-491ad` (optional)
   - `FIREBASE_CREDENTIALS_JSON`: Raw JSON string of the Firebase service account (optional; enables in-memory initialization without committing credentials to Git)

---

## Security & Secrets Management

- **Credentials Protection**: `.gitignore` strictly ignores `.env`, `firebase-service-account.json`, and all `*-adminsdk-*.json` files.
- **In-Memory Cloud Loading**: `auth_service.py` supports `FIREBASE_CREDENTIALS_JSON`, allowing cloud providers to pass credentials securely via environment variables without creating filesystem traces.
- **Graceful Offline Mode**: If Firebase credentials are not provided, the backend falls back gracefully to local JWT sessions and local storage, ensuring core safety scoring and navigation remain fully operational.
