# SafeHer AI – Backend API

FastAPI backend powering the SafeHer AI route safety scoring engine for Hyderabad, India.

---

## Backend Architecture

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                  # FastAPI application, CORS, exception handlers, startup
│   ├── api/
│   │   ├── __init__.py
│   │   └── routes.py            # Endpoint registration (GET /health, POST /api/v1/safety/score)
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── route.py             # Pydantic request schema (CoordinatePoint, RouteScoreRequest)
│   │   └── safety.py            # Pydantic response schema (RouteScoreResponse, etc.)
│   ├── services/
│   │   ├── __init__.py
│   │   └── route_service.py     # Application service bridging API to SafetyScorer
│   └── ml/
│       ├── config.py            # Configurable weights, thresholds, dataset paths
│       ├── normalization.py     # Mathematical normalization functions and score calculation
│       ├── spatial_features.py  # Dataset loaders, Haversine geometry, spatial extractors
│       ├── safety_scorer.py     # Core SafetyScorer engine and route comparison logic
│       └── demo_scoring.py      # Synthetic geometry test/demo script
├── tests/
│   ├── test_safety_scoring.py   # 14 ML scoring engine unit tests
│   └── test_api.py              # FastAPI endpoint integration tests
├── requirements.txt
└── README.md
```

---

## Setup Instructions

### 1. Prerequisites
- Python 3.12 (or 3.10+)
- All datasets present in `SafeHerAI/datasets/` (verified spatial datasets from Phase 2)

### 2. Create a Virtual Environment
```bash
cd SafeHerAI/backend
python -m venv venv
```

### 3. Activate the Virtual Environment
**Windows (PowerShell):**
```powershell
.\venv\Scripts\Activate.ps1
```
**Windows (Command Prompt):**
```cmd
venv\Scripts\activate.bat
```
**macOS / Linux:**
```bash
source venv/bin/activate
```

### 4. Install Requirements
```bash
pip install -r requirements.txt
```

### 5. Environment Variables
No API keys are required to run the scoring backend.
When Google APIs and Firebase are integrated in a later phase, copy `.env.example` (to be created) and fill in your own credentials. Never commit secrets to Git.

---

## Running the Backend

From the project root (`SafeHerAI/`):
```bash
uvicorn backend.app.main:app --reload --host 0.0.0.0 --port 8000
```

Or from inside the `backend/` directory:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### API Documentation
Once running, open in your browser:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **Health Check**: http://localhost:8000/health

---

## API Endpoints

### `GET /health`
Returns service operational status.

**Response:**
```json
{
  "status": "ok",
  "service": "SafeHer AI backend"
}
```

---

### `POST /api/v1/safety/score`
Evaluates a route polyline against genuine Hyderabad spatial datasets and official police zone statistics.

**Request Body:**
```json
{
  "route_id": "route_alpha",
  "route_coords": [
    {"latitude": 17.4100, "longitude": 78.4500},
    {"latitude": 17.4150, "longitude": 78.4550},
    {"latitude": 17.4200, "longitude": 78.4600}
  ],
  "route_distance_km": 1.85,
  "route_duration_min": 8.0
}
```

**Response:**
```json
{
  "route_id": "route_alpha",
  "safety_score": 65.5,
  "safety_tier": "Moderate Safety Corridor",
  "route_distance_km": 1.85,
  "straight_line_distance_km": 1.82,
  "detour_ratio": 1.02,
  "route_duration_min": 8.0,
  "components": {
    "S_police": 0.8368,
    "S_medical": 0.9879,
    "S_transit": 0.9218,
    "S_arterial": 0.0625,
    "P_crime": 1.0,
    "P_blackspot": 0.0,
    "P_exposure": 0.0
  },
  "contributions": {
    "police_pts": 20.92,
    "medical_pts": 14.82,
    "transit_pts": 13.83,
    "arterial_pts": 0.94,
    "crime_compliance_pts": 0.0,
    "blackspot_compliance_pts": 10.0,
    "exposure_compliance_pts": 5.0
  },
  "raw_features": {
    "avg_police_dist_km": 0.49,
    "police_within_1km_count": 3,
    "min_hospital_dist_km": 0.04,
    "transit_count_within_500m": 17,
    "arterial_length_km": 0.12,
    "traversed_zones": ["West Zone"],
    "blackspot_count": 0
  },
  "limitations_and_proxies": [
    "Transit Presence is a contextual infrastructure proxy...",
    "Arterial Road Hierarchy reflects classified primary roadway proportion...",
    "Crime Volume is derived from official Hyderabad City Police annual reports at zone level...",
    "Traffic Accident Black Spots represent vehicular collision junctions...",
    "The Safety Score is an analytical comparative estimate and does not guarantee absolute safety."
  ]
}
```

> **Note:** The example coordinates and values above are illustrative. Always supply real route geometry from Google Directions API in production use.

---

## Synthetic TEST DATA Example Request

> **IMPORTANT:** The coordinates below are SYNTHETIC TEST GEOMETRIES for software testing only.
> They are NOT real Hyderabad travel routes and MUST NOT be treated as empirical project results.

```bash
curl -X POST http://localhost:8000/api/v1/safety/score \
  -H "Content-Type: application/json" \
  -d '{
    "route_id": "SYNTHETIC_TEST_ONLY",
    "route_coords": [
      {"latitude": 17.4100, "longitude": 78.4500},
      {"latitude": 17.4150, "longitude": 78.4550},
      {"latitude": 17.4200, "longitude": 78.4600},
      {"latitude": 17.4250, "longitude": 78.4650}
    ],
    "route_distance_km": 3.07,
    "route_duration_min": 18.5
  }'
```

---

## Running Tests

### ML Scoring Engine Tests (14 tests)
```bash
python -m unittest backend/tests/test_safety_scoring.py
```

### FastAPI API Endpoint Tests
```bash
python -m unittest backend/tests/test_api.py
```

### Run All Tests
```bash
python -m unittest discover -s backend/tests -p "test_*.py"
```

---

## Safety Score Interpretation

| Score Range | Tier | Meaning |
|---|---|---|
| 75.0 – 100.0 | Comparatively Safer Route | Higher police proximity, emergency access, transit density |
| 50.0 – 74.9 | Moderate Safety Corridor | Standard urban infrastructure presence |
| 0.0 – 49.9 | Caution Advised Corridor | Lower infrastructure density or proximity to identified hazards |

> The score is a comparative analytical estimate — not a guarantee of safety.

---

## Important Notes

- **Google APIs are optional** — the backend includes a high-fidelity offline fallback routing engine using verified Hyderabad landmarks. Add `GOOGLE_MAPS_API_KEY` to `.env` for real-time routing.
- **Firebase is optional** — JWT-based authentication operates without Firebase. Set `FIREBASE_PROJECT_ID` and `FIREBASE_CREDENTIALS_PATH` to enable Firebase token exchange.
- **Flutter frontend is fully implemented** — see `frontend/` directory. CORS is pre-configured for `localhost:3000/8000/8080` and Android emulator (`10.0.2.2`).
- **No API keys are stored in source code** — all credentials use environment variables. See `.env.example` in the project root.
- **43 tests pass** (14 ML unit tests + 29 API integration tests) covering all endpoints.
